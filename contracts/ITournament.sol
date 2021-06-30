//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.3;

interface ITournament {
    function getRegisteredGladiatorCount() external view returns(uint16);

    function openRegistration() external;

    function closeRegistration() external;

    function getNextTournamentId() external view returns(uint);

    function registerGladiator(uint gladiatorId) external;

    function startTournament() external;
}