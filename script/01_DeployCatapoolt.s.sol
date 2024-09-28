// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {CLPositionManager} from "pancake-v4-periphery/src/pool-cl/CLPositionManager.sol";

import "forge-std/Script.sol";
import "../src/Catapoolt.sol";

contract DeployCatapoolt is Script {
    function run() external {
        // Get environment variables or specify them directly
        address poolManager = vm.envAddress("POOL_MANAGER");
        address positionManager = vm.envAddress("POSITION_MANAGER");
        address brevisRequest = vm.envAddress("BREVIS_REQUEST");
        bytes32 vkHash = vm.envBytes32("VK_HASH");
        console.log("VK_HASH:");
        console.logBytes32(vkHash);

        // Start broadcasting transactions (deploying the contract)
        vm.startBroadcast();

        // Deploy the contract
        Catapoolt catapoolt = new Catapoolt(ICLPoolManager(poolManager), CLPositionManager(positionManager), brevisRequest);
        catapoolt.setVkHash(vkHash);

        // Log the contract address for future reference
        vm.stopBroadcast();
        
        console.log("Deployed Catapoolt at:", address(catapoolt));
    }
}
