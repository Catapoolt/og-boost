import { PoolOption, Token } from "./models/createCampaign";

export const truncateMiddle = (fullStr: string, strLen: number, separator: string = '...') => {
	if (fullStr.length <= strLen) return fullStr;
	
	const separatorLength = separator.length;
	const charsToShow = strLen - separatorLength;
	const frontChars = Math.ceil(charsToShow / 2);
	const backChars = Math.floor(charsToShow / 2);
	
	return (
		fullStr.substring(0, frontChars) +
		separator +
		fullStr.substring(fullStr.length - backChars)
	);
}

export const getUnixTimestamp = (date: string) => {
	return Math.floor(new Date(date).getTime() / 1000);
}

export const CONTRACT_ADDRESS = process.env.REACT_APP_CONTRACT_ADDRESS || '';

export const tokenList: Token[] = [
	{
		name: "Cake 3 Token",
		symbol: 'CAKE3',
		address: "0xD3677F083B127a93c825d015FcA7DD0e45684AcA",
		img: "https://tokens.pancakeswap.finance/images/0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82.png",
	},
	{
		symbol: 'WBNB',
		address: "0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd",
		img: "https://tokens.pancakeswap.finance/images/0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c.png",
		name: "Wrapped BNB",
	},
	{
		symbol: 'USDC',
		img: 'https://tokens.pancakeswap.finance/images/0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d.png',
		name: "Binance-Peg USD Coin",
		address: "0xb48249Ef5b895d6e7AD398186DF2B0c3Cec2BF94",
	}
]

export const poolOptions: PoolOption[] = [
	{
		poolId: process.env.REACT_APP_POOL_ID || '',
		poolSymbol: 'CAKE3/WBNB',
		token1: {
			img: "https://tokens.pancakeswap.finance/images/0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82.png",
			address: "0xD3677F083B127a93c825d015FcA7DD0e45684AcA",
			name: "Cake 3",
			symbol: "CAKE3"
		},
		token2: {
			img: "https://tokens.pancakeswap.finance/images/0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c.png",
			address: "0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd",
			name: "wrapped BNB",
			symbol: "WBNB"
		}
	},
];

export const poolOptionsForRewards: PoolOption[] = [
	{
		poolId: process.env.REACT_APP_POOL_ID || '',
		poolSymbol: 'CAKE3/WBNB',
		token1: {
			img: "https://tokens.pancakeswap.finance/images/0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82.png",
			address: "0xD3677F083B127a93c825d015FcA7DD0e45684AcA",
			name: "Cake 3",
			symbol: "CAKE3"
		},
		token2: {
			img: "https://tokens.pancakeswap.finance/images/0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c.png",
			address: "0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd",
			name: "wrapped BNB",
			symbol: "WBNB"
		}
	},
	
	{
		poolId: '0x48d1d3d5b41db6da10e6d68317a3bfb6257d3d015dfb607e1fec80a4d9751ecb',
		poolSymbol: 'CAKE3/WBNB',
		token1: {
			img: "https://tokens.pancakeswap.finance/images/0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82.png",
			address: "0xD3677F083B127a93c825d015FcA7DD0e45684AcA",
			name: "Cake 3",
			symbol: "CAKE3"
		},
		token2: {
			img: "https://tokens.pancakeswap.finance/images/0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c.png",
			address: "0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd",
			name: "wrapped BNB",
			symbol: "WBNB"
		}
	},
];

export const getTokenByAddress = (address: string) => {
	return tokenList.find(token => token.address === address);
}

export const getPoolById = (poolId: string) => {
	return poolOptionsForRewards.find(pool => pool.poolId === poolId);
}