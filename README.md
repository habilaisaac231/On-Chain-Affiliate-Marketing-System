# 🚀 On-Chain Affiliate Marketing System

A transparent, trustless affiliate marketing platform built on the Stacks blockchain using Clarity smart contracts.

## 🎯 Overview

This system enables merchants to work with affiliates in a completely transparent way, with automated commission tracking and payouts. All referrals, earnings, and statistics are stored on-chain for maximum transparency.

## ✨ Features

- 🏷️ **Affiliate Registration**: Affiliates can register with custom commission rates
- 🏪 **Merchant Registration**: Merchants can join the platform to work with affiliates  
- 🔗 **Referral Tracking**: Create and track referrals with unique IDs
- 💰 **Automated Commissions**: Automatic commission calculation based on sales
- 💸 **Earnings Withdrawal**: Affiliates can withdraw their earned commissions
- 📊 **Real-time Statistics**: Track total affiliates, referrals, and earnings
- 🛡️ **Platform Fees**: Built-in platform fee system for sustainability

## 🔧 Usage Instructions

### For Affiliates

1. **Register as an Affiliate** 📝
   ```clarity
   (contract-call? .contract register-affiliate u500) ;; 5% commission rate (500 basis points)
   ```

2. **Check Your Profile** 👤
   ```clarity
   (contract-call? .contract get-affiliate 'SP1ABC...)
   ```

3. **Withdraw Earnings** 💰
   ```clarity
   (contract-call? .contract withdraw-earnings 'SP1MERCHANT...)
   ```

### For Merchants

1. **Register as a Merchant** 🏪
   ```clarity
   (contract-call? .contract register-merchant)
   ```

2. **Create a Referral** 🎯
   ```clarity
   (contract-call? .contract create-referral 'SP1AFFILIATE... 'SP1CUSTOMER... u1000000) ;; 1 STX sale
   ```

3. **Complete a Referral** ✅
   ```clarity
   (contract-call? .contract complete-referral u1) ;; Complete referral ID 1
   ```

## 📊 Key Functions

| Function | Description | Parameters |
|----------|-------------|------------|
| `register-affiliate` | Register as an affiliate with commission rate | `commission-rate: uint` |
| `register-merchant` | Register as a merchant | None |
| `create-referral` | Create a new referral | `affiliate, customer, sale-amount` |
| `complete-referral` | Mark referral as completed | `referral-id: uint` |
| `withdraw-earnings` | Withdraw pending earnings | `merchant: principal` |
| `get-affiliate` | Get affiliate information | `affiliate: principal` |
| `get-referral` | Get referral details | `referral-id: uint` |

## 🎨 Commission Structure

- **Minimum Commission**: 0.5% (50 basis points)
- **Maximum Commission**: 20% (2000 basis points)  
- **Platform Fee**: 1% (100 basis points) on withdrawals
- **Basis Points**: 10000 = 100%

## 🔐 Security Features

- Only merchants can complete their own referrals
- Only contract owner can modify platform settings
- Affiliates must be active to receive new referrals
- All earnings are tracked separately by merchant-affiliate pairs

## 🚀 Getting Started

1. Deploy the contract to Stacks testnet/mainnet
2. Register as either an affiliate or merchant
3. Start creating and tracking referrals
4. Monitor earnings in real-time
5. Withdraw commissions when ready

## 📈 Statistics Tracking

The contract maintains comprehensive statistics:
- Total number of affiliates
- Total referrals created
- Individual affiliate performance
- Merchant sales volumes
- Platform-wide commission rates

## 🛠️ Development

Built with:
- **Clarinet** for smart contract development
- **Clarity** programming language
- **Stacks** blockchain for deployment

## 📝 License

This project is open source and available under the MIT License.

---

*Ready to revolutionize affiliate marketing with blockchain transparency? Deploy this contract and start building trust! 🌟*
