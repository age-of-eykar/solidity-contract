// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

import "./CoordinatesLib.sol";

contract Eykar {
    constructor() {}

    enum StructureType {
        None,
        House,
        Mansion
    }

    struct Plot {
        address owner;
        StructureType structure;
    }

    mapping(bytes32 => Plot) public map;

    function conquer(bytes32 location) public returns (bool conquered) {
        if (map[location].owner == address(0)) return false;

        map[location] = Plot(msg.sender, StructureType.None);
        return true;
    }
}
