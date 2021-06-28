//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.3;

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IGladiator.sol";

contract Tournament is Ownable {
    IGladiator internal gladiatorContract;
    uint[] internal registeredGladiators;
    mapping(uint => bool) internal unregisteredGladiators;
    bool public registrationOpen;
    bool public hardcoreEnabled;

    constructor(address _gladiatorContractAddress) {
        gladiatorContract = IGladiator(_gladiatorContractAddress);
    }

    function changeGladiatorContractAddress(address _gladiatorContractAddress) external onlyOwner {
        gladiatorContract = IGladiator(_gladiatorContractAddress);
    }

    function getRegisteredGladiatorCount() external view returns(uint) {
        return registeredGladiators.length;
    }

    function openRegistration() public onlyOwner {
        registrationOpen = true;
    }

    function closeRegistration() public onlyOwner {
        registrationOpen = false;
    }

    function unregisterGladiator(uint gladiatorId) external {
        require(msg.sender == address(gladiatorContract), "Not the owner of this gladiator");
        unregisteredGladiators[gladiatorId] = true;
    }

    function registerGladiator(uint gladiatorId) external {
        require(msg.sender == address(gladiatorContract), "Not the owner of this gladiator");
        require(registrationOpen, "Registration is currently closed");
        registeredGladiators.push(gladiatorId);
    }

    function startTournament() external onlyOwner {
        require(registeredGladiators.length > 0, "No gladiators registered");
        uint nonce = 0;
        uint chosenOne = rollDice(registeredGladiators.length, nonce++);
        uint loser = chosenOne - 1;
        // Burn the loser :O
        gladiatorContract.burnGladiator(registeredGladiators[loser]);
        console.log(loser);
    }

    function rollDice(uint _modulus, uint _nonce) internal view returns(uint) {
        return uint(uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), block.difficulty, _nonce)))%_modulus) + 1;
    }
}
