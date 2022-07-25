import { BigNumber } from "ethers";
import { expect } from "chai";
import { ethers } from "hardhat";
import { ERC3525BurnableUpgradeable } from "../typechain";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { TokenData, ZERO_ADDRESS } from "./lib/constants";

describe("ERC3525", function () {
  const deploy = async (): Promise<ERC3525BurnableUpgradeable> => {
    const ERC3525Factory = await ethers.getContractFactory(
      "ERC3525BurnableUpgradeable"
    );
    const erc3525 =
      (await ERC3525Factory.deploy()) as ERC3525BurnableUpgradeable;
    await erc3525.deployed();
    return erc3525;
  };

  const mint = async (slot: string = "3525"): Promise<TokenData> => {
    const erc3525 = await deploy();
    const [minter] = await ethers.getSigners();
    return mintWithOutDeploy(erc3525, minter, slot);
  };

  const mintWithOutDeploy = async (
    erc3525: ERC3525BurnableUpgradeable,
    minter: SignerWithAddress,
    slot: string
  ): Promise<TokenData> => {
    const value = BigNumber.from("1000000000000000000");
    await erc3525.mint(minter.address, slot, value);

    let eventFilter = erc3525.filters["TransferValue"](0);
    let block = await ethers.provider.getBlock("latest");
    let event = await erc3525.queryFilter(eventFilter, block.number, "latest");
    let args = event[0]["args"];
    const tokenData = {
      id: BigNumber.from(args[1]),
      slot: BigNumber.from(slot),
      balance: value,
      owner: minter.address,
      erc3525: erc3525,
    };

    return tokenData;
  };

  const checkTransferEvent = async (
    erc3525: ERC3525BurnableUpgradeable,
    from: string,
    to: string,
    tokenId: BigNumber
  ) => {
    let eventFilter = erc3525.filters["Transfer"](from, to);
    let block = await ethers.provider.getBlock("latest");
    let event = await erc3525.queryFilter(eventFilter, block.number, "latest");

    let args = event[0]["args"];
    expect(args[0]).to.equal(from);
    expect(args[1]).to.equal(to);
    expect(args[2]).to.equal(tokenId);
  };

  const checkTransferValueEvent = async (
    erc3525: ERC3525BurnableUpgradeable,
    fromTokenId: BigNumber,
    toTokenId: BigNumber,
    balance: BigNumber
  ) => {
    let eventFilter = erc3525.filters["TransferValue"](fromTokenId, toTokenId);
    let block = await ethers.provider.getBlock("latest");
    let event = await erc3525.queryFilter(eventFilter, block.number, "latest");
    let args = event[0]["args"];
    expect(args[0]).to.equal(fromTokenId);
    expect(args[1]).to.equal(toTokenId);
    expect(args[2]).to.equal(balance);
  };

  describe("ERC721 compatible interface", function () {
    it("mint should be success", async function () {
      const t = await mint();
      await checkTransferEvent(t.erc3525, ZERO_ADDRESS, t.owner, t.id);

      expect(await t.erc3525["balanceOf(address)"](t.owner)).to.eq(t.id);
      expect(await t.erc3525.ownerOf(t.id)).to.eq(t.owner);
      await expect(t.erc3525.ownerOf(5)).revertedWith(
        "ERC3525: owner query for nonexistent token"
      );
      expect(await t.erc3525["balanceOf(uint256)"](t.id)).to.eq(t.balance);
      expect(await t.erc3525.slotOf(t.id)).to.eq(t.slot);
      expect(await t.erc3525.totalSupply()).to.eq(1);
    });

    it("approve all should be success", async () => {
      const [_, approval] = await ethers.getSigners();

      const t = await mint();

      await t.erc3525.setApprovalForAll(approval.address, true);
      expect(await t.erc3525.isApprovedForAll(t.owner, approval.address)).to.eq(
        true
      );
      expect(
        await t.erc3525.isApprovedForAll(
          t.owner,
          "0x000000000000000000000000000000000000dEaD"
        )
      ).to.eq(false);
    });

    it("approve id should be success", async () => {
      const t = await mint();

      const [_, approval] = await ethers.getSigners();

      await t.erc3525["approve(address,uint256)"](approval.address, t.id);
      expect(await t.erc3525.getApproved(t.id)).to.eq(approval.address);
      await expect(
        t.erc3525["approve(address,uint256)"](approval.address, 5)
      ).revertedWith("ERC3525: owner query for nonexistent token");
      await expect(t.erc3525.getApproved(6)).revertedWith(
        "ERC3525: approved query for nonexistent token"
      );
    });

    it("transfer token id should be success", async () => {
      const t = await mint();
      const oldOwner = t.owner;
      const [minter, receiver] = await ethers.getSigners();
      
      await t.erc3525["transferFrom(address,address,uint256)"](
        t.owner,
        receiver.address,
        t.id
      )

      await checkTransferEvent(t.erc3525, oldOwner, receiver.address, t.id);
      const newOwner = receiver.address;
      expect(await t.erc3525.ownerOf(t.id)).to.eq(newOwner);
      expect(await t.erc3525["balanceOf(address)"](newOwner)).to.eq(1);
      expect(await t.erc3525["balanceOf(address)"](oldOwner)).to.eq(0);
      expect(await t.erc3525["balanceOf(uint256)"](t.id)).to.eq(t.balance);
      expect(await t.erc3525.totalSupply()).to.eq(1);
    });

    it("allowance should be zero after transfer token id", async () => {
      const t = await mint();
      const [_, receiver, approval] = await ethers.getSigners();
      await t.erc3525["approve(uint256,address,uint256)"](
        t.id,
        approval.address,
        t.balance
      );
      expect(await t.erc3525.allowance(t.id, approval.address)).to.eq(t.balance);
      await t.erc3525["transferFrom(address,address,uint256)"](
        t.owner,
        receiver.address,
        t.id
      );
      expect(await t.erc3525.allowance(t.id, approval.address)).to.eq(0);
    });

    it("not owner should be rejected", async () => {
      const t = await mint();
      const [_, approval, other] = await ethers.getSigners();
      t.erc3525 = t.erc3525.connect(other);
      await expect(
        t.erc3525["approve(uint256,address,uint256)"](
          t.id,
          approval.address,
          t.balance
        )
      ).revertedWith("ERC3525: approve caller is not owner nor approved for all");

      await expect(
        t.erc3525["transferFrom(address,address,uint256)"](
          approval.address,
          other.address,
          t.id
        )
      ).revertedWith("ERC3525: transfer caller is not owner nor approved");
    });

    it("transfer id should  be success after setApprovalForAll", async () => {
      const t = await mint();
      const [_, approval, receiver] = await ethers.getSigners();
      await t.erc3525.setApprovalForAll(approval.address, true);
      t.erc3525 = t.erc3525.connect(approval);
      await t.erc3525["transferFrom(address,address,uint256)"](
        t.owner,
        receiver.address,
        t.id
      );
      await checkTransferEvent(t.erc3525, t.owner, receiver.address, t.id);
    });

    it("transfer should be success after approve", async () => {
      const t = await mint();
      const [_, approval, receiver] = await ethers.getSigners();
      await t.erc3525["approve(address,uint256)"](approval.address, t.id);
      await t.erc3525["transferFrom(address,address,uint256)"](
        t.owner,
        receiver.address,
        t.id
      );
      await checkTransferEvent(t.erc3525, t.owner, receiver.address, t.id);
    });

    it("balance of address should be correct after transfer id", async () => {
      const erc3525 = await deploy();
      const [minter, receiver] = await ethers.getSigners();

      const tokenDatas = [];

      for (let i = 1; i < 11; i++) {
        const tokenData = await mintWithOutDeploy(erc3525, minter, "3525");
        tokenDatas.push(tokenData);
      }
      expect(await erc3525["balanceOf(address)"](minter.address)).to.eq(10);
      for (let t of tokenDatas.slice(0, 4)) {
        await erc3525.burn(t.id);
      }
      expect(await erc3525["balanceOf(address)"](minter.address)).to.eq(6);

      for (let t of tokenDatas.slice(5, 7)) {
        await erc3525["transferFrom(address,address,uint256)"](
          minter.address,
          receiver.address,
          t.id
        );
      }
      expect(await erc3525["balanceOf(address)"](minter.address)).to.eq(4);
    });
  });

  describe("ERC3525 interface", function () {
    it("approve value should be success", async () => {
      const t = await mint();

      const [_, approval] = await ethers.getSigners();
      const approvedValue = t.balance.div(2);

      await t.erc3525["approve(uint256,address,uint256)"](
        t.id,
        approval.address,
        approvedValue
      );
      expect(await t.erc3525.allowance(t.id, approval.address)).to.eq(
        approvedValue
      );
      expect(
        await t.erc3525.allowance(
          t.id,
          "0x000000000000000000000000000000000000dEaD"
        )
      ).to.eq(0);
      expect(await t.erc3525.allowance(5, approval.address)).to.eq(0);
    });

    it("transfer value to id should be success", async () => {
      const erc3525 = await deploy();
      const [from, to] = await ethers.getSigners();

      const f = await mintWithOutDeploy(erc3525, from, "3525");
      const t = await mintWithOutDeploy(erc3525, to, "3525");
      const value = f.balance.div(2);
      const expectFromValue = f.balance.sub(value);
      const expectToValue = t.balance.add(value);

      expect(
        await erc3525["transferFrom(uint256,uint256,uint256)"](
          f.id,
          t.id,
          value
        )
      );
      expect(await erc3525["balanceOf(uint256)"](f.id)).to.eq(expectFromValue);
      expect(await erc3525["balanceOf(uint256)"](t.id)).to.eq(expectToValue);
    });

    it("approved value should be correct after transfer value to id", async () => {
      const erc3525 = await deploy();
      const [from, to, spender] = await ethers.getSigners();

      const f = await mintWithOutDeploy(erc3525, from, "3525");
      const t = await mintWithOutDeploy(erc3525, to, "3525");
      const value = f.balance.div(2);
      const expectApprovedValue = f.balance.sub(value);

      await erc3525["approve(uint256,address,uint256)"](
        f.id,
        spender.address,
        f.balance
      );
      expect(await erc3525.allowance(f.id, spender.address)).to.eq(f.balance);

      const spenderERC3525 = erc3525.connect(spender);
      await spenderERC3525["transferFrom(uint256,uint256,uint256)"](
        f.id,
        t.id,
        value
      )
      expect(await erc3525.allowance(f.id, spender.address)).to.eq(expectApprovedValue);
    });

    it("transfer value to id should sucess after setApprovalForAll", async () => {
      const erc3525 = await deploy();
      const [from, to, spender] = await ethers.getSigners();

      const f = await mintWithOutDeploy(erc3525, from, "3525");
      const t = await mintWithOutDeploy(erc3525, to, "3525");
      const value = f.balance.div(2);

      await erc3525.setApprovalForAll(spender.address, true);

      const spenderERC3525 = await erc3525.connect(spender);
      expect(
        await spenderERC3525["transferFrom(uint256,uint256,uint256)"](
          f.id,
          t.id,
          value
        )
      );
    });

    it("transfer value to id should sucess after id approved", async () => {
      const erc3525 = await deploy();
      const [from, to, spender] = await ethers.getSigners();

      const f = await mintWithOutDeploy(erc3525, from, "3525");
      const t = await mintWithOutDeploy(erc3525, to, "3525");
      const value = f.balance.div(2);

      await erc3525["approve(address,uint256)"](spender.address, f.id);

      const spenderERC3525 = await erc3525.connect(spender);
      expect(
        await spenderERC3525["transferFrom(uint256,uint256,uint256)"](
          f.id,
          t.id,
          value
        )
      );
    });
  });
});
