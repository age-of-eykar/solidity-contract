// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

library CoordinatesLib{
    function split(bytes32 source) public pure returns (bytes16 x, bytes16 y) {
        bytes16[2] memory output = [bytes16(0), 0];
        assembly {
            mstore(output, source)
            mstore(add(output, 16), source)
        }
        return (output[0], output[1]);
    }

    function convertToCoordinates(bytes32 input)
        public
        pure
        returns (int64 x, int64 y)
    {}

    function convertFromCoordinates(int64 x, int64 y)
        public
        pure
        returns (bytes32 output)
    {}
}