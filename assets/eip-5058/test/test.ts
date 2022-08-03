import "@nomiclabs/hardhat-ethers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { ethers } from "hardhat";
import { EIP5058Mock } from "typechain-types";

describe("EIP5058 contract", function() {
  let owner: SignerWithAddress;
  let alice: SignerWithAddress;
  let EIP5058: EIP5058Mock;
  
  beforeEach(async () => {
    [owner, alice] = await ethers.getSigners();
    
    const EIP5058Factory = await ethers.getContractFactory("EIP5058Mock");
    
    EIP5058 = await EIP5058Factory.deploy("Mock", "M");
  });
  
  it("Deployment should assign the total supply of tokens to the owner", async function() {
    const ownerBalance = await EIP5058.balanceOf(owner.address);
    expect(await EIP5058.totalSupply()).to.equal(ownerBalance);
  });
  
  it("lockMint works", async function() {
    const NFTId = 0;
    const block = await ethers.provider.getBlockNumber();
    const blockBefore = await ethers.provider.getBlock(block);
    const timestamp = blockBefore.timestamp;
    await EIP5058.lockMint(alice.address, NFTId, timestamp + 2);
    
    expect(await EIP5058.isLocked(NFTId)).eq(true);
    expect(await EIP5058.lockerOf(NFTId)).eq(owner.address);
  });
  
  it("Can not transfer when token is locked", async function() {
    const NFTId = 0;
    const block = await ethers.provider.getBlockNumber();
    const blockBefore = await ethers.provider.getBlock(block);
    const timestamp = blockBefore.timestamp;
    await EIP5058.lockMint(owner.address, NFTId, timestamp + 3);
    
    // can not transfer when token is locked
    await expect(EIP5058.transferFrom(owner.address, alice.address, NFTId)).to.be.revertedWith(
      "EIP5058: token transfer while locked",
    );
    
    // can transfer when token is unlocked
    await ethers.provider.send("evm_mine", []);
    await EIP5058.transferFrom(owner.address, alice.address, NFTId);
    expect(await EIP5058.ownerOf(NFTId)).eq(alice.address);
  });
  
  it("isLocked works", async function() {
    const NFTId = 0;
    const block = await ethers.provider.getBlockNumber();
    const blockBefore = await ethers.provider.getBlock(block);
    const timestamp = blockBefore.timestamp;
    await EIP5058.lockMint(owner.address, NFTId, timestamp + 2);
    
    // isLocked works
    expect(await EIP5058.isLocked(NFTId)).eq(true);
    await ethers.provider.send("evm_mine", []);
    expect(await EIP5058.isLocked(NFTId)).eq(false);
  });
  
  it("lock works", async function() {
    const NFTId = 0;
    let block = await ethers.provider.getBlockNumber();
    const blockBefore = await ethers.provider.getBlock(block);
    const timestamp = blockBefore.timestamp;
    await EIP5058.lockMint(owner.address, NFTId, timestamp + 3);
    
    await expect(EIP5058.lock(NFTId, timestamp + 5)).to.be.revertedWith(
      "EIP5058: token is locked",
    );
    
    await ethers.provider.send("evm_mine", []);
    await EIP5058.lock(NFTId, timestamp + 5);
  });
  
  it("unlock works with lockMint", async function() {
    const NFTId = 0;
    const block = await ethers.provider.getBlockNumber();
    const blockBefore = await ethers.provider.getBlock(block);
    const timestamp = blockBefore.timestamp;
    await EIP5058.lockMint(owner.address, NFTId, timestamp + 3);
    
    // unlock works
    expect(await EIP5058.isLocked(NFTId)).eq(true);
    expect(await EIP5058.lockerOf(NFTId)).eq(owner.address);
    await EIP5058.unlock(NFTId);
    expect(await EIP5058.isLocked(NFTId)).eq(false);
  });
  
  it("unlock works", async function() {
    const NFTId = 0;
    
    await EIP5058.mint(owner.address, NFTId);
    
    await expect(EIP5058.unlock(NFTId)).to.be.revertedWith(
      "EIP5058: locker query for non-locked token",
    );
    const block = await ethers.provider.getBlockNumber();
    const blockBefore = await ethers.provider.getBlock(block);
    const timestamp = blockBefore.timestamp;
    await EIP5058.lock(NFTId, timestamp + 3);
    expect(await EIP5058.isLocked(NFTId)).eq(true);
    await EIP5058.unlock(NFTId);
    expect(await EIP5058.isLocked(NFTId)).eq(false);
  });
  
  it("lockApprove works", async function() {
    const NFTId = 0;
    await EIP5058.mint(alice.address, NFTId);
    
    let block = await ethers.provider.getBlockNumber();
    const blockBefore = await ethers.provider.getBlock(block);
    const timestamp = blockBefore.timestamp;
    await expect(EIP5058.lock(NFTId, timestamp + 2)).to.be.revertedWith(
      "EIP5058: lock caller is not owner nor approved",
    );
    
    await EIP5058.connect(alice).lockApprove(owner.address, NFTId);
    expect(await EIP5058.getLockApproved(NFTId)).eq(owner.address);
    
    await expect(EIP5058.lock(NFTId, timestamp + 4)).to.be.revertedWith(
      "EIP5058: lock from incorrect owner",
    );
    await EIP5058.lock(NFTId, timestamp + 6);
    expect(await EIP5058.isLocked(NFTId)).eq(true);
    
    await expect(EIP5058.lockApprove(alice.address, NFTId)).to.be.revertedWith(
      "EIP5058: token is locked",
    );
  });
  
  it("setLockApproveForAll works", async function() {
    const NFTId = 0;
    
    await EIP5058.mint(alice.address, NFTId);
    const block = await ethers.provider.getBlockNumber();
    const blockBefore = await ethers.provider.getBlock(block);
    const timestamp = blockBefore.timestamp;
    await expect(EIP5058.lock(NFTId, timestamp + 2)).to.be.revertedWith(
      "EIP5058: lock caller is not owner nor approved",
    );
    
    await EIP5058.connect(alice).setLockApprovalForAll(owner.address, true);
    expect(await EIP5058.isLockApprovedForAll(alice.address, owner.address)).eq(true);
    
    await EIP5058.lock(NFTId, timestamp + 6);
    
    await EIP5058.connect(alice).setLockApprovalForAll(owner.address, false);
    expect(await EIP5058.isLockApprovedForAll(alice.address, owner.address)).eq(false);
  });
});
