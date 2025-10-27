// Real FLOW Balance Script
import FungibleToken from "../contracts/FungibleToken.cdc"
import FlowToken from "../contracts/FlowToken.cdc"
import "FrothToken"
import "SavingsVault"

// Script to get real FLOW token balances
access(all) fun main(address: Address): {String: AnyStruct} {
    let account = getAccount(address)
    
    // Get FLOW token balance
    let flowVaultRef = account.capabilities.get<&FlowToken.Vault>(/public/flowTokenBalance)
        .borrow()
    
    let flowBalance = flowVaultRef?.balance ?? 0.0
    
    // Try to get FROTH token balance (if exists)
    var frothBalance: UFix64 = 0.0
    // In full implementation, would check for FROTH vault
    
    // Try to get SavingsVault balance (if exists)
    var savingsBalance: UFix64 = 0.0
    // In full implementation, would check SavingsVault
    
    return {
        "address": address.toString(),
        "flowBalance": flowBalance,
        "frothBalance": frothBalance,
        "savingsBalance": savingsBalance,
        "totalValue": flowBalance + savingsBalance,
        "timestamp": getCurrentBlock().timestamp,
        "blockHeight": getCurrentBlock().height
    }
}