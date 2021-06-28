// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IGladiator is IERC721 {

    function registerTournamentAddress(address _address) external;

    function removeTournamentAddress(address _address) external;

    function isValidTournamentAddress(address _address) external view returns(bool);

    function mintNewGladiatorFromExternal(
        string memory name,
        uint8 strength,
        uint8 vitality,
        uint8 dexterity,
        uint8 size,
        uint8 intelligence,
        uint8 luck,
        string memory ipfsMetaUrl
    ) external;

    function getGladiatorCount() external view returns(uint);

    function gladiatorExists(uint gladiatorId) external view returns(bool);

    function getGladiatorAttributes(uint gladiatorId) external view returns(uint, uint, uint, uint, uint, uint);

    function getGladiatorName(uint gladiatorId) external view returns(string memory);

    function burnGladiator(uint gladiatorId) external;
}