import { Box, Button, Menu, MenuButton, MenuItem, MenuList } from "@chakra-ui/react";
import S from "../../pages/index.module.css";
import { ChevronDownIcon } from "@chakra-ui/icons";
import React from "react";
import { Token } from "../../models/createCampaign";

interface TokenSelectProps {
	tokenList: Token[];
	selectedToken: Token | null;
	handleTokenSelect: (token: Token) => void;
}

const TokenSelect: React.FC<TokenSelectProps> = ({ tokenList,selectedToken,  handleTokenSelect }) => {
	return (
		<Menu>
			<MenuButton
				className={`bg-main color-secondary ${S.selectToken}`}
				as={Button}
				rightIcon={<ChevronDownIcon />}
				textAlign="left"
				textColor={'white'}
				_hover={{ bg: '#333952' }}
				_active={{ bg: '#333952' }}
			>
				{selectedToken ? (
					<Box display={'flex'} alignItems={'center'}>
						<img width={25} src={selectedToken.img} alt={selectedToken.symbol} />
						<Box ml={3}>{selectedToken.name}</Box>
					</Box>
				) : 'Select Token'}
			</MenuButton>
			<MenuList bg={'#333952'} border={0}>
				{tokenList.map((token, index) => (
					<MenuItem key={index} bg={'#333952'}
							  onClick={() => handleTokenSelect(token)}
							  _hover={{ bg: 'linear-gradient(90deg, #1C202B, #6A5ACD)' }}>
						<Box display={'flex'}>
							<img width={25} src={token.img} alt={token.symbol} />
							<Box ml={3}>{token.name}</Box>
						</Box>
					</MenuItem>
				))}
			</MenuList>
		</Menu>
	)
}

export default TokenSelect;