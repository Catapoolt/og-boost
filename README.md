## Project Overview
OGBoost is a tool for Incentive Providers (IPs) to ofer rewards to PancakeSwap v4 Liquidity Providers (LPs) based on the amount of swap fees generated on other AMMs (e.g. PancakeSwap v3). Also known as fee-based Liquidity Mining, OGBoost automatically calculates the rewards allocation to LPs proportionally, based on the amount of fees earned by each LP during a reward campaign. A hook is put in place to store the positions of LPs as they add liquidity to PancakeSwap V4.

IPs have the ability to ditribute multiplied rewards to OG LPs that have earned fees above configured thresholds on external pools or AMMs. The Incentive Provider sets up reward multipliers for pools with farming rewards. The list of the top LPs is aggregated by the off-chain Brevis based service. The ZK circuit proves that the OG list is correct.

### Future Feature
Idea for the future: Prevent liquidity withdrawal based on the amount of reward tokens sold. If small amounts are sold, no liquidity is locked. In case large amounts of tokens are sold, the hook will gradualy release the LP position liquidity only after more fees are earned. Brevis will be used to quantify selling behaviour of the reward token and inform the hook to lock liquidity.

## How to run
The contracts have been deployed to BNB Chain test net.

1. Set environment vars

`cp .env.template .env`

You need 4 wallets with tBNB. Set the private keys in your .env
`PRIVATE_KEY` - the pkey of the deployer and campaign creator
`ALICE_KEY` - the pkey of the first LP
`BOB_KEY` - the pkey of the second LP
`CAROL_KEY` - the pkey of the swapper

Run approve reward token for the campaign creator
```
forge script script/21_Approves.sol \                                                                        
  --rpc-url $RPC_URL \
  --broadcast
```

1. Frontend
In order to run the frontend, you have to go to the `frontend` directory and run the following commands:
`nvm use v20` 
`npm install`
`npm start`

Runs the app in the development mode.\
Open [http://localhost:3000](http://localhost:3000) to view it in the browser.

2. 


## Deployment

```
PRIVATE_KEY=<Your_Private_Key>
RPC_URL=https://data-seed-prebsc-1-s1.binance.org:8545/
POOL_MANAGER=<Pool_Manager_Address>
BREVIS_REQUEST=<Brevis_Request_Address>
```

### OGBoost contract (BNB Chain Testnet)
`0x1feeF9f80248dcB4614905e1cbe96d1be08B1155`

##### Dependencies
CLPoolManager `0x969D90aC74A1a5228b66440f8C8326a8dA47A5F9`
BrevisRequest `0xF7E9CB6b7A157c14BCB6E6bcf63c1C7c92E952f5`
