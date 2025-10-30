import "FlowTransactionScheduler"
import "FlowTransactionSchedulerUtils"
import "AutoCompoundHandler"
import "FlowToken"
import "FungibleToken"

transaction(intervalDays: UInt64) {
    
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
            
            // Create public capability
            let publicHandlerCap = account.capabilities.storage.issue<&AutoCompoundHandler.Handler>(AutoCompoundHandler.HandlerStoragePath)
            account.capabilities.publish(publicHandlerCap, at: AutoCompoundHandler.HandlerPublicPath)
        }
        
        log("Auto-compound handler setup completed for ".concat(account.address.toString()))
    }
}