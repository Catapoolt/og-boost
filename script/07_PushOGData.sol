// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Script.sol";
import "../src/Catapoolt.sol"; // Path to the contract
// import {ERC20} from "solmate/src/tokens/ERC20.sol";
import {MockERC20} from "solmate/src/test/utils/mocks/MockERC20.sol";
import {Currency, CurrencyLibrary} from "pancake-v4-core/src/types/Currency.sol";
import {Constants} from "pancake-v4-core/test/pool-cl/helpers/Constants.sol";
import {PoolKey} from "pancake-v4-core/src/types/PoolKey.sol";
import {CLPoolParametersHelper} from "pancake-v4-core/src/pool-cl/libraries/CLPoolParametersHelper.sol";
import {SortTokens} from "pancake-v4-core/test/helpers/SortTokens.sol";

import {Utils} from "./Utils.s.sol";

contract DeployCatapoolt is Script {
    using CLPoolParametersHelper for bytes32;

    function run() external {
        address catapooltAddress = vm.envAddress("CATAPOOLT");
        address alice = Utils.getAddressForPerson(vm, "alice");
        address wbnbAddress = vm.envAddress("WBNB");

        Catapoolt catapoolt = Catapoolt(catapooltAddress);
        console.log("Loaded Catapoolt at:", address(catapoolt));

        vm.startBroadcast();
        uint256 amount = 12 ether;
        bytes memory appCircuitOutput = abi.encodePacked(
            address(alice),
            address(wbnbAddress),
            uint256(amount)
        );
        catapoolt._handleProofResult(appCircuitOutput);
        vm.stopBroadcast();

        console.log("Pushed OG Data for Alice");
    }

    function encodeOutput(
        address wallet,
        address token,
        uint256 amount
    ) internal pure returns (bytes memory) {
        return abi.encodePacked(
            bytes20(wallet),  // First 20 bytes for the wallet address
            bytes20(token),   // Next 20 bytes for the token address
            bytes32(amount)   // Next 32 bytes for the uint256 amount
        );
    }
}
