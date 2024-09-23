// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

// Import OpenZeppelin's IERC20 and SafeERC20 libraries
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import {PoolKey} from "pancake-v4-core/src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "pancake-v4-core/src/types/PoolId.sol";
import {ICLPoolManager} from "pancake-v4-core/src/pool-cl/interfaces/ICLPoolManager.sol";
import {CLBaseHook} from "./CLBaseHook.sol";

import "brevis-sdk/apps/framework/BrevisApp.sol";
import "brevis-sdk/interface/IBrevisProof.sol";

contract Catapoolt is BrevisApp, Ownable {
    using SafeERC20 for IERC20;
    using PoolIdLibrary for PoolKey;

    struct Campaign {
        uint256 id;
        address pool;
        uint256 rewardAmount;
        address rewardToken;
        uint256 startsAt;
        uint256 endsAt;
    }

    struct Multiplier {
        uint256 campaignId;
        // minimum amount of fees to be earned to get the multiplier
        uint256 earnedFeesAmount;
        address feeToken;
        // multiplier expressed in basis points
        uint256 multiplier;
    }
    
    struct Reward {
        uint256 id;
        uint256 campaignId;
        address user;
        uint256 amount;
        bool claimed;
        uint256 claimedAt;
    }

    struct Offering {
        address currency;
        uint256 amount;
        PoolId poolId;
        uint256 multiplier;
    }

    Campaign[] public campaigns;

    uint256 public campaignId;

    // Event emitted when a new campaign is created
    event CampaignCreated(
        uint256 indexed id,
        address indexed pool,
        uint256 rewardAmount,
        address rewardToken,
        uint256 startsAt,
        uint256 endsAt
    );

    bytes32 public vkHash;

    mapping(address => Offering[]) internal offerings;
    mapping(address => uint256) internal offeringLengths;
    mapping(address => mapping(PoolId => uint256)) internal ogMultipliers;

    constructor(ICLPoolManager _poolManager, address _brevisRequest) BrevisApp(address(_brevisRequest)) Ownable(msg.sender) {
        
    }

    function setVkHash(bytes32 _vkHash) external onlyOwner {
        vkHash = _vkHash;
    }

    function handleProofResult(
        bytes32 _vkHash,
        bytes calldata _appCircuitOutput
    ) internal override {
        require(vkHash == _vkHash, "invalid vk");
        (address[] memory ogAddresses, address[] memory currencies, uint256[] memory amounts) = decodeOutput(_appCircuitOutput);

        // TODO: Reset all OG multipliers

        // Save OG multipliers on the corresponding pools
        for (uint256 i = 0; i < ogAddresses.length; i++) {
            address ogAddress = ogAddresses[i];
            address currency = currencies[i];
            uint256 amount = amounts[i];
            for (uint256 j = 0; j < offeringLengths[currency]; j++) {
                Offering storage offering = offerings[currency][j];
                if (amount >= offering.amount) {
                    ogMultipliers[ogAddress][offering.poolId] = offering.multiplier;
                }
            }
        }
    }

    function decodeOutput(
        bytes calldata output
    ) internal pure returns (address[] memory, address[] memory, uint256[] memory) {
        uint256 numEntries = output.length / 72;
        address[] memory ogAddresses = new address[](numEntries);
        address[] memory tokenAddresses = new address[](numEntries);
        uint256[] memory amounts = new uint256[](numEntries);

        for (uint256 i = 0; i < numEntries; i++) {
            ogAddresses[i] = address(bytes20(output[i * 72: i * 72 + 20]));
            tokenAddresses[i] = address(bytes20(output[i * 72 + 20: i * 72 + 40]));
            amounts[i] = uint256(bytes32(output[i * 72 + 40: i * 72 + 72]));
        }

        return (ogAddresses, tokenAddresses, amounts);
    }


    ////////////////////////////////////////
    // HOOK RELATED FUNCTIONS             //    
    ////////////////////////////////////////

    // function getHooksRegistrationBitmap() external pure override returns (uint16) {
    //     return _hooksRegistrationBitmapFrom(
    //         Permissions({
    //             beforeInitialize: false,
    //             afterInitialize: false,
    //             beforeAddLiquidity: false,
    //             afterAddLiquidity: false,
    //             beforeRemoveLiquidity: false,
    //             afterRemoveLiquidity: false,
    //             beforeSwap: false,
    //             afterSwap: false,
    //             beforeDonate: false,
    //             afterDonate: false,
    //             beforeSwapReturnsDelta: false,
    //             afterSwapReturnsDelta: false,
    //             afterAddLiquidityReturnsDelta: false,
    //             afterRemoveLiquidityReturnsDelta: false
    //         })
    //     );
    // }


    ////////////////////////////////////////
    // CAMPAIGN FUNCTIONS                 //    
    ////////////////////////////////////////

    /**
     * @dev Creates a new reward campaign.
     * Transfers the specified amount of reward tokens from the caller to the contract.
     * @param _pool The address of the liquidity pool.
     * @param _rewardAmount The total amount of reward tokens to be distributed.
     * @param _rewardToken The address of the ERC20 reward token.
     * @param _startsAt The timestamp when the campaign starts.
     * @param _endsAt The timestamp when the campaign ends.
     */
    function createCampaign(
        address _pool,
        uint256 _rewardAmount,
        address _rewardToken,
        uint256 _startsAt,
        uint256 _endsAt
    ) external {
        require(_pool != address(0), "Invalid pool address");
        require(_rewardToken != address(0), "Invalid reward token address");
        require(_endsAt > _startsAt, "End time must be after start time");
        require(_rewardAmount > 0, "Reward amount must be greater than zero");

        // Transfer the reward tokens from the IP to the contract
        IERC20 rewardToken = IERC20(_rewardToken);
        rewardToken.safeTransferFrom(msg.sender, address(this), _rewardAmount);

        // Create the campaign
        Campaign memory newCampaign = Campaign({
            id: campaignId,
            pool: _pool,
            rewardAmount: _rewardAmount,
            rewardToken: _rewardToken,
            startsAt: _startsAt,
            endsAt: _endsAt
        });

        campaigns.push(newCampaign);

        emit CampaignCreated(
            campaignId,
            _pool,
            _rewardAmount,
            _rewardToken,
            _startsAt,
            _endsAt
        );

        campaignId++;
    }

    function createMultiplier(Multiplier memory multiplier) public {
        // Create a new multiplier
    }

    function getCampaigns() public view returns (Campaign[] memory) {
        // Return all campaigns
        return campaigns;
    }

    function getCampaign(uint256 id) public view returns (Campaign memory) {
        require(id < campaigns.length, "Campaign does not exist");
        return campaigns[id];
    }

    function listRewards(address user) public view returns (Reward[] memory) {
        // mock function. all users get a reward of 100 tokens in each campaign
        Reward[] memory rewards = new Reward[](campaigns.length);
        for (uint256 i = 0; i < campaigns.length; i++) {
            rewards[i] = Reward({
                id: i,
                campaignId: i,
                user: user,
                amount: 100 ether,
                claimed: false,
                claimedAt: 0
            });
        }
        return rewards;
    }

    function claimReward(uint256 rewardId) public {
        // Implementation to claim rewards
    }
}