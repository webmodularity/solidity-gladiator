const { assert } = require("chai");
const fs = require('fs');
const path = require("path");

const gladiators = JSON.parse(fs.readFileSync(path.resolve(__dirname, "../data/JSON/starting_gladiators.json")));
let gladiator, tournament;
const gladiator0 = gladiators[0];
const gladiator1 = gladiators[1];

describe("Create Gladiator NFTs", function() {
  before(async () => {
    const Gladiator = await ethers.getContractFactory("Gladiator");
    gladiator = await Gladiator.deploy();
    await gladiator.deployed();
  });

  it("Should create 2 new gladiator NFTs", async function() {
    // Gladiator 0
    const createTx0 = await gladiator.mintNewGladiatorFromExternal(
        gladiator0.name,
        gladiator0.attributes.strength,
        gladiator0.attributes.vitality,
        gladiator0.attributes.dexterity,
        gladiator0.attributes.size,
        gladiator0.attributes.intelligence,
        gladiator0.attributes.luck,
        gladiator0.ipfsUrl
    );
    // wait until the transaction is mined
    await createTx0.wait();

    // Gladiator 1
    const createTx1 = await gladiator.mintNewGladiatorFromExternal(
        gladiator1.name,
        gladiator1.attributes.strength,
        gladiator1.attributes.vitality,
        gladiator1.attributes.dexterity,
        gladiator1.attributes.size,
        gladiator1.attributes.intelligence,
        gladiator1.attributes.luck,
        gladiator1.ipfsUrl
    );
    // wait until the transaction is mined
    await createTx1.wait();

    // Should be 2 gladiators
    const gladiatorCount = await gladiator.getGladiatorCount();
    assert(gladiatorCount == 2, `${gladiatorCount} does not equal 2!`);
  });

  it("Gladiator names should match what was passed in", async function() {
    const storedGladiatorName0 = await gladiator.getGladiatorName(0);
    const storedGladiatorName1 = await gladiator.getGladiatorName(1);
    assert(storedGladiatorName0 === gladiator0.name, `${storedGladiatorName0} doesn't equal ${gladiator0.name}`);
    assert(storedGladiatorName1 === gladiator1.name, `${storedGladiatorName1} doesn't equal ${gladiator1.name}`);
  });

  it("Gladiator attributes should be in range (3-18)", async function() {
    // Gladiator 0
    const [strength0, vitality0, dexterity0, size0, intelligence0, luck0] = await gladiator.getGladiatorAttributes(0);
    assert(strength0 >= 3 && strength0 <= 18, `Strength attribute for ${gladiator0.name} out of range!`);
    assert(vitality0 >= 3 && vitality0 <= 18, `Vitality attribute for ${gladiator0.name} out of range!`);
    assert(dexterity0 >= 3 && dexterity0 <= 18, `Dexterity attribute for ${gladiator0.name} out of range!`);
    assert(size0 >= 3 && size0 <= 18, `Size attribute for ${gladiator0.name} out of range!`);
    assert(intelligence0 >= 3 && intelligence0 <= 18, `Intelligence attribute for ${gladiator0.name} out of range!`);
    assert(luck0 >= 3 && luck0 <= 18, `Luck attribute for ${gladiator0.name} out of range!`);

    // Gladiator 1
    const [strength1, vitality1, dexterity1, size1, intelligence1, luck1] = await gladiator.getGladiatorAttributes(1);
    assert(strength1 >= 3 && strength1 <= 18, `Strength attribute for ${gladiator1.name} out of range!`);
    assert(vitality1 >= 3 && vitality1 <= 18, `Vitality attribute for ${gladiator1.name} out of range!`);
    assert(dexterity1 >= 3 && dexterity1 <= 18, `Dexterity attribute for ${gladiator1.name} out of range!`);
    assert(size1 >= 3 && size1 <= 18, `Size attribute for ${gladiator1.name} out of range!`);
    assert(intelligence1 >= 3 && intelligence1 <= 18, `Intelligence attribute for ${gladiator1.name} out of range!`);
    assert(luck1 >= 3 && luck1 <= 18, `Luck attribute for ${gladiator1.name} out of range!`);
  });

  // it("Gladiators can be burned", async function() {
  //   // Gladiator 0 RIP
  //   const burnTx = await gladiator.burnGladiator(0);
  //   await burnTx.wait();
  //   // Gladaitor 2 RIP
  //   const burnTx2 = await gladiator.burnGladiator(1);
  //   await burnTx2.wait();
  //   let gladiatorCountAfterBurn = await gladiator.getGladiatorCount();
  //   assert(gladiatorCountAfterBurn == 0, `${gladiatorCountAfterBurn} does not equal 0!`);
  // });
});

describe("Test Tournaments", function() {
  before(async () => {
    const Tournament = await ethers.getContractFactory("Tournament");
    tournament = await Tournament.deploy(gladiator.address);
    await tournament.deployed();
  });

  it("Open registration for this tournament", async function() {
    const openTx = await tournament.openRegistration();
    // wait until the transaction is mined
    await openTx.wait();
    assert(await tournament.registrationOpen(), "Registration not open");
  });

  it("Register 2 Gladiators at tournament", async function() {
    // Gladiator 0
    const registerTx0 = await gladiator.registerGladiator(0, tournament.address);
    // wait until the transaction is mined
    await registerTx0.wait();
    // Gladiator 0
    const registerTx1 = await gladiator.registerGladiator(1, tournament.address);
    // wait until the transaction is mined
    await registerTx1.wait();
    // Should have 2 gladiators registered
    const registeredGladiatorCount = await tournament.getRegisteredGladiatorCount();
    assert(registeredGladiatorCount == 2, `${registeredGladiatorCount} does not equal 2!`);
  });

  it("Start tournament with 2 registered gladiators", async function() {
    const startTx = await tournament.startTournament();
    // wait until the transaction is mined
    await startTx.wait();
    // Should have 1 gladiator registered now
    const afterBurnGladiatorCount = await gladiator.getGladiatorCount();
    assert(afterBurnGladiatorCount == 1, `${afterBurnGladiatorCount} does not equal 1!`);
  });
});
