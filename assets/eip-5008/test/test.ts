import { expect } from "chai";
import { ethers } from "hardhat";

describe("Test ERC5008 ",  function () {

    it("test nonce", async function () {
    let [alice, bob] = await ethers.getSigners();

    const ERC5008Demo = await ethers.getContractFactory("ERC5008Demo");

    let contract = await ERC5008Demo.deploy("ERC5008Demo","ERC5008Demo");

    let tokenId = 1;
    await expect(contract.mint(alice.address, tokenId)).to.emit(contract, "NonceChanged").withArgs(tokenId, 1);

    expect(await contract.nonce(tokenId)).equals(1);


    await expect(contract.transferFrom(alice.address, bob.address, tokenId)).to.emit(contract, "NonceChanged").withArgs(tokenId, 2);


    expect(await contract.nonce(tokenId)).equals(2);

    console.log("IERC5008 InterfaceId:", await contract.getInterfaceId())
    let isSupport = await contract.supportsInterface('0xce03fdab');
    expect(isSupport).equals(true , "supportsInterface error");

   });
});
