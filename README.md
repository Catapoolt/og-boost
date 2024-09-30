## Project Overview
OGBoost is a tool for Incentive Providers (IPs) to ofer rewards to PancakeSwap v4 Liquidity Providers (LPs) based on the amount of swap fees generated on other AMMs (e.g. PancakeSwap v3). Also known as fee-based Liquidity Mining, OGBoost automatically calculates the rewards allocation to LPs proportionally, based on the amount of fees earned by each LP during a reward campaign. A hook is put in place to store the positions of LPs as they add liquidity to PancakeSwap V4.

IPs have the ability to ditribute multiplied rewards to OG LPs that have earned fees above configured thresholds on external pools or AMMs. The Incentive Provider sets up reward multipliers for pools with farming rewards. The list of the top LPs is aggregated by the off-chain Brevis based service. The ZK circuit proves that the OG list is correct.

### Future Feature
Idea for the future: Prevent liquidity withdrawal based on the amount of reward tokens sold. If small amounts are sold, no liquidity is locked. In case large amounts of tokens are sold, the hook will gradualy release the LP position liquidity only after more fees are earned. Brevis will be used to quantify selling behaviour of the reward token and inform the hook to lock liquidity.

## How to run
The contracts have been deployed to BNB Chain test net.

#### Prerequisites
Set environment vars

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

1. Deploy the contract
```
forge script script/01_DeployCatapoolt.s.sol \
  --rpc-url $RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast
```
Copy the address to .env 

2. PancakeSwap V4 pool
```
forge script script/03_InitCLPool.s.sol \ 
  --rpc-url $RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast
```
Copy the PoolId to .env 

3. Approve reward token transfer to OGBoost
```
forge script script/21_Approves.sol \ 
  --rpc-url $RPC_URL \
  --broadcast
```

4. Frontend
In order to run the frontend, you have to go to the `frontend` directory and run the following commands:
`nvm use v20` 
`npm install`
`npm start`

Runs the app in the development mode.\
Open [http://localhost:3000](http://localhost:3000) to view it in the browser.


5. Create campaign from UI
Connect with campaign creator (deployer) address and create a campaign.
`http://localhost:3000/list-campaigns`

6. Add liquidity
Alice adds liquidity
```
PERSON=alice forge script script/04_AddLiquidity.s.sol \
  --rpc-url $RPC_URL \
  --broadcast
```
Bob adds same amount of liquidity
```
PERSON=bob forge script script/04_AddLiquidity.s.sol \ 
  --rpc-url $RPC_URL \
  --broadcast
```

7. Perform Seaps
Carol swaps WBNB to CAKE3 and generates fees for LPs
```
PERSON=carol forge script script/06_Swaps.sol \
  --rpc-url $RPC_URL \
  --broadcast
```

8. Push OG Data
```
forge script script/07_PushOGData.sol \ 
  --rpc-url $RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast
```

9. Get rewards in the console
The pool is also "poked" to update the LP fees for Alice and Bob
```
forge script script/08_CheckRewards.sol \
  --rpc-url $RPC_URL \
  --broadcast
```

10. See Rewards in the frontend
Connect with Alice's wallet
`http://localhost:3000/list-campaigns`

