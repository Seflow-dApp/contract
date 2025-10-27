// Get Account Balances Script - Simplified for testnet demo
access(all) fun main(address: Address): {String: UFix64} {
    let account = getAccount(address)
    let balances: {String: UFix64} = {}

    // Get account balance (simplified)
    balances["flow"] = account.balance
    
    // Seflow-specific balances (will be real once vaults are set up)
    balances["froth"] = 0.0      // FROTH rewards earned
    balances["savings"] = 0.0    // Locked savings amount  
    balances["lp"] = 0.0         // LP investment amount

    // Log for demo purposes
    log("📊 Checking balances for: ".concat(address.toString()))
    log("💰 Account Balance: ".concat(account.balance.toString()).concat(" FLOW"))
    log("🎉 This is your Seflow account!")
    
    return balances
}