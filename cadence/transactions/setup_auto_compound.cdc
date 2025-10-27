import FlowTransactionScheduler from 0x8c5303eaa26202d6
import FlowTransactionSchedulerUtils from 0x8c5303eaa26202d6
import AutoCompoundHandler from 0x7d7f281847222367
import FlowToken from 0x7e60df042a9c0868
import FungibleToken from 0x9a0766d93b6608b7

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
            
            // Create execute capability for the scheduler
            account.capabilities.storage.issue<auth(FlowTransactionScheduler.Execute) &{FlowTransactionScheduler.TransactionHandler}>(AutoCompoundHandler.HandlerStoragePath)
            
            // Create public capability
            let publicHandlerCap = account.capabilities.storage.issue<&{FlowTransactionScheduler.TransactionHandler}>(AutoCompoundHandler.HandlerStoragePath)
            account.capabilities.publish(publicHandlerCap, at: AutoCompoundHandler.HandlerPublicPath)
        }
        
        // Get the execute capability for scheduling
        var handlerCap: Capability<auth(FlowTransactionScheduler.Execute) &{FlowTransactionScheduler.TransactionHandler}>? = nil
        
        let controllers = account.capabilities.storage.getControllers(forPath: AutoCompoundHandler.HandlerStoragePath)
        for controller in controllers {
            if let cap = controller.capability as? Capability<auth(FlowTransactionScheduler.Execute) &{FlowTransactionScheduler.TransactionHandler}> {
                handlerCap = cap
                break
            }
        }
        
        if handlerCap == nil {
            panic("Could not get execute capability for auto-compound handler")
        }
        
        // Get vault for fees
        let vault = account.storage.borrow<auth(FungibleToken.Withdraw) &FlowToken.Vault>(from: /storage/flowTokenVault)
            ?? panic("Could not borrow FlowToken vault")
        
        let fees <- vault.withdraw(amount: feeAmount) as! @FlowToken.Vault
        
        // Calculate next execution time (1 minute from now for testing, would be intervalDays in production)
        let currentTime = getCurrentBlock().timestamp
        let nextExecutionTime = currentTime + 60.0 // 1 minute for testing
        
        // Get manager reference
        let manager = account.storage.borrow<auth(FlowTransactionSchedulerUtils.Owner) &{FlowTransactionSchedulerUtils.Manager}>(from: FlowTransactionSchedulerUtils.managerStoragePath)
            ?? panic("Could not borrow Manager reference")
        
        // Schedule the first auto-compound transaction
        manager.schedule(
            handlerCap: handlerCap!,
            data: nil,
            timestamp: nextExecutionTime,
            priority: FlowTransactionScheduler.Priority.Medium,
            executionEffort: 100, // Conservative gas limit
            fees: <-fees
        )
        
        log("Auto-compound scheduled for next execution at: ".concat(nextExecutionTime.toString()))
    }
}