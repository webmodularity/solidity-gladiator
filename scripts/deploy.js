async function main() {
    const Gladiator = await ethers.getContractFactory("Gladiator");
    const gladiator = await Gladiator.deploy();
    await gladiator.deployed();
    console.log("Gladiator contract deployed to:", gladiator.address);
    // Create a tournament with registrationOpen = true and hardcoreEnabled = false
    const Tournament = await ethers.getContractFactory("Tournament");
    const normalTournament = await Tournament.deploy(gladiator.address, true, false);
    await normalTournament.deployed();
    // Add normal tournament address to Gladiator contract
    let normalTournamentRegisterTx = await gladiator.registerTournamentAddress(normalTournament.address);
    await normalTournamentRegisterTx.wait();
    console.log("Normal Tournament registered with Gladiator contract and deployed to:", normalTournament.address);
    // Create a tournament with registrationOpen = true and hardcoreEnabled = false
    const hardcoreTournament = await Tournament.deploy(gladiator.address, true, true);
    await hardcoreTournament.deployed();
    // Add normal tournament address to Gladiator contract
    let hardcoreTournamentRegisterTx = await gladiator.registerTournamentAddress(hardcoreTournament.address);
    await hardcoreTournamentRegisterTx.wait();
    console.log("Hardcore Tournament registered with Gladiator contract and deployed to:", hardcoreTournament.address);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });