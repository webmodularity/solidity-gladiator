const gladiatorContractAddr = "0xe21744104caD0198f44248ecc62Be3E940F26170";

async function main() {
    const gladiator = await ethers.getContractAt("Gladiator", gladiatorContractAddr);

    // The Golden Knight
    const gladiatorName0 = "The Golden Knight";
    const ipfsMetaUrl0 = "https://ipfs.io/ipfs/QmYEg6dUsA1nSiY7C1C73Kf5g7pqkzezz1pzENJWqAMTe2";
    const createTx0 = await gladiator.mintNewGladiatorFromExternal(gladiatorName0, 18, 18, 18, 18, 18, 18, ipfsMetaUrl0);
    // wait until the transaction is mined
    await createTx0.wait();
    console.log(gladiatorName0 + ' has been generated.');

    // The Executioner
    const gladiatorName1 = "The Executioner";
    const ipfsMetaUrl1 = "https://ipfs.io/ipfs/QmZY3pKHWam5wqqQLePHrwiqag7osGeQ4eif5eVpHGp2ca";
    const createTx1 = await gladiator.mintNewGladiatorFromExternal(gladiatorName1, 18, 14, 11, 18, 7, 3, ipfsMetaUrl1);
    // wait until the transaction is mined
    await createTx1.wait();
    console.log(gladiatorName1 + ' has been generated.');
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });