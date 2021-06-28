async function main() {
    const Gladiator = await ethers.getContractFactory("Gladiator");
    const gladiator = await Gladiator.deploy();
    await gladiator.deployed();

    console.log("Gladiator contract deployed to:", gladiator.address);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });