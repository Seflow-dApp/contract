// get_user_stats.cdc - Get user statistics and profile info
import "Seflow"

access(all) fun main(userAddress: Address): {String: AnyStruct} {
    
    // Get contract stats
    let contractStats = Seflow.getContractStats()
    
    // Get mock Find Labs balance
    let findLabsBalance = Seflow.mockFindLabsBalance(userAddress: userAddress)
    
    // Try to get user profile (if exists)
    var userStats: {String: AnyStruct} = {}
    
    if let profileRef = getAccount(userAddress)
        .capabilities.borrow<&Seflow.UserProfile>(/public/seflowProfile) {
        userStats = profileRef.getStats()
    }
    
    // Return combined data
    return {
        "userAddress": userAddress,
        "contractStats": contractStats,
        "findLabsBalance": findLabsBalance,
        "userProfile": userStats,
        "timestamp": getCurrentBlock().timestamp
    }
}