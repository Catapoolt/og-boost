import { Box, Text, Grid } from "@chakra-ui/react";
import { NumericFormat } from "react-number-format";
import S from "../../pages/index.module.css";
import React from "react";
import { Token } from "../../models/createCampaign";
import TokenSelect from "../common/TokenSelect";

interface RewardsProps {
	tokenList: Token[];
	selectedToken: Token | null;
	totalRewards: number | string;
	setTotalRewards: (value: number) => void;
	handleTokenSelect: (token: Token) => void;
}

const Rewards: React.FC<RewardsProps> = ({
											 totalRewards,
											 setTotalRewards,
											 tokenList,
											 handleTokenSelect,
											 selectedToken,
										 }) => {
	return (
		<>
			<Grid templateColumns="repeat(2, 1fr)" gap={4}> {/* Two columns with a gap */}
				<Box>
					<Text>Total rewards:</Text>
					<NumericFormat
						className={`bg-main color-secondary ${S.totalRewards}`}
						value={totalRewards}
						displayType={'input'} // Make it editable
						thousandSeparator={true}
						decimalScale={2}
						onValueChange={(values) => {
							const { floatValue } = values;
							setTotalRewards(floatValue || 0.0); // Set the value of totalRewards
						}}
					/>
				</Box>
				
				<Box>
					<Box display={'flex'} flexDirection={'column'}>
						 <Box display={'flex'} alignSelf={'self-end'} mb={1}>
							<Text me={1}>Balance:</Text>
							<Text me={1} style={{ fontWeight: 'bold' }}
								  className='color-secondary'>0</Text> {selectedToken && selectedToken.symbol}
						</Box>
						<TokenSelect tokenList={tokenList} selectedToken={selectedToken} handleTokenSelect={handleTokenSelect} />
					</Box>
				</Box>
			</Grid>
		</>
	);
};

export default Rewards;
