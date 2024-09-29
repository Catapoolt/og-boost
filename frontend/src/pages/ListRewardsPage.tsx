import { Box, Table, Thead, Tbody, Tr, Th, Td } from '@chakra-ui/react';

const ListRewardsPage = () => {
	return (
		<Box p={6}>
			<Table variant="simple">
				<Thead>
					<Tr>
						<Th>Pool</Th>
						<Th>Rewards</Th>
						<Th>Ends</Th>
						<Th>Multiplier</Th>
						<Th>Claim</Th>
					</Tr>
				</Thead>
				<Tbody>
					<Tr>
						<Td>USDC/ETH</Td>
						<Td>100 AIT</Td>
						<Td>3 days 2 hours</Td>
						<Td>{'x2.3 (> 1000 USDC in fees)'}</Td>
						<Td>23.43 AIT</Td>
					</Tr>
					<Tr>
						<Td>USDC/OP</Td>
						<Td>100 RTE</Td>
						<Td>4 days</Td>
						<Td>{'x5 (> 1000 USDC in fees)'}</Td>
						<Td>0 AIT</Td>
					</Tr>
				</Tbody>
			</Table>
			
			<Box mt={4}>
				<b>Total Claimed:</b>
				<p>34 USDC - 29/07/2024</p>
				<p>12.23 OP - 29/05/2024</p>
			</Box>
		</Box>
	);
};

export default ListRewardsPage;
