# Viethereum Token (VIΞTH)

A fully-featured ERC-20 token built on Ethereum with advanced functionalities.

## 🎯 Token Information

- **Name**: Viethereum
- **Symbol**: VIΞTH
- **Standard**: ERC-20
- **Initial Supply**: 1,000,000,000 VIΞTH
- **Decimals**: 18
- **Network**: Sepolia Testnet (Chain ID: 11155111)

## 📜 Deployed Contract

**Sepolia Testnet:**
- Contract Address: `0x627B60304eb80a5Bc4b38a8C2A8194E453681ABD`
- [View on Etherscan](https://sepolia.etherscan.io/address/0x627B60304eb80a5Bc4b38a8C2A8194E453681ABD)

## ✨ Features

- ✅ **Pausable**: Contract owner can pause/unpause transfers
- ✅ **BlackList**: Ability to blacklist addresses
- ✅ **Upgradeable**: Can be upgraded to a new contract
- ✅ **Fee System**: Optional transaction fees (configurable)
- ✅ **Issue/Redeem**: Owner can issue or redeem tokens
- ✅ **ERC-20 Compatible**: Full ERC-20 standard implementation

## 🛠 Technology Stack

- Solidity 0.8.20
- Hardhat
- Node.js
- Express.js

## 📦 Installation

```bash
# Install dependencies
npm install

# Compile contracts
npx hardhat compile

# Run tests (if available)
npx hardhat test
```

## 🚀 Deployment

### Deploy to Sepolia Testnet

1. Create a `.env` file:
```
PRIVATE_KEY=your_private_key_here
```

2. Make sure you have Sepolia ETH in your wallet (get from faucet)

3. Deploy:
```bash
npx hardhat run contracts/deploy.js --network sepolia
```

### Deploy to Mainnet

```bash
npx hardhat run contracts/deploy.js --network mainnet
```

## 📝 Contract Functions

### Owner Functions
- `transferOwnership(address newOwner)` - Transfer ownership
- `pause()` / `unpause()` - Pause/unpause transfers
- `addBlackList(address user)` / `removeBlackList(address user)` - Manage blacklist
- `destroyBlackFunds(address user)` - Destroy tokens from blacklisted address
- `issue(uint amount)` - Issue new tokens
- `redeem(uint amount)` - Redeem (burn) tokens
- `setParams(uint basisPoints, uint maxFee)` - Set fee parameters
- `deprecate(address newAddress)` - Upgrade to new contract

### Standard ERC-20 Functions
- `transfer(address to, uint value)`
- `transferFrom(address from, address to, uint value)`
- `approve(address spender, uint value)`
- `balanceOf(address owner)`
- `totalSupply()`
- `allowance(address owner, address spender)`

## 🔒 Security

- ⚠️ **NEVER** commit your `.env` file or private keys to GitHub
- ⚠️ Store private keys securely in a password manager or hardware wallet
- ⚠️ Backup your private keys in multiple secure locations

## 📄 License

MIT License

## 🌐 Website

The project includes a web interface for viewing token information and contract details.

```bash
# Start the web server
node server.js
```

Then visit `http://localhost:5000`

## 🤝 Contributing

Contributions, issues, and feature requests are welcome!

## 📧 Contact

For questions or support, please open an issue in this repository.

---

**Disclaimer**: This is a testnet deployment. Always audit smart contracts before deploying to mainnet with real funds.
# VI-T
