//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.3;

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./UniformRandomNumber.sol";
import "./IGladiator.sol";

contract Tournament is Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tournamentIds;
    IGladiator internal gladiatorContract;
    // Gladiators who have registered, cannot rely on count as actual valid participants
    // NFT approval status may have changed since registration and those gladiators will be ignored
    uint[] internal registeredGladiators;
    // Allow gladiators to register for next tournament
    bool public registrationOpen;
    // Enable NFT burn on loss
    bool public hardcoreEnabled;

    // Events
    event TournamentWinner(uint tournamentId, uint gladiatorId);

    constructor(address _gladiatorContractAddress, bool _registrationOpen, bool _hardcoreEnabled) {
        gladiatorContract = IGladiator(_gladiatorContractAddress);
        registrationOpen = _registrationOpen;
        hardcoreEnabled = _hardcoreEnabled;
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

    function getNextTournamentId() external view returns(uint) {
        return _tournamentIds.current();
    }

    function registerGladiator(uint gladiatorId) external {
        require(msg.sender == address(gladiatorContract), "Not the owner of this gladiator");
        require(registrationOpen, "Registration is currently closed");
        registeredGladiators.push(gladiatorId);
    }

    function startTournament() external onlyOwner {
        require(registeredGladiators.length > 0, "No gladiators registered");
        bool initialRegistrationStatus = registrationOpen;
        // Turn off gladiator registration if it is currently on
        if (initialRegistrationStatus) {
            closeRegistration();
        }
        // Randomize order of gladiators so matchups cannot be predicted
        // ...Or at least make it more difficult to predict opponent based on registration order
        _shuffleGladiators();
        // Fight until 1 gladiator left standing
        uint winningGladiatorId = _fight(registeredGladiators[0], registeredGladiators[1]);
        // Finish up tournament
        emit TournamentWinner(_tournamentIds.current(), winningGladiatorId);
        delete registeredGladiators;
        _tournamentIds.increment();
        // Turn gladiator registration back on if it started that way
        if (initialRegistrationStatus) {
            openRegistration();
        }
    }

    function _shuffleGladiators() internal {
        for (uint i = 0; i < registeredGladiators.length; i++) {
            uint n = i + uint(keccak256(abi.encodePacked(block.timestamp))) % (registeredGladiators.length - i);
            uint temp = registeredGladiators[n];
            registeredGladiators[n] = registeredGladiators[i];
            registeredGladiators[i] = temp;
        }
    }

    function _fight(uint gladiatorId1, uint gladiatorId2) internal virtual returns(uint) {
        IGladiator.Attributes memory gladiator1Attributes = gladiatorContract.getGladiatorAttributes(gladiatorId1);
        IGladiator.Attributes memory gladiator2Attributes = gladiatorContract.getGladiatorAttributes(gladiatorId2);
        // Fighting
        uint diceNonce = 0;
        // Simply sum attributes of gladiator and use that as _upperLimit of _rollDice
        // The gladiator with the highest _rollDice result wins
        uint gladiator1Sum = _getAttributeSum(gladiator1Attributes);
        uint gladiator2Sum = _getAttributeSum(gladiator2Attributes);
        // Determine score using a single dice roll weighted by sum of Attributes
        uint gladiator1Score = _rollDice(gladiator1Sum, diceNonce++);
        uint gladiator2Score = _rollDice(gladiator2Sum, diceNonce++);
        if (gladiator1Score >= gladiator2Score) {
            // Going 1st has some bias in this battle mode :O
            // Gladiator1 is winner
            _handleWinner(gladiatorId1);
            _handleLoser(gladiatorId2);
            return gladiatorId1;
        } else {
            // Gladiator2 is winner
            _handleWinner(gladiatorId2);
            _handleLoser(gladiatorId1);
            return gladiatorId2;
        }
    }

    function _getAttributeSum(IGladiator.Attributes memory _attributes) internal returns(uint) {
        return uint(_attributes.strength +
        _attributes.vitality +
        _attributes.dexterity +
        _attributes.size +
        _attributes.intelligence +
            _attributes.luck);
    }

    function _handleWinner(uint gladiatorId) internal {
        // TODO implement tournament stats
        // Increase win counter for this tournament
    }

    function _handleLoser(uint gladiatorId) internal {
        // TODO implement tournament stats
        // Decrease win counter for this tournament
        if (hardcoreEnabled) {
            // Burn the loser :O
            gladiatorContract.burnGladiator(gladiatorId);
        }
    }

    function _rollDice(uint256 _upperLimit, uint _nonce) internal view returns(uint) {
        uint bigRandomNumber = uint(keccak256(abi.encodePacked(blockhash(block.number - 1), block.difficulty, _nonce)));
        return UniformRandomNumber.uniform(bigRandomNumber, _upperLimit);
    }
}
