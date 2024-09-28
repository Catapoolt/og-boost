// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Script.sol";
import "../src/Catapoolt.sol"; // Path to the contract
// import {ERC20} from "solmate/src/tokens/ERC20.sol";
import {MockERC20} from "pancake-v4-core/test/helpers/TokenFixture.sol";
import {Currency, CurrencyLibrary} from "pancake-v4-core/src/types/Currency.sol";
import {Constants} from "pancake-v4-core/test/pool-cl/helpers/Constants.sol";
import {PoolKey} from "pancake-v4-core/src/types/PoolKey.sol";
import {CLPoolParametersHelper} from "pancake-v4-core/src/pool-cl/libraries/CLPoolParametersHelper.sol";
import {SortTokens} from "pancake-v4-core/test/helpers/SortTokens.sol";
import {PoolId} from "pancake-v4-core/src/types/PoolId.sol";
import {CLPoolManager} from "pancake-v4-core/src/pool-cl/CLPoolManager.sol";
import {UniversalRouter, RouterParameters} from "pancake-v4-universal-router/src/UniversalRouter.sol";
import {ICLRouterBase} from "pancake-v4-periphery/src/pool-cl/interfaces/ICLRouterBase.sol";
import {LiquidityAmounts} from "pancake-v4-periphery/src/pool-cl/libraries/LiquidityAmounts.sol";
import {TickMath} from "pancake-v4-core/src/pool-cl/libraries/TickMath.sol";
import {PositionConfig} from "../test/utils/PositionConfig.sol";
import {Planner, Plan} from "pancake-v4-periphery/src/libraries/Planner.sol";
import {Actions} from "pancake-v4-periphery/src/libraries/Actions.sol";
import {ActionConstants} from "pancake-v4-periphery/src/libraries/ActionConstants.sol";
import {Commands} from "pancake-v4-universal-router/src/libraries/Commands.sol";
import {IAllowanceTransfer} from "permit2/src/interfaces/IAllowanceTransfer.sol";

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

contract Swaps is Script {

    function run() external {
        address catapooltAddress = vm.envAddress("CATAPOOLT");
        address wbnbAddress = vm.envAddress("WBNB");
        address cake3Address = vm.envAddress("CAKE3");
        address alice = 0xb83A3061D0D34073ACcbDA25b32c4c62caff4529;
        address bob = 0x0da8B226E31E55B5265c11B3CE8da776f5dDAd02;

        MockERC20 wbnb = MockERC20(wbnbAddress);
        console.log("Loaded WBNB at:", address(wbnb));
        MockERC20 cake3 = MockERC20(cake3Address);
        console.log("Loaded CAKE3 at:", address(cake3));

        Catapoolt catapoolt = Catapoolt(catapooltAddress);
        console.log("Loaded Catapoolt at:", address(catapoolt));


        console.log("Campaigns BELOW: ");
        Catapoolt.Campaign[] memory campaigns = catapoolt.getCampaigns();
        for (uint i = 0; i < campaigns.length; i++) {
            console.log("ID:     ", campaigns[i].id);
            string memory hashStr = Strings.toHexString(uint256(uint256(PoolId.unwrap(campaigns[i].pool))), 32);
            console.log("Pool:   ", hashStr);
            console.log("Reward: ", campaigns[i].rewardAmount);
            console.log("Token:  ", campaigns[i].rewardToken);
            console.log("Starts: ", campaigns[i].startsAt);
            console.log("Ends:   ", campaigns[i].endsAt);
            console.log("\n");
        }

        // Multiplier checks
        PoolId poolId = PoolId.wrap(
            0x48d1d3d5b41db6da10e6d68317a3bfb6257d3d015dfb607e1fec80a4d9751ecb
        );

        address potentialOG = 0x0da8B226E31E55B5265c11B3CE8da776f5dDAd02;
        uint256 multiplier = catapoolt.ogMultipliers(potentialOG, poolId);
        console.log("Multiplier for potential OG: ", multiplier);

        // console.log("Alice's rewards BELOW: ");
        // Catapoolt.Reward[] memory aliceRew = catapoolt.listRewards(alice);
        // for (uint i = 0; i < aliceRew.length; i++) {
        //     console.log("Reward: ", aliceRew[i].amount);
        // }

        // console.log("Bob's rewards BELOW: ");
        // Catapoolt.Reward[] memory bobRew = catapoolt.listRewards(bob);
        // for (uint i = 0; i < bobRew.length; i++) {
        //     console.log("Reward: ", bobRew[i].amount);
        // }
    }
}
