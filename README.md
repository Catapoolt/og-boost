## Project Overview
OGBoost is a tool for Incentive Providers (IPs) to ofer rewards to PancakeSwap v4 Liquidity Providers (LPs) based on the amount of swap fees generated on other AMMs (e.g. PancakeSwap v3). Also known as fee-based Liquidity Mining, OGBoost automatically calculates the rewards allocation to LPs proportionally, based on the amount of fees earned by each LP during a reward campaign. A hook is put in place to store the positions of LPs as they add liquidity to PancakeSwap V4.

IPs have the ability to ditribute multiplied rewards to OG LPs that have earned fees above configured thresholds on external pools or AMMs. The Incentive Provider sets up reward multipliers for pools with farming rewards. The list of the top LPs is aggregated by the off-chain Brevis based service. The ZK circuit proves that the OG list is correct.




## Future Feature
Idea for the future: Prevent liquidity withdrawal based on the amount of reward tokens sold. If small amounts are sold, no liquidity is locked. In case large amounts of tokens are sold, the hook will gradualy release the LP position liquidity only after more fees are earned. Brevis will be used to quantify selling behaviour of the reward token and inform the hook to lock liquidity.


## Deployment

```
PRIVATE_KEY=<Your_Private_Key>
RPC_URL=https://data-seed-prebsc-1-s1.binance.org:8545/
POOL_MANAGER=<Pool_Manager_Address>
BREVIS_REQUEST=<Brevis_Request_Address>
```

### OGBoost contract (BNB Chain Testnet)
`0x87cb1aCd722232b00a8045abc406376E8aCb5F8F`

##### Dependencies
CLPoolManager `0x969D90aC74A1a5228b66440f8C8326a8dA47A5F9`
BrevisRequest `0xF7E9CB6b7A157c14BCB6E6bcf63c1C7c92E952f5`
