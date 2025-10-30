import "FlowTransactionScheduler"
import "FlowTransactionSchedulerUtils"
import "AutoCompoundHandler"
import "FlowToken"
import "FungibleToken"

transaction(intervalDays: UInt64, feeAmount: UFix64) {
    
    prepare(account: auth(BorrowValue, SaveValue, IssueStorageCapabilityController, PublishCapability, GetStorageCapabilityController) &Account) {
        
        // Create transaction scheduler manager if it doesn't exist
        if !account.storage.check<@{FlowTransactionSchedulerUtils.Manager}>(from: FlowTransactionSchedulerUtils.managerStoragePath) {
            let manager <- FlowTransactionSchedulerUtils.createManager()
            account.storage.save(<-manager, to: FlowTransactionSchedulerUtils.managerStoragePath)

            // Create public capability to the manager
            let managerRef = account.capabilities.storage.issue<&{FlowTransactionSchedulerUtils.Manager}>(FlowTransactionSchedulerUtils.managerStoragePath)
            account.capabilities.publish(managerRef, at: FlowTransactionSchedulerUtils.managerPublicPath)
        }
        
        // Create auto-compound handler if it doesn't exist
        if !account.storage.check<@AutoCompoundHandler.Handler>(from: AutoCompoundHandler.HandlerStoragePath) {
            let intervalSeconds = intervalDays * 24 * 3600 // Convert days to seconds
            let handler <- AutoCompoundHandler.createHandler(
                accountAddress: account.address,
                intervalSeconds: intervalSeconds,
                lpContractAddress: 0x7d7f281847222367
            )
            
            account.storage.save(<-handler, to: AutoCompoundHandler.HandlerStoragePath)

            // Create public capability (read-only)
            let publicHandlerCap = account.capabilities.storage.issue<&{FlowTransactionScheduler.TransactionHandler}>(AutoCompoundHandler.HandlerStoragePath)
            account.capabilities.publish(publicHandlerCap, at: AutoCompoundHandler.HandlerPublicPath)
        }
        
        // Create or get the execute capability for scheduling
        var handlerCap: Capability<auth(FlowTransactionScheduler.Execute) &{FlowTransactionScheduler.TransactionHandler}>? = nil
        
        // Check if we already have an execute capability
        let controllers = account.capabilities.storage.getControllers(forPath: AutoCompoundHandler.HandlerStoragePath)
        for controller in controllers {
            if let cap = controller.capability as? Capability<auth(FlowTransactionScheduler.Execute) &{FlowTransactionScheduler.TransactionHandler}> {
                handlerCap = cap
                break
            }
        }
        
        // If no execute capability exists, create one
        if handlerCap == nil {
            let executeHandlerCap = account.capabilities.storage.issue<auth(FlowTransactionScheduler.Execute) &{FlowTransactionScheduler.TransactionHandler}>(AutoCompoundHandler.HandlerStoragePath)
            handlerCap = executeHandlerCap
            log("✨ Created new execute capability for auto-compound handler")
        }
        
        if handlerCap == nil {
            panic("Failed to create execute capability for auto-compound handler")
        }
        
        // Get vault for fees
        let vault = account.storage.borrow<auth(FungibleToken.Withdraw) &FlowToken.Vault>(from: /storage/flowTokenVault)
            ?? panic("Could not borrow FlowToken vault")
        
        let fees <- vault.withdraw(amount: feeAmount) as! @FlowToken.Vault
                
        // Calculate next execution time
        let currentTime = getCurrentBlock().timestamp
        let nextExecutionTime = currentTime + UFix64(intervalDays * 24 * 60 * 60)
        
        // Schedule the first auto-compound transaction
        let scheduledTx <- FlowTransactionScheduler.schedule(
            handlerCap: handlerCap!,
            data: nil,
            timestamp: nextExecutionTime,
            priority: FlowTransactionScheduler.Priority.Medium,
            executionEffort: 100,
            fees: <-fees
        )
        
        log("✅ Auto-compound handler setup completed!")
        log("📅 First auto-compound scheduled for: ".concat(nextExecutionTime.toString()))
        log("🆔 Scheduled transaction ID: ".concat(scheduledTx.id.toString()))
        
        // Store or destroy the scheduled transaction resource
        destroy scheduledTx
    }
}