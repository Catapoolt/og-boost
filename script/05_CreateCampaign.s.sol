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

contract DeployCatapoolt is Script {
    using CLPoolParametersHelper for bytes32;

    function run() external {
        address catapooltAddress = vm.envAddress("CATAPOOLT");
        address cake3Address = vm.envAddress("CAKE3");
        address wbnbAddress = vm.envAddress("WBNB");

        Catapoolt catapoolt = Catapoolt(catapooltAddress);
        console.log("Loaded Catapoolt at:", address(catapoolt));

        MockERC20 cake3 = MockERC20(cake3Address);

        // PARAMETERS
        PoolId poolId = PoolId.wrap(
            0x48d1d3d5b41db6da10e6d68317a3bfb6257d3d015dfb607e1fec80a4d9751ecb
        );
        uint256 rewardAmount = 1 ether;
        address rewardToken = cake3Address;
        uint256 startsAt = block.timestamp;
        uint256 endsAt = block.timestamp + 1 days;
        uint256 earnedFeesAmount = 0.001 ether;
        address feeToken = wbnbAddress;
        uint256 multiplierPercent = 250;

        vm.startBroadcast();
        // Approve cake3 to Catapoolt
        cake3.approve(catapooltAddress, type(uint256).max);

        uint256 campaignId = catapoolt.createCampaign(
            poolId,
            rewardAmount,
            rewardToken,
            startsAt,
            endsAt,
            earnedFeesAmount,
            feeToken,
            multiplierPercent
        );

        console.log("Created campaign with ID:", campaignId);

        vm.stopBroadcast();
    }
}
