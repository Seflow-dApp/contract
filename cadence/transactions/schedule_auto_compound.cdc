import FlowTransactionScheduler from 0x8c5303eaa26202d6
import FlowTransactionSchedulerUtils from 0x8c5303eaa26202d6
import AutoCompoundHandler from 0x7d7f281847222367
import FlowToken from 0x7e60df042a9c0868
import FungibleToken from 0x9a0766d93b6608b7

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
        
        log("Estimated fee for scheduled transaction: ".concat(estimate.totalCost.toString()).concat(" FLOW"))
        
        // Get vault for fees
        let vault = account.storage.borrow<auth(FungibleToken.Withdraw) &FlowToken.Vault>(from: /storage/flowTokenVault)
            ?? panic("Could not borrow FlowToken vault")
        
        // Check if we have enough funds
        if vault.balance < estimate.totalCost {
            panic("Insufficient funds. Need ".concat(estimate.totalCost.toString()).concat(" FLOW but only have ".concat(vault.balance.toString())))
        }
        
        let fees <- vault.withdraw(amount: estimate.totalCost) as! @FlowToken.Vault
        
        // Get the auto compound handler capability
        let handlerCap = account.capabilities.storage
            .getControllers(forPath: AutoCompoundHandler.HandlerStoragePath)[0]
            .capability as! Capability<auth(FlowTransactionScheduler.Execute) &{FlowTransactionScheduler.TransactionHandler}>
        
        // Schedule the transaction directly
        let scheduledTx <- FlowTransactionScheduler.schedule(
            handlerCap: handlerCap,
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