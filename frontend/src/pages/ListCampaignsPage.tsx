import {
	Box,
	Button,
	Text,
	Container,
	Spinner,
	Stack,
	Table,
	Tbody,
	Td,
	Th,
	Thead,
	Tr,
	useToast,
	Flex, Link,
} from '@chakra-ui/react';
import { BrowserProvider, Contract, ethers, JsonRpcProvider } from 'ethers';
import { CONTRACT_ADDRESS, getPoolById, getTokenByAddress, truncateMiddle } from '../utils';
import Project from '../abi/Catapoolt.json';
import React, { useEffect, useState } from 'react';
import { iCampaign } from '../models/createCampaign';
import { useWeb3ModalAccount } from '@web3modal/ethers/react';
import { useWeb3ModalProvider } from '@web3modal/ethers/react';

const ListCampaignsPage = () => {
	const { address } = useWeb3ModalAccount();
	const { walletProvider } = useWeb3ModalProvider();
	
	const toast = useToast();
	
	const [loading, setLoading] = useState(false);
	const [campaigns, setCampaigns] = useState<iCampaign[]>([]);
	const [loadingClaim, setLoadingClaim] = useState(false);
	const [txHash, setTxHash] = useState<string>('');
	
	useEffect(() => {
		if (address) {
			getCampaigns();
		}
	}, [address, txHash]);
	
	const getReward = async (
		campaignId: string,
		contract: Contract
	): Promise<string> => {
		if (!address) {
			toast({
				title: 'Error creating campaign',
				position: 'top',
				description: (
					<>
						<Box>
							{'User address is not available.'}
						</Box>
					</>
				),
				status: 'error',
				duration: 9000,
				isClosable: true,
			});
			console.error('User address is not available.');
			return '0';
		}
		
		try {
			const reward = await contract.listRewards(address, campaignId);
			return Number(ethers.formatUnits(reward.amount)).toFixed(3);
		} catch (error) {
			console.error(`Error getting reward for campaign ${campaignId}:`, error);
			toast({
				title: 'Error creating campaign',
				position: 'top',
				description: (
					<Box>
						{`Error getting reward for campaign ${campaignId}:`}
					</Box>
				),
				status: 'error',
				duration: 9000,
				isClosable: true,
			});
			return '0';
		}
	};
	
	const getCampaigns = async (): Promise<void> => {
		const provider = new JsonRpcProvider('https://bsc-testnet-rpc.publicnode.com');
		const contract = new Contract(CONTRACT_ADDRESS, Project.abi, provider);
		
		try {
			setLoading(true);
			const campaigns = await contract.getCampaigns();
			
			const response = await Promise.all(
				campaigns.map(async (campaign: iCampaign) => {
					const claimAmount = await getReward(campaign.id.toString(), contract);
					
					return {
						id: campaign.id.toString(),
						pool: campaign.pool,
						rewardAmount: Number(ethers.formatUnits(campaign.rewardAmount)).toFixed(3),
						rewardToken: campaign.rewardToken,
						startsAt: Number(campaign.startsAt),
						endsAt: Number(campaign.endsAt),
						earnedFeesAmount: ethers.formatUnits(campaign.earnedFeesAmount),
						feeToken: campaign.feeToken,
						multiplier: Number(campaign.multiplier),
						claimAmount: claimAmount,
					};
				})
			);
			
			console.log('response:', response);
			setCampaigns(response);
			setLoading(false);
		} catch (error) {
			setLoading(false);
			console.error('Error:', error);
		}
	};
	
	const toastNotify = (title: string, message: string, txHas?: string, type: 'error' | 'success' = 'error') => {
		toast({
			title: title,
			position: 'top',
			description: (
				<>
					<Box>
						{message}
					</Box>
					{txHas && (
						<Link
							color={'yellow.100'}
							href={`https://testnet.bscscan.com/tx/${txHas}`}
							isExternal
						>
							{`https://testnet.bscscan.com/tx/${truncateMiddle(txHas, 13)}`}
						</Link>
					)}
				</>
			),
			status: type,
			duration: 9000,
			isClosable: true,
		});
	}
	
	const handleClaimReward = async (campaignId: string) => {
		if (!walletProvider) {
			toastNotify('Error creating campaign', 'Please connect your wallet to claim rewards.');
			return;
		}
		
		const provider = new BrowserProvider(walletProvider);
		const signer = await provider.getSigner();
		const contract = new Contract(CONTRACT_ADDRESS, Project.abi, signer);
		
		try {
			setLoadingClaim(true);
			const gasEstimate = await contract.claimReward.estimateGas(Number(campaignId));
			console.log('Gas limit:', gasEstimate);
			
			const tx = await contract.claimReward(Number(campaignId), { gasLimit: 5_000_000 });
			const receipt = await tx.wait();
			console.log('receipt:', receipt);
			setLoadingClaim(false);
			toastNotify('Rewards claimed', 'Rewards successfully claimed 🎉', receipt.hash, 'success');
			setTxHash(receipt.hash);
			
		} catch (e) {
			console.log('Error claiming reward:', e);
			setLoadingClaim(false);
			// @ts-ignore
			toastNotify('Error claiming reward', e.reason);
		}
	}
	
	return (
		<>
			<Container maxW="5xl" mt={10} className={'color-secondary'} display={'flex'} alignItems={'center'}>
				<Box fontSize={'35px'} me={5}>🌾</Box>
				Welcome to the Campaigns Dashboard! Here you can explore all the active campaigns available for you to
				participate in. Each campaign offers unique rewards and incentives. Below you'll find a list of
				campaigns along with essential details:
			</Container>
			<Container maxW="5xl" mt={5} p={6} display={'flex'} justifyContent={'center'}>
				{
					loading ? (
							<Stack spacing={4} align="center">
								<Spinner
									thickness="4px"
									speed="0.65s"
									emptyColor="gray.200"
									color="purple.500"
									size="xl"
								/>
								<Box textAlign="center">Loading campaigns...</Box>
							</Stack>
						)
						:
						<Box
							width="100%"
							overflowX="auto"
							className="listCampaignsTable"
							padding={'20px'}
							justifyContent={'center'}
						>
							<Table variant="simple" minWidth="max-content">
								<Thead>
									<Tr>
										<Th fontWeight="bold" className="color-secondary">
											Pool
										</Th>
										<Th fontWeight="bold" className="color-secondary">
											Rewards{' '}
										</Th>
										<Th fontWeight="bold" className="color-secondary">
											End Date
										</Th>
										<Th fontWeight="bold" className="color-secondary">
											Multiplier
										</Th>
										<Th fontWeight="bold" className="color-secondary">
											Claim
										</Th>
									</Tr>
								</Thead>
								<Tbody>
									{campaigns.map((campaign) => (
										<Tr key={campaign.id}>
											<Td className="color-secondary">
												<Box display="flex" alignItems="center">
													<Box display="flex">
														<img
															width={25}
															src={getPoolById(campaign.pool)?.token1.img}
															alt=""
														/>
														<img
															width={25}
															src={getPoolById(campaign.pool)?.token2.img}
															alt=""
														/>
													</Box>
													<Box ml={3}>{getPoolById(campaign.pool)?.poolSymbol}</Box>
												</Box>
											</Td>
											<Td className="color-secondary">
												{campaign.rewardAmount}{' '}
												{getTokenByAddress(campaign.rewardToken)?.symbol}
											</Td>
											<Td className="color-secondary">
												{new Date(Number(campaign.endsAt) * 1000).toLocaleDateString()}
											</Td>
											<Td className="color-secondary">
												{`x${campaign.multiplier / 100} (> ${campaign.earnedFeesAmount} ${
													getTokenByAddress(campaign.feeToken)?.symbol
												} in fees)`}
											</Td>
											<Td className="color-secondary">
												<Flex alignItems={'center'} justifyContent={'space-between'}>
													<Text>{campaign.claimAmount}</Text>
													<Button loadingText='Claiming' isLoading={loadingClaim}
															onClick={() => handleClaimReward(campaign.id)}
															className={'btn-primary'}
															colorScheme="teal" size="md">Claim</Button>
												</Flex>
											
											</Td>
										</Tr>
									))}
								</Tbody>
							</Table>
						</Box>
				}
			</Container>
		</>
	);
};

export default ListCampaignsPage;
