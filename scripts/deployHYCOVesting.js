const hre = require("hardhat");

async function main() {
    const ContractCode = await hre.ethers.getContractFactory("HYCOVesting");
    const contractCode = await ContractCode.deploy("0x77F76483399Dc6328456105B1db23e2Aca455bf9", "0x4720f1796314FBE7d242Ae5848D6a6689CC843dc", "0x487F823e2F71f8042B463006D1812CBe3b17eCDb");

    await contractCode.deployed();

    console.log("HYCOVesting deployed to : ", contractCode.address);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
