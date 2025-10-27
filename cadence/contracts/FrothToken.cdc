// FrothToken.cdc - Mock $FROTH reward token for Seflow
// Reward token for salary splitting and yield compounding actions
access(all) contract FrothToken {
    
    // Total supply of FROTH tokens
    access(all) var totalSupply: UFix64
    
    // Events
    access(all) event TokensInitialized(initialSupply: UFix64)
    access(all) event TokensWithdrawn(amount: UFix64, from: Address?)
    access(all) event TokensDeposited(amount: UFix64, to: Address?)
    access(all) event TokensMinted(amount: UFix64, to: Address?)
    
    // Vault Resource - Holds FROTH tokens
    access(all) resource Vault {
        access(all) var balance: UFix64
        
        init(balance: UFix64) {
            self.balance = balance
        }
        
        // Withdraw FROTH tokens from vault
        access(all) fun withdraw(amount: UFix64): @Vault {
            pre {
                amount > 0.0: "Withdrawal amount must be positive"
                amount <= self.balance: "Insufficient FROTH balance"
            }
            post {
                self.balance == before(self.balance) - amount: "Incorrect balance after withdrawal"
            }
            
            self.balance = self.balance - amount
            emit TokensWithdrawn(amount: amount, from: self.owner?.address)
            return <-create Vault(balance: amount)
        }
        
        // Deposit FROTH tokens to vault
        access(all) fun deposit(from: @Vault) {
            pre {
                from.balance > 0.0: "Deposit amount must be positive"
            }
            post {
                self.balance == before(self.balance) + before(from.balance): "Incorrect balance after deposit"
            }
            
            let amount = from.balance
            self.balance = self.balance + amount
            emit TokensDeposited(amount: amount, to: self.owner?.address)
            destroy from
        }
        
        // Get current balance
        access(all) fun getBalance(): UFix64 {
            return self.balance
        }
    }
    
    // Create empty vault for users
    access(all) fun createEmptyVault(): @Vault {
        return <-create Vault(balance: 0.0)
    }
    
    // Admin function to mint FROTH tokens (for rewards)
    access(all) fun mintTokens(amount: UFix64): @Vault {
        pre {
            amount > 0.0: "Mint amount must be positive"
        }
        post {
            FrothToken.totalSupply == before(FrothToken.totalSupply) + amount: "Total supply not updated correctly"
        }
        
        FrothToken.totalSupply = FrothToken.totalSupply + amount
        return <-create Vault(balance: amount)
    }
    
    // Get total supply
    access(all) fun getTotalSupply(): UFix64 {
        return FrothToken.totalSupply
    }
    
    // Contract initialization
    init() {
        self.totalSupply = 0.0
        
        // Create admin vault with initial supply for testing
        let adminVault <- create Vault(balance: 0.0)
        self.account.storage.save(<-adminVault, to: /storage/frothAdminVault)
        
        // Create public capability for admin vault
        let adminCap = self.account.capabilities.storage.issue<&Vault>(/storage/frothAdminVault)
        self.account.capabilities.publish(adminCap, at: /public/frothAdminVault)
        
        emit TokensInitialized(initialSupply: self.totalSupply)
    }
}