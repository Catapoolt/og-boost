PERSON=alice; forge script script/04_AddLiquidity.s.sol \
  --rpc-url $RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast



# verify caontract
forge verify-contract --compiler-version 0.8.26 --chain-id 97 \
  --constructor-args $(cast abi-encode "constructor(address, address, address)" \
  0x969D90aC74A1a5228b66440f8C8326a8dA47A5F9 0x89A7D45D007077485CB5aE2abFB740b1fe4FF574 0xF7E9CB6b7A157c14BCB6E6bcf63c1C7c92E952f5) \
  --etherscan-api-key $BSCSCAN_API_KEY 0x8486D0e5938B037AAEAD280a33D0c9cc2f8d3AF6 src/Catapoolt.sol:Catapoolt