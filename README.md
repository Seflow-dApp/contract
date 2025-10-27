# 🌊 Seflow Smart Contracts - Flow Blockchain

**Automated Salary Allocation System Built on Flow**

Seflow smart contracts automate salary splitting for professionals worldwide. Deposit $FLOW, set custom allocation percentages (savings, DeFi, spending), enable auto-compounding, and earn $FROTH rewards - all powered by Flow's native smart contract capabilities.

## 🏆 Forte Hacks by Flow 2025 Submission

This smart contract system leverages Flow's Forte network upgrade, utilizing **Actions and Workflows** for automated transaction scheduling and DeFi operations.

## 📋 Contract Overview

### Core Contracts

- **AutoCompoundHandler** (`0x7d7f281847222367`): Manages automated yield compounding with scheduled transactions
- **LiquidityPool**: Handles DeFi yield generation and LP token management  
- **SeflowSalary**: Core salary splitting logic and fund allocation
- **FROTHRewards**: Token reward system for user engagement

### Key Features

✅ **Smart Salary Splitting**: Automated allocation across savings, DeFi, and spending
✅ **Scheduled Auto-Compounding**: Uses Flow's transaction scheduler for yield optimization
✅ **Vault Locking**: 30-day lock mechanism with enhanced APY rewards
✅ **FROTH Token Rewards**: Gamified reward system for consistent usage
✅ **On-chain Storage**: All user preferences and state stored on Flow blockchain

## 🔨 Getting Started

Here are some essential resources to help you hit the ground running:

