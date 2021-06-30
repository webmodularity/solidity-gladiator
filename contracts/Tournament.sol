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
    // Hardcap gladiators per tournament
    uint constant MAX_GLADIATORS_PER_TOURNAMENT = 2**8;
    IGladiator internal gladiatorContract;
    // Gladiators who have registered, we cannot rely on count as total of actual valid participants
    // NFT may no longer exist or approval status may have changed since registration and those gladiators will be ignored
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
        require(registeredGladiators.length <= MAX_GLADIATORS_PER_TOURNAMENT,
            "Too many gladiators registered, wait for next tournament");
        registeredGladiators.push(gladiatorId);
    }

    function startTournament() external onlyOwner {
        // Reject any gladiators that no longer exist or have revoked approve() since registering
        uint[] memory _activeGladiators = _getActiveGladiatorList();
        require(_activeGladiators.length > 1, "Not enough active gladiators registered");
        // Ensure that no new gladiators can register during tournament (TODO make sure this is necessary?)
        bool initialRegistrationStatus = registrationOpen;
        if (initialRegistrationStatus) {
            closeRegistration();
        }
        // Randomize order of gladiators so first round matchups are more difficult to predict
        _shuffleGladiators(_activeGladiators);
        // Single Elimination style tournament ending with 1 winner
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
            // Shuffling gladiator positions every round to avoid the last gladiator getting too many byes in certain situations
            _activeGladiators = _shuffleGladiators(winners);
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

    function _getAttributeSum(IGladiator.Attributes memory _attributes) internal pure returns(uint) {
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

    function _getActiveGladiatorCount() internal view returns(uint) {
        // TODO Has to be a more gas efficient way to get the length
        uint activeCounter;
        for (uint i = 0;i < registeredGladiators.length;i++) {
            if (_isGladiatorActive(registeredGladiators[i])) {
                activeCounter++;
            }
        }
        return activeCounter;
    }

    function _isGladiatorActive(uint gladiatorId) internal view returns(bool) {
        return (gladiatorContract.gladiatorExists(registeredGladiators[gladiatorId]) &&
        gladiatorContract.getApproved(registeredGladiators[gladiatorId]) == address(this));
    }

    function _getActiveGladiatorList() internal view returns(uint[] memory) {
        uint[] memory activeGladiators = new uint[](_getActiveGladiatorCount());
        uint activeCounter;
        for (uint i = 0;i < registeredGladiators.length;i++) {
            if (_isGladiatorActive(registeredGladiators[i])) {
                activeGladiators[activeCounter] = registeredGladiators[i];
                activeCounter++;
            }
        }
        return activeGladiators;
    }


    function _getNumberOfRounds(uint _totalGladiators) internal pure returns(uint) {
        // Calculating total rounds using binary logarithm
        // https://medium.com/coinmonks/math-in-solidity-part-5-exponent-and-logarithm-9aef8515136e
        uint count = _totalGladiators;
        uint _totalRounds;
        if (_totalGladiators >= 2**8) { _totalGladiators >>= 8; _totalRounds += 8; }
        if (_totalGladiators >= 2**4) { _totalGladiators >>= 4; _totalRounds += 4; }
        if (_totalGladiators >= 2**2) { _totalGladiators >>= 2; _totalRounds += 2; }
        if (_totalGladiators >= 2**1) { /* _totalGladiators >>= 1; */ _totalRounds += 1; }
        // This is an attempt to do ceil(log2x) if necessary
        for (uint i = 1;i <= 8;i++) {
            if (count == 2**i) {
                return _totalRounds;
            }
        }
        return _totalRounds + 1;
    }

    function _shuffleGladiators(uint[] memory activeGladiators) internal view returns(uint[] memory) {
        for (uint i = 0; i < activeGladiators.length; i++) {
            uint n = i + uint(keccak256(abi.encodePacked(block.timestamp))) % (activeGladiators.length - i);
            uint temp = activeGladiators[n];
            activeGladiators[n] = activeGladiators[i];
            activeGladiators[i] = temp;
        }
        return activeGladiators;
    }

    function _rollDice(uint256 _upperLimit, uint _nonce) internal view returns(uint) {
        uint bigRandomNumber = uint(keccak256(abi.encodePacked(blockhash(block.number - 1), block.difficulty, _nonce)));
        return UniformRandomNumber.uniform(bigRandomNumber, _upperLimit);
    }
}