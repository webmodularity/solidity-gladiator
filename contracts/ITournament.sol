//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.3;

interface ITournament {
    function changeGladiatorContractAddress(address _gladiatorContractAddress) external;

    function getRegisteredGladiatorCount() external view returns(uint);

    function openRegistration() external;

    function closeRegistration() external;

    function unregisterGladiator(uint gladiatorId) external;

    function registerGladiator(uint gladiatorId) external;

    function startTournament() external;
}