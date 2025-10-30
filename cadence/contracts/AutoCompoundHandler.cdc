import "FlowTransactionScheduler"
import "FlowTransactionSchedulerUtils"
import "FlowToken"
import "FungibleToken"
import "LiquidityPool"

access(all) contract AutoCompoundHandler {
    
    access(all) let HandlerStoragePath: StoragePath
    access(all) let HandlerPublicPath: PublicPath
    
    // Events
    access(all) event AutoCompoundExecuted(accountAddress: Address, yieldCompounded: UFix64, nextScheduledTime: UFix64)
    access(all) event AutoCompoundScheduled(accountAddress: Address, intervalSeconds: UInt64, nextExecutionTime: UFix64)
    access(all) event AutoCompoundCanceled(accountAddress: Address, transactionId: UInt64)
    
    // Handler resource for scheduled auto-compound transactions
    access(all) resource Handler: FlowTransactionScheduler.TransactionHandler {
        
        // Account address that owns the LP to compound
        access(all) let accountAddress: Address
        
        // Interval between auto-compound executions (in seconds)
        access(all) let intervalSeconds: UInt64
        
        // Reference to the LP contract for compounding
        access(all) let lpContractAddress: Address
        
        init(accountAddress: Address, intervalSeconds: UInt64, lpContractAddress: Address) {
            self.accountAddress = accountAddress
            self.intervalSeconds = intervalSeconds
            self.lpContractAddress = lpContractAddress
        }
        
        // Execute the auto-compound transaction
        access(FlowTransactionScheduler.Execute)
        fun executeTransaction(id: UInt64, data: AnyStruct?) {
            // Get account reference
            let account = getAccount(self.accountAddress)
            
            // Get current time for calculating next execution
            let currentTime = getCurrentBlock().timestamp
            let nextExecutionTime = currentTime + UFix64(self.intervalSeconds)
            
            // Get a reference to the user's LP vault to compound yield
            if let lpVaultRef = account.capabilities.get<&LiquidityPool.Vault>(/public/lpVault)
                .borrow() {
                
                // Compound the yield - this calls the real LP contract function
                let yieldCompounded = lpVaultRef.compound()
                
                // Emit event with actual compounded amount
                emit AutoCompoundExecuted(
                    accountAddress: self.accountAddress,
                    yieldCompounded: yieldCompounded,
                    nextScheduledTime: nextExecutionTime
                )
                
                log("Auto-compound executed for ".concat(self.accountAddress.toString())
                    .concat(": ").concat(yieldCompounded.toString()).concat(" FLOW compounded"))
                    
            } else {
                // If we can't access the LP vault, log an error but don't panic
                // This prevents the scheduled transaction from failing completely
                log("Warning: Could not access LP vault for auto-compound at address ".concat(self.accountAddress.toString()))
                
                // Emit event with 0 yield to indicate execution attempt
                emit AutoCompoundExecuted(
                    accountAddress: self.accountAddress,
                    yieldCompounded: 0.0,
                    nextScheduledTime: nextExecutionTime
                )
            }
        }
        
        // Basic metadata implementation for TransactionHandler interface
        access(all) view fun getViews(): [Type] {
            return [
                Type<StoragePath>(),
                Type<PublicPath>()
            ]
        }
        
        access(all) fun resolveView(_ view: Type): AnyStruct? {
            switch view {
                case Type<StoragePath>():
                    return AutoCompoundHandler.HandlerStoragePath
                case Type<PublicPath>():
                    return AutoCompoundHandler.HandlerPublicPath
                default:
                    return nil
            }
        }
    }
    
    // Create a new auto-compound handler
    access(all) fun createHandler(
        accountAddress: Address, 
        intervalSeconds: UInt64, 
        lpContractAddress: Address
    ): @Handler {
        return <- create Handler(
            accountAddress: accountAddress,
            intervalSeconds: intervalSeconds,
            lpContractAddress: lpContractAddress
        )
    }
    
    init() {
        self.HandlerStoragePath = /storage/autoCompoundHandler
        self.HandlerPublicPath = /public/autoCompoundHandler
    }
}