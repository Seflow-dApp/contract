// LiquidityPool.cdc - $FLOW/USDC LP for Seflow
access(all) contract LiquidityPool {
    
    // Pool stats
    access(all) var totalDeposits: UFix64
    access(all) var totalYieldPaid: UFix64
    access(all) let weeklyYieldRate: UFix64 // 1% weekly = 0.01
    
    // Events
    access(all) event PoolCreated(initialRate: UFix64)
    access(all) event LiquidityDeposited(amount: UFix64, to: Address?)
    access(all) event LiquidityWithdrawn(amount: UFix64, from: Address?)
    access(all) event YieldCompounded(amount: UFix64, to: Address?)
    access(all) event YieldCalculated(principal: UFix64, yield: UFix64, to: Address?)
    
    // Vault Resource - Holds LP position
    access(all) resource Vault {
        access(all) var balance: UFix64
        access(all) var lastCompoundTime: UFix64
        access(all) var totalYieldEarned: UFix64
        
        init(balance: UFix64) {
            self.balance = balance
            self.lastCompoundTime = getCurrentBlock().timestamp
            self.totalYieldEarned = 0.0
        }
        
        // Deposit to LP position
        access(all) fun deposit(amount: UFix64) {
            pre {
                amount > 0.0: "Deposit amount must be positive"
            }
            post {
                self.balance == before(self.balance) + amount: "Balance not updated correctly"
            }
            
            self.balance = self.balance + amount
            LiquidityPool.totalDeposits = LiquidityPool.totalDeposits + amount
            emit LiquidityDeposited(amount: amount, to: self.owner?.address)
        }
        
        // Withdraw from LP position
        access(all) fun withdraw(amount: UFix64): UFix64 {
            pre {
                amount > 0.0: "Withdrawal amount must be positive"
                amount <= self.balance: "Insufficient LP balance"
            }
            post {
                self.balance == before(self.balance) - amount: "Balance not updated correctly"
            }
            
            self.balance = self.balance - amount
            LiquidityPool.totalDeposits = LiquidityPool.totalDeposits - amount
            emit LiquidityWithdrawn(amount: amount, from: self.owner?.address)
            return amount
        }
        
        // Calculate current yield available
        access(all) fun calculateYield(): UFix64 {
            if self.balance == 0.0 {
                return 0.0
            }
            
            let currentTime = getCurrentBlock().timestamp
            let timeElapsed = currentTime - self.lastCompoundTime
            let weeksElapsed = timeElapsed / (7.0 * 86400.0) // 7 days in seconds
            
            // Calculate compound yield: principal * (1 + rate)^weeks - principal
            let yieldMultiplier = 1.0 + LiquidityPool.weeklyYieldRate
            var compoundMultiplier = 1.0
            
            // Compound interest calculation
            var i = 0.0
            while i < weeksElapsed {
                compoundMultiplier = compoundMultiplier * yieldMultiplier
                i = i + 1.0
            }
            
            let totalValue = self.balance * compoundMultiplier
            let yieldAmount = totalValue - self.balance
            
            emit YieldCalculated(principal: self.balance, yield: yieldAmount, to: self.owner?.address)
            return yieldAmount
        }
        
        // Compound yield and update balance
        access(all) fun compound(): UFix64 {
            let yieldAmount = self.calculateYield()
            
            if yieldAmount > 0.0 {
                self.balance = self.balance + yieldAmount
                self.totalYieldEarned = self.totalYieldEarned + yieldAmount
                self.lastCompoundTime = getCurrentBlock().timestamp
                LiquidityPool.totalYieldPaid = LiquidityPool.totalYieldPaid + yieldAmount
                
                emit YieldCompounded(amount: yieldAmount, to: self.owner?.address)
            }
            
            return yieldAmount
        }
        
        // Get position info
        access(all) fun getPositionInfo(): {String: UFix64} {
            let availableYield = self.calculateYield()
            return {
                "balance": self.balance,
                "totalYieldEarned": self.totalYieldEarned,
                "availableYield": availableYield,
                "lastCompoundTime": self.lastCompoundTime,
                "weeksSinceLastCompound": (getCurrentBlock().timestamp - self.lastCompoundTime) / (7.0 * 86400.0)
            }
        }
        
        // Get current balance
        access(all) fun getBalance(): UFix64 {
            return self.balance
        }
        
        // Get APY info
        access(all) fun getAPYInfo(): {String: UFix64} {
            let weeklyRate = LiquidityPool.weeklyYieldRate * 100.0 // Convert to percentage
            let annualRate = weeklyRate * 52.0 // 52 weeks per year
            return {
                "weeklyAPY": weeklyRate,
                "annualAPY": annualRate,
                "currentRate": LiquidityPool.weeklyYieldRate
            }
        }
    }
    
    // Create empty LP vault
    access(all) fun createEmptyVault(): @Vault {
        return <-create Vault(balance: 0.0)
    }
    
    // Get pool statistics
    access(all) fun getPoolStats(): {String: UFix64} {
        return {
            "totalDeposits": self.totalDeposits,
            "totalYieldPaid": self.totalYieldPaid,
            "weeklyYieldRate": self.weeklyYieldRate,
            "annualAPY": self.weeklyYieldRate * 52.0 * 100.0
        }
    }
    
    // Admin function to set yield rate
    access(all) fun setYieldRate(newRate: UFix64) {
        pre {
            newRate >= 0.0: "Yield rate must be non-negative"
            newRate <= 1.0: "Yield rate must be <= 100%"
        }
    }
    
    // Contract initialization
    init() {
        self.totalDeposits = 0.0
        self.totalYieldPaid = 0.0
        self.weeklyYieldRate = 0.01 // 1% weekly yield
        
        // Create admin vault for testing
        let adminVault <- create Vault(balance: 0.0)
        self.account.storage.save(<-adminVault, to: /storage/lpAdminVault)
        
        // Create public capability for admin vault
        let adminCap = self.account.capabilities.storage.issue<&Vault>(/storage/lpAdminVault)
        self.account.capabilities.publish(adminCap, at: /public/lpAdminVault)
        
        emit PoolCreated(initialRate: self.weeklyYieldRate)
    }
}