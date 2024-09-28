// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/SaltEncoderDecoder.sol";

contract SaltEncoderDecoderTest is Test {
    function testEncodeDecode() public pure {
        // Set up a test address and bytes8 value
        address testAddress = address(0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496);
        bytes8 testBytes = 0x1234567890abcdef;

        // Call encode and check that the output matches expected
        bytes32 encoded = SaltEncoderDecoder.encode(testAddress, testBytes);
        (address decodedAddress, bytes8 decodedBytes) = SaltEncoderDecoder.decode(encoded);

        // Check that the decoded values match the original input
        assertEq(testAddress, decodedAddress);
        assertEq(testBytes, decodedBytes);
    }
}