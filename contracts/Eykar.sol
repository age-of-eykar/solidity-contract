// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

import "./CoordinatesLib.sol";

contract Eykar {
    address payable public owner;

    constructor() payable {
        owner = payable(msg.sender);
    }

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

    // map of non empty chunks for efficient queries
    mapping(bytes32 => bool) public chunks;

    // registered colonies
    Colony[] public colonies;

    // colonies id per player address
    mapping(address => uint256[]) public coloniesPerPlayer;

    /**
     * Places a Plot on the map
     * @param location of the plot
     * @param plot to place
     */
    function setPlot(bytes32 location, Plot memory plot) private {
        map[location] = plot;
        bytes32 chunkLocation = CoordinatesLib.getChunk(location);
        if (!chunks[chunkLocation]) chunks[chunkLocation] = true;
    }

    /**
     * Returns a specific Plot object
     * @param x coordinate on the x axis
     * @param y coordinate on the y axis
     * @return plot object at this location
     */
    function getPlot(int128 x, int128 y) public view returns (Plot memory) {
        return map[CoordinatesLib.convertFromCoordinates(x, y)];
    }

    /**
     * Returns an array of Plots found on a specific chunk
     * @param xChunk coordinate on the x axis of the chunk
     * @param yChunk coordinate on the y axis of the chunk
     * @return plots an array of plot object on this area
     * @return xArray array of point x
     * @return yArray array of point
     */
    function getPlots(int128 xChunk, int128 yChunk)
        public
        view
        returns (
            Plot[] memory plots,
            int128[] memory xArray,
            int128[] memory yArray
        )
    {
        uint256 i = 0;
        if (chunks[CoordinatesLib.convertFromCoordinates(xChunk, yChunk)]) {
            Plot[] memory tempOutput = new Plot[](64);
            int128[] memory tempxArray = new int128[](64);
            int128[] memory tempyArray = new int128[](64);

            for (int128 x = xChunk * 8; x < (xChunk + 1) * 8; x++)
                for (int128 y = yChunk * 8; y < (yChunk + 1) * 8; y++) {
                    Plot memory plot = getPlot(x, y);
                    if (plot.structure != StructureType.None) {
                        tempOutput[i] = plot;
                        tempxArray[i] = x;
                        tempyArray[i] = y;
                        i++;
                    }
                }
            plots = new Plot[](i);
            xArray = new int128[](i);
            yArray = new int128[](i);
            while (i > 0) {
                i--;
                plots[i] = tempOutput[i];
                xArray[i] = tempxArray[i];
                yArray[i] = tempyArray[i];
            }
        } else {
            plots = new Plot[](i);
            xArray = new int128[](i);
            yArray = new int128[](i);
        }
    }

    /**
     * Returns the next available plot location on the map and updates the lastRegistrationId
     * @param spacing between plots
     * @return location of the next available plot
     */
    function findNextLocationOnSpiral(
        uint128 currentRegistrationId,
        int128 spacing
    ) public view returns (bytes32 location, uint128 newRegistrationId) {
        do {
            uint128 sqrt = uint128(CoordinatesLib.sqrt(currentRegistrationId));
            if (sqrt > 0 && sqrt % 2 == 0) sqrt -= 1;

            uint128 position_id = currentRegistrationId - sqrt * sqrt;
            sqrt += 1;
            uint128 circle_id = sqrt / 2;
            uint128 side = position_id / sqrt;
            uint128 position = position_id % sqrt;

            location = CoordinatesLib.convertFromCoordinates(
                spacing *
                    ([int128(1), int128(1), int128(-1), int128(-1)][side] *
                        int128(circle_id) +
                        [int128(0), int128(-1), int128(0), int128(1)][side] *
                        int128(position)),
                spacing *
                    ([int128(1), int128(-1), int128(-1), int128(1)][side] *
                        int128(circle_id) +
                        [int128(-1), int128(0), int128(1), int128(0)][side] *
                        int128(position))
            );
            newRegistrationId = currentRegistrationId + 1;
        } while (
            map[location].owner != 0 &&
                map[location].dateOfOwnership <= block.timestamp
        );
    }

    // next input to the spiral function called on register
    uint128 registrationId;

    /**
     * Registers a player to the game (creates its first colony)
     * costs 10 ether
     * @param name of the colony
     */
    function register(string memory name) public payable {
        require(msg.value >= 10 ether);
        (
            bytes32 location,
            uint128 newRegistrationId
        ) = findNextLocationOnSpiral(registrationId, 64);

        registrationId = newRegistrationId;
        createColony(name, msg.sender, location, 4, 8, 16);
    }

    /**
     * Withdraws all the balance
     */
    function withdraw() public {
        (bool success, ) = owner.call{value: address(this).balance}("");
        require(success, "Failed to send Ether");
    }

    /**
     * Returns the player owned colonies
     * @param playerAddress the player address
     * @return coloniesOwned by the player
     */
    function getColonies(address playerAddress)
        public
        view
        returns (Colony[] memory coloniesOwned)
    {
        uint256[] memory result = coloniesPerPlayer[playerAddress];
        uint256 count = 0;
        for (uint256 i = 0; i < result.length; i++) {
            uint256 colonyId = result[i];
            Colony memory colony = colonies[colonyId - 1];
            if (colonyId == colony.redirection && colony.owner == playerAddress)
                count++;
        }
        coloniesOwned = new Colony[](count);
        count = 0;
        for (uint256 i = 0; i < result.length; i++) {
            uint256 colonyId = result[i];
            Colony memory colony = colonies[colonyId - 1];
            if (colonyId == colony.redirection && colony.owner == playerAddress)
                coloniesOwned[count++] = colony;
        }
    }

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
     * Merges an array of colony into one single colony
     * @param toMerge colonies to merge
     * @param amount size of toMerge
     * @return finalColony the merged colony
     */
    function mergeColonies(Colony[] memory toMerge, uint8 amount)
        private
        returns (Colony memory finalColony)
    {
        uint64 plotsAmount = toMerge[0].plotsAmount;
        uint256 people = toMerge[0].people;
        uint256 food = toMerge[0].food;
        uint256 materials = toMerge[0].materials;
        uint64 maxPlotsAmount = plotsAmount;
        finalColony = toMerge[0];
        for (uint8 i = 1; i < amount; i++) {
            Colony memory toCompare = toMerge[i];
            plotsAmount += toCompare.plotsAmount;
            people += toCompare.people;
            food += toCompare.food;
            materials += toCompare.materials;
            if (toCompare.plotsAmount > maxPlotsAmount) {
                maxPlotsAmount = toCompare.plotsAmount;
                finalColony = toCompare;
            }
        }

        finalColony.plotsAmount = plotsAmount;
        finalColony.people = people;
        finalColony.food = food;
        finalColony.materials = materials;

        for (uint8 i = 0; i < amount; i++) {
            Colony memory current = toMerge[i];
            uint256 arrayPosition = current.redirection;
            current.redirection = finalColony.redirection;
            colonies[arrayPosition - 1] = current;
        }
    }

    /**
     * Create and register a new Colony
     * @param name of the colony
     * @param colonyOwner (player) of the colony
     * @param location of the place of power
     * @param people amount of people
     * @param food amount of food
     * @param materials amount of materials
     * @return id of the created colony
     */
    function createColony(
        string memory name,
        address colonyOwner,
        bytes32 location,
        uint256 people,
        uint256 food,
        uint256 materials
    ) private returns (uint256 id) {
        id = colonies.length + 1;
        colonies.push(
            Colony({
                name: name,
                owner: colonyOwner,
                location: location,
                plotsAmount: 1,
                people: people,
                food: food,
                materials: materials,
                redirection: id
            })
        );
        setPlot(
            location,
            Plot({
                owner: id,
                dateOfOwnership: block.timestamp,
                structure: StructureType.SettlerCamp
            })
        );
        coloniesPerPlayer[colonyOwner].push(id);
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
        setPlot(
            location,
            Plot(
                mergeColonies(detectedColonies, detectedColoniesSize)
                    .redirection,
                arrivalDate,
                StructureType.SettlerCamp
            )
        );
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
        uint256 newColonyId = createColony({
            name: newColonyName,
            colonyOwner: msg.sender,
            location: location,
            people: 4,
            food: 4,
            materials: 4
        });
        setPlot(
            location,
            Plot(newColonyId, arrivalDate, StructureType.SettlerCamp)
        );
    }
}
