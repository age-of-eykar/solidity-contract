// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

import "./CoordinatesLib.sol";

contract Eykar {
    constructor() public {}

    enum StructureType {
        House,
        Mansion
    }

    struct Plot {
        StructureType structure;
    }

    mapping(bytes32 => Plot) public map;

    string public message = "hello world";

    function getMessage() public view returns (string memory) {
        return message;
    }
}