- **[Flow Documentation](https://developers.flow.com/)** - The official Flow Documentation is a great starting point to start learning about [building](https://developers.flow.com/build/flow) on Flow.
- **[Cadence Documentation](https://cadence-lang.org/docs/language)** - Cadence is the native language for the Flow Blockchain. It is a resource-oriented programming language that is designed for developing smart contracts.  The documentation is a great place to start learning about the language.
- **[Visual Studio Code](https://code.visualstudio.com/)** and the **[Cadence Extension](https://marketplace.visualstudio.com/items?itemName=onflow.cadence)** - It is recommended to use the Visual Studio Code IDE with the Cadence extension installed.  This will provide syntax highlighting, code completion, and other features to support Cadence development.
- **[Flow Clients](https://developers.flow.com/tools/clients)** - There are clients available in multiple languages to interact with the Flow Blockchain.  You can use these clients to interact with your smart contracts, run transactions, and query data from the network.
- **[Block Explorers](https://developers.flow.com/ecosystem/block-explorers)** - Block explorers are tools that allow you to explore on-chain data.  You can use them to view transactions, accounts, events, and other information.  [Flowser](https://flowser.dev/) is a powerful block explorer for local development on the Flow Emulator.

## 📦 Project Structure

```
/cadence
├── contracts/
│   ├── AutoCompoundHandler.cdc          # Automated yield compounding logic
│   ├── LiquidityPool.cdc               # DeFi LP management
│   ├── SeflowSalary.cdc                # Core salary splitting
│   └── FROTHRewards.cdc                # Token reward system
├── scripts/
│   ├── check_auto_compound_status.cdc   # Query compound status
│   ├── get_salary_split_info.cdc       # Retrieve user allocations
│   └── get_froth_balance.cdc           # Check reward balances
├── transactions/
│   ├── setup_salary_splitting.cdc      # Initialize user account
│   ├── set_split_config.cdc            # Configure allocations
│   ├── schedule_auto_compound.cdc       # Enable auto-compounding
│   └── claim_froth_rewards.cdc         # Claim reward tokens
└── tests/
    ├── salary_splitting_test.cdc        # Core functionality tests
    ├── auto_compound_test.cdc           # Automation tests
    └── rewards_test.cdc                 # Token reward tests
```

## 🔧 Smart Contract Architecture

### AutoCompoundHandler.cdc
- **Purpose**: Manages scheduled transaction execution for yield compounding
- **Key Features**:
  - Integrates with Flow's transaction scheduler
  - Configurable compounding intervals (daily to monthly)
  - Real LP yield compounding (no mock data)
  - Error handling for insufficient funds

### SeflowSalary.cdc  
- **Purpose**: Core salary allocation and management
- **Key Features**:
  - Three-way split: Savings, DeFi, Spending
  - Percentage-based allocation system
  - Vault locking mechanism (30-day periods)
  - Integration with Flow token standards

### LiquidityPool.cdc
- **Purpose**: DeFi yield generation and LP token management
- **Key Features**:
  - Automated LP token minting/burning
  - Yield calculation and distribution
  - Compound interest algorithms
  - Pool balance management

### FROTHRewards.cdc
- **Purpose**: Gamified token reward system
- **Key Features**:
  - 1% base rewards for standard transactions
  - 1.5% enhanced rewards for vault locking
  - Token minting and distribution logic
  - User engagement tracking

## 🚀 Running Seflow Contracts

### Prerequisites
- Flow CLI installed and configured
- Flow testnet account with FLOW tokens
- VS Code with Cadence extension (recommended)

### Deployed Contract Addresses (Flow Testnet)

```
AutoCompoundHandler: 0x7d7f281847222367
FlowToken: 0x7e60df042a9c0868
FungibleToken: 0x9a0766d93b6608b7
```

### Key Operations

#### 1. Check Auto-Compound Status
```shell
flow scripts execute cadence/scripts/check_auto_compound_status.cdc --arg Address:0x[YOUR_ADDRESS]
```

#### 2. Set Up Salary Splitting
```shell
flow transactions send cadence/transactions/setup_salary_splitting.cdc
```

#### 3. Configure Split Allocation
```shell
flow transactions send cadence/transactions/set_split_config.cdc \
  --arg UFix64:1000.0 \    # Total salary amount
  --arg UInt8:50 \         # Savings percentage
  --arg UInt8:30 \         # DeFi percentage  
  --arg UInt8:20 \         # Spending percentage
  --arg Bool:true          # Lock vault (30 days)
```

#### 4. Enable Auto-Compounding
```shell
flow transactions send cadence/transactions/schedule_auto_compound.cdc \
  --arg UInt64:7           # Interval in days (weekly)
```

#### 5. Query User Allocations
```shell
flow scripts execute cadence/scripts/get_salary_split_info.cdc --arg Address:0x[YOUR_ADDRESS]
```

### Example Transaction Flow

1. **Initialize Account**: Set up storage and capabilities
2. **Configure Split**: Define allocation percentages (must sum to 100%)
3. **Enable Automation**: Schedule auto-compound with desired frequency
4. **Monitor Status**: Check compound execution and yields
5. **Claim Rewards**: Collect FROTH tokens earned from usage

## 🔐 Security & Best Practices

### Resource-Oriented Programming
- All assets stored as Cadence resources (cannot be copied or lost)
- Strict access control with capability-based security
- Move semantics prevent double-spending attacks

### Access Control Patterns
- Public functions for user interactions
- Private admin functions for contract management  
- Capability-based resource access for automated operations
- Time-locked vault mechanisms for enhanced security

### Error Handling
- Comprehensive input validation
- Graceful failure modes for insufficient funds
- Transaction rollback on any operation failure
- Detailed logging for debugging and monitoring

## 💡 Technical Innovations

### Flow Forte Integration
- **Scheduled Transactions**: Automated compounding without manual intervention
- **Workflow Composition**: Reusable DeFi action patterns
- **Time-based Triggers**: Configurable execution intervals
- **Protocol Agnostic**: Works with any Flow DeFi protocol

### Gas Optimization
- Efficient resource management patterns
- Batched operations to minimize transaction costs
- Lazy evaluation for expensive computations
- Optimal storage layout for frequently accessed data

### Yield Calculation Algorithm
```cadence
// Compound interest formula implementation
pub fun calculateCompoundYield(
    principal: UFix64,
    rate: UFix64,
    periods: UInt64
): UFix64 {
    // A = P(1 + r/n)^(nt)
    let compoundFactor = (1.0 + rate).power(periods)
    return principal * compoundFactor - principal
}
```

## 👨‍💻 Start Developing

### Creating a New Contract

To add a new contract to your project, run the following command:

```shell
flow generate contract
```

This command will create a new contract file and add it to the `flow.json` configuration file.

### Creating a New Script

To add a new script to your project, run the following command:

```shell
flow generate script
```

This command will create a new script file.  Scripts are used to read data from the blockchain and do not modify state (i.e. get the current balance of an account, get a user's NFTs, etc).

You can import any of your own contracts or installed dependencies in your script file using the `import` keyword.  For example:

```cadence
import "Counter"
```

### Creating a New Transaction

To add a new transaction to your project you can use the following command:

```shell
flow generate transaction
```

This command will create a new transaction file.  Transactions are used to modify the state of the blockchain (i.e purchase an NFT, transfer tokens, etc).

You can import any dependencies as you would in a script file.

### Creating a New Test

To add a new test to your project you can use the following command:

```shell
flow generate test
```

This command will create a new test file.  Tests are used to verify that your contracts, scripts, and transactions are working as expected.

### Installing External Dependencies

If you want to use external contract dependencies (such as NonFungibleToken, FlowToken, FungibleToken, etc.) you can install them using [Flow CLI Dependency Manager](https://developers.flow.com/tools/flow-cli/dependency-manager).

For example, to install the NonFungibleToken contract you can use the following command:

```shell
flow deps add mainnet://1d7e57aa55817448.NonFungibleToken
```

Contracts can be found using [ContractBrowser](https://contractbrowser.com/), but be sure to verify the authenticity before using third-party contracts in your project.

## 🧪 Testing

To verify that your project is working as expected you can run the tests using the following command:

```shell
flow test
```

This command will run all tests with the `_test.cdc` suffix (these can be found in the `cadence/tests` folder). You can add more tests here using the `flow generate test` command (or by creating them manually).

To learn more about testing in Cadence, check out the [Cadence Test Framework Documentation](https://cadence-lang.org/docs/testing-framework).

## 🚀 Seflow Contract Deployment

### Current Deployment Status

**✅ Flow Testnet (Live)**
- AutoCompoundHandler: `0x7d7f281847222367`
- Successfully handling real LP compounding (no mock data)
- Integrated with Flow's transaction scheduler
- Supporting scheduled auto-compound operations

### Deployment Process

#### 1. Prerequisites Setup
```shell
# Install Flow CLI
sh -ci "$(curl -fsSL https://storage.googleapis.com/flow-cli/install.sh)"

# Create testnet account
flow accounts create --network=testnet

# Fund account with testnet FLOW
# Visit: https://testnet-faucet.onflow.org/
```

#### 2. Configure flow.json
```json
{
  "contracts": {
    "AutoCompoundHandler": "./cadence/contracts/AutoCompoundHandler.cdc",
    "SeflowSalary": "./cadence/contracts/SeflowSalary.cdc",
    "LiquidityPool": "./cadence/contracts/LiquidityPool.cdc"
  },
  "deployments": {
    "testnet": {
      "account-1": ["AutoCompoundHandler", "SeflowSalary", "LiquidityPool"]
    }
  }
}
```

#### 3. Deploy to Testnet
```shell
# Deploy all contracts
flow project deploy --network=testnet --update

# Verify deployment
flow accounts get 0x7d7f281847222367 --network=testnet
```

#### 4. Initialize Contracts
```shell
# Set up initial liquidity pool
flow transactions send cadence/transactions/initialize_pool.cdc --network=testnet

# Configure reward parameters
flow transactions send cadence/transactions/setup_rewards.cdc --network=testnet
```

### Mainnet Deployment (Future)

Seflow contracts are currently optimized for testnet development and hackathon demonstration. For mainnet deployment:

1. **Security Audit**: Complete third-party security review
2. **Gas Optimization**: Final gas cost optimizations
3. **Admin Controls**: Multi-sig admin account setup
4. **Emergency Procedures**: Pause/upgrade mechanisms
5. **Oracle Integration**: Real-time price feeds for yield calculations

## 📚 Other Resources

- [Cadence Design Patterns](https://cadence-lang.org/docs/design-patterns)
- [Cadence Anti-Patterns](https://cadence-lang.org/docs/anti-patterns)
- [Flow Core Contracts](https://developers.flow.com/build/core-contracts)

## 🤝 Community
- [Flow Community Forum](https://forum.flow.com/)
- [Flow Discord](https://discord.gg/flow)
- [Flow Twitter](https://x.com/flow_blockchain)
