import React from "react";
import { Box, Input, Text, Grid } from "@chakra-ui/react";
import S from './index.module.css';

interface PeriodCampaignProps {
	startDate: string;
	setStartDateCallback: (value: string) => void;
	endDate: string;
	setEndDateCallback: (value: string) => void;
}

const PeriodCampaign: React.FC<PeriodCampaignProps> = ({
														   startDate,
														   setStartDateCallback,
														   endDate,
														   setEndDateCallback
													   }) => {
	
	return (
		<Grid templateColumns="repeat(2, 1fr)" gap={4} mt={5} width="100%">
			{/* Start Date Input */}
			<Box display={'flex'} flexDirection={'column'}>
				<Text mb={1}>Start</Text>
				<Input
					className={`${S.borderGradient}`}
					type="datetime-local"
					bg="gray.700"
					color="white"
					value={startDate}
					onChange={(e) => setStartDateCallback(e.target.value)} // Update state on input change
				/>
			</Box>
			
			{/* End Date Input */}
			<Box display={'flex'} flexDirection={'column'}>
				<Text mb={1} alignSelf={'flex-end'}>End</Text>
				<Input
					className={`${S.borderGradient}`}
					type="datetime-local"
					bg="gray.700"
					color="white"
					value={endDate}
					onChange={(e) => setEndDateCallback(e.target.value)} // Update state on input change
				/>
			</Box>
		</Grid>
	);
};

export default PeriodCampaign;
