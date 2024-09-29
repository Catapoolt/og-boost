// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {CLPositionManager} from "pancake-v4-periphery/src/pool-cl/CLPositionManager.sol";

import "forge-std/Script.sol";
import "../src/Catapoolt.sol";

contract SetVKHash is Script {
    function run() external {
        // Get environment variables or specify them directly
        address catapooltAddress = vm.envAddress("CATAPOOLT");
        bytes32 vkHash = vm.envBytes32("VK_HASH");
        console.log("VK_HASH:");
        console.logBytes32(vkHash);

        // Start broadcasting transactions (deploying the contract)
        vm.startBroadcast();

        // Deploy the contract
        Catapoolt catapoolt = Catapoolt(catapooltAddress);
        catapoolt.setVkHash(vkHash);

        // Log the contract address for future reference
        vm.stopBroadcast();
        
        console.log("Loaded Catapoolt at:", address(catapoolt));
    }
}
