// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

library CoordinatesLib {
    /**
     * Splits a bytes32 in two bytes16
     * @param source to split
     * @return x the first 16 bytes
     * @return y the next 16 bytes
     */
    function split(bytes32 source) public pure returns (bytes16 x, bytes16 y) {
        bytes16[2] memory output = [bytes16(0), 0];
        assembly {
            mstore(output, source)
            mstore(add(output, 16), source)
        }
        return (output[0], output[1]);
    }

    /**
     * Merges two bytes16 in a bytes32
     * @param sourceA the first 16 bytes
     * @param sourceB the next 16 bytes
     * @return output the merged bytes
     */
    function merge(bytes16 sourceA, bytes16 sourceB)
        public
        pure
        returns (bytes32 output)
    {
        return bytes32((uint256(uint128(sourceA)) << 128) | uint128(sourceB));
    }

    /**
     * Deserializes a bytes32 in a (x,y) point
     * @param input to deserialize
     * @return x deserialized value on the x axis
     * @return y deserialized value on the y axis
     */
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

    /**
     * Takes (x,y) coordinates and returns its bytes32 serialization
     * @param x the value on the x axis
     * @param y the value on the y axis
     * @return output serialized (x,y) coordinates
     */
    function convertFromCoordinates(int128 x, int128 y)
        public
        pure
        returns (bytes32 output)
    {
        return merge(bytes16(uint128(x)), bytes16(uint128(y)));
    }

    /**
     * Takes a number and returns its square root.
     * @param x the value to square
     * @return output the square root of the given number
     */
    function sqrt(uint256 x) public pure returns (uint256 output) {
        uint256 z = (x + 1) / 2;
        output = x;
        while (z < output) {
            output = z;
            z = (x / z + z) / 2;
        }
    }

    /**
     * Takes two (x,y) points on a grid and returns distance between them.
     * @param x1 the value on the x axis of the first point
     * @param y1 the value on the y axis of the first point
     * @param x2 the value on the x axis of the second point
     * @param y2 the value on the y axis of the second point
     * @return estimatedDistance between the two points
     */
    function distance(
        int128 x1,
        int128 y1,
        int128 x2,
        int128 y2
    ) public pure returns (uint256 estimatedDistance) {
        int256 x = x2 - x1;
        int256 y = y2 - y1;
        estimatedDistance = sqrt(uint256(x * x + y * y));
    }

    /**
     * Takes two bytes32 serialized points on a grid and returns distance between them.
     * @param p1 the first serialized point
     * @param p2 the second serialized point
     * @return estimatedDistance between the two points
     todo: test this function
     */
    function distance(bytes32 p1, bytes32 p2)
        public
        pure
        returns (uint256 estimatedDistance)
    {
        (int128 x1, int128 y1) = convertToCoordinates(p1);
        (int128 x2, int128 y2) = convertToCoordinates(p2);
        return distance(x1, y1, x2, y2);
    }
}
