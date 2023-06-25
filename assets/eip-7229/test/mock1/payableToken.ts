import { PayableToken } from "../typechain/PayableToken";
import { Provider } from "@ethersproject/providers";
import { Contract, Wallet } from "ethers";
import { expect } from "chai";
import { ethers } from "hardhat";
import { pack } from "@ethersproject/solidity";

let proxyContract: PayableToken;
describe("pay to upgradable contract for 1 byte slot", function () {
  before("deploy minimal upgradable proxy", async function () {
    // deploy SimV1
    const V1 = await ethers.getContractFactory("PayableTokenV1");
    const v1 = await V1.deploy();
    await v1.deployed();
    console.log("logic PayableToken contract", v1.address);

    // deploy proxy contract
    const code = pack(
      ["bytes1", "uint8", "bytes1", "address", "bytes"],
      [
        "0x60",
        await v1.getImplementSlot(),
        "0x73",
        v1.address,
        "0x8155600960305f3960f81b60095260106039600a39601a5ff3365f5f375f5f365f60545af43d5f5f3e3d5f82601857fd5bf3",
      ]
    );
    const Proxy = new ethers.ContractFactory(
      "[]",
      code.slice(2),
      await ethers.getSigner()
    );
    const proxy = await Proxy.deploy();
    await proxy.deployed();
    console.log("deploy proxy contract:", proxy.address);
    proxyContract = v1.attach(proxy.address);
  });

  it("update data", async function () {
    // init & update data
    await proxyContract.init();
    await proxyContract.setNumber(11, { value: ethers.utils.parseEther("1") });

    // check proxy data
    expect(await proxyContract.owner()).to.equal(
      await (await ethers.getSigner()).getAddress()
    );
    expect(await proxyContract.number()).to.equal(11);

    expect(
      await ethers.provider.getBalance(proxyContract.address),
      ethers.utils.parseEther("1")
    );
  });

  it("receive & fallback", async function () {
    // await ethers.provider.sendTransaction()
    await (
      await ethers.getSigner()
    ).sendTransaction({
      to: proxyContract.address,
      value: ethers.utils.parseEther("1"),
    });

    expect(
      await ethers.provider.getBalance(proxyContract.address),
      ethers.utils.parseEther("2")
    );

    expect(await proxyContract.number()).to.equal(12);

    await (
      await ethers.getSigner()
    ).sendTransaction({
      to: proxyContract.address,
      value: ethers.utils.parseEther("2"),
      data: "0x11112222",
    });

    expect(
      await ethers.provider.getBalance(proxyContract.address),
      ethers.utils.parseEther("4")
    );

    expect(await proxyContract.number()).to.equal(14);
  });

  it("upgrade", async function () {
    // deploy SimV1
    const V2 = await ethers.getContractFactory("PayableTokenV2");
    const v2 = await V2.deploy();
    await v2.deployed();
    console.log("logic PayableTokenV2 contract", v2.address);

    await expect(proxyContract.upgrade(v2.address))
      .to.emit(proxyContract, "Upgraded")
      .withArgs(v2.address);
  });

  it("check receive & fallback after upgrade", async function () {
    // await ethers.provider.sendTransaction()
    await expect(
      (
        await ethers.getSigner()
      ).sendTransaction({
        to: proxyContract.address,
        value: ethers.utils.parseEther("1"),
      })
    ).to.be.reverted;

    await expect(
      (
        await ethers.getSigner()
      ).sendTransaction({
        to: proxyContract.address,
        value: ethers.utils.parseEther("2"),
        data: "0x11112222",
      })
    ).to.be.reverted;

    expect(
      await ethers.provider.getBalance(proxyContract.address),
      ethers.utils.parseEther("4")
    );

    expect(await proxyContract.number(), 14);
  });
});
