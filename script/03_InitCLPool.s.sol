// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {MockERC20} from "pancake-v4-core/test/helpers/TokenFixture.sol";
import {Currency, CurrencyLibrary} from "pancake-v4-core/src/types/Currency.sol";
import {Constants} from "pancake-v4-core/test/pool-cl/helpers/Constants.sol";
import {PoolKey} from "pancake-v4-core/src/types/PoolKey.sol";
import {CLPoolParametersHelper} from "pancake-v4-core/src/pool-cl/libraries/CLPoolParametersHelper.sol";
import {SortTokens} from "pancake-v4-core/test/helpers/SortTokens.sol";
import {PoolId, PoolIdLibrary} from "pancake-v4-core/src/types/PoolId.sol";

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

import {Utils} from "./Utils.s.sol";

import "forge-std/Script.sol";
import "../src/Catapoolt.sol"; 

contract DeployCatapoolt is Script {

    using CLPoolParametersHelper for bytes32;
    using PoolIdLibrary for PoolKey;

    function run() external {
        address poolManagerAddress = vm.envAddress("POOL_MANAGER");

        ICLPoolManager poolManager = ICLPoolManager(poolManagerAddress);

        // create the pool key
        (PoolKey memory key, ) = Utils.getThePool(vm);

        PoolId id = key.toId();
        string memory hashStr = Strings.toHexString(uint256(uint256(PoolId.unwrap(id))), 32);
        console.log("Pool ID:", hashStr);

        vm.startBroadcast();
        int24 tick = poolManager.initialize(key, Constants.SQRT_RATIO_1_1, new bytes(0));
        console.log("Initialized pool at tick:", tick);
        vm.stopBroadcast();    
    }
}
