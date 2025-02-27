# StackRemit

## Secure Decentralized Money Transfer Protocol

StackRemit is a secure, decentralized protocol for transferring money built on the Stacks blockchain using Clarity smart contracts. It enables users to send funds across borders with transparent fees and exchange rates.

## Features

- **User Registration**: Create an account with a display name and payment identifier
- **Secure Transfers**: Send funds to other registered users
- **Exchange Rate Management**: Controlled by appointed administrators
- **Fee Transparency**: Clear transaction fee structure with admin control
- **Emergency Controls**: Ability to pause transfers in case of security issues

## Smart Contract Functions

### User Management

- `register-user`: Register a new user profile with display name and payment identifier
- `get-user-profile`: Retrieve user information

### Fund Management

- `deposit-funds`: Add funds to your account
- `withdraw-funds`: Withdraw funds from your account
- `get-balance`: Check your current balance

### Payment Operations

- `send-payment`: Transfer funds to another registered user
- `is-transfer-locked`: Check if transfers are currently locked

### Administrative Functions

- `update-exchange-rate`: Update the current exchange rate (rate administrators only)
- `update-transaction-fee`: Modify the transaction fee percentage (contract administrator only)
- `add-rate-administrator`: Assign exchange rate management privileges
- `remove-rate-administrator`: Revoke exchange rate management privileges
- `set-global-transfer-lock`: Enable/disable all transfers (emergency function)

## Error Codes

| Code | Description |
|------|-------------|
| u200 | Unauthorized access |
| u201 | User not found |
| u202 | Insufficient balance |
| u203 | Invalid amount |
| u204 | Transaction failed |
| u205 | Permission denied |
| u206 | Invalid exchange rate |
| u207 | User already exists |
| u208 | Invalid input data |
| u209 | Transfers are locked |

## Implementation Details

- Transaction fees are expressed in basis points (1/100 of a percent)
- Default fee is 150 basis points (1.5%)
- Exchange rates are scaled by 10^8 to handle decimal values
- User display names can be up to 55 ASCII characters
- Payment identifiers can be up to 22 ASCII characters

## Security Features

- Function-level authentication for administrative actions
- Emergency transfer lock for system-wide pauses
- Balance verification before transfers
- Controlled exchange rate management

## Getting Started

1. Deploy the contract to the Stacks blockchain
2. The deploying address becomes the contract administrator
3. Set an initial exchange rate using an appointed rate administrator
4. Users can register and begin using the protocol

## Usage Example

```clarity
;; Register as a user
(contract-call? .stackremit register-user "Alice" "ALICEPAY123")

;; Deposit funds
(contract-call? .stackremit deposit-funds u1000)

;; Send payment to another user
(contract-call? .stackremit send-payment 'ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE u500)
```
