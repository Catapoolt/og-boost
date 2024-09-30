// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {MockERC20} from "solmate/src/test/utils/mocks/MockERC20.sol";
import {Test} from "forge-std/Test.sol";
import {Constants} from "pancake-v4-core/test/pool-cl/helpers/Constants.sol";
import {Currency} from "pancake-v4-core/src/types/Currency.sol";
import {PoolKey} from "pancake-v4-core/src/types/PoolKey.sol";
import {PoolId} from "pancake-v4-core/src/types/PoolId.sol";
import {CLPoolParametersHelper} from "pancake-v4-core/src/pool-cl/libraries/CLPoolParametersHelper.sol";
import {Catapoolt} from "../src/Catapoolt.sol";
// import {CLCounterHook} from "../src/CLCounterHook.sol";
import {CLTestUtils} from "./utils/CLTestUtils.sol";
import {CLPoolParametersHelper} from "pancake-v4-core/src/pool-cl/libraries/CLPoolParametersHelper.sol";
import {PoolIdLibrary} from "pancake-v4-core/src/types/PoolId.sol";
import {ICLRouterBase} from "pancake-v4-periphery/src/pool-cl/interfaces/ICLRouterBase.sol";
import {CLPositionManager} from "pancake-v4-periphery/src/pool-cl/CLPositionManager.sol";
import {CLPoolManagerRouter} from "pancake-v4-core/test/pool-cl/helpers/CLPoolManagerRouter.sol";
import {ICLPoolManager} from "pancake-v4-core/src/pool-cl/interfaces/ICLPoolManager.sol";
import "forge-std/Console.sol";

contract Rewards is Test, CLTestUtils {
    using PoolIdLibrary for PoolKey;
    using CLPoolParametersHelper for bytes32;

    Catapoolt hook;
    Currency currency0;
    Currency currency1;
    PoolKey key;
    PoolId poolId;

    function setUp() public {
        (currency0, currency1) = deployContractsWithTokens();

        // TODO MockBrevisProof?
        hook = new Catapoolt(poolManager, positionManager, address(0));

        // create the pool key
        key = PoolKey({
            currency0: currency0,
            currency1: currency1,
            hooks: hook,
            poolManager: poolManager,
            fee: uint24(3000), // 0.3% fee
            // tickSpacing: 10
            parameters: bytes32(uint256(hook.getHooksRegistrationBitmap())).setTickSpacing(10)
        });

        poolId = key.toId();

        // initialize pool at 1:1 price point (assume stablecoin pair)
        poolManager.initialize(key, Constants.SQRT_RATIO_1_1, new bytes(0));

        console.log("Test user address:", address(this));
    }

    function testRewards() public {
        MockERC20(Currency.unwrap(currency0)).mint(address(this), 100 ether);
        MockERC20(Currency.unwrap(currency1)).mint(address(this), 100 ether);
        
        // ADD LIQUIDITY
        uint256 tokenId = addLiquidity(key, 1 ether, 1 ether, -60, 60, address(this));
        console.log("Liqudity added. Token ID:", tokenId);
        vm.roll(10);
        vm.warp(30);

        // CREATE CAMPAIGN
        uint256 rewardAmount = 10 ether;
        address rewardToken = Currency.unwrap(currency1);
        uint256 startsAt = block.timestamp;
        uint256 endsAt = block.timestamp + 1 days;
        uint256 earnedFeesAmount = 10 ether;
        address feeToken = Currency.unwrap(currency0);
        uint256 multiplierPercent = 200;

        MockERC20(Currency.unwrap(currency0)).approve(address(hook), type(uint256).max);
        MockERC20(Currency.unwrap(currency1)).approve(address(hook), type(uint256).max);

        //approve vault?
        MockERC20(Currency.unwrap(currency0)).approve(address(vault), 1_000 ether);
        console.log("Approved currency0 for vault", Currency.unwrap(currency0), address(vault));
        MockERC20(Currency.unwrap(currency1)).approve(address(vault), 1_000 ether);
        console.log("Approved currency1 for vault", Currency.unwrap(currency1), address(vault));

        uint256 campaignId = hook.createCampaign(
            poolId,
            rewardAmount,
            rewardToken,
            startsAt,
            endsAt,
            earnedFeesAmount,
            feeToken,
            multiplierPercent
        );
        console.log("Created campaign with ID:", campaignId);
        vm.roll(20);
        vm.warp(60);

        // SWAPS
        exactInputSingle(
            ICLRouterBase.CLSwapExactInputSingleParams({
                poolKey: key,
                zeroForOne: true,
                amountIn: 0.1 ether,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0,
                hookData: new bytes(0)
            })
        );
        console.log("Swap performed");
        vm.roll(30);
        vm.warp(90);

        // POKE REWARDS
        console.log("Poking rewards");
        increaseLiquidity(tokenId, key, 0 ether, 0 ether, -60, 60);

        
        vm.roll(40);
        vm.warp(120);

        // OG Multiplier
        bytes memory appCircuitOutput = abi.encodePacked(
            address(address(this)),
            address(Currency.unwrap(currency1)),
            uint256(12 ether)
        );
        hook._handleProofResult(appCircuitOutput);


        // SHOW REWARDS
        Catapoolt.Reward[] memory rewards = hook.listAllRewards(address(this));
        for (uint256 i = 0; i < rewards.length; i++) {
            console.log("Reward amount:", rewards[i].amount);
        }
    }
}