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
import {Vault} from "pancake-v4-core/src/Vault.sol";
import {CLPoolManager} from "pancake-v4-core/src/pool-cl/CLPoolManager.sol";
import {CLPositionManager} from "pancake-v4-periphery/src/pool-cl/CLPositionManager.sol";
import {UniversalRouter, RouterParameters} from "pancake-v4-universal-router/src/UniversalRouter.sol";
import {LiquidityAmounts} from "pancake-v4-periphery/src/pool-cl/libraries/LiquidityAmounts.sol";
import {TickMath} from "pancake-v4-core/src/pool-cl/libraries/TickMath.sol";
import {PositionConfig} from "../test/utils/PositionConfig.sol";
import {Planner, Plan} from "pancake-v4-periphery/src/libraries/Planner.sol";
import {Actions} from "pancake-v4-periphery/src/libraries/Actions.sol";

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

contract DeployCatapoolt is Script {

    using CLPoolParametersHelper for bytes32;
    using Planner for Plan;
    using PoolIdLibrary for PoolKey;

    Vault vault;
    CLPoolManager poolManager;
    CLPositionManager positionManager;
    UniversalRouter universalRouter;

    function run() external {
        vault = Vault(vm.envAddress("VAULT"));
        console.log("Loaded Vault at:", address(vault));
        poolManager = CLPoolManager(vm.envAddress("POOL_MANAGER"));
        console.log("Loaded Pool Manager at:", address(poolManager));
        positionManager = CLPositionManager(vm.envAddress("POSITION_MANAGER"));
        console.log("Loaded Position Manager at:", address(positionManager));
        universalRouter = UniversalRouter(payable(vm.envAddress("UNIVERSAL_ROUTER")));
        console.log("Loaded Universal Router at:", address(universalRouter));

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
        uint128 amount0Max = 0.01 ether;
        uint128 amount1Max = 0.01 ether;
        int24 tickLower = -120;
        int24 tickUpper = 120;
        address recipient = personAddress;

        vm.startBroadcast(personPKey);
        cake3.approve(address(positionManager), type(uint256).max);
        wbnb.approve(address(positionManager), type(uint256).max);

        uint256 tokenId = addLiquidity(key, amount0Max, amount1Max, tickLower, tickUpper, recipient);
        console.log("Added liquidity. Returned token ID:", tokenId);

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
        positionManager.modifyLiquidities(data, block.timestamp);
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
