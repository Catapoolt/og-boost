// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {PoolKey} from "pancake-v4-core/src/types/PoolKey.sol";
import {MockERC20} from "pancake-v4-core/test/helpers/TokenFixture.sol";
import {Currency, CurrencyLibrary} from "pancake-v4-core/src/types/Currency.sol";
import {SortTokens} from "pancake-v4-core/test/helpers/SortTokens.sol";
import {Catapoolt} from "../src/Catapoolt.sol";
import {ICLPoolManager} from "pancake-v4-core/src/pool-cl/interfaces/ICLPoolManager.sol";
import {CLPoolParametersHelper} from "pancake-v4-core/src/pool-cl/libraries/CLPoolParametersHelper.sol";
import {PoolId, PoolIdLibrary} from "pancake-v4-core/src/types/PoolId.sol";

import {Vm} from "forge-std/Vm.sol";
import "forge-std/Script.sol";

library Utils {
    
    using CLPoolParametersHelper for bytes32;
    using PoolIdLibrary for PoolKey;

    function getThePool(Vm vm) internal view returns (PoolKey memory poolKey, PoolId poolId) {
        address wbnbAddress = vm.envAddress("WBNB");
        address cake3Address = vm.envAddress("CAKE3");
        address catapooltAddress = vm.envAddress("CATAPOOLT");
        address poolManagerAddress = vm.envAddress("POOL_MANAGER");

        MockERC20 wbnb = MockERC20(wbnbAddress);
        MockERC20 cake3 = MockERC20(cake3Address);
        Catapoolt catapoolt = Catapoolt(catapooltAddress);
        ICLPoolManager poolManager = ICLPoolManager(poolManagerAddress);

        (Currency currency0, Currency currency1) = SortTokens.sort(wbnb, cake3);

        poolKey = PoolKey({
            currency0: currency0,
            currency1: currency1,
            hooks: catapoolt,
            poolManager: poolManager,
            fee: uint24(3000), // 0.3% fee
            // tickSpacing: 10
            parameters: bytes32(uint256(catapoolt.getHooksRegistrationBitmap())).setTickSpacing(10)
        });
        poolId = poolKey.toId();
    }

    // Function to map a person name to the private key and derive the corresponding address
    function getAddressForPerson(Vm vm, string memory person) internal view returns (address) {
        uint256 privateKey = getPkeyForPerson(vm, person);

        // Derive the address from the private key
        return deriveAddress(vm, privateKey);
    }

    function getPkeyForPerson(Vm vm, string memory person) internal view returns (uint256) {
        string memory privateKeyStr;

        if (keccak256(abi.encodePacked((person))) == keccak256(abi.encodePacked(("alice")))) {
            privateKeyStr = vm.envString("ALICE_KEY"); // Get Alice's private key
        } else if (keccak256(abi.encodePacked((person))) == keccak256(abi.encodePacked(("bob")))) {
            privateKeyStr = vm.envString("BOB_KEY"); // Get Bob's private key
        } else if (keccak256(abi.encodePacked((person))) == keccak256(abi.encodePacked(("carol")))) {
            privateKeyStr = vm.envString("CAROL_KEY"); // Get Bob's private key
        } else if (keccak256(abi.encodePacked((person))) == keccak256(abi.encodePacked(("deployer")))) {
            privateKeyStr = vm.envString("PRIVATE_KEY");
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

    function deriveAddress(Vm vm, uint256 privateKey) internal pure returns (address) {
        return vm.addr(privateKey);
    }
}