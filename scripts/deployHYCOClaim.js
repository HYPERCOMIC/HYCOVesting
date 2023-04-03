const hre = require("hardhat");

async function main() {
    const ContractCode = await hre.ethers.getContractFactory("HYCOClaim");
    const contractCode = await ContractCode.deploy("0x35973aa36974eaEB162bddFB90B1581948c140C3");

    await contractCode.deployed();

    console.log("HYCOClaim deployed to : ", contractCode.address);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
