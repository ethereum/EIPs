const {ethers} = require("hardhat");

deployContracts = async () => {
    return await deployERC6785()
}

deployERC6785 = async () => {
    const utilityContractName = 'ERC6785'
    const UtilityNFT = await ethers.getContractFactory(utilityContractName);
    const royaltyDebtRegistry = await UtilityNFT.deploy('UNFT', 'UNFT');
    await royaltyDebtRegistry.deployed();

    return royaltyDebtRegistry;
}

module.exports = {
    deployContracts
}
