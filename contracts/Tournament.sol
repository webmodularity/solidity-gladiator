//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.3;

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./UniformRandomNumber.sol";
import "./IGladiator.sol";

contract Tournament is Ownable {
    IGladiator internal gladiatorContract;
    uint[] internal registeredGladiators;
    mapping(uint => bool) internal unregisteredGladiators;
    bool public registrationOpen;
    bool public hardcoreEnabled;

    constructor(address _gladiatorContractAddress, bool _hardcoreEnabled) {
        gladiatorContract = IGladiator(_gladiatorContractAddress);
        hardcoreEnabled = _hardcoreEnabled;
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

    event Winner(uint gladiatorId);

    function startTournament() external onlyOwner {
        require(registeredGladiators.length > 0, "No gladiators registered");
        _shuffleGladiators();
        _fight(registeredGladiators[0], registeredGladiators[1]);
//        uint[] storage _gladiators = registeredGladiators;
//        while (_gladiators.length > 0) {
//            uint winner;
//            if (_gladiators.length >= 2) {
//                uint gladiator1 = _gladiators.pop();
//                uint gladiator2 = _gladiators.pop();
//                winner = _fight(gladiator1, gladiator2);
//            } else {
//                uint gladiator1 = _gladiators.pop();
//                winner = gladiator1;
//            }
//            emit Winner(winner);
//        }
        delete registeredGladiators;
    }

    function _shuffleGladiators() internal {
        for (uint i = 0; i < registeredGladiators.length; i++) {
            uint n = i + uint(keccak256(abi.encodePacked(block.timestamp))) % (registeredGladiators.length - i);
            uint temp = registeredGladiators[n];
            registeredGladiators[n] = registeredGladiators[i];
            registeredGladiators[i] = temp;
        }
    }

    function _fight(uint gladiatorId1, uint gladiatorId2) internal returns(uint) {
        IGladiator.Attributes memory gladiator1Attributes = gladiatorContract.getGladiatorAttributes(gladiatorId1);
        IGladiator.Attributes memory gladiator2Attributes = gladiatorContract.getGladiatorAttributes(gladiatorId2);
        // Fighting
        uint nonce = 0;
        uint chosenOne = _rollDice(1, nonce++);
        if (chosenOne == 0) {
            // Gladiator1 is winner
            if (hardcoreEnabled) {
                // Burn the loser :O
                gladiatorContract.burnGladiator(gladiatorId2);
            }
            return gladiatorId1;
        } else {
            // Gladiator2 is winner
            if (hardcoreEnabled) {
                // Burn the loser :O
                gladiatorContract.burnGladiator(gladiatorId1);
            }
            return gladiatorId2;
        }
    }

    function _rollDice(uint256 _upperLimit, uint _nonce) internal view returns(uint) {
        uint bigRandomNumber = uint(keccak256(abi.encodePacked(blockhash(block.number - 1), block.difficulty, _nonce)));
        return UniformRandomNumber.uniform(bigRandomNumber, _upperLimit);
    }
}
