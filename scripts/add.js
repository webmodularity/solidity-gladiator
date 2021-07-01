const fs = require('fs');
const path = require("path");
const contractAddresses = require(path.resolve(__dirname, "../src/contract_addresses.js"));

async function main() {
    const gladiator = await ethers.getContractAt("Gladiator", contractAddresses.gladiator);
    const gladiators = JSON.parse(fs.readFileSync(path.resolve(__dirname, "../src/starting_gladiators.json")));

    let gladiatorsAdded = 0;
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
        console.log(`${gladiators[i].name} generated...`);
        gladiatorsAdded++;
    }
    console.log(`Added ${gladiatorsAdded} new gladiators.`);
    const gladiatorCount = await gladiator.getGladiatorCount();
    console.log(`There are now ${gladiatorCount.toString()} gladiators total.`);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });