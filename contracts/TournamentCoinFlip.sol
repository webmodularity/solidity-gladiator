////SPDX-License-Identifier: Unlicense
//pragma solidity ^0.8.3;
//
//import "./Tournament.sol";
//
//contract TournamentCoinFlip is Tournament {
//
//function _fight(uint gladiatorId1, uint gladiatorId2) internal override returns(uint) {
//    uint chosenOne = _rollDice(1, 0);
//    if (chosenOne == 0) {
//        // Gladiator1 is winner
//        _handleWinner(gladiatorId1);
//        _handleLoser(gladiatorId2);
//        return gladiatorId1;
//    } else {
//        // Gladiator2 is winner
//        _handleWinner(gladiatorId2);
//        _handleLoser(gladiatorId1);
//        return gladiatorId2;
//    }
//}
//
//}