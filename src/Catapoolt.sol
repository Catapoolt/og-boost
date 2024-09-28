// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

// Import OpenZeppelin's IERC20 and SafeERC20 libraries
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import {PoolKey} from "pancake-v4-core/src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "pancake-v4-core/src/types/PoolId.sol";
import {ICLPoolManager} from "pancake-v4-core/src/pool-cl/interfaces/ICLPoolManager.sol";
import {CLPosition} from "pancake-v4-core/src/pool-cl/libraries/CLPosition.sol";
import {BalanceDelta, BalanceDeltaLibrary} from "pancake-v4-core/src/types/BalanceDelta.sol";

import {FullMath} from "pancake-v4-core/src/pool-cl/libraries/FullMath.sol";

import {CLBaseHook} from "./CLBaseHook.sol";
import {CLPositionManager} from "pancake-v4-periphery/src/pool-cl/CLPositionManager.sol";

import "brevis-sdk/apps/framework/BrevisApp.sol";
import "brevis-sdk/interface/IBrevisProof.sol";

import "forge-std/Script.sol";

contract Catapoolt is CLBaseHook, BrevisApp, Ownable {
    using SafeERC20 for IERC20;
    using PoolIdLibrary for PoolKey;

    struct Campaign {
        uint256 id;
        PoolId pool;
        uint256 rewardAmount;
        address rewardToken;
        uint256 startsAt;
        uint256 endsAt;
        uint256 earnedFeesAmount;
        address feeToken;
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

    struct RewardClaim{
        uint256 campaignId;
        address user;
        uint256 amount;
        uint256 claimedAt;
    }

    struct Offering {
        address currency;
        uint256 amount;
        PoolId poolId;
        uint256 multiplier;
    }

    Campaign[] public campaigns;

    uint256 public campaignsCount;

    // Event emitted when a new campaign is created
    event CampaignCreated(
        uint256 indexed id,
        PoolId indexed pool,
        uint256 rewardAmount,
        address rewardToken,
        uint256 startsAt,
        uint256 endsAt
    );

    event OGProofSubmitted(
        address indexed wallet, 
        address indexed token, 
        uint256 amount
    );

    bytes32 public vkHash;

    mapping(address => Offering[]) internal offerings;
    mapping(address => uint256) internal offeringLengths;
    mapping(address => mapping(PoolId => uint256)) public ogMultipliers;
    

    CLPositionManager positionManager;

    constructor(ICLPoolManager _poolManager, CLPositionManager _positionManager, address _brevisRequest)  CLBaseHook(_poolManager) BrevisApp(address(_brevisRequest)) Ownable(msg.sender) {
        positionManager = _positionManager;
    }

    ////////////////////////////////////////
    // BREVIS FUNCTIONS                   //    
    ////////////////////////////////////////

    function setVkHash(bytes32 _vkHash) external onlyOwner {
        vkHash = _vkHash;
    }

    function handleProofResult(
        bytes32 _vkHash,
        bytes calldata _appCircuitOutput
    ) internal override {
        require(vkHash == _vkHash, "invalid vk");
        (address wallet, address token, uint256 amount) = decodeOutput(_appCircuitOutput);

        emit OGProofSubmitted(wallet, token, amount);

        // TODO CLEAR ALL MULTIPLIERS
        // delete ogMultipliers;

        // Save OG multipliers on the corresponding pools
        for (uint256 i = 0; i < offeringLengths[token]; i++) {
            Offering storage offering = offerings[token][i];
            if (amount >= offering.amount) {
                ogMultipliers[wallet][offering.poolId] = offering.multiplier;
            }
        }
    }

    function decodeOutput(
        bytes calldata output
    ) internal pure returns (address wallet, address token, uint256 amount) {
        wallet = address(bytes20(output[0: 20]));
        token = address(bytes20(output[20: 40]));
        amount = uint256(bytes32(output[40: 72]));
    }


    ////////////////////////////////////////
    // HOOK FUNCTIONS                     //    
    ////////////////////////////////////////

    function getHooksRegistrationBitmap() external pure override returns (uint16) {
        return _hooksRegistrationBitmapFrom(
            Permissions({
                beforeInitialize: false,
                afterInitialize: false,
                beforeAddLiquidity: false,
                afterAddLiquidity: true,
                beforeRemoveLiquidity: false,
                afterRemoveLiquidity: true,
                beforeSwap: false,
                afterSwap: false,
                beforeDonate: false,
                afterDonate: false,
                beforeSwapReturnsDelta: false,
                afterSwapReturnsDelta: false,
                afterAddLiquidityReturnsDelta: false,
                afterRemoveLiquidityReturnsDelta: false
            })
        );
    }

    function afterAddLiquidity(
        address caller,
        PoolKey calldata poolKey,
        ICLPoolManager.ModifyLiquidityParams calldata modLiqParams,
        BalanceDelta,
        bytes calldata
    ) external override returns (bytes4, BalanceDelta) {
        console.log("CATAPOOLT: afterAddLiquidity");

        PoolId poolId = poolKey.toId();

        uint256 tokenId = uint256(modLiqParams.salt);
        address owner = positionManager.ownerOf(tokenId);
        console.log("POSITION Owner:", owner);
        int24 tickLower = modLiqParams.tickLower;
        int24 tickUpper = modLiqParams.tickUpper;
        bytes32 salt = modLiqParams.salt;

        PositionParams memory positionParams = PositionParams({
            poolId: poolId,
            owner: owner,
            tickLower: tickLower,
            tickUpper: tickUpper,
            salt: salt
        });

        userPositions[owner].push(positionParams);

        return (this.afterAddLiquidity.selector, BalanceDeltaLibrary.ZERO_DELTA);
    }

    function beforeRemoveLiquidity(
        address,
        PoolKey calldata,
        ICLPoolManager.ModifyLiquidityParams calldata,
        bytes calldata
    ) external override pure returns (bytes4) {
        console.log("CATAPOOLT: beforeRemoveLiquidity");
        return this.beforeRemoveLiquidity.selector;
    }



    ////////////////////////////////////////
    // CAMPAIGN PUBLIC FUNCTIONS          //    
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
        PoolId _pool,
        uint256 _rewardAmount,
        address _rewardToken,
        uint256 _startsAt,
        uint256 _endsAt,
        uint256 earnedFeesAmount,
        address feeToken,
        uint256 multiplierPercent
    ) external returns (uint256) {
        require(_rewardToken != address(0), "Invalid reward token address");
        require(_endsAt > _startsAt, "End time must be after start time");
        require(_rewardAmount > 0, "Reward amount must be greater than zero");

        // Transfer the reward tokens from the IP to the contract
        IERC20 rewardToken = IERC20(_rewardToken);
        rewardToken.safeTransferFrom(msg.sender, address(this), _rewardAmount);

        uint256 campaignId = campaignsCount;

        // Create the campaign
        Campaign memory newCampaign = Campaign({
            id: campaignId,
            pool: _pool,
            rewardAmount: _rewardAmount,
            rewardToken: _rewardToken,
            startsAt: _startsAt,
            endsAt: _endsAt,
            earnedFeesAmount: earnedFeesAmount,
            feeToken: feeToken,
            multiplier: multiplierPercent
        });

        campaigns.push(newCampaign);
        campaignIds[_pool] = campaignId;

        emit CampaignCreated(
            campaignId,
            _pool,
            _rewardAmount,
            _rewardToken,
            _startsAt,
            _endsAt
        );

        campaignsCount++;
        return campaignId;
    }

    function getCampaigns() public view returns (Campaign[] memory) {
        // Return all campaigns
        return campaigns;
    }

    function getCampaign(uint256 id) public view returns (Campaign memory) {
        require(id < campaigns.length, "Campaign does not exist");
        return campaigns[id];
    }

    mapping(address => PositionParams[]) public userPositions;
    
    mapping(PoolId => uint256) public campaignIds;

    function listRewards(address user) public view returns (Reward[] memory) {
        PositionParams[] memory positionParams = userPositions[user];
        
        // Keep track of campaigns that have already been processed
        uint256[] memory processedCampaigns = new uint256[](positionParams.length);
        uint256 totalCampaigns = 0;
        
        // Estimate the maximum number of rewards
        Reward[] memory tempRewards = new Reward[](positionParams.length);

        // Loop through each position of the user
        for (uint256 i = 0; i < positionParams.length; i++) {
            uint256 campaignId = campaignIds[positionParams[i].poolId];
            
            // Check if this campaignId has already been processed
            bool alreadyProcessed = false;
            for (uint256 j = 0; j < totalCampaigns; j++) {
                if (processedCampaigns[j] == campaignId) {
                    alreadyProcessed = true;
                    break;
                }
            }

            // If not already processed, list rewards for this campaign
            if (!alreadyProcessed) {
                processedCampaigns[totalCampaigns] = campaignId;
                tempRewards[totalCampaigns] = listRewards(user, campaignId);
                totalCampaigns++;
            }
        }

        // Prepare the final array with the correct size
        Reward[] memory userRewards = new Reward[](totalCampaigns);
        for (uint256 i = 0; i < totalCampaigns; i++) {
            userRewards[i] = tempRewards[i];
        }

        return userRewards;
    }

    function listRewards(address user, uint256 campaignId) public view returns (Reward memory) {
        PositionParams[] memory positionParams = userPositions[user];
        uint256 totalRewards = 0;
        
        // Iterate over user's positions to find positions for the given campaign
        for (uint256 i = 0; i < positionParams.length; i++) {
            if (campaignIds[positionParams[i].poolId] == campaignId) {
                IERC20 rewardToken = IERC20(campaigns[campaignId].rewardToken);
                (uint256 rewards0, uint256 rewards1) = calculateRewards(positionParams[i], rewardToken);
                totalRewards += rewards0 + rewards1;
            }
        }

        // Return the reward struct for the user and the specified campaign
        return Reward({
            id: 0,
            campaignId: campaignId,
            user: user,
            amount: totalRewards,
            claimed: false,
            claimedAt: 0
        });
    }

    mapping(address => RewardClaim[]) public rewardClaims;
    mapping(address => uint256) public rewardClaimsCount;

    function claimReward(uint256 campaign) public {
        Campaign memory _campaign = campaigns[campaign];
        IERC20 rewardToken = IERC20(_campaign.rewardToken);
        
        Reward memory reward = listRewards(msg.sender, campaign);
        require(reward.amount > 0, "No rewards to claim");
        require(rewardToken.balanceOf(address(this)) >= reward.amount, "Insufficient contract balance");

        rewardToken.transfer(msg.sender, reward.amount);
        // Update campaign balance
        campaigns[campaign].rewardAmount -= reward.amount;

        // Store history of claimed rewards
        RewardClaim memory claimed = RewardClaim({
            campaignId: campaign,
            user: msg.sender,
            amount: reward.amount,
            claimedAt: block.timestamp
        });

        rewardClaims[msg.sender].push(claimed);
        rewardClaimsCount[msg.sender]++;
    }


    ////////////////////////////////////////
    // LP INCENTIVES HELPER FUNCTIONS     //    
    ////////////////////////////////////////

    struct PositionParams {
        PoolId poolId;
        address owner;
        int24 tickLower;
        int24 tickUpper;
        bytes32 salt;
    }

    struct WithdrawalSnapshot {
        uint256 feeGrowthInside0X128;
        uint256 feeGrowthInside1X128;
        uint256 feesGrowthGlobal0X128;
        uint256 feesGrowthGlobal1X128;
        uint256 timestamp; // Replace blockNumber with timestamp
    }

    struct Values {
        uint256 amountPerSecond; // Changed from amountPerBlock to amountPerSecond
        uint256 durationInSeconds;
    }

    mapping(bytes32 => WithdrawalSnapshot) public lastWithdrawals;

    mapping(PoolId => mapping(IERC20 => Values)) public rewards;

    function withdrawRewards(
        PositionParams memory params,
        IERC20 rewardToken,
        address claimer
    ) external returns (uint256 rewards0, uint256 rewards1) {
        // TODO Ensure the claimer is the owner of the position
        // require(params.owner == msg.sender, "Caller is not the owner");

        // Calculate rewards
        (rewards0, rewards1) = calculateRewards(params, rewardToken);

        // Fetch the position information to get fee growth inside values
        CLPosition.Info memory position = poolManager.getPosition(
            params.poolId,
            params.owner,
            params.tickLower,
            params.tickUpper,
            params.salt
        );

        // Fetch the global fee growth values
        (uint256 feeGrowthGlobal0X128, uint256 feeGrowthGlobal1X128) = poolManager.getFeeGrowthGlobals(params.poolId);

        // Update the last withdrawal snapshot
        bytes32 positionId = toPositionId(params.poolId, params.owner, params.tickLower, params.tickUpper, params.salt);
        lastWithdrawals[positionId] = WithdrawalSnapshot({
            feeGrowthInside0X128: position.feeGrowthInside0LastX128,
            feeGrowthInside1X128: position.feeGrowthInside1LastX128,
            feesGrowthGlobal0X128: feeGrowthGlobal0X128,
            feesGrowthGlobal1X128: feeGrowthGlobal1X128,
            timestamp: block.timestamp // Use block.timestamp instead of block.number
        });

        // Transfer the rewards to the user
        uint256 totalRewards = rewards0 + rewards1;
        require(rewardToken.balanceOf(address(this)) >= totalRewards, "Insufficient contract balance");

        rewardToken.transfer(claimer, totalRewards);
    }

    function calculateRewards(
        PositionParams memory params,
        IERC20 rewardToken
    ) public view returns (uint256 rewards0, uint256 rewards1) {
        // Create position ID using the struct
        bytes32 positionId = toPositionId(params.poolId, params.owner, params.tickLower, params.tickUpper, params.salt);

        // Access withdrawal data
        WithdrawalSnapshot memory lastWithdrawal = lastWithdrawals[positionId];

        // Calculate fees accrued by the user since the last reward withdrawal
        (uint256 fees0, uint256 fees1) = getFeesAccrued(
            params.poolId, params.owner, params.tickLower, params.tickUpper, params.salt,
            lastWithdrawal.feeGrowthInside0X128, lastWithdrawal.feeGrowthInside1X128
        );

        // Calculate fees accrued by all the users since the last reward withdrawal
        (uint256 feesGlobal0, uint256 feesGlobal1) = getFeesAccruedGlobal(
            params.poolId, lastWithdrawal.feesGrowthGlobal0X128, lastWithdrawal.feesGrowthGlobal1X128
        );

        // Calculate total rewards since the last withdrawal of the user
        uint256 timePassed = block.timestamp - lastWithdrawal.timestamp; // Use time difference in seconds
        uint256 rewardPerSecond = rewards[params.poolId][rewardToken].amountPerSecond; // Use amountPerSecond instead of amountPerBlock
        uint256 totalRewards = timePassed * rewardPerSecond;

        // Rewards are split equally between the two swap directions
        uint256 totalRewardsPerDirection = totalRewards / 2;

        // Calculate the amount of rewards the user can claim
        rewards0 = (feesGlobal0 == 0) ? 0 : FullMath.mulDiv(fees0, totalRewardsPerDirection, feesGlobal0);
        rewards1 = (feesGlobal1 == 0) ? 0 : FullMath.mulDiv(fees1, totalRewardsPerDirection, feesGlobal1);
    }

    function getRewards(
        PoolId pool,
        IERC20 rewardToken
    ) external view returns (uint256, uint256) {
        // PoolId poolId,
        // IERC20 rewardToken

    }

    function toPositionId(PoolId poolId, address owner, int24 tickLower, int24 tickUpper, bytes32 salt) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(poolId, owner, tickLower, tickUpper, salt));
    }

    function getFeesAccrued(
        PoolId poolId,
        address owner,
        int24 tickLower, 
        int24 tickUpper,
        bytes32 salt,
        uint256 feeGrowthInside0X128LastWithdrawal,
        uint256 feeGrowthInside1X128LastWithdrawal
    ) public view returns (uint256 fees0, uint256 fees1) {
        CLPosition.Info memory position = poolManager.getPosition(poolId, owner, tickLower, tickUpper, salt);

        unchecked {
            fees0 = position.feeGrowthInside0LastX128 - feeGrowthInside0X128LastWithdrawal;
            fees1 = position.feeGrowthInside1LastX128 - feeGrowthInside1X128LastWithdrawal;
        }
    }

    function getFeesAccruedGlobal(
        PoolId poolId,
        uint256 feesGrowthGlobal0X128LastWithdrawal,
        uint256 feesGrowthGlobal1X128LastWithdrawal
    ) public view returns (uint256 feesGlobal0, uint256 feesGlobal1) {
        (uint256 feeGrowthGlobal0X128, uint256 feeGrowthGlobal1X128) = poolManager.getFeeGrowthGlobals(poolId);

        unchecked {
            feesGlobal0 = feeGrowthGlobal0X128 - feesGrowthGlobal0X128LastWithdrawal;
            feesGlobal1 = feeGrowthGlobal1X128 - feesGrowthGlobal1X128LastWithdrawal;
        }
    }

}