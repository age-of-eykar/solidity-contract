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
        uint64 plotsAmount;
        uint256 people;
        uint256 food;
        uint256 materials;
        uint256 redirection; // id should be your own if there is no redirection
    }

    // all redeemed plots on the map
    mapping(bytes32 => Plot) public map;

    // registered colonies
    Colony[] public colonies;

    // colonies id per player address
    mapping(address => uint256[]) public coloniesPerPlayer;

    /**
     * Returns the colony struct for the given colony id
     * @param colonyId the colony id
     * @return colony struct after redirections
     */
    function getColony(uint256 colonyId)
        public
        view
        returns (Colony memory colony)
    {
        colony = colonies[colonyId - 1];
        while (colony.redirection != colonyId) {
            colonyId = colony.redirection;
            colony = colonies[colonyId - 1];
        }
    }

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
        (int128 x1, int128 y1) = CoordinatesLib.convertToCoordinates(
            colony.location
        );
        (int128 x2, int128 y2) = CoordinatesLib.convertToCoordinates(location);
        uint256 distanceLength = CoordinatesLib.distance(x1, y1, x2, y2);
        arrivalDate = distanceLength * 8 + block.timestamp;

        require(
            map[location].owner == 0 ||
                map[location].dateOfOwnership > arrivalDate
        );

        // we can have only 4 surrounding different colonies
        Colony[] memory detectedColonies = new Colony[](4);
        uint8 size = 0;

        for (int8 i = -1; i <= 1; i++)
            for (int8 j = -1; j <= 1 && !(i == j && i == 0); j++) {
                Plot memory plot = map[
                    CoordinatesLib.convertFromCoordinates(x2 + i, y2 + j)
                ];

                // Insert colonies to detectedColonies so it doesn't contain duplicate value
                bool found = false;
                Colony memory foundColony = getColony(plot.owner);
                for (uint8 k = 0; found == false && k < size; k++)
                    if (
                        detectedColonies[k].redirection ==
                        foundColony.redirection
                    ) found = true;
                if (!found) detectedColonies[size++] = foundColony;
            }

        // todo: find real colonyId (create it if needed?)
        map[location] = Plot(colonyId, arrivalDate, StructureType.SettlerCamp);
    }
}
