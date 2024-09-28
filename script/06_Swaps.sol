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

    using CLPoolParametersHelper for bytes32;
    using Planner for Plan;
    using PoolIdLibrary for PoolKey;

    UniversalRouter universalRouter;
    CLPoolManager poolManager;

    IAllowanceTransfer permit2;

    function run() external {
        universalRouter = UniversalRouter(payable(vm.envAddress("UNIVERSAL_ROUTER")));
        console.log("Loaded Universal Router at:", address(universalRouter));
        poolManager = CLPoolManager(vm.envAddress("POOL_MANAGER"));
        console.log("Loaded Pool Manager at:", address(poolManager));
        permit2 = IAllowanceTransfer(vm.envAddress("PERMIT2"));

        address catapooltAddress = vm.envAddress("CATAPOOLT");
        address wbnbAddress = vm.envAddress("WBNB");
        address cake3Address = vm.envAddress("CAKE3");

        string memory person = vm.envString("PERSON");
        console.log("Person:", person);
        uint256 personPKey = getPkeyForPerson(person);
        address personAddress = getAddressForPerson(person);
        console.log("Address for", person, "is:", personAddress);

        MockERC20 wbnb = MockERC20(wbnbAddress);
        console.log("Loaded WBNB at:", address(wbnb));
        MockERC20 cake3 = MockERC20(cake3Address);
        console.log("Loaded CAKE3 at:", address(cake3));

        Catapoolt catapoolt = Catapoolt(catapooltAddress);
        console.log("Loaded Catapoolt at:", address(catapoolt));

        (Currency currency0, Currency currency1) = SortTokens.sort(wbnb, cake3);

        // create the pool key
        PoolKey memory key = PoolKey({
            currency0: currency0,
            currency1: currency1,
            hooks: catapoolt,
            poolManager: poolManager,
            fee: uint24(3000), // 0.3% fee
            // tickSpacing: 10
            parameters: bytes32(uint256(catapoolt.getHooksRegistrationBitmap())).setTickSpacing(10)
        });

        PoolId id = key.toId();
        string memory hashStr = Strings.toHexString(uint256(uint256(PoolId.unwrap(id))), 32);
        console.log("Pool ID:", hashStr);

        vm.startBroadcast(personPKey);

        // Approvals
        cake3.approve(address(permit2), type(uint256).max);
        // query and log approval amount
        uint256 cake3Allowance2 = cake3.allowance(personAddress, address(permit2));
        wbnb.approve(address(permit2), type(uint256).max);
        // query and log approval amount
        uint256 wbnbAllowance2 = wbnb.allowance(personAddress, address(permit2));


        (uint160 allowance0, ,) = permit2.allowance(personAddress, Currency.unwrap(currency0), address(universalRouter));
        console.log("Allowance for currency0:", allowance0);
        if(allowance0 == 0) {
            permit2.approve(Currency.unwrap(currency0), address(universalRouter), type(uint160).max, type(uint48).max);
        }

        (uint160 allowance1, ,) = permit2.allowance(personAddress, Currency.unwrap(currency1), address(universalRouter));
        console.log("Allowance for currency1:", allowance1);
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


    // Function to map a person name to the private key and derive the corresponding address
    function getAddressForPerson(string memory person) internal returns (address) {
        uint256 privateKey = getPkeyForPerson(person);

        // Derive the address from the private key
        return deriveAddress(privateKey);
    }

    function getPkeyForPerson(string memory person) internal returns (uint256) {
        string memory privateKeyStr;

        if (keccak256(abi.encodePacked((person))) == keccak256(abi.encodePacked(("alice")))) {
            privateKeyStr = vm.envString("ALICE_KEY"); // Get Alice's private key
        } else if (keccak256(abi.encodePacked((person))) == keccak256(abi.encodePacked(("bob")))) {
            privateKeyStr = vm.envString("BOB_KEY"); // Get Bob's private key
        } else if (keccak256(abi.encodePacked((person))) == keccak256(abi.encodePacked(("carol")))) {
            privateKeyStr = vm.envString("CAROL_KEY"); // Get Bob's private key
        } else {
            revert("Person not found.");
        }

        // Ensure the private key has the '0x' prefix, prepend if missing
        if (bytes(privateKeyStr).length >= 2 && bytes(privateKeyStr)[0] == '0' && bytes(privateKeyStr)[1] == 'x') {
            // If it already has the '0x' prefix
            return vm.parseUint(privateKeyStr); 
        } else {
            // If it's missing the '0x' prefix, add it
            return vm.parseUint(string(abi.encodePacked("0x", privateKeyStr)));
        }
    }

    function deriveAddress(uint256 privateKey) internal pure returns (address) {
        return vm.addr(privateKey);
    }
}
