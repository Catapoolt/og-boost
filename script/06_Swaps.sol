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

contract Swaps is Script {

    using CLPoolParametersHelper for bytes32;
    using Planner for Plan;
    using PoolIdLibrary for PoolKey;

    UniversalRouter universalRouter;

    IAllowanceTransfer permit2;

    function run() external {
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

        (Currency currency0, Currency currency1) = SortTokens.sort(wbnb, cake3);

        (PoolKey memory key, ) = Utils.getThePool(vm);

        vm.startBroadcast(personPKey);

        // Approvals
        cake3.approve(address(permit2), type(uint256).max);
        wbnb.approve(address(permit2), type(uint256).max);

        (uint160 allowance0, ,) = permit2.allowance(personAddress, Currency.unwrap(currency0), address(universalRouter));
        if(allowance0 == 0) {
            permit2.approve(Currency.unwrap(currency0), address(universalRouter), type(uint160).max, type(uint48).max);
        }

        (uint160 allowance1, ,) = permit2.allowance(personAddress, Currency.unwrap(currency1), address(universalRouter));
        if(allowance1 == 0) {
            permit2.approve(Currency.unwrap(currency1), address(universalRouter), type(uint160).max, type(uint48).max);
        }

        // Swap
        exactInputSingle(
            ICLRouterBase.CLSwapExactInputSingleParams({
                poolKey: key,
                zeroForOne: true,
                amountIn: 0.001 ether,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0,
                hookData: new bytes(0)
            })
        );
        console.log("Swapped 0.001 WBNB for CAKE3");

        vm.stopBroadcast();    
    }

    function exactInputSingle(ICLRouterBase.CLSwapExactInputSingleParams memory params) internal {
        Plan memory plan = Planner.init().add(Actions.CL_SWAP_EXACT_IN_SINGLE, abi.encode(params));
        bytes memory data = params.zeroForOne
            ? plan.finalizeSwap(params.poolKey.currency0, params.poolKey.currency1, ActionConstants.MSG_SENDER)
            : plan.finalizeSwap(params.poolKey.currency1, params.poolKey.currency0, ActionConstants.MSG_SENDER);

        bytes memory commands = abi.encodePacked(bytes1(uint8(Commands.V4_SWAP)));
        bytes[] memory inputs = new bytes[](1);
        inputs[0] = data;

        universalRouter.execute(commands, inputs);
    }
}
