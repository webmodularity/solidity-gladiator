const { assert } = require("chai");
const fs = require('fs');
const path = require("path");

const gladiators = JSON.parse(fs.readFileSync(path.resolve(__dirname, "../src/starting_gladiators.json")));
let gladiator, normalTournament, hardcoreTournament;

describe("Create Gladiator NFTs", function() {
  before(async () => {
    const Gladiator = await ethers.getContractFactory("Gladiator");
    gladiator = await Gladiator.deploy();
    await gladiator.deployed();
  });

  it(`Should create (${gladiators.length}) new gladiator NFTs`, async function() {
    for (let i = 0;i < gladiators.length;i++) {
      let createTx = await gladiator.mintNewGladiatorFromExternal(
          gladiators[i].name,
          gladiators[i].attributes.strength,
          gladiators[i].attributes.vitality,
          gladiators[i].attributes.dexterity,
          gladiators[i].attributes.size,
          gladiators[i].attributes.intelligence,
          gladiators[i].attributes.luck,
          gladiators[i].ipfsUrl
      );
      await createTx.wait();
    }
    const gladiatorCount = await gladiator.getGladiatorCount();
    assert(gladiatorCount == gladiators.length, `Expected ${gladiators.length} gladiators but only found ${gladiatorCount} `);
  });

  it("Gladiator names should match what was passed in", async function() {
    for (let i = 0;i < gladiators.length;i++) {
      let storedGladiatorName = await gladiator.getGladiatorName(i);
      assert(storedGladiatorName === gladiators[i].name,
          `Name mismatch in gladiator contract storage, expected ${gladiators[i].name}  but got ${storedGladiatorName}`);
    }
  });

  it("Gladiator attributes should be in range (3-18)", async function() {
    for (let i = 0;i < gladiators.length;i++) {
      let [strength, vitality, dexterity, size, intelligence, luck] = await gladiator.getGladiatorAttributes(i);
      assert(strength >= 3 && strength <= 18, `Strength attribute of:${strength} for ${gladiators[i].name} out of range!`);
      assert(vitality >= 3 && vitality <= 18, `Vitality attribute of:${vitality} for ${gladiators[i].name} out of range!`);
      assert(dexterity >= 3 && dexterity <= 18, `Dexterity attribute of:${dexterity} for ${gladiators[i].name} out of range!`);
      assert(size >= 3 && size <= 18, `Size attribute of:${size} for ${gladiators[i].name} out of range!`);
      assert(intelligence >= 3 && intelligence <= 18, `Intelligence attribute of ${intelligence} for ${gladiators[i].name} out of range!`);
      assert(luck >= 3 && luck <= 18, `Luck attribute of ${luck} for ${gladiators[i].name} out of range!`);
    }
  });
});

describe("Test Normal Tournament Mode", function() {
  before(async () => {
    // Create a tournament with registrationOpen = true and hardcoreEnabled = false
    const Tournament = await ethers.getContractFactory("Tournament");
    normalTournament = await Tournament.deploy(gladiator.address, true, false);
    await normalTournament.deployed();
  });

  it("Check to see if registration is open", async function() {
    assert(await normalTournament.registrationOpen(), "Registration not open");
  });

  it(`Register all (${gladiators.length}) gladiators at normal tournament`, async function() {
    for (let i = 0;i < gladiators.length;i++) {
      let registerTx = await gladiator.registerGladiator(i, normalTournament.address);
      // wait until the transaction is mined
      await registerTx.wait();
    }
    const registeredGladiatorCount = await normalTournament.getRegisteredGladiatorCount();
    assert(registeredGladiatorCount == gladiators.length,
        `Failed to register all gladiators for normal tournament, expected (${gladiators.length}) but got ${registeredGladiatorCount}`);
  });

  it("Start normal tournament and listen for TournamentWinner Event", async function() {
    const startTx = await normalTournament.startTournament();
    // wait until the transaction is mined
    const startReceipt = await startTx.wait();
    const winnerEvent = startReceipt.events.find(x => x.event === "TournamentWinner");
    // tournamentId should be 0 for first tournament
    assert(winnerEvent.args.tournamentId == 0, `Expecting first tournament ID of 0, but found ${winnerEvent.args.tournamentId}`);
    // Winning gladiator ID should be between 0 and (gladiators.length -1)
    assert(winnerEvent.args.gladiatorId >= 0 && winnerEvent.args.gladiatorId <= (gladiators.length -1),
        `Unexpected gladiatorId was the winner (${winnerEvent.args.gladiatorId})`);
  });

  it("Normal mode tournament should NOT burn any gladiators", async function() {
    const noBurnGladiatorCount = await gladiator.getGladiatorCount();
    assert(noBurnGladiatorCount == gladiators.length, `Normal tournaments should NOT burn on loss, expected (${gladiators.length}) but got ${noBurnGladiatorCount}`);
  });

  it("Make sure registration is still open (gets disabled during tournament)", async function() {
    assert(await normalTournament.registrationOpen(), "Registration not open");
  });

  it("Expect _tournamentIds to increment after tournament is finished", async function() {
    const nextTournamentId = await normalTournament.getNextTournamentId();
    assert(nextTournamentId == 1, "Tournament counter did not increase as expected");
  });
});

describe("Test Hardcore Tournament Mode", function() {
  before(async () => {
    // Create a tournament with registrationOpen = true and hardcoreEnabled = false
    const Tournament = await ethers.getContractFactory("Tournament");
    hardcoreTournament = await Tournament.deploy(gladiator.address, true, true);
    await hardcoreTournament.deployed();
  });

  it(`Register all (${gladiators.length}) gladiators at hardcore tournament`, async function() {
    for (let i = 0;i < gladiators.length;i++) {
      let registerTx = await gladiator.registerGladiator(i, hardcoreTournament.address);
      // wait until the transaction is mined
      await registerTx.wait();
    }
    const registeredGladiatorCount = await hardcoreTournament.getRegisteredGladiatorCount();
    assert(registeredGladiatorCount == gladiators.length,
        `Failed to register all gladiators for hardcore tournament, expected (${gladiators.length}) but got ${registeredGladiatorCount}`);
  });

  it("Start hardcore tournament and listen for TournamentWinner Event", async function() {
    const startTx = await hardcoreTournament.startTournament();
    // wait until the transaction is mined
    const startReceipt = await startTx.wait();
    const winnerEvent = startReceipt.events.find(x => x.event === "TournamentWinner");
    // tournamentId should be 0 for first tournament
    assert(winnerEvent.args.tournamentId == 0, `Expecting first tournament ID of 0, but found ${winnerEvent.args.tournamentId}`);
    // Winning gladiator ID should be between 0 and (gladiators.length -1)
    assert(winnerEvent.args.gladiatorId >= 0 && winnerEvent.args.gladiatorId <= (gladiators.length -1),
        `Unexpected gladiatorId was the winner (${winnerEvent.args.gladiatorId})`);
  });

  it("Hardcore mode tournament should burn the losing gladiators", async function() {
    // Should only have 1 gladiator after burn
    const afterBurnGladiatorCount = await gladiator.getGladiatorCount();
    assert(afterBurnGladiatorCount == 1, `Should have burned all gladiators except for the 1 winner but are still ${afterBurnGladiatorCount}`);
  });
});