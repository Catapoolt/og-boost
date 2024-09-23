// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Script.sol";
import "../src/Catapoolt.sol"; // Path to the contract

contract DeployCatapoolt is Script {
    function run() external {
        // Get environment variables or specify them directly
        address poolManager = vm.envAddress("POOL_MANAGER");
        address brevisRequest = vm.envAddress("BREVIS_REQUEST");

        // Start broadcasting transactions (deploying the contract)
        vm.startBroadcast();

        // Deploy the contract
        Catapoolt catapoolt = new Catapoolt(ICLPoolManager(poolManager), brevisRequest);

        // Log the contract address for future reference
        console.log("Deployed Catapoolt at:", address(catapoolt));

        vm.stopBroadcast();
    }
}
