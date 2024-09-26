// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Script.sol";
import "../src/Catapoolt.sol"; // Path to the contract
import {MockERC20} from "solmate/src/test/utils/mocks/MockERC20.sol";

contract DeployERC20 is Script {
    function run() external {

        string memory deployerPKey = getPKey("PRIVATE_KEY");
        string memory alicePKey = getPKey("ALICE_KEY");
        string memory bobPKey = getPKey("BOB_KEY");

        address deployer = getAddress(deployerPKey);
        address alice = getAddress(alicePKey);
        address bob = getAddress(bobPKey);

        // Log the address to the console
        console.log("Address for the private key:", deployer);

        vm.startBroadcast();

        MockERC20 cake3Token = new MockERC20("Cake 3 Token", "CAKE3", 18);

        console.log("Deployed Cake 3 Token at:", address(cake3Token));

        cake3Token.mint(deployer, 1_000_000 ether);

        console.log("Minted 1,000,000 CAKE3 to DEPLOYER");

        cake3Token.transfer(alice, 100 ether);
        console.log("Transferred 100 CAKE3 to ALICE");
        cake3Token.transfer(bob, 100 ether);
        console.log("Transferred 100 CAKE3 to BOB");

        vm.stopBroadcast();
    }

    function getPKey(string memory pkeyEnv) internal returns (string memory) {
        // Get the private key from the environment as a string
        return vm.envString(pkeyEnv);
    }

    function getAddress(string memory privateKeyStr) internal returns (address) {
        // Add '0x' prefix if it doesn't exist
        if (bytes(privateKeyStr)[0] != '0' || bytes(privateKeyStr)[1] != 'x') {
            privateKeyStr = string(abi.encodePacked("0x", privateKeyStr));
        }

        // Convert the private key from string to uint256
        uint256 privateKey = vm.parseUint(privateKeyStr);

        // Get the address associated with the private key
        address derivedAddress = vm.addr(privateKey);
        return derivedAddress;
    }
}
