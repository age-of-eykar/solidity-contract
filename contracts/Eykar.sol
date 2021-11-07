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

    function createColony(
        string memory name,
        address owner,
        bytes32 location,
        uint256 people,
        uint256 food,
        uint256 materials
    ) public returns (uint256 id) {
        id = colonies.length + 1;
        colonies.push(
            Colony({
                name: name,
                owner: owner,
                location: location,
                plotsAmount: 0,
                people: people,
                food: food,
                materials: materials,
                redirection: id
            })
        );
    }

    /**
     * Common code between conquer with and without existing colony
     * @param colonyId the source colony id
     * @param location serialized plot location
     * @return detectedColonies array of detected colonies
     * @return detectedColoniesSize amount of detected colonies
     * @return arrivalDate date of arrival
     */
    function conquer(uint256 colonyId, bytes32 location)
        private
        view
        returns (
            Colony[] memory detectedColonies,
            uint8 detectedColoniesSize,
            uint256 arrivalDate
        )
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
        detectedColonies = new Colony[](4);
        detectedColoniesSize = 0;

        for (int8 i = -1; i <= 1; i++)
            for (int8 j = -1; j <= 1 && !(i == j && i == 0); j++) {
                Plot memory plot = map[
                    CoordinatesLib.convertFromCoordinates(x2 + i, y2 + j)
                ];

                // Insert colonies to detectedColonies so it doesn't contain duplicate value
                bool found = false;
                Colony memory foundColony = getColony(plot.owner);
                if (foundColony.owner != msg.sender) continue;
                for (uint8 k = 0; !found && k < detectedColoniesSize; k++)
                    if (
                        detectedColonies[k].redirection ==
                        foundColony.redirection
                    ) found = true;
                if (!found)
                    detectedColonies[detectedColoniesSize++] = foundColony;
            }
    }

    /**
     * Allows a player to conquer a new plot next to an existing colony
     * @param colonyId the source colony id
     * @param location serialized plot location
     * @return arrivalDate
     */
    function conquerWithExistingColony(uint256 colonyId, bytes32 location)
        public
        returns (uint256 arrivalDate)
    {
        Colony[] memory detectedColonies;
        uint8 detectedColoniesSize;
        (detectedColonies, detectedColoniesSize, arrivalDate) = conquer(
            colonyId,
            location
        );
        require(detectedColoniesSize > 0);

        /*
        map[location] = Plot(
            mergeColonies(detectedColonies, size).redirection,
            arrivalDate,
            StructureType.SettlerCamp
        );
        */
    }

    /**
     * Allows a player to conquer a new plot that is not next to an existing owned colony
     * @param colonyId the source colony id
     * @param location serialized plot location
     * @return arrivalDate
     */
    function conquerWithoutExistingColony(
        uint256 colonyId,
        bytes32 location,
        string memory newColonyName
    ) public returns (uint256 arrivalDate) {
        Colony[] memory detectedColonies;
        uint8 detectedColoniesSize;
        (detectedColonies, detectedColoniesSize, arrivalDate) = conquer(
            colonyId,
            location
        );
        require(detectedColoniesSize == 0);

        /*
        map[location] = Plot(
            mergeColonies(detectedColonies, size).redirection,
            arrivalDate,
            StructureType.SettlerCamp
        );
        */
    }
}
