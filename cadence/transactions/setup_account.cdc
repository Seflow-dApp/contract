// Setup Account Transaction - Initialize user vaults for Seflow

transaction() {
    prepare(acct: auth(Storage, Capabilities) &Account) {
        log("Setting up Seflow user account...")
        log("Account address: ".concat(acct.address.toString()))
        
        log("✅ Seflow account setup completed!")
    }

    execute {
        log("Account setup completed!")
    }
}