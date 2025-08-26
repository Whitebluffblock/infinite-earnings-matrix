# 🌌 Guild Deployment Guide — Infinity Vault (Mainnet)

This guide transmits the knowledge of how to deploy the **Infinity Vault** smart contract to Ethereum (or any EVM mainnet) so that *any guild member or Copilot agent* can repeat it.

---

## ⚒️ Prerequisites
- Node.js ≥ 18
- pnpm or npm
- Hardhat (already in repo)
- Wallet with deployer funds (guild-provided, not personal)
- RPC provider (Alchemy / Infura / SKALE / etc.)

---

## 📂 Files
- `contracts/InfinityVault.sol` → Vault logic  
- `scripts/deploy.js` → Hardhat deploy script  
- `.env` → Environment variables  

Example `.env`:
```env
PRIVATE_KEY=0xYOUR_DEPLOYER_PRIVATE_KEY
RPC_URL=https://mainnet.infura.io/v3/YOUR_KEY
ETHERSCAN_API_KEY=YOUR_ETHERSCAN_KEY
