import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { ERC7231Mock } from "../typechain-types";

import { expect } from "chai";
import  web3 from "web3";


describe("ERC7231", async () => {

  let owner : SignerWithAddress;
  let others: SignerWithAddress[];

  let ERC7231Mock: ERC7231Mock;

  const name = "carvTest";
  const symbol = "CVTS";
  const tokenId = 1;

  const MultiUserIDs =  [
    {
      "userID":"openID2:steam:a000000000000000000000000000000000000000000000000000000000000001",
      "verifierUri1":"https://carv.io/verify/steam/a000000000000000000000000000000000000000000000000000000000000001",
      "memo":"memo1"
    },
    {
      "userID":"did:polgyonId:b000000000000000000000000000000000000000000000000000000000000002",
      "verifierUri1":"https://carv.io/verify/steam/b000000000000000000000000000000000000000000000000000000000000002",
      "memo":"memo1"
    }
  ]
    
  beforeEach(async () => {

    [owner, ...others] = await ethers.getSigners();

    const ERC7231Factory = await ethers.getContractFactory("ERC7231Mock");
    ERC7231Mock = await ERC7231Factory.deploy(name, symbol,);
    await ERC7231Mock.deployed();

    // await ERC7231Mock.
    await ERC7231Mock.connect(owner).mint(owner.address,tokenId);
    
  });

  describe("Init of Erc721 ", async function () {

    it("Name", async function () {
      expect(await ERC7231Mock.name()).to.equal(name);
    });

    it("Symbol", async function () {
      expect(await ERC7231Mock.symbol()).to.equal(symbol);
    });
    
  });

  describe("set MultiUserIDs Root", async function () {

    it("Normal case", async function () {

      let multiUserIDsHash = "0xa5b9d60f32436310afebcfda832817a68921beb782fabf7915cc0460b443116a"
      await expect(
        ERC7231Mock.connect(owner).setIdentitiesRoot(
          tokenId,
          multiUserIDsHash
        )
      ).to.emit(ERC7231Mock,"SetIdentitiesRoot").withArgs(        
          tokenId,
          multiUserIDsHash
      );

      let multiUserIDsRoot = await ERC7231Mock.getIdentitiesRoot(
        tokenId
      );
      
      expect(multiUserIDsHash).to.eql(multiUserIDsRoot);

    });
    
  });


  describe("verify UserIDs Binding", async function () {

    it("Normal case", async function () {

      const dataHash = ethers.utils.keccak256(
          ethers.utils.toUtf8Bytes(JSON.stringify(MultiUserIDs))
      );
      const dataHashBin = ethers.utils.arrayify(dataHash);
      const ethHash = ethers.utils.hashMessage(dataHashBin);

      // const wallet = new ethers.Wallet(process.env.PK);
      const signature = await owner.signMessage(dataHashBin);

      await ERC7231Mock.connect(owner).setIdentitiesRoot(
        tokenId,ethHash
      )

      let userIDS = new Array();
      MultiUserIDs.forEach(
        (MultiUserIDObj) => {
          userIDS.push(MultiUserIDObj.userID)
        }
      )

      let result = await ERC7231Mock.verifyIdentitiesBinding(
        tokenId,
        owner.address,
        userIDS,
        ethHash,
        signature
      )
      expect(result).to.eql(true);

    });
    

  });









});
