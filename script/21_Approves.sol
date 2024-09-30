// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Script.sol";
import "../src/Catapoolt.sol"; // Path to the contract
import {MockERC20} from "solmate/src/test/utils/mocks/MockERC20.sol";

import {Utils} from "./Utils.s.sol";

contract Approves is Script {
    function run() external {
        uint256 pkey = Utils.getPkeyForPerson(vm, 'deployer');
        address addr = Utils.getAddressForPerson(vm, 'deployer');

        address cake3Address = vm.envAddress("CAKE3");
        address catapooltAddress = vm.envAddress("CATAPOOLT");

        MockERC20 cake3 = MockERC20(cake3Address);

        // Log the address to the console
        console.log("Address for the private key:", addr);

        vm.startBroadcast(pkey);

        cake3.approve(catapooltAddress, type(uint256).max);

        // query and log approval amount
        uint256 allowance = cake3.allowance(addr, catapooltAddress);
        console.log("Contract address:", catapooltAddress);
        console.log("Approved CAKE3 amount:", allowance);

        vm.stopBroadcast();
    }
}
