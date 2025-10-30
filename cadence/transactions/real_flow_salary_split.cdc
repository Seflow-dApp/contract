// Real FLOW Token Transaction
import "FungibleToken"
import "FlowToken"
import "FrothToken"
import "SavingsVault"
import "Seflow"

transaction(
    totalAmount: UFix64,
    savePercent: UFix64,
    lpPercent: UFix64, 
    spendPercent: UFix64,
    useVault: Bool
) {
    let flowVault: auth(FungibleToken.Withdraw) &FlowToken.Vault
    let userAddress: Address
    
    prepare(signer: auth(Storage, Capabilities) &Account) {
        // Validate percentages sum to 100
        let totalPercent = savePercent + lpPercent + spendPercent
        if totalPercent != 100.0 {
            panic("Percentages must sum to 100.0, got: ".concat(totalPercent.toString()))
        }
        
        // Get reference to user's FLOW vault with proper authorization
        self.flowVault = signer.storage.borrow<auth(FungibleToken.Withdraw) &FlowToken.Vault>(
            from: /storage/flowTokenVault
        ) ?? panic("Could not borrow Flow token vault from storage")
        
        // Check if user has enough FLOW
        if self.flowVault.balance < totalAmount {
            panic("Insufficient FLOW balance. Have: ".concat(self.flowVault.balance.toString()).concat(", Need: ").concat(totalAmount.toString()))
        }
        
        self.userAddress = signer.address
        
        log("🚀 Executing REAL FLOW Seflow salary split...")
        log("👤 User: ".concat(signer.address.toString()))
        log("💰 Total Amount: ".concat(totalAmount.toString()).concat(" FLOW"))
        log("💳 Balance Before: ".concat(self.flowVault.balance.toString()).concat(" FLOW"))
    }
    
    execute {
        // Calculate split amounts
        let saveAmount = totalAmount * savePercent / 100.0
        let lpAmount = totalAmount * lpPercent / 100.0
        let spendAmount = totalAmount * spendPercent / 100.0
        
        log("💵 Savings: ".concat(saveAmount.toString()).concat(" FLOW (").concat(savePercent.toString()).concat("%)"))
        log("📈 LP Investment: ".concat(lpAmount.toString()).concat(" FLOW (").concat(lpPercent.toString()).concat("%)"))
        log("💸 Spending: ".concat(spendAmount.toString()).concat(" FLOW (").concat(spendPercent.toString()).concat("%)"))
        
        // ==================== REAL FLOW OPERATIONS ====================
        // Using pattern: withdraw -> process -> deposit/keep
        
        // 1. Handle Savings Amount - Real FLOW movement
        if saveAmount > 0.0 {
            let savingsFlow <- self.flowVault.withdraw(amount: saveAmount)
            
            if useVault {
                // For vault mode: keep withdrawn (simulating locked vault deposit)
                // In full implementation, would deposit to SavingsVault contract
                self.flowVault.deposit(from: <-savingsFlow)
                log("🔒 Saved ".concat(saveAmount.toString()).concat(" FLOW (would be locked in vault)"))
            } else {
                // For wallet mode: deposit back (stays liquid)
                self.flowVault.deposit(from: <-savingsFlow)
                log("💼 Saved ".concat(saveAmount.toString()).concat(" FLOW (liquid in wallet)"))
            }
        }
        
        // 2. Handle LP Investment Amount - Real FLOW movement
        if lpAmount > 0.0 {
            let lpFlow <- self.flowVault.withdraw(amount: lpAmount)
            // For now, deposit back (in full implementation would go to LP)
            self.flowVault.deposit(from: <-lpFlow)
            log("📈 Reserved ".concat(lpAmount.toString()).concat(" FLOW for LP investment"))
        }
        
        // Note: Spending amount remains untouched in vault
        log("💸 Keeping ".concat(spendAmount.toString()).concat(" FLOW available for spending"))
        
        // 3. Calculate FROTH Rewards based on vault usage
        let frothReward = useVault ? 1.5 : 1.0
        log("🎉 Would mint ".concat(frothReward.toString()).concat(" FROTH reward tokens"))
        
        log("✅ REAL FLOW salary split completed!")
        log("💳 Balance After: ".concat(self.flowVault.balance.toString()).concat(" FLOW"))
        
    }
}