// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library SaltEncoderDecoder {
    // Encodes an address and bytes8 into bytes32
    function encode(address addr, bytes8 data) internal pure returns (bytes32) {
        // Pack the address and bytes8 into a bytes32
        return bytes32(bytes20(addr)) | (bytes32(data) >> 160);
    }

    // Decodes bytes32 back into address and bytes8
    function decode(bytes32 encodedData) internal pure returns (address, bytes8) {
        // Extract the address from the first 20 bytes (160 bits)
        address addr = address(bytes20(encodedData));
        
        // Extract the bytes8 from the last 8 bytes
        bytes8 data = bytes8(encodedData << 160);

        return (addr, data);
    }
}
