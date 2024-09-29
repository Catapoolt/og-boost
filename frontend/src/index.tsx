import React from 'react';
import ReactDOM from 'react-dom/client';
import { ChakraProvider } from '@chakra-ui/react';
import { BrowserRouter as Router } from 'react-router-dom'; // Import Router
import theme from './theme'; // Import the theme
import App from './App';
import './App.css';
import { createWeb3Modal, defaultConfig } from "@web3modal/ethers";

const root = ReactDOM.createRoot(
	document.getElementById('root') as HTMLElement
);

const projectId = process.env.REACT_APP_PROJECT_ID || '';

const metadata = {
	name: 'OG Boost',
	description: 'AppKit Example',
	url: 'https://web3modal.com', // origin must match your domain & subdomain
	icons: ['https://avatars.githubusercontent.com/u/37784886']
}

const ethersConfig = defaultConfig({
	/*Required*/
	metadata,
})

createWeb3Modal({
	ethersConfig,
	chains: [{
		chainId: 97,
		name: 'BSC Testnet',
		currency: 'tBNB',
		explorerUrl: 'https://testnet.bscscan.com',
		rpcUrl: 'https://bsc-testnet-rpc.publicnode.com',
	}],
	projectId,
	enableAnalytics: true // Optional - defaults to your Cloud configuration
})

root.render(
	<React.StrictMode>
		<ChakraProvider theme={theme}>
			<Router>
				<App />
			</Router>
		</ChakraProvider>
	</React.StrictMode>
);

export default function ConnectButton() {
	return <w3m-button />
}