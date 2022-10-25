import { BigNumber } from "ethers";
import { expect } from "chai";
import { ethers } from "hardhat";
import { ERC3525Example } from "../typechain";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

const ZERO_ADDRESS = "0x0000000000000000000000000000000000000000";
const ZERO_TOKEN_ID = 0;

let owner: SignerWithAddress,
  approval: SignerWithAddress,
  to: SignerWithAddress;
let token: ERC3525Example;
let snapshotId: any;
const fromTokenId = 35251;
const toTokenId = 35252;
const fromValue = 10000000000;
const approveValue = 5000000000;
const transferValue = 3000000000;
const slotDetails = {
  name: "Test Slot",
  description: "Test Slot Description",
  image: "https://example.com/slot/test_slot.png",
  underlying: "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE",
  vestingType: 1,
  maturity: 1658989800,
  term: 2592000,
  value: fromValue,
};

describe("ERC3525", function () {
  before(async () => {
    const signers = await ethers.getSigners();
    owner = signers[0];
    approval = signers[1];
    to = signers[2];
    const ERC3525Factory = await ethers.getContractFactory("ERC3525Example");
    token = (await ERC3525Factory.deploy(
      "TST",
      "Test 3525",
      18
    )) as ERC3525Example;
    await token.deployed();

    await token.mint(
      slotDetails.name,
      slotDetails.description,
      slotDetails.image,
      fromTokenId,
      slotDetails.underlying,
      slotDetails.vestingType,
      slotDetails.maturity,
      slotDetails.term,
      slotDetails.value
    );

    await token.mint(
      slotDetails.name,
      slotDetails.description,
      slotDetails.image,
      toTokenId,
      slotDetails.underlying,
      slotDetails.vestingType,
      slotDetails.maturity,
      slotDetails.term,
      0
    );
  });

  beforeEach(async function () {
    snapshotId = await ethers.provider.send("evm_snapshot", []);
  });

  afterEach(async function () {
    await ethers.provider.send("evm_revert", [snapshotId]);
  });

  describe("ERC3525 Example", function () {
    it("approve value should be success", async () => {
      await token["approve(uint256,address,uint256)"](
        fromTokenId,
        approval.address,
        approveValue
      );

      expect(await token.allowance(fromTokenId, approval.address)).to.eq(
        approveValue
      );
    });

    it("transfer value to id should be success", async () => {
      expect(
        await token["transferFrom(uint256,uint256,uint256)"](
          fromTokenId,
          toTokenId,
          transferValue
        )
      );
      expect(await token["balanceOf(uint256)"](fromTokenId)).to.eq(
        fromValue - transferValue
      );
      expect(await token["balanceOf(uint256)"](toTokenId)).to.eq(transferValue);
    });

    it("transfer value to address should be success", async () => {
      expect(
        await token["transferFrom(uint256,address,uint256)"](
          fromTokenId,
          to.address,
          transferValue
        )
      );
      expect(await token["balanceOf(uint256)"](fromTokenId)).to.eq(
        fromValue - transferValue
      );
      const newTokenId = 1000000000 + fromTokenId;
      expect(await token["balanceOf(uint256)"](newTokenId)).to.eq(
        transferValue
      );
    });

    it("approved value should be correct after transfer value to id", async () => {
      await token["approve(uint256,address,uint256)"](
        fromTokenId,
        approval.address,
        approveValue
      );
      const approvalToken = token.connect(approval);
      await approvalToken["transferFrom(uint256,uint256,uint256)"](
        fromTokenId,
        toTokenId,
        transferValue
      );
      expect(await token.allowance(fromTokenId, approval.address)).to.eq(
        approveValue - transferValue
      );
    });
  });
});
