const hre = require("hardhat");
const fs = require("fs");

async function main() {
    const MultiSigWallet = await hre.ethers.getContractFactory("MultiSigWallet");
    const multisigwallet = await MultiSigWallet.deploy();
    await multisigwallet.deployed();
    console.log("multisigwallet deployed to:", multisigwallet.address);


}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });