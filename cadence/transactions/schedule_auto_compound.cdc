import "FlowTransactionScheduler"
import "FlowTransactionSchedulerUtils"
import "AutoCompoundHandler"
import "FlowToken"
import "FungibleToken"

transaction(intervalDays: UInt64, feeAmount: UFix64) {
    
    prepare(account: auth(BorrowValue, SaveValue, IssueStorageCapabilityController, PublishCapability, GetStorageCapabilityController) &Account) {
        
        // Estimate fees first
        let currentTime = getCurrentBlock().timestamp
        let nextExecutionTime = currentTime + UFix64(intervalDays * 24 * 3600) // Convert days to seconds
        
        let estimate = FlowTransactionScheduler.estimate(
            data: nil,
            timestamp: nextExecutionTime,
            priority: FlowTransactionScheduler.Priority.Medium,
            executionEffort: 100
        )
        
        // borrow a reference to the vault that will be used for fees
        let vault = account.storage.borrow<auth(FungibleToken.Withdraw) &FlowToken.Vault>(from: /storage/flowTokenVault)
            ?? panic("Could not borrow FlowToken vault")
        
        let fees <- vault.withdraw(amount: feeAmount) as! @FlowToken.Vault

        // Get the auto compound handler execute capability
        let controllers = account.capabilities.storage.getControllers(forPath: AutoCompoundHandler.HandlerStoragePath)
        
        if controllers.length == 0 {
            panic("No AutoCompoundHandler found. Please run setup_auto_compound.cdc transaction first to create the handler.")
        }
        
        // Find the execute capability (not the public read-only one)
        var handlerCap: Capability<auth(FlowTransactionScheduler.Execute) &{FlowTransactionScheduler.TransactionHandler}>? = nil
        
        for controller in controllers {
            if let execCap = controller.capability as? Capability<auth(FlowTransactionScheduler.Execute) &{FlowTransactionScheduler.TransactionHandler}> {
                handlerCap = execCap
                break
            }
        }
        
        if handlerCap == nil {
            panic("No execute capability found for AutoCompoundHandler. The handler exists but lacks proper execute permissions.")
        }
        
        // Schedule the transaction directly
        let scheduledTx <- FlowTransactionScheduler.schedule(
            handlerCap: handlerCap!,
            data: nil,
            timestamp: nextExecutionTime,
            priority: FlowTransactionScheduler.Priority.Medium,
            executionEffort: 100,
            fees: <-fees
        )
        
        log("Auto-compound scheduled! Transaction ID: ".concat(scheduledTx.id.toString()))
        log("Next execution time: ".concat(nextExecutionTime.toString()))
        
        // Store the scheduled transaction resource (you might want to save this to account storage)
        destroy scheduledTx
    }
}