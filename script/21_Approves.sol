// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Script.sol";
import "../src/Catapoolt.sol"; // Path to the contract
import {MockERC20} from "solmate/src/test/utils/mocks/MockERC20.sol";

contract Approves is Script {
    function run() external {

        string memory dev1PKey = getPKey("DEV1_KEY");
        address cake3Address = vm.envAddress("CAKE3");

        address dev1 = getAddress(dev1PKey);
        MockERC20 cake3 = MockERC20(cake3Address);

        // Log the address to the console
        console.log("Address for the private key:", dev1);

        vm.startBroadcast();

        cake3.approve(address(0x61bE9F9bbbf34D1CA94f3bAbc9486A04ac353f77), type(uint256).max);

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
