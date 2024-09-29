export interface Token {
	img: string;
	address: string;
	name: string;
	symbol: string;
}

export interface PoolOption {
	poolId: string;
	poolSymbol: string;
	token1: Token;
	token2: Token;
}

export interface iCampaign {
	id: string;
	pool: string;
	rewardAmount: string;
	rewardToken: string;
	startsAt: number;
	endsAt: number;
	earnedFeesAmount: string;
	feeToken: string;
	multiplier: number;
	claimAmount?: string;
};

export interface iReward {
	id: number,
	campaignId: string,
	user: 'string',
	amount: string,
	claimed: false,
	claimedAt: 0
}

export const mockCampaigns: iCampaign[] = [
	{
		id: "1",
		pool: "0x172fcD41E0913e95784454622d1c3724f546f849",
		rewardAmount: "1000.0",
		rewardToken: "0x2170Ed0880ac9A755fd29B2688956BD959F933F8",
		startsAt: 1672531200,
		endsAt: 1675132800,
		earnedFeesAmount: "50.0",
		feeToken: "0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c",
		multiplier: 200
	},
	{
		id: "2",
		pool: "0x36696169C63e42cd08ce11f5deeBbCeBae652050",
		rewardAmount: "500.0",
		rewardToken: "0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d",
		startsAt: 1672531200,
		endsAt: 1675132800,
		earnedFeesAmount: "25.0",
		feeToken: "0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c",
		multiplier: 150
	},
	{
		id: "3",
		pool: "0xD0e226f674bBf064f54aB47F42473fF80DB98CBA",
		rewardAmount: "2000.0",
		rewardToken: "0x2170Ed0880ac9A755fd29B2688956BD959F933F8",
		startsAt: 1672531200,
		endsAt: 1675132800,
		earnedFeesAmount: "100.0",
		feeToken: "0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c",
		multiplier: 300
	}
];