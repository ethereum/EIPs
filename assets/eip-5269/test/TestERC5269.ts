// SPDX-License-Identifier: CC0-1.0
// Author: Zainan Victor Zhou <ercref@zzn.im>
// DRAFTv1
// Source https://github.com/ercref/ercref-contracts/tree/main/ERCs/eip-5269
// Deployment https://goerli.etherscan.io/address/0x33F735852619E3f99E1AF069cCf3b9232b2806bE#code

import { loadFixture, mine } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { BigNumber, ContractReceipt, Wallet } from "ethers";
import { ethers } from "hardhat";

describe("ERC5269", function () {
  async function deployFixture() {
    // Contracts are deployed using the first signer/account by default
    const [owner, mintSender, recipient] = await ethers.getSigners();
    const testWallet: Wallet = new ethers.Wallet("0x0000000000000000000000000000000000000000000000000000000000000001");

    const factory = await ethers.getContractFactory("ERC5269");
    const contract = await factory.deploy();
    let tx1 = await contract.deployed();
    let txDeployErc5269: ContractReceipt = await tx1.deployTransaction.wait();

    const ERC721ForTesting = await ethers.getContractFactory("ERC721ForTesting");
    const erc721ForTesting = await ERC721ForTesting.deploy();
    let tx2 = await erc721ForTesting.deployed();
    const txDeployErc721: ContractReceipt = await tx2.deployTransaction.wait();
    const provider = ethers.provider;
    return {
      provider,
      contract,
      erc721ForTesting,
      tx1, txDeployErc5269,
      tx2, txDeployErc721,
      owner, mintSender, recipient, testWallet
    };
  }

  describe("Deployment", function () {
    it("Should be deployable", async function () {
      await loadFixture(deployFixture);
    });

    it("Should emit proper OnSupportEIP events", async function () {
      let { txDeployErc721 } = await loadFixture(deployFixture);
      let events = txDeployErc721.events?.filter(event => event.event === 'OnSupportEIP');
      expect(events).to.have.lengthOf(4);

      let ev5269 = events!.filter(
        (event) => event.args!.majorEIPIdentifier.eq(5269));
      expect(ev5269).to.have.lengthOf(1);
      expect(ev5269[0].args!.caller).to.equal(BigNumber.from(0));
      expect(ev5269[0].args!.minorEIPIdentifier).to.equal(BigNumber.from(0));
      expect(ev5269[0].args!.eipStatus).to.equal(ethers.utils.id("DRAFTv1"));

      let ev721 = events!.filter(
        (event) => event.args!.majorEIPIdentifier.eq(721));
      expect(ev721).to.have.lengthOf(3);
      expect(ev721[0].args!.caller).to.equal(BigNumber.from(0));
      expect(ev721[0].args!.minorEIPIdentifier).to.equal(BigNumber.from(0));
      expect(ev721[0].args!.eipStatus).to.equal(ethers.utils.id("FINAL"));

      expect(ev721[1].args!.caller).to.equal(BigNumber.from(0));
      expect(ev721[1].args!.minorEIPIdentifier).to.equal(ethers.utils.id("ERC721Metadata"));
      expect(ev721[1].args!.eipStatus).to.equal(ethers.utils.id("FINAL"));

      expect(ev721[2].args!.caller).to.equal(BigNumber.from(0));
      expect(ev721[2].args!.minorEIPIdentifier).to.equal(ethers.utils.id("ERC721Enumerable"));
      expect(ev721[2].args!.eipStatus).to.equal(ethers.utils.id("FINAL"));
    });

    it("Should return proper eipStatus value when called supportEIP() for declared supported EIP/features", async function () {
      let { erc721ForTesting, owner } = await loadFixture(deployFixture);
      expect(await erc721ForTesting.supportEIP(owner.address, 5269, ethers.utils.hexZeroPad("0x00", 32), [])).to.equal(ethers.utils.id("DRAFTv1"));
      expect(await erc721ForTesting.supportEIP(owner.address, 721, ethers.utils.hexZeroPad("0x00", 32), [])).to.equal(ethers.utils.id("FINAL"));
      expect(await erc721ForTesting.supportEIP(owner.address, 721, ethers.utils.id("ERC721Metadata"), [])).to.equal(ethers.utils.id("FINAL"));
      expect(await erc721ForTesting.supportEIP(owner.address, 721, ethers.utils.id("ERC721Enumerable"), [])).to.equal(ethers.utils.id("FINAL"));

      expect(await erc721ForTesting.supportEIP(owner.address, 721, ethers.utils.id("WRONG FEATURE"), [])).to.equal(BigNumber.from(0));
      expect(await erc721ForTesting.supportEIP(owner.address, 9999, ethers.utils.hexZeroPad("0x00", 32), [])).to.equal(BigNumber.from(0));
    });

    it("Should return zero as eipStatus value when called supportEIP() for non declared EIP/features", async function () {
      let { erc721ForTesting, owner } = await loadFixture(deployFixture);
      expect(await erc721ForTesting.supportEIP(owner.address, 721, ethers.utils.id("WRONG FEATURE"), [])).to.equal(BigNumber.from(0));
      expect(await erc721ForTesting.supportEIP(owner.address, 9999, ethers.utils.hexZeroPad("0x00", 32), [])).to.equal(BigNumber.from(0));
    });
  });
});
