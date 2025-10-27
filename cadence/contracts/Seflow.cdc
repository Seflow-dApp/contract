// Seflow.cdc - Core contract for salary splitting and compounding
// Main contract implementing Flow Actions and Scheduled Transactions
access(all) contract Seflow {
    
    // Contract state
    access(all) var totalUsers: UInt64
    access(all) var totalSplits: UInt64
    access(all) var totalVolumeProcessed: UFix64
    
    // Events for Flow Actions and Scheduled Transactions
    access(all) event ContractInitialized()
    access(all) event UserRegistered(user: Address)
    access(all) event SalarySplit(
        sender: Address, 
        total: UFix64, 
        save: UFix64, 
        lp: UFix64, 
        spend: UFix64, 
        vault: Bool,
        frothReward: UFix64
    )
    access(all) event YieldCompounded(user: Address, yield: UFix64, frothReward: UFix64)
    access(all) event VaultSetup(user: Address, vaultType: String)
    
    // User Profile Resource - Tracks user's Seflow activity
    access(all) resource UserProfile {
        access(all) var totalSplits: UInt64
        access(all) var totalVolume: UFix64
        access(all) var totalFrothEarned: UFix64
        access(all) var totalYieldEarned: UFix64
        access(all) var lastSplitTime: UFix64
        access(all) var lastCompoundTime: UFix64
        access(all) var hasVaultSetup: Bool
        access(all) var hasSavingsVault: Bool
        access(all) var hasLPVault: Bool
        access(all) var hasFrothVault: Bool
        
        init() {
            self.totalSplits = 0
            self.totalVolume = 0.0
            self.totalFrothEarned = 0.0
            self.totalYieldEarned = 0.0
            self.lastSplitTime = getCurrentBlock().timestamp
            self.lastCompoundTime = getCurrentBlock().timestamp
            self.hasVaultSetup = false
            self.hasSavingsVault = false
            self.hasLPVault = false
            self.hasFrothVault = false
        }
        
        // Update profile after salary split
        access(all) fun recordSplit(amount: UFix64, frothReward: UFix64) {
            self.totalSplits = self.totalSplits + 1
            self.totalVolume = self.totalVolume + amount
            self.totalFrothEarned = self.totalFrothEarned + frothReward
            self.lastSplitTime = getCurrentBlock().timestamp
        }
        
        // Update profile after yield compound
        access(all) fun recordCompound(yieldAmount: UFix64, frothReward: UFix64) {
            self.totalYieldEarned = self.totalYieldEarned + yieldAmount
            self.totalFrothEarned = self.totalFrothEarned + frothReward
            self.lastCompoundTime = getCurrentBlock().timestamp
        }
        
        // Set vault setup status
        access(all) fun markVaultSetup(vaultType: String) {
            self.hasVaultSetup = true
            if vaultType == "savings" {
                self.hasSavingsVault = true
            } else if vaultType == "lp" {
                self.hasLPVault = true
            } else if vaultType == "froth" {
                self.hasFrothVault = true
            }
        }
        
        // Get profile stats
        access(all) fun getStats(): {String: AnyStruct} {
            return {
                "totalSplits": self.totalSplits,
                "totalVolume": self.totalVolume,
                "totalFrothEarned": self.totalFrothEarned,
                "totalYieldEarned": self.totalYieldEarned,
                "lastSplitTime": self.lastSplitTime,
                "lastCompoundTime": self.lastCompoundTime,
                "hasVaultSetup": self.hasVaultSetup,
                "hasSavingsVault": self.hasSavingsVault,
                "hasLPVault": self.hasLPVault,
                "hasFrothVault": self.hasFrothVault
            }
        }
    }
    
    // Create user profile
    access(all) fun createUserProfile(): @UserProfile {
        return <-create UserProfile()
    }
    
    // Flow Action: Atomic Salary Split
    // Implements FLIP-338 for atomic workflow execution
    access(all) fun salarySplit(
        userAddress: Address,
        totalAmount: UFix64,
        savePercent: UFix64,
        lpPercent: UFix64,
        spendPercent: UFix64,
        useVault: Bool
    ): {String: UFix64} {
        pre {
            totalAmount > 0.0: "Total amount must be positive"
            savePercent >= 0.0 && savePercent <= 100.0: "Save percent must be 0-100"
            lpPercent >= 0.0 && lpPercent <= 100.0: "LP percent must be 0-100"
            spendPercent >= 0.0 && spendPercent <= 100.0: "Spend percent must be 0-100"
            savePercent + lpPercent + spendPercent == 100.0: "Percentages must sum to 100"
        }
        
        // Calculate split amounts
        let saveAmount = totalAmount * savePercent / 100.0
        let lpAmount = totalAmount * lpPercent / 100.0
        let spendAmount = totalAmount * spendPercent / 100.0
        
        // Mock Find Labs API balance check (commented for hackathon)
        // GET /wallets/{userAddress} to verify totalAmount <= balance
        // let userBalance = FindLabsAPI.getWalletBalance(userAddress)
        // assert(totalAmount <= userBalance, message: "Insufficient wallet balance")
        
        // Calculate FROTH reward (1.5 for vault, 1.0 for wallet)
        let frothReward = useVault ? 1.5 : 1.0
        
        // Update contract stats
        self.totalSplits = self.totalSplits + 1
        self.totalVolumeProcessed = self.totalVolumeProcessed + totalAmount
        
        // Emit Flow Action event for atomic execution
        emit SalarySplit(
            sender: userAddress,
            total: totalAmount,
            save: saveAmount,
            lp: lpAmount,
            spend: spendAmount,
            vault: useVault,
            frothReward: frothReward
        )
        
        // Return split results for frontend display
        return {
            "totalAmount": totalAmount,
            "saveAmount": saveAmount,
            "lpAmount": lpAmount,
            "spendAmount": spendAmount,
            "frothReward": frothReward,
            "useVault": useVault ? 1.0 : 0.0,
            "timestamp": getCurrentBlock().timestamp
        }
    }
    
    // Scheduled Transaction: Weekly Yield Compounding
    // Implements Forte Scheduled Transactions for automated execution
    access(all) fun compoundYield(userAddress: Address): {String: UFix64} {
        pre {
            userAddress != nil: "User address cannot be nil"
        }
        
        // Mock LP yield calculation (1% weekly)
        // In production, this would interact with real LP contracts
        let mockLPBalance = 100.0 // This would come from user's LP position
        let weeklyYieldRate = 0.01 // 1% weekly yield
        let yieldAmount = mockLPBalance * weeklyYieldRate
        
        // FROTH reward for compounding (0.5 tokens)
        let frothReward = 0.5
        
        // Update contract stats
        self.totalVolumeProcessed = self.totalVolumeProcessed + yieldAmount
        
        // Emit Scheduled Transaction event
        emit YieldCompounded(
            user: userAddress,
            yield: yieldAmount,
            frothReward: frothReward
        )
        
        // Return compound results
        return {
            "yieldAmount": yieldAmount,
            "frothReward": frothReward,
            "timestamp": getCurrentBlock().timestamp,
            "weeklyRate": weeklyYieldRate * 100.0 // Return as percentage
        }
    }
    
    // Setup user vaults (one-time setup)
    access(all) fun setupUserVaults(userAddress: Address): {String: Bool} {
        // This would set up the user's savings vault, LP vault, and FROTH vault
        // For hackathon, we'll mock the setup process
        
        emit VaultSetup(user: userAddress, vaultType: "all")
        
        return {
            "savingsVaultCreated": true,
            "lpVaultCreated": true,
            "frothVaultCreated": true,
            "setupComplete": true
        }
    }
    
    // Get contract statistics
    access(all) fun getContractStats(): {String: AnyStruct} {
        return {
            "totalUsers": self.totalUsers,
            "totalSplits": self.totalSplits,
            "totalVolumeProcessed": self.totalVolumeProcessed,
            "contractAddress": self.account.address,
            "deployedAt": getCurrentBlock().timestamp
        }
    }
    
    // Register new user
    access(all) fun registerUser(userAddress: Address) {
        self.totalUsers = self.totalUsers + 1
        emit UserRegistered(user: userAddress)
    }
    
    // Mock Find Labs API integration (for hackathon)
    access(all) fun mockFindLabsBalance(userAddress: Address): {String: UFix64} {
        // In production: GET https://api.find.com/wallets/{userAddress}
        // Returns: { "flow": 150.0, "savings": 75.0, "lp": 45.0, "froth": 12.5 }
        return {
            "flowBalance": 150.0,
            "savingsBalance": 75.0,
            "lpBalance": 45.0,
            "frothBalance": 12.5,
            "lastUpdated": getCurrentBlock().timestamp
        }
    }
    
    // Validate salary split parameters
    access(all) fun validateSplitParams(
        savePercent: UFix64,
        lpPercent: UFix64,
        spendPercent: UFix64
    ): Bool {
        return savePercent >= 0.0 && 
               lpPercent >= 0.0 && 
               spendPercent >= 0.0 &&
               savePercent <= 100.0 && 
               lpPercent <= 100.0 && 
               spendPercent <= 100.0 &&
               savePercent + lpPercent + spendPercent == 100.0
    }
    
    // Contract initialization
    init() {
        self.totalUsers = 0
        self.totalSplits = 0
        self.totalVolumeProcessed = 0.0
        
        // Create admin profile for testing
        let adminProfile <- create UserProfile()
        self.account.storage.save(<-adminProfile, to: /storage/seflowAdminProfile)
        
        // Create public capability for admin profile
        let adminCap = self.account.capabilities.storage.issue<&UserProfile>(/storage/seflowAdminProfile)
        self.account.capabilities.publish(adminCap, at: /public/seflowAdminProfile)
        
        emit ContractInitialized()
    }
}