import React from 'react';
import { Box, Flex, Text, Link as ChakraLink, Container } from '@chakra-ui/react';
import { Routes, Route, Link } from 'react-router-dom';
import CreateCampaignPage from './pages/CreateCampaignPage';
import ListCampaignsPage from './pages/ListCampaignsPage';
import ListRewardsPage from './pages/ListRewardsPage';

function App() {
	
	const [selectedLink, setSelectedLink] = React.useState('/' as string);
	
	return (
		<>
			<Flex as="nav" bg="gray.800" p={4} borderRadius="md" justify="space-between" align="center" px={20}>
				<Box display={'flex'} mx={2}>
					<Text fontSize="xxx-large" fontWeight="bold" className={'text-gradient'} me={2}>
						OG
					</Text>
					<Text fontSize="xxx-large" fontWeight="bold" className={'text-gradient'}>
						b
					</Text>
					<Text fontSize="xxx-large" fontWeight="bold" className={''}>
						☄️☄️
					</Text>
					<Text fontSize="xxx-large" fontWeight="bold" className={'text-gradient'}>
						ST
					</Text>
				</Box>
				<Box display={'flex'} alignItems={'center'}>
					<ChakraLink as={Link} to="/"
								className={`color-secondary ${selectedLink === '/' && 'text-gradient'}`}
								fontWeight="bold" mx={2}
								onClick={() => setSelectedLink('/')}>
						Create Campaign
					</ChakraLink>
					<ChakraLink as={Link} to="/list-campaigns"
								className={`color-secondary ${selectedLink === '/list-campaigns' && 'text-gradient'}`}
								fontWeight="bold" mx={2}
								onClick={() => setSelectedLink('/list-campaigns')}>
						List Campaigns
					</ChakraLink>
					{/*<ChakraLink as={Link} to="/list-rewards"*/}
					{/*			className={`color-secondary ${selectedLink === '/list-rewards' && 'text-gradient'}`}*/}
					{/*			fontWeight="bold" mx={2}*/}
					{/*			onClick={() => setSelectedLink('/list-rewards')}>*/}
					{/*	List Rewards*/}
					{/*</ChakraLink>*/}
					<Box>
						<w3m-button />
					</Box>
				</Box>
			
			</Flex>
			
			
			<Box mt={6}>
				<Routes>
					<Route path="/" element={<CreateCampaignPage />} />
					<Route path="/list-campaigns" element={<ListCampaignsPage />} />
					<Route path="/list-rewards" element={<ListRewardsPage />} />
				</Routes>
			</Box>
		</>
	
	);
}

export default App;
