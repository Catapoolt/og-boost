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

import {Utils} from "./Utils.s.sol";

contract CheckRewards is Script {

    using CLPoolParametersHelper for bytes32;
    using Planner for Plan;
    using PoolIdLibrary for PoolKey;

    CLPoolManager poolManager;

    CLPositionManager positionManager;

    function run() external {
        address catapooltAddress = vm.envAddress("CATAPOOLT");
        uint256 campaignId = vm.parseUint(vm.envString("CAMPAIGN_ID"));
        address alice = Utils.getAddressForPerson(vm, "alice");
        uint256 alicePKey = Utils.getPkeyForPerson(vm, "alice");
        uint256 aliceTokenId = vm.parseUint(vm.envString("ALICE_TOKEN_ID"));
        address bob = Utils.getAddressForPerson(vm, "bob");
        uint256 bobPKey = Utils.getPkeyForPerson(vm, "bob");
        uint256 bobTokenId = vm.parseUint(vm.envString("BOB_TOKEN_ID"));


        poolManager = CLPoolManager(vm.envAddress("POOL_MANAGER"));
        console.log("Loaded Pool Manager at:", address(poolManager));
        positionManager = CLPositionManager(vm.envAddress("POSITION_MANAGER"));
        console.log("Loaded Position Manager at:", address(positionManager));

        Catapoolt catapoolt = Catapoolt(catapooltAddress);
        console.log("Loaded Catapoolt at:", address(catapoolt));

        (PoolKey memory key, PoolId poolId) = Utils.getThePool(vm);
        string memory poolStr = Strings.toHexString(uint256(uint256(PoolId.unwrap(poolId))), 32);

        console.log("Campaigns BELOW: ");
        Catapoolt.Campaign memory campaign = catapoolt.getCampaign(campaignId);
        console.log("ID:     ", campaign.id);
        console.log("Pool:   ", poolStr);
        console.log("Reward: ", campaign.rewardAmount);
        console.log("Token:  ", campaign.rewardToken);
        console.log("Starts: ", campaign.startsAt);
        console.log("Ends:   ", campaign.endsAt);
        console.log("\n");

        // Multiplier checks
        uint256 aliceMultiplier = catapoolt.ogMultipliers(alice, poolId);
        console.log("Multiplier for Alice: ", aliceMultiplier);
        uint256 bobMultiplier = catapoolt.ogMultipliers(bob, poolId);
        console.log("Multiplier for Bob: ", bobMultiplier);

        // Poke Alice earned fees
        vm.startBroadcast(alicePKey);
        increaseLiquidity(aliceTokenId, key, 0 ether, 0 ether, -120, 120);
        vm.stopBroadcast();

        console.log("Alice's rewards BELOW: ");
        Catapoolt.Reward memory aliceRew = catapoolt.listRewards(alice, campaignId);
        console.log("Reward: ", aliceRew.amount);

        // Poke Bob earned fees
        vm.startBroadcast(bobPKey);
        increaseLiquidity(bobTokenId, key, 0 ether, 0 ether, -120, 120);
        vm.stopBroadcast();

        console.log("Bob's rewards BELOW: ");
        Catapoolt.Reward memory bobRew = catapoolt.listRewards(bob, campaignId);
        console.log("Reward: ", bobRew.amount);

        // Claim Alice's rewards
        vm.startBroadcast(alicePKey);
        catapoolt.claimReward(campaignId);
        vm.stopBroadcast();

        // Claim Bob's rewards
        vm.startBroadcast(bobPKey);
        catapoolt.claimReward(campaignId);
        vm.stopBroadcast();
    }

    function increaseLiquidity(
        uint256 tokenId,
        PoolKey memory key,
        uint128 amount0,
        uint128 amount1,
        int24 tickLower,
        int24 tickUpper
    ) internal {
        (uint160 sqrtPriceX96,,,) = poolManager.getSlot0(key.toId());
        uint256 liquidity = LiquidityAmounts.getLiquidityForAmounts(
            sqrtPriceX96,
            TickMath.getSqrtRatioAtTick(tickLower),
            TickMath.getSqrtRatioAtTick(tickUpper),
            amount0,
            amount1
        );
        PositionConfig memory config = PositionConfig({poolKey: key, tickLower: tickLower, tickUpper: tickUpper});

        // amount0Min and amount1Min is 0 as some hook takes a fee from here
        Plan memory planner = Planner.init().add(
            Actions.CL_INCREASE_LIQUIDITY, abi.encode(tokenId, config, liquidity, 0, 0, new bytes(0))
        );
        bytes memory data = planner.finalizeModifyLiquidityWithClose(key);
        positionManager.modifyLiquidities(data, block.timestamp + 1 hours);
    }
}
