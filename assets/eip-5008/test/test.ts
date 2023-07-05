import { expect } from "chai";
import { ethers } from "hardhat";

describe("Test ERC5008 ",  function () {

    it("test nonce", async function () {
    let [alice, bob] = await ethers.getSigners();

    const ERC5008Demo = await ethers.getContractFactory("ERC5008Demo");

    let contract = await ERC5008Demo.deploy("ERC5008Demo","ERC5008Demo");

    let tokenId = 1;
    await contract.mint(alice.address, tokenId);

    expect(await contract.nonce(tokenId)).equals(1);

    await contract.transferFrom(alice.address, bob.address, tokenId);

    expect(await contract.nonce(tokenId)).equals(2);
   });
});
