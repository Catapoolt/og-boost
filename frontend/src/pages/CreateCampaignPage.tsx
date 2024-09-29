import { Box, Button, Text, useToast, Link, Container } from '@chakra-ui/react';
import React, { useState } from "react";
import { PoolOption, Token } from "../models/createCampaign";
import SelectPool from "../components/createCampaign/SelectPool";
import Rewards from "../components/createCampaign/Rewards";
import PeriodCampaign from "../components/createCampaign/PeriodCampaign";
import OGMultiplier from "../components/createCampaign/OGMultiplier";
import { BrowserProvider, Contract, ethers } from 'ethers';
import { useWeb3ModalProvider } from '@web3modal/ethers/react';
import Project from "../abi/Catapoolt.json";
import { CONTRACT_ADDRESS, getUnixTimestamp, poolOptions, tokenList, truncateMiddle } from "../utils";

const CreateCampaignPage = () => {
	const { walletProvider } = useWeb3ModalProvider();
	const toast = useToast()
	
	const [loading, setLoading] = useState(false);
	
	const [selectedPool, setSelectedPool] = React.useState<PoolOption | null>(null);
	const [totalRewards, setTotalRewards] = React.useState<number | string>('0.0');
	const [feesAmount, setFeesAmount] = React.useState<number | string>('0.0');
	const [multiplier, setMultiplier] = React.useState<number | string>('0.0');
	const [selectedToken, setSelectedToken] = React.useState<Token | null>(null);
	const [feeTokenOG, setFeeTokenOGTokenOG] = React.useState<Token | null>(null);
	const [startDate, setStartDate] = useState('');
	const [endDate, setEndDate] = useState('');
	
	const handlePoolSelect = (poolOption: PoolOption) => {
		setSelectedPool(poolOption);
	};
	
	const handleCreateCampaign = async () => {
		if (!walletProvider) {
			alert('Please connect your wallet');
			return;
		}
		
		const provider = new BrowserProvider(walletProvider);
		const signer = await provider.getSigner();
		const contract = new Contract(CONTRACT_ADDRESS, Project.abi, signer);
		
		try {
			setLoading(true);
			const wBNB = '0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd';
			const CAKE3 = '0xD3677F083B127a93c825d015FcA7DD0e45684AcA';
			
			if (!ethers.isAddress(wBNB) || !ethers.isAddress(CAKE3)) {
				throw new Error('One of the addresses is invalid');
			}
			
			const poolIdBytes32 = '0x48d1d3d5b41db6da10e6d68317a3bfb6257d3d015dfb607e1fec80a4d9751ecb';
			console.log('Pool ID:', poolIdBytes32);
			
			const rewardAmount = ethers.parseUnits(totalRewards.toString(), 18);
			const rewardToken = selectedToken?.address || CAKE3;
			const earnedFeesAmount = ethers.parseUnits(feesAmount.toString(), 18);
			const feeToken = feeTokenOG?.address || wBNB;
			
			const startsAt = getUnixTimestamp(startDate);
			const endsAt = getUnixTimestamp(endDate);
			const multiplierPercent = parseFloat(multiplier.toString()) * 100;
			
			const gasEstimate = await contract.createCampaign.estimateGas(
				poolIdBytes32, rewardAmount, rewardToken, startsAt, endsAt, earnedFeesAmount, feeToken, multiplierPercent
			);
			console.log('Gas limit:', gasEstimate);
			
			const tx = await contract.createCampaign(
				poolIdBytes32, rewardAmount, rewardToken, startsAt, endsAt, earnedFeesAmount, feeToken, multiplierPercent,
				{ gasLimit: gasEstimate }
			);
			
			const receipt = await tx.wait();
			toast({
				title: 'Campaign created successfully! 🎉 ',
				position: 'top',
				description: (
					<>
						<Box>
							You can view the transaction receipt on BscScan:
						</Box>
						<Link
							color={'yellow.100'}
							href={`https://testnet.bscscan.com/tx/${receipt.hash}`}
							isExternal
						>
							{`https://testnet.bscscan.com/tx/${truncateMiddle(receipt.hash, 13)}`}
						</Link>
					</>
				),
				status: 'success',
				duration: 9000,
				isClosable: true,
			});
			
			console.log('Transaction receipt:', receipt);
			setLoading(false);
		} catch (e: any) {
			setLoading(false);
			console.log('error: ', e);
			toast({
				title: 'Error creating campaign',
				position: 'top',
				description: (
					<>
						<Box>
							{e ? e.info.error.message : 'An error occurred while creating the campaign. Please try again later.'}
						</Box>
					</>
				),
				status: 'error',
				duration: 9000,
				isClosable: true,
			});
		}
	}
	
	return (
		<>
			<Container maxW="3xl" mt={10} className={'color-secondary'} display={'flex'}>
				<Box fontSize={'40px'} me={2}>🧁</Box>
				Welcome to the Campaign Creation page! Here, you can set up a new campaign to promote your project and
				engage with your community. Please follow the steps below to configure your campaign:
			</Container>
			<Container maxW="3xl" mt={5} p={6}>
				<Text mb={2} className={'color-secondary'} fontWeight={'700'} fontSize={'xl'}>Create Campaign</Text>
				<SelectPool selectedPool={selectedPool} handlePoolSelect={handlePoolSelect} poolOptions={poolOptions} />
				<Box p={6} mb={6} borderRadius={'10'} bg={'#141620'}>
					<Rewards tokenList={tokenList} totalRewards={totalRewards} setTotalRewards={setTotalRewards}
							 handleTokenSelect={setSelectedToken} selectedToken={selectedToken} />
					<PeriodCampaign startDate={startDate} endDate={endDate} setStartDateCallback={setStartDate}
									setEndDateCallback={setEndDate} />
				</Box>
				<hr className="gradient-separator" />
				
				<OGMultiplier feesAmount={feesAmount} multiplier={multiplier} setFeesAmountCallback={setFeesAmount}
							  setMultiplierCallback={setMultiplier} selectedToken={feeTokenOG} tokenList={tokenList}
							  handleTokenSelect={setFeeTokenOGTokenOG} />
				
				<Button loadingText='Creating campaign' isLoading={loading} onClick={handleCreateCampaign}
						className={'btn-primary'}
						colorScheme="teal" size="md">Create Campaign</Button>
			</Container>
		</>
	)
};

export default CreateCampaignPage;

// const rewardAmount = ethers.parseUnits('1', 18);
// const rewardToken = CAKE3;
// const earnedFeesAmount = ethers.parseUnits('0.001', 18);
// const feeToken = wBNB;
// const startsAt = Math.floor(Date.now() / 1000) + 60; // Starts in 1 minute
// const endsAt = startsAt + (5 * 24 * 60 * 60); // Ends in 5 days
// const multiplierPercent = 250;