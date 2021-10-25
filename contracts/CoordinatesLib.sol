// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

library CoordinatesLib {
    function split(bytes32 source) public pure returns (bytes16 x, bytes16 y) {
        bytes16[2] memory output = [bytes16(0), 0];
        assembly {
            mstore(output, source)
            mstore(add(output, 16), source)
        }
        return (output[0], output[1]);
    }

    function merge(bytes16 sourceA, bytes16 sourceB)
        public
        pure
        returns (bytes32)
    {
        return bytes32((uint256(uint128(sourceA)) << 128) | uint128(sourceB));
    }

    function convertToCoordinates(bytes32 input)
        public
        pure
        returns (int128 x, int128 y)
    {
        bytes16 xbytes;
        bytes16 ybytes;
        (xbytes, ybytes) = split(input);

        uint128 ux = uint128(xbytes);
        uint128 uy = uint128(ybytes);

        x = int128(ux);
        y = int128(uy);
    }

    function convertFromCoordinates(int128 x, int128 y)
        public
        pure
        returns (bytes32 output)
    {
        return merge(bytes16(uint128(x)), bytes16(uint128(y)));
    }
}
