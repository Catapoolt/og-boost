import { Box, Button, Menu, MenuButton, MenuItem, MenuList } from "@chakra-ui/react";
import { ChevronDownIcon, CopyIcon } from "@chakra-ui/icons";
import React from "react";
import { PoolOption } from "../../models/createCampaign";

interface SelectPoolProps {
	selectedPool: PoolOption | null;
	handlePoolSelect: (pool: PoolOption) => void;
	poolOptions: PoolOption[];
}

const SelectPool: React.FC<SelectPoolProps> = ({
												   selectedPool, handlePoolSelect, poolOptions
											   }) => {
	return (
		<Box p={6} mb={3} borderRadius={'10'} bg={'#141620'}>
			<Menu>
				<MenuButton
					bg={'#333952'}
					width="100%"
					as={Button}
					rightIcon={<ChevronDownIcon />}
					textAlign="left"
					textColor={'white'}
					_hover={{ bg: '#333952' }}
					_active={{ bg: '#333952' }}
				>
					{selectedPool ? (
						<Box display={'flex'} alignItems={'center'}>
							<Box display={'flex'}>
								<img width={25} src={selectedPool.token1.img} alt={selectedPool.token1.symbol} />
								<img width={25} src={selectedPool.token2.img} alt={selectedPool.token2.symbol} />
							</Box>
							<Box ml={3}>{selectedPool.poolSymbol}</Box>
						</Box>
					) : 'Select Pool'}
				
				</MenuButton>
				<MenuList width={'100%'} bg={'#333952'} border={0}>
					{
						poolOptions.map((poolOption, index) => (
							<MenuItem key={index} bg={'#333952'}
									  onClick={() => handlePoolSelect(poolOption)}
									  _hover={{ bg: 'linear-gradient(90deg, #1C202B, #6A5ACD)' }}>
								<Box display={'flex'}>
									<img width={25} src={poolOption.token1.img} alt={poolOption.token1.symbol} />
									<img width={25} src={poolOption.token2.img} alt={poolOption.token2.symbol} />
								</Box>
								<Box ml={3}>{poolOption.poolSymbol}</Box>
							</MenuItem>
						))
					}
				</MenuList>
			</Menu>
			
			{selectedPool && (
				<Box
					display={'flex'}
					justifyContent={'space-between'}
					alignItems={'center'}
					mt={3}
					p={2}
					borderRadius={5}
					bg={'#333952'}
					background="linear-gradient(90deg, #1C202B, #6A5ACD)"
					backgroundClip="padding-box" // This keeps the gradient on the border while the inner background stays solid
				>
					{selectedPool.poolId}
					<CopyIcon cursor={'pointer'} color={'gray.400'} />
				</Box>
			)}
		</Box>
	);
}

export default SelectPool;