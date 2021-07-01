const fs = require('fs');
const path = require("path");
const contractAddresses = require(path.resolve(__dirname, "../src/contract_addresses.js"));

async function main() {
    const gladiator = await ethers.getContractAt("Gladiator", contractAddresses.gladiator);
    const tournament = await ethers.getContractAt("Tournament", contractAddresses.normal);
    const gladiators = JSON.parse(fs.readFileSync(path.resolve(__dirname, "../src/starting_gladiators.json")));

    let gladiatorsRegistered = 0;
    for (let i = 0;i < gladiators.length;i++) {
        let registerTx = await gladiator.registerGladiator(i, tournament.address);
        console.log(`${gladiators[i].name} registered...`);
        // Wait for Tx to mine
        await registerTx.wait();
        gladiatorsRegistered++;
    }
    console.log(`Registered ${gladiatorsRegistered} new gladiators.`);
    const registeredCount = await tournament.getRegisteredGladiatorCount();
    const tournamentId = await tournament.getNextTournamentId();
    console.log(`There are now ${registeredCount.toString()} gladiators registered for tournament ID: (${tournamentId}).`);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });