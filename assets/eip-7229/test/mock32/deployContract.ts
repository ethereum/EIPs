import { SimV1 } from "./../typechain/SimV1.d";
import { Provider } from "@ethersproject/providers";
import { Contract, Wallet } from "ethers";
import { expect } from "chai";
import { ethers } from "hardhat";
import { pack } from "@ethersproject/solidity";

let proxyContract: SimV1;
describe("deploy contract by contract for 32 bytes slot", function () {
  before("deploy minimal upgradable proxy", async function () {
    // deploy SimV1
    const V1 = await ethers.getContractFactory("Test32");
    const v1 = await V1.deploy(11);
    await v1.deployed();
    console.log("logic v1 contract", v1.address);

    const Deploy = await ethers.getContractFactory("DeployContract32");
    const deploy = await Deploy.deploy();
    await deploy.deployed();

    const tx = await deploy.createContract(v1.address);
    await tx.wait();

    const proxy = await deploy.precomputeContract(v1.address);
    proxyContract = v1.attach(proxy);
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
});
