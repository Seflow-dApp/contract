// Get Account Balances Script
access(all) fun main(address: Address): {String: UFix64} {
    let account = getAccount(address)
    let balances: {String: UFix64} = {}

    // Get account balance
    balances["flow"] = account.balance
    
    // Seflow-specific balances
    balances["froth"] = 0.0      // FROTH rewards earned
    balances["savings"] = 0.0    // Locked savings amount  
    balances["lp"] = 0.0         // LP investment amount
    
    return balances
}