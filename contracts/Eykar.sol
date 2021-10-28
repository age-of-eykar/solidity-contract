// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

import "./CoordinatesLib.sol";

contract Eykar {
    constructor() {}

    enum StructureType {
        None,
        SettlerCamp,
        Hamlet,
        Town
    }

    struct Plot {
        uint256 owner; // owner is a colony id
        uint256 dateOfOwnership; // when owner will really own it
        StructureType structure;
    }

    struct Colony {
        string name;
        address owner; // owner is a player
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

    /**
     * Allows a player to conquer a new plot
     * @param colonyId the source colony id
     * @param location serialized plot location
     * @return arrivalDate
     */
    function conquer(uint256 colonyId, bytes32 location)
        public
        returns (uint256 arrivalDate)
    {
        Colony memory colony = colonies[colonyId - 1];
        require(msg.sender == colony.owner);

        uint256 distanceLength = CoordinatesLib.distance(
            colony.location,
            location
        );
        arrivalDate = distanceLength * 8 + block.timestamp;

        require(
            map[location].owner == 0 ||
                map[location].dateOfOwnership > arrivalDate
        );

        // todo: find real colonyId (create it if needed?)
        map[location] = Plot(colonyId, arrivalDate, StructureType.SettlerCamp);
    }
}
