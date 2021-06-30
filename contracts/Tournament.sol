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
    // Gladiators who have registered, we cannot rely on count as total of actual valid participants
    // NFT approval status may have changed since registration and those gladiators will be ignored
    uint[] internal registeredGladiators;
    uint[] internal activeGladiators;
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
        require(registeredGladiators.length < 2 ** 16, "Too many gladiators registered");
        registeredGladiators.push(gladiatorId);
    }

    function startTournament() external onlyOwner {
        require(registeredGladiators.length > 0, "No gladiators registered");
        bool initialRegistrationStatus = registrationOpen;
        // Turn off gladiator registration if it is currently on
        if (initialRegistrationStatus) {
            closeRegistration();
        }
        // Reject any gladiators that no longer exist or have revoked approve() since registering
        _buildActiveGladiatorList();
        // Randomize order of gladiators so matchups are difficult to predict and round byes are more fair
        _shuffleActiveGladiators();

        // Fight until 1 gladiator left standing
        uint[] memory _activeGladiators = activeGladiators;
        for (uint roundNumber = 0;roundNumber < _getNumberOfRounds(_activeGladiators.length);roundNumber++) {
            uint matchesThisRound = _activeGladiators.length % 2 == 0
            ? _activeGladiators.length / 2 : _activeGladiators.length / 2 + 1;
            uint[] memory winners = new uint[](matchesThisRound);
            uint fightCounter;
            for (uint i = 0;i < _activeGladiators.length;i+=2) {
                winners[fightCounter] = (i + 1) >= _activeGladiators.length
                ? registeredGladiators[i] : _fight(registeredGladiators[i], registeredGladiators[i+1]);
                fightCounter++;
            }
            _activeGladiators = winners;
        }
        // Finish up tournament
        emit TournamentWinner(_tournamentIds.current(), _activeGladiators[0]);
        delete registeredGladiators;
        _tournamentIds.increment();
        // Turn gladiator registration back on if it started that way
        if (initialRegistrationStatus) {
            openRegistration();
        }
    }

    function tournamentLoop(uint[] memory _gladiators) internal returns(uint[] memory) {
        uint fightCounter;
        uint[] memory winners;
        for (uint i = 0;i < _gladiators.length;i+=2) {
            if ((i + 1) >= _gladiators.length) {
                // Single fighter remains, add to winner without the _fight
                winners[fightCounter] = registeredGladiators[i];
            } else {
                winners[fightCounter] = _fight(registeredGladiators[i], registeredGladiators[i+1]);
            }
            fightCounter++;
        }
        return winners;
    }

    function _fight(uint gladiatorId1, uint gladiatorId2) internal returns(uint) {
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

    function _buildActiveGladiatorList() internal {
        for (uint i = 0;i < registeredGladiators.length;i++) {
            if (gladiatorContract.gladiatorExists(registeredGladiators[i]) &&
                gladiatorContract.getApproved(registeredGladiators[i]) == address(this)) {
                activeGladiators.push(registeredGladiators[i]);
            }
        }
    }

    function _getNumberOfRounds(uint _totalGladiators) internal view returns(uint) {
        // Calculating total rounds using binary logarithm
        // https://medium.com/coinmonks/math-in-solidity-part-5-exponent-and-logarithm-9aef8515136e
        uint count = _totalGladiators;
        uint _totalRounds;
        if (_totalGladiators >= 2**16) { _totalGladiators >>= 16; _totalRounds += 16; }
        if (_totalGladiators >= 2**8) { _totalGladiators >>= 8; _totalRounds += 8; }
        if (_totalGladiators >= 2**4) { _totalGladiators >>= 4; _totalRounds += 4; }
        if (_totalGladiators >= 2**2) { _totalGladiators >>= 2; _totalRounds += 2; }
        if (_totalGladiators >= 2**1) { /* _totalGladiators >>= 1; */ _totalRounds += 1; }
        // This is an attempt to do ceil(log2x) if necessary
        for (uint i = 1;i <= 16;i++) {
            if (count == 2**i) {
                return _totalRounds;
            }
        }
        return _totalRounds + 1;
    }

    function _shuffleActiveGladiators() internal {
        for (uint i = 0; i < activeGladiators.length; i++) {
            uint n = i + uint(keccak256(abi.encodePacked(block.timestamp))) % (activeGladiators.length - i);
            uint temp = activeGladiators[n];
            activeGladiators[n] = activeGladiators[i];
            activeGladiators[i] = temp;
        }
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