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
        uint256 dateOfOwnership; // when owner will really own it
        StructureType structure;
    }

    struct Colony {
        string name;
        address owner;
        bytes32 location; // place of power
        uint256 people;
        uint256 food;
        uint256 materials;
        int256 redirection; // id should be your own if there is no redirection
    }

    // all redeemed plots on the map
    mapping(bytes32 => Plot) public map;

    // registered colonies
    Colony[] public colonies;

    // colonies id per player address
    mapping(address => uint256[]) public coloniesPerPlayer;

    function conquer(bytes32 location) public returns (bool conquered) {
        if (map[location].owner == address(0)) return false;

        map[location] = Plot(msg.sender, block.timestamp, StructureType.None);
        return true;
    }
}
