//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.3;

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./ITournament.sol";

contract Gladiator is ERC721URIStorage, Ownable {
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;
  Counters.Counter private gladiatorCount;
  mapping(uint => GladiatorStruct) internal gladiators;
  address[] public registeredTournamentAddresses;
  mapping(address => bool) internal registeredTournamentAddressMap;

  struct GladiatorStruct {
    string name;
    Attributes attributes;
    address registeredTournamentAddress;
  }

  struct Attributes {
    uint8 strength;
    uint8 vitality;
    uint8 dexterity;
    uint8 size;
    uint8 intelligence;
    uint8 luck;
  }

  constructor() ERC721("Gladiator Sim", "GLADSM") {}

  function registerTournamentAddress(address _address) external onlyOwner {
    require(!registeredTournamentAddressMap[_address], "This address is already registered");
    // Add _address to array + mapping for easy lookup
    registeredTournamentAddresses.push(_address);
    registeredTournamentAddressMap[_address] = true;
  }

  function removeTournamentAddress(address _address) external onlyOwner {
    require(registeredTournamentAddressMap[_address], "This address is NOT registered, unable to remove");
    // Remove address from array + mapping
    delete registeredTournamentAddressMap[_address];
    address[] memory newRegisteredTournamentAddresses;
    uint newCounter = 0;
    for (uint i = 0;i < registeredTournamentAddresses.length;i++) {
      if (registeredTournamentAddresses[i] != _address) {
        newRegisteredTournamentAddresses[newCounter] = registeredTournamentAddresses[i];
        newCounter++;
      }
    }
    registeredTournamentAddresses = newRegisteredTournamentAddresses;
  }

  function isValidTournamentAddress(address _address) external view returns(bool) {
    return registeredTournamentAddressMap[_address];
  }

  function mintNewGladiatorFromExternal(
    string memory name,
    uint8 strength,
    uint8 vitality,
    uint8 dexterity,
    uint8 size,
    uint8 intelligence,
    uint8 luck,
    string memory ipfsMetaUrl
  ) external onlyOwner {
    uint256 gladiatorId = _tokenIds.current();
    gladiators[gladiatorId] =
    GladiatorStruct(
      name,
        Attributes(
          strength,
            vitality,
            dexterity,
            size,
            intelligence,
            luck
        ),
        address(0)
    );
    _safeMint(msg.sender, gladiatorId);
    _setTokenURI(gladiatorId, ipfsMetaUrl);
    _tokenIds.increment();
    gladiatorCount.increment();
  }

  function registerGladiator(uint gladiatorId, address tournamentAddress) external {
    // isOwner
    require(ownerOf(gladiatorId) == msg.sender);
    // gladiator exists (isn't dead)
    require(gladiatorExists(gladiatorId), "Failed to find that gladiator");
    // not already registered for this tournament address
    require(gladiators[gladiatorId].registeredTournamentAddress != tournamentAddress, "Gladiator already registered for this tournament");
    // Check if gladiator is already registered to different tournament address
    if (gladiators[gladiatorId].registeredTournamentAddress != address(0)) {
      // Try and unregister from old tournament first
      ITournament oldTournament = ITournament(gladiators[gladiatorId].registeredTournamentAddress);
      oldTournament.unregisterGladiator(gladiatorId);
    }
    // Approve tournament contract address
    approve(tournamentAddress, gladiatorId);
    // Register Gladiator
    ITournament newTournament = ITournament(tournamentAddress);
    newTournament.registerGladiator(gladiatorId);
  }

  function getGladiatorCount() external view returns(uint) {
    return gladiatorCount.current();
  }

  function gladiatorExists(uint gladiatorId) public view returns(bool) {
    return _exists(gladiatorId);
  }

  function getGladiatorAttributes(uint gladiatorId) external view returns(uint, uint, uint, uint, uint, uint) {
    return (
    gladiators[gladiatorId].attributes.strength,
    gladiators[gladiatorId].attributes.vitality,
    gladiators[gladiatorId].attributes.dexterity,
    gladiators[gladiatorId].attributes.size,
    gladiators[gladiatorId].attributes.intelligence,
    gladiators[gladiatorId].attributes.luck
    );
  }

  function getGladiatorName(uint gladiatorId) external view returns(string memory) {
    return gladiators[gladiatorId].name;
  }

  function burnGladiator(uint gladiatorId) external {
    require(_isApprovedOrOwner(msg.sender, gladiatorId));
    require(_exists(gladiatorId));
    delete gladiators[gladiatorId];
    gladiatorCount.decrement();
    _burn(gladiatorId);
  }

}
