const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("ComposableSoulboundNFTDemo contract", function () {

  it("InterfaceId should equals 0x911ec470", async function () {
    const [owner, addr1, addr2] = await ethers.getSigners();

    const ComposableSoulboundNFTDemo = await ethers.getContractFactory("ComposableSoulboundNFTDemo");

    const demo = await ComposableSoulboundNFTDemo.deploy();
    await demo.deployed();

    expect(await demo.getInterfaceId()).equals("0x911ec470");
  });

  it("Test soulbound", async function () {
    const [owner, addr1, addr2] = await ethers.getSigners();

    const ComposableSoulboundNFTDemo = await ethers.getContractFactory("ComposableSoulboundNFTDemo");

    const demo = await ComposableSoulboundNFTDemo.deploy();
    await demo.deployed();

    await demo.setSoulbound(1, true);
    expect(await demo.isSoulbound(1)).to.equal(true);
    expect(await demo.isSoulbound(2)).to.equal(false);

    await demo.mint(addr1.address, 1, 2, "0x");
    await demo.mint(addr1.address, 2, 2, "0x");

    await expect(demo.connect(addr1).safeTransferFrom(addr1.address, addr2.address, 1, 1, "0x")).to.be.revertedWith(
        "ComposableSoulboundNFT: Soulbound, Non-Transferable"
    );
    await expect(demo.connect(addr1).safeBatchTransferFrom(addr1.address, addr2.address, [1], [1], "0x")).to.be.revertedWith(
        "ComposableSoulboundNFT: Soulbound, Non-Transferable"
    );
    await expect(demo.connect(addr1).safeBatchTransferFrom(addr1.address, addr2.address, [1,2], [1,1], "0x")).to.be.revertedWith(
        "ComposableSoulboundNFT: Soulbound, Non-Transferable"
    );

    await demo.mint(addr1.address, 2, 1, "0x");
    demo.connect(addr1).safeTransferFrom(addr1.address, addr2.address, 2, 1, "0x");
    demo.connect(addr1).safeBatchTransferFrom(addr1.address, addr2.address, [2], [1], "0x");

    await demo.connect(addr1).burn(addr1.address, 1, 1);
    await demo.connect(addr1).burnBatch(addr1.address, [1], [1]);
    await demo.connect(addr2).burn(addr2.address, 2, 1);
    await demo.connect(addr2).burnBatch(addr2.address, [2], [1]);
  });
});
