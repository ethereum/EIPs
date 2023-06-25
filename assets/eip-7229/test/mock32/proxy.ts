import { SimV1 } from "../typechain/SimV1";
import { Provider } from "@ethersproject/providers";
import { Contract, Wallet } from "ethers";
import { expect } from "chai";
import { ethers } from "hardhat";
import { pack } from "@ethersproject/solidity";

let proxyContract: SimV1;
describe("Proxy for 32 bytes slot", function () {
  before("deploy minimal upgradable proxy", async function () {
    // deploy SimV1
    const V1 = await ethers.getContractFactory("SimV1");
    const v1 = await V1.deploy(11);
    await v1.deployed();
    console.log("logic v1 contract", v1.address);

    // deploy proxy contract
    const code = pack(
      ["bytes1", "uint256", "bytes1", "address", "bytes"],
      [
        "0x7f",
        await v1.getImplementSlot(),
        "0x73",
        v1.address,
        "0x81556009604c3d396009526010605560293960395ff3365f5f375f5f365f7f545af43d5f5f3e3d5f82603757fd5bf3",
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
    await proxyContract.setNumber(11);

    // check proxy data
    expect(await proxyContract.owner()).to.equal(
      await (await ethers.getSigner()).getAddress()
    );
    expect(await proxyContract.number()).to.equal(11);
  });

  it("upgrade", async function () {
    // deploy SimV1
    const V2 = await ethers.getContractFactory("SimV2");
    const v2 = await V2.deploy(1);
    await v2.deployed();
    console.log("logic v2 contract", v2.address);

    await expect(proxyContract.upgrade(v2.address))
      .to.emit(proxyContract, "Upgraded")
      .withArgs(v2.address);

    v2.attach(proxyContract.address).addNumber(1);
    // check proxy data
    expect(await proxyContract.owner()).to.equal(
      await (await ethers.getSigner()).getAddress()
    );
    expect(await proxyContract.number()).to.equal(12);

    expect(await v2.attach(proxyContract.address).upgradeTime()).to.equal(0);
  });
});
