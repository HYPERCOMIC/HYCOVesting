const hre = require("hardhat");

async function main() {
    const ContractCode = await hre.ethers.getContractFactory("HYCOClaim");
    const contractCode = await ContractCode.deploy("0x77F76483399Dc6328456105B1db23e2Aca455bf9");

    await contractCode.deployed();

    console.log("HYCOClaim deployed to : ", contractCode.address);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
