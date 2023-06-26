import { Example0V1 } from "../typechain/Example0V1";
import { Provider } from "@ethersproject/providers";
import { Contract, Wallet } from "ethers";
import { expect } from "chai";
import { ethers } from "hardhat";
import { pack } from "@ethersproject/solidity";

let proxyContract: Example0V1;
describe("example test  for 0 slot", function () {
  before(
    "deploy minimal upgradable proxy when deploying logic contract",
    async function () {
      // deploy SimV1
      const V1 = await ethers.getContractFactory("Example0V1");
      const v1 = await V1.deploy();
      await v1.deployed();
      console.log("logic payable contract", v1.address);

      // proxy's code
      const code = pack(
        ["bytes1",  "address", "bytes"],
        [
          "0x73",
          v1.address,
          "0x5f55600960285f396010603160093960195ff3365f5f375f5f365f5f545af43d5f5f3e3d5f82601757fd5bf3",
        ]
      );
      const proxyAddr = ethers.utils.getCreate2Address(
        v1.address,
        "0x0000000000000000000000000000000000000000000000000000000000000000",
        ethers.utils.keccak256(code)
      );
      console.log("proxy contract", proxyAddr);
      proxyContract = v1.attach(proxyAddr);
    }
  );

  it("update data", async function () {
    // update data
    await proxyContract.setNumber(11);

    expect(await proxyContract.number()).to.equal(11);
  });

  it("upgrade", async function () {
    // deploy SimV1
    const V2 = await ethers.getContractFactory("Example1V2");
    const v2 = await V2.deploy();
    await v2.deployed();
    console.log("logic v2 contract", v2.address);

    await expect(proxyContract.upgrade(v2.address))
      .to.emit(proxyContract, "Upgraded")
      .withArgs(v2.address);

    v2.attach(proxyContract.address).addNumber(1);

    expect(await proxyContract.number()).to.equal(12);
  });
});
