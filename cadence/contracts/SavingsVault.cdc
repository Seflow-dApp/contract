// SavingsVault.cdc - Locked savings vault for Seflow
// 30-day locked savings vault with withdrawal restrictions

access(all) contract SavingsVault {
    
    // Events
    access(all) event VaultCreated(owner: Address?)
    access(all) event SavingsDeposited(amount: UFix64, to: Address?, lockTime: UFix64)
    access(all) event SavingsWithdrawn(amount: UFix64, from: Address?)
    access(all) event VaultLocked(owner: Address?, lockTime: UFix64)
    
    // Vault Resource - Holds locked FLOW tokens
    access(all) resource Vault {
        access(all) var balance: UFix64
        access(all) var lockTime: UFix64
        access(all) var isLocked: Bool
        
        // Lock duration in seconds (30 days)
        access(all) let lockDuration: UFix64
        
        init(balance: UFix64) {
            self.balance = balance
            self.lockTime = getCurrentBlock().timestamp
            self.isLocked = false
            self.lockDuration = 30.0 * 86400.0 // 30 days in seconds
        }
        
        // Deposit amount and activate lock
        access(all) fun deposit(amount: UFix64, activateLock: Bool) {
            pre {
                amount > 0.0: "Deposit amount must be positive"
            }
            post {
                self.balance == before(self.balance) + amount: "Balance not updated correctly"
            }
            
            self.balance = self.balance + amount
            
            // Activate lock if requested
            if activateLock {
                self.lockTime = getCurrentBlock().timestamp
                self.isLocked = true
                emit VaultLocked(owner: self.owner?.address, lockTime: self.lockTime)
            }
            
            emit SavingsDeposited(amount: amount, to: self.owner?.address, lockTime: self.lockTime)
        }
        
        // Withdraw amount (with lock check)
        access(all) fun withdraw(amount: UFix64): UFix64 {
            pre {
                amount > 0.0: "Withdrawal amount must be positive"
                amount <= self.balance: "Insufficient savings balance"
                !self.isLocked || getCurrentBlock().timestamp >= self.lockTime + self.lockDuration: 
                    "Vault is locked. Wait until lock period expires."
            }
            post {
                self.balance == before(self.balance) - amount: "Balance not updated correctly"
            }
            
            self.balance = self.balance - amount
            emit SavingsWithdrawn(amount: amount, from: self.owner?.address)
            return amount
        }
        
        // Check if vault is currently locked
        access(all) fun isCurrentlyLocked(): Bool {
            if !self.isLocked {
                return false
            }
            return getCurrentBlock().timestamp < self.lockTime + self.lockDuration
        }
        
        // Get remaining lock time in seconds
        access(all) fun getRemainingLockTime(): UFix64 {
            if !self.isLocked {
                return 0.0
            }
            let currentTime = getCurrentBlock().timestamp
            let unlockTime = self.lockTime + self.lockDuration
            
            if currentTime >= unlockTime {
                return 0.0
            }
            return unlockTime - currentTime
        }
        
        // Get unlock timestamp
        access(all) fun getUnlockTime(): UFix64 {
            if !self.isLocked {
                return getCurrentBlock().timestamp
            }
            return self.lockTime + self.lockDuration
        }
        
        // Get current balance
        access(all) fun getBalance(): UFix64 {
            return self.balance
        }
        
        // Get lock information
        access(all) fun getLockInfo(): {String: UFix64} {
            return {
                "balance": self.balance,
                "lockTime": self.lockTime,
                "unlockTime": self.getUnlockTime(),
                "remainingTime": self.getRemainingLockTime(),
                "isLocked": self.isLocked ? 1.0 : 0.0
            }
        }
    }
    
    // Create empty savings vault
    access(all) fun createEmptyVault(): @Vault {
        let vault <- create Vault(balance: 0.0)
        emit VaultCreated(owner: nil)
        return <-vault
    }
    
    // Contract initialization
    init() {
        // Create admin vault for testing
        let adminVault <- create Vault(balance: 0.0)
        self.account.storage.save(<-adminVault, to: /storage/savingsAdminVault)
        
        // Create public capability for admin vault
        let adminCap = self.account.capabilities.storage.issue<&Vault>(/storage/savingsAdminVault)
        self.account.capabilities.publish(adminCap, at: /public/savingsAdminVault)
    }
}