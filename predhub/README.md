# CinePredikt

A decentralized movie box office prediction market built on the Stacks blockchain.

## Overview

CinePredikt is a smart contract-powered platform that enables users to participate in prediction markets for movie box office revenues. Users can create markets, make predictions, and earn rewards based on accurate forecasts.

## Features

- **Multiple Prediction Types**
  - Winner Takes All: The correct predictors split the entire pool
  - Weighted Share: Rewards distributed proportionally to stake
  - Fixed Multiplier: Predetermined reward multipliers for each range

- **Flexible Revenue Ranges**
  - Support for up to 10 different revenue ranges per prediction
  - Multiple correct outcomes possible (up to 5)

- **Security Features**
  - Automated reward distribution
  - Built-in timelock mechanisms
  - Refund capability for cancelled predictions

## Smart Contract Functions

### For Market Creators

- `create-prediction`: Create a new prediction market for a movie
- `close-prediction`: Close a prediction market after the specified time
- `cancel-prediction`: Cancel a prediction market (with refunds)

### For Participants

- `make-prediction`: Place a prediction with STX tokens
- `claim-rewards`: Claim rewards for correct predictions

### For Administrators

- `settle-prediction`: Settle a prediction market with correct outcomes

## Error Handling

The contract includes comprehensive error handling for various scenarios:
- Unauthorized actions
- Invalid prediction parameters
- Timing violations
- Insufficient funds
- Invalid ranges or outcomes

## Technical Details

- Built with Clarity smart contract language
- Deployed on the Stacks blockchain
- Supports up to 10 revenue ranges per prediction
- Handles STX token transfers for predictions and rewards

## Getting Started

1. **Prerequisites**
   - Stacks wallet (Hiro or similar)
   - STX tokens for making predictions

2. **Interacting with the Contract**
   - Use a Stacks wallet to connect
   - Browse available prediction markets
   - Make predictions by selecting ranges and staking STX

## Security Considerations

- All token transfers are handled through secure contract functions
- Timelock mechanisms prevent premature market closure
- Only authorized participants can perform sensitive operations
- Built-in validation for all input parameters

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Disclaimer

This is a decentralized prediction market platform. Please ensure compliance with your local regulations regarding prediction markets and cryptocurrency trading.