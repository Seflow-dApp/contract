import FlowTransactionScheduler from 0x8c5303eaa26202d6
import FlowTransactionSchedulerUtils from 0x8c5303eaa26202d6
import AutoCompoundHandler from 0x7d7f281847222367
import FlowToken from 0x7e60df042a9c0868
import FungibleToken from 0x9a0766d93b6608b7

transaction(intervalDays: UInt64) {
    
    prepare(account: auth(BorrowValue, SaveValue, IssueStorageCapabilityController, PublishCapability, GetStorageCapabilityController) &Account) {
        
        // Create transaction scheduler manager if it doesn't exist
        if !account.storage.check<@FlowTransactionSchedulerUtils.Manager>(from: FlowTransactionSchedulerUtils.managerStoragePath) {
            let manager <- FlowTransactionSchedulerUtils.createManager()
            account.storage.save(<-manager, to: FlowTransactionSchedulerUtils.managerStoragePath)

            // Create public capability to the manager
            let managerRef = account.capabilities.storage.issue<&FlowTransactionSchedulerUtils.Manager>(FlowTransactionSchedulerUtils.managerStoragePath)
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
            account.capabilities.storage.issue<auth(FlowTransactionScheduler.Execute) &AutoCompoundHandler.Handler>(AutoCompoundHandler.HandlerStoragePath)
            
            // Create public capability
            let publicHandlerCap = account.capabilities.storage.issue<&AutoCompoundHandler.Handler>(AutoCompoundHandler.HandlerStoragePath)
            account.capabilities.publish(publicHandlerCap, at: AutoCompoundHandler.HandlerPublicPath)
        }
        
        log("Auto-compound handler setup completed for ".concat(account.address.toString()))
    }
}