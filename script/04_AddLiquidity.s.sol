// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Script.sol";
import "../src/Catapoolt.sol";
import {MockERC20} from "pancake-v4-core/test/helpers/TokenFixture.sol";
import {Currency, CurrencyLibrary} from "pancake-v4-core/src/types/Currency.sol";
import {Constants} from "pancake-v4-core/test/pool-cl/helpers/Constants.sol";
import {PoolKey} from "pancake-v4-core/src/types/PoolKey.sol";
import {CLPoolParametersHelper} from "pancake-v4-core/src/pool-cl/libraries/CLPoolParametersHelper.sol";
import {SortTokens} from "pancake-v4-core/test/helpers/SortTokens.sol";
import {PoolId} from "pancake-v4-core/src/types/PoolId.sol";
import {CLPoolManager} from "pancake-v4-core/src/pool-cl/CLPoolManager.sol";
import {CLPositionManager} from "pancake-v4-periphery/src/pool-cl/CLPositionManager.sol";
import {UniversalRouter, RouterParameters} from "pancake-v4-universal-router/src/UniversalRouter.sol";
import {LiquidityAmounts} from "pancake-v4-periphery/src/pool-cl/libraries/LiquidityAmounts.sol";
import {TickMath} from "pancake-v4-core/src/pool-cl/libraries/TickMath.sol";
import {PositionConfig} from "../test/utils/PositionConfig.sol";
import {Planner, Plan} from "pancake-v4-periphery/src/libraries/Planner.sol";
import {Actions} from "pancake-v4-periphery/src/libraries/Actions.sol";
import {IAllowanceTransfer} from "permit2/src/interfaces/IAllowanceTransfer.sol";

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

import {Utils} from "./Utils.s.sol";

contract DeployCatapoolt is Script {

    using CLPoolParametersHelper for bytes32;
    using Planner for Plan;
    using PoolIdLibrary for PoolKey;

    CLPoolManager poolManager;
    CLPositionManager positionManager;
    UniversalRouter universalRouter;

    IAllowanceTransfer permit2;

    function run() external {
        poolManager = CLPoolManager(vm.envAddress("POOL_MANAGER"));
        console.log("Loaded Pool Manager at:", address(poolManager));
        positionManager = CLPositionManager(vm.envAddress("POSITION_MANAGER"));
        console.log("Loaded Position Manager at:", address(positionManager));
        universalRouter = UniversalRouter(payable(vm.envAddress("UNIVERSAL_ROUTER")));
        console.log("Loaded Universal Router at:", address(universalRouter));
        permit2 = IAllowanceTransfer(vm.envAddress("PERMIT2"));

        address wbnbAddress = vm.envAddress("WBNB");
        address cake3Address = vm.envAddress("CAKE3");

        string memory person = vm.envString("PERSON");
        console.log("Person:", person);
        uint256 personPKey = Utils.getPkeyForPerson(vm, person);
        address personAddress = Utils.getAddressForPerson(vm, person);
        console.log("Address for", person, "is:", personAddress);

        MockERC20 wbnb = MockERC20(wbnbAddress);
        console.log("Loaded WBNB at:", address(wbnb));
        MockERC20 cake3 = MockERC20(cake3Address);
        console.log("Loaded CAKE3 at:", address(cake3));

        (PoolKey memory key, ) = Utils.getThePool(vm);

        uint128 amount0Max = 0.001 ether;
        uint128 amount1Max = 0.001 ether;
        int24 tickLower = -120;
        int24 tickUpper = 120;
        address recipient = personAddress;

        vm.startBroadcast(personPKey);
        
        // Approvals
        cake3.approve(address(positionManager), type(uint256).max);
        wbnb.approve(address(positionManager), type(uint256).max);

        cake3.approve(address(permit2), type(uint256).max);
        wbnb.approve(address(permit2), type(uint256).max);

        permit2.approve(address(cake3), address(positionManager), type(uint160).max, type(uint48).max);
        permit2.approve(address(wbnb), address(positionManager), type(uint160).max, type(uint48).max);

        permit2.approve(address(cake3), address(universalRouter), type(uint160).max, type(uint48).max);
        permit2.approve(address(wbnb), address(universalRouter), type(uint160).max, type(uint48).max);

        // Add liquidity
        uint256 tokenId = addLiquidity(key, amount0Max, amount1Max, tickLower, tickUpper, recipient);
        console.log("Liquidity added. Token ID:", tokenId);
        vm.stopBroadcast();    
    }

    function addLiquidity(
        PoolKey memory key,
        uint128 amount0Max,
        uint128 amount1Max,
        int24 tickLower,
        int24 tickUpper,
        address recipient
    ) internal returns (uint256 tokenId) {
        tokenId = positionManager.nextTokenId();

        (uint160 sqrtPriceX96,,,) = poolManager.getSlot0(key.toId());

        uint256 liquidity = LiquidityAmounts.getLiquidityForAmounts(
            sqrtPriceX96,
            TickMath.getSqrtRatioAtTick(tickLower),
            TickMath.getSqrtRatioAtTick(tickUpper),
            amount0Max,
            amount1Max
        );
        
        PositionConfig memory config = PositionConfig({poolKey: key, tickLower: tickLower, tickUpper: tickUpper});
        Plan memory planner = Planner.init().add(
            Actions.CL_MINT_POSITION, abi.encode(config, liquidity, amount0Max, amount1Max, recipient, new bytes(0))
        );
        bytes memory data = planner.finalizeModifyLiquidityWithClose(key);
        positionManager.modifyLiquidities(data, block.timestamp + 1 minutes);
    }
}
