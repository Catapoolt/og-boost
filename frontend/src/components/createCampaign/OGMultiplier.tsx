import { Box, Grid, GridItem, Text } from "@chakra-ui/react";
import React from "react";
import TokenSelect from "../common/TokenSelect";
import { Token } from "../../models/createCampaign";
import { NumericFormat } from "react-number-format";
import S from "../../pages/index.module.css";
import St from './index.module.css';

interface OGMultiplierProps {
	tokenList: Token[];
	selectedToken: Token | null;
	handleTokenSelect: (token: Token) => void;
	setFeesAmountCallback: (value: string) => void;
	setMultiplierCallback: (value: number | string) => void;
	feesAmount: number | string;
	multiplier: number | string;
}

const OGMultiplier: React.FC<OGMultiplierProps> = ({
													   tokenList,
													   selectedToken,
													   handleTokenSelect,
													   setMultiplierCallback,
													   setFeesAmountCallback,
													   feesAmount,
													   multiplier
												   }) => {
	return (
		<Box p={6} mb={6} borderRadius={'10'} bg={'#141620'}>
			
			{/* First Row: Full-width Token Select */}
			
			<Grid templateColumns={'repeat(2, 1fr)'} gap={4} mb={4}
				  alignItems={'center'}> {/* Two equal-width columns */}
				<GridItem>
					<Text mb={1}>Token:</Text>
					<TokenSelect tokenList={tokenList} selectedToken={selectedToken}
								 handleTokenSelect={handleTokenSelect} />
				</GridItem>
				<Text mt={4} fontSize={'x-large'} fontWeight={'700'} className={St.ogText}>OG Multiplier</Text>
			</Grid>
			
			{/* Second Row: Fees Amount and Multiplier */}
			<Grid templateColumns={'repeat(2, 1fr)'} gap={4}> {/* Two equal-width columns */}
				<GridItem>
					<Text mb={1}>Fees Amount:</Text>
					<Box display={'flex'} alignItems={'center'}>
						<Text me={1} className={'color-secondary'} fontWeight={'700'} fontSize={'x-large'}>{'>'}</Text>
						<NumericFormat
							className={`bg-main color-secondary ${S.totalRewards}`}
							value={feesAmount}
							displayType={'input'} // Make it editable
							thousandSeparator={true}
							decimalScale={2}
							onValueChange={(values) => {
								const { floatValue } = values;
								setFeesAmountCallback(floatValue?.toString() || '0.0'); // Set the value of totalRewards
							}}
						/>
					</Box>
				</GridItem>
				
				<GridItem>
					<Text mb={1}>Multiplier (ex: x2.5)</Text>
					<Box display={'flex'} alignItems={'center'}>
						<Text mt={2} me={1} className={'color-secondary'} fontWeight={'700'} fontSize={'small'}>X</Text>
						<NumericFormat
							className={`bg-main color-secondary ${S.totalRewards}`}
							value={multiplier}
							displayType={'input'} // Make it editable
							thousandSeparator={true}
							decimalScale={2}
							onValueChange={(values) => {
								const { floatValue } = values;
								setMultiplierCallback(floatValue || 0.0); // Set the value of totalRewards
							}}
						/>
					</Box>
				
				</GridItem>
			</Grid>
		</Box>
	);
};

export default OGMultiplier;
