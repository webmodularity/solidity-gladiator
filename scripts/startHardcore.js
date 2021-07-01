const fs = require('fs');
const path = require("path");
const contractAddresses = require(path.resolve(__dirname, "../src/contract_addresses.js"));

async function main() {
    const gladiator = await ethers.getContractAt("Gladiator", contractAddresses.gladiator);
    const tournament = await ethers.getContractAt("Tournament", contractAddresses.hardcore);

    const startTx = await tournament.startTournament();
    // wait until the transaction is mined
    const startReceipt = await startTx.wait();
    const winnerEvent = startReceipt.events.find(x => x.event === "TournamentWinner");
    const winnerName = await gladiator.getGladiatorName(winnerEvent.args.gladiatorId);
    console.log(`The winner of tournament ID: (${winnerEvent.args.tournamentId}) was ${winnerName} ID: (${winnerEvent.args.gladiatorId.toString()})`);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });