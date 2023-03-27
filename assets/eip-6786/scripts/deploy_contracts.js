const {ethers} = require("hardhat");

deployContracts = async () => {
    let erc721Royalty = await deployERC721Royalties();
    let erc721 = await deployERC721();
    let royaltyDebtRegistry = await deployERC5666();

    return {erc721Royalty, erc721, royaltyDebtRegistry}
}

deployERC5666 = async () => {
    const royaltyContractName = 'ERC6786'
    const RoyaltyDebtRegistry = await ethers.getContractFactory(royaltyContractName);
    const royaltyDebtRegistry = await RoyaltyDebtRegistry.deploy();
    await royaltyDebtRegistry.deployed();

    return royaltyDebtRegistry;
}

deployERC721 = async () => {
    const NFTContractName = 'ERC721'
    const ERC721Name = 'NFT';
    const ERC721Symbol = 'NFT';
    const ERC721 = await ethers.getContractFactory(NFTContractName);
    const erc721 = await ERC721.deploy(ERC721Name, ERC721Symbol);
    await erc721.deployed();

    return erc721;
}

deployERC721Royalties = async () => {
    const royaltyNFTContractName = 'ERC721Royalty';
    const royaltyERC721Name = 'RoyaltyNFT';
    const royaltyERC721Symbol = 'RNFT';
    const ERC721Royalty = await ethers.getContractFactory(royaltyNFTContractName);
    const erc721Royalty = await ERC721Royalty.deploy(royaltyERC721Name, royaltyERC721Symbol);
    await erc721Royalty.deployed();

    return erc721Royalty;
}

module.exports = {
    deployContracts
}
