// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Script.sol";
import "../src/Catapoolt.sol"; // Path to the contract
import {MockERC20} from "solmate/src/test/utils/mocks/MockERC20.sol";

import {Utils} from "./Utils.s.sol";

contract DeployERC20 is Script {
    function run() external {

        address deployer = Utils.getAddressForPerson(vm, "deployer");
        address alice = Utils.getAddressForPerson(vm, "alice");
        address bob = Utils.getAddressForPerson(vm, "bob");
        address carol = Utils.getAddressForPerson(vm, "carol");

        vm.startBroadcast();

        MockERC20 cake3Token = new MockERC20("Cake 3 Token", "CAKE3", 18);
        console.log("Deployed Cake 3 Token at:", address(cake3Token));
        cake3Token.mint(deployer, 1_000_000 ether);
        console.log("Minted 1,000,000 CAKE3 to DEPLOYER");

        cake3Token.transfer(alice, 100 ether);
        console.log("Transferred 100 CAKE3 to ALICE");

        cake3Token.transfer(bob, 100 ether);
        console.log("Transferred 100 CAKE3 to BOB");

        cake3Token.transfer(carol, 100 ether);
        console.log("Transferred 100 CAKE3 to CAROL");
        
        vm.stopBroadcast();
    }
}
