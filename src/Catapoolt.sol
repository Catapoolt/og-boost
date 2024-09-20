// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

contract Catapoolt {

    struct Campaign {
        uint256 id;
        address pool;
        uint256 rewardAmount;
        address rewardToken;
        uint256 startsAt;
        uint256 endsAt;
        uint256 earnedFeesAmount;
        address feeToken;
        uint256 minFees;
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

    Campaign[] public campaigns;

    uint256 public campaignId;

    function createCampaign(Campaign memory campaign) public {
        // Create a new campaign
        campaignId++;
        campaign.id = campaignId;
        campaigns.push(campaign);
    }

    function getCampaigns() public view returns (Campaign[] memory) {
        // Return all campaigns
        return campaigns;
    }

    function getCampaign(uint256 id) public view returns (Campaign memory) {
        // Return a specific campaign
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
    }
}