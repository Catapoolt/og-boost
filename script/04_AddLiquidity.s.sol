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

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

contract DeployCatapoolt is Script {

    using CLPoolParametersHelper for bytes32;

    function run() external {
        address catapooltAddress = vm.envAddress("CATAPOOLT");
        address wbnbAddress = vm.envAddress("WBNB");
        address cake3Address = vm.envAddress("CAKE3");

        address poolManagerAddress = vm.envAddress("POOL_MANAGER");

        MockERC20 wbnb = MockERC20(wbnbAddress);
        MockERC20 cake3 = MockERC20(cake3Address);

        Catapoolt catapoolt = Catapoolt(catapooltAddress);
        console.log("Loaded Catapoolt at:", address(catapoolt));
        ICLPoolManager poolManager = ICLPoolManager(poolManagerAddress);

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

        vm.startBroadcast();
        cake3.approve(catapooltAddress, type(uint256).max);
        wbnb.approve(catapooltAddress, type(uint256).max);

        vm.stopBroadcast();    
    }
}
