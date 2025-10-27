// Simplified FungibleToken stub - matches testnet pattern
access(all) contract FungibleToken {
    
    access(all) entitlement Withdraw

    access(all) resource interface Vault {
        access(all) var balance: UFix64
        access(Withdraw) fun withdraw(amount: UFix64): @{FungibleToken.Vault}
        access(all) fun deposit(from: @{FungibleToken.Vault})
    }
}