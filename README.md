## Project Overview
Catapoolt is a tool for Incentive Providers (IPs) to ofer rewards to Liquidity Providers (LPs) based on the amount of swap fees generated on PancakeSwap v4. Also known as fee-based Liquidity Mining, Catapoolt automatically calculates the rewards allocation to LPs proportionally, based on the amount of fees earned by each LP during a reward campaign. 

IPs have the ability to ditribute multiplied rewards to OG LPs that have earned fees above configured thresholds on external pools or AMMs. The Incentive Provider sets up reward multipliers for pools with farming rewards. The list of the top LPs is aggregated by the off-chain Brevis based service. The ZK circuit proves that the OG list is correct.

In order to alleviate the risk of OG LPs selling large amounts of the rewarded tokens, and thus dumping the price, a PancakeSwap V4 hook will prevent liquidity withdrawal based on the amount of reward tokens sold. If small amounts are sold, no liquidity is locked. In case large amounts of tokens are sold, the hook will gradualy release the LP position liquidity only after more fees are earned.
Brevis is used to quantify selling behaviour of the reward token and inform the hook to lock liquidity.

### Basic LP Incentives
An IP creates a reward campaign on a selected pool and specifies the amount of reward tokens and the campaign interval.
At a given point in time, an LP can withdraw the amount of accrued rewards. The IP rewards are equally allocated for each block within the interval.


## Catapoolt contract

0x6F7DBD987e1a8c8F335d351C561C5687e415F5a5
