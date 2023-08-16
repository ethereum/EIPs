import { expect } from "chai"
import hre, { ethers } from "hardhat"
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers"

import { ERC20Spendable } from "../typechain-types/contracts/ERC20Spendable"
import { MockSpendableERC20Receiver } from "../typechain-types/contracts/mock/MockSpendableERC20Receiver"
import { MockSpendableERC20NonReceiver } from "../typechain-types/contracts/mock/MockSpendableERC20NonReceiver"
import { BytesLike } from "ethers"

describe.only("ERC20Spendable", function () {
  let hhMockSpendable: ERC20Spendable
  let hhMockSpendableReceipt: ERC20Spendable
  let hhMockStaking: MockSpendableERC20Receiver
  let hhMockStakingReceipt: MockSpendableERC20Receiver
  let hhMockNonReceiver: MockSpendableERC20NonReceiver

  let addr1: SignerWithAddress

  const initialBalance = 1000
  const message = "stake please"
  const daysToStake = 30

  const emptyBytes = "0x"

  const sendArgs = ethers.utils.defaultAbiCoder.encode(
    ["string", "uint256"],
    [message, daysToStake],
  )

  beforeEach(async function () {
    ;[addr1] = await ethers.getSigners()

    const spendable = await ethers.getContractFactory("MockSpendableERC20")
    hhMockSpendable = await spendable.deploy(addr1.address, initialBalance)

    const spendableReceipt = await ethers.getContractFactory(
      "MockSpendableERC20ReturnedArgs",
    )
    hhMockSpendableReceipt = await spendableReceipt.deploy(
      addr1.address,
      initialBalance,
    )

    const receiver = await ethers.getContractFactory(
      "MockSpendableERC20Receiver",
    )
    hhMockStaking = await receiver.deploy(hhMockSpendable.address)

    hhMockStakingReceipt = await receiver.deploy(hhMockSpendableReceipt.address)

    const nonReceiver = await ethers.getContractFactory(
      "MockSpendableERC20NonReceiver",
    )
    hhMockNonReceiver = await nonReceiver.deploy()
  })

  describe("ERC20 Validations", function () {
    beforeEach(async function () {
      //
    })
    context("No passed arguments", function () {
      it("Cannot spend more than balance", async () => {
        await expect(
          hhMockSpendable
            .connect(addr1)
            ["spend(address,uint256)"](
              hhMockStaking.address,
              initialBalance + 1,
            ),
        ).to.be.revertedWith("ERC20: transfer amount exceeds balance")
      })

      it("Cannot spend to zero address", async () => {
        await expect(
          hhMockSpendable
            .connect(addr1)
            ["spend(address,uint256)"](
              ethers.constants.AddressZero,
              initialBalance,
            ),
        ).to.be.revertedWith("ERC20: transfer to the zero address")
      })
    })

    context("Passed arguments", function () {
      it("Cannot spend more than balance", async () => {
        await expect(
          hhMockSpendable
            .connect(addr1)
            ["spend(address,uint256,bytes)"](
              hhMockStaking.address,
              initialBalance + 1,
              emptyBytes,
            ),
        ).to.be.revertedWith("ERC20: transfer amount exceeds balance")
      })

      it("Cannot spend to zero address", async () => {
        await expect(
          hhMockSpendable
            .connect(addr1)
            ["spend(address,uint256,bytes)"](
              ethers.constants.AddressZero,
              initialBalance,
              emptyBytes,
            ),
        ).to.be.revertedWith("ERC20: transfer to the zero address")
      })
    })
  })

  describe("Sending tokens to invalid receiver", function () {
    beforeEach(async function () {
      //
    })
    context("No passed arguments", function () {
      it("Reverts", async () => {
        await expect(
          hhMockSpendable
            .connect(addr1)
            ["spend(address,uint256)"](
              hhMockNonReceiver.address,
              initialBalance,
            ),
        ).to.be.revertedWithCustomError(
          hhMockSpendable,
          "ERC20SpendableInvalidReveiver",
        )
      })
    })

    context("Passed arguments", function () {
      it("Cannot spend more than balance", async () => {
        await expect(
          hhMockSpendable
            .connect(addr1)
            ["spend(address,uint256,bytes)"](
              hhMockNonReceiver.address,
              initialBalance,
              emptyBytes,
            ),
        ).to.be.revertedWithCustomError(
          hhMockSpendable,
          "ERC20SpendableInvalidReveiver",
        )
      })
    })
  })

  describe("Sending tokens to valid receiver", function () {
    context("No passed arguments", function () {
      const amountToStake = initialBalance / 2

      beforeEach(async function () {
        await expect(
          hhMockSpendable
            .connect(addr1)
            ["spend(address,uint256)"](hhMockStaking.address, amountToStake),
        )
          .to.emit(hhMockStaking, "AmountStaked")
          .withArgs(amountToStake, "", 0)
      })

      it("Spend received", async () => {
        expect(await hhMockStaking.stakedAmount(addr1.address)).to.equal(
          amountToStake,
        )
      })

      it("Additional spend received", async () => {
        await expect(
          hhMockSpendable
            .connect(addr1)
            ["spend(address,uint256)"](hhMockStaking.address, amountToStake),
        )
          .to.emit(hhMockStaking, "AmountStaked")
          .withArgs(amountToStake, "", 0)

        expect(await hhMockStaking.stakedAmount(addr1.address)).to.equal(
          initialBalance,
        )
      })
    })

    context("Passed arguments", function () {
      const amountToStake = initialBalance / 2

      beforeEach(async function () {
        await expect(
          hhMockSpendable
            .connect(addr1)
            ["spend(address,uint256,bytes)"](
              hhMockStaking.address,
              amountToStake,
              sendArgs,
            ),
        )
          .to.emit(hhMockStaking, "AmountStaked")
          .withArgs(amountToStake, message, daysToStake)
      })

      it("Spend received", async () => {
        expect(await hhMockStaking.stakedAmount(addr1.address)).to.equal(
          amountToStake,
        )
      })

      it("Additional spend received", async () => {
        await expect(
          hhMockSpendable
            .connect(addr1)
            ["spend(address,uint256,bytes)"](
              hhMockStaking.address,
              amountToStake,
              sendArgs,
            ),
        )
          .to.emit(hhMockStaking, "AmountStaked")
          .withArgs(amountToStake, message, daysToStake)

        expect(await hhMockStaking.stakedAmount(addr1.address)).to.equal(
          initialBalance,
        )
      })
    })
  })

  describe("SpendReceipt event", function () {
    const amountToStake = initialBalance / 2
    let returnArguments: BytesLike

    beforeEach(async function () {
      returnArguments = ethers.utils.defaultAbiCoder.encode(
        ["address", "uint256", "bool"],
        [addr1.address, amountToStake, true],
      )
    })

    context("No passed arguments", function () {
      beforeEach(async function () {
        await expect(
          hhMockSpendable
            .connect(addr1)
            ["spend(address,uint256)"](hhMockStaking.address, amountToStake),
        )
          .to.emit(hhMockSpendable, "SpendReceipt")
          .withArgs(
            addr1.address,
            hhMockStaking.address,
            amountToStake,
            emptyBytes,
            returnArguments,
          )
      })

      it("Spend received", async () => {
        expect(await hhMockStaking.stakedAmount(addr1.address)).to.equal(
          amountToStake,
        )
      })

      it("Additional spend received", async () => {
        await expect(
          hhMockSpendable
            .connect(addr1)
            ["spend(address,uint256)"](hhMockStaking.address, amountToStake),
        )
          .to.emit(hhMockSpendable, "SpendReceipt")
          .withArgs(
            addr1.address,
            hhMockStaking.address,
            amountToStake,
            emptyBytes,
            returnArguments,
          )

        expect(await hhMockStaking.stakedAmount(addr1.address)).to.equal(
          initialBalance,
        )
      })
    })

    context("Passed arguments", function () {
      beforeEach(async function () {
        await expect(
          hhMockSpendable
            .connect(addr1)
            ["spend(address,uint256,bytes)"](
              hhMockStaking.address,
              amountToStake,
              sendArgs,
            ),
        )
          .to.emit(hhMockSpendable, "SpendReceipt")
          .withArgs(
            addr1.address,
            hhMockStaking.address,
            amountToStake,
            sendArgs,
            returnArguments,
          )
      })

      it("Spend received", async () => {
        expect(await hhMockStaking.stakedAmount(addr1.address)).to.equal(
          amountToStake,
        )
      })

      it("Additional spend received", async () => {
        await expect(
          hhMockSpendable
            .connect(addr1)
            ["spend(address,uint256,bytes)"](
              hhMockStaking.address,
              amountToStake,
              sendArgs,
            ),
        )
          .to.emit(hhMockSpendable, "SpendReceipt")
          .withArgs(
            addr1.address,
            hhMockStaking.address,
            amountToStake,
            sendArgs,
            returnArguments,
          )

        expect(await hhMockStaking.stakedAmount(addr1.address)).to.equal(
          initialBalance,
        )
      })
    })
  })

  describe("Receiving receipt from valid receiver", function () {
    context("No passed arguments", function () {
      const amountToStake = initialBalance / 2

      beforeEach(async function () {
        await expect(
          hhMockSpendableReceipt
            .connect(addr1)
            ["spend(address,uint256)"](
              hhMockStakingReceipt.address,
              amountToStake,
            ),
        )
          .to.emit(hhMockSpendableReceipt, "Receipt")
          .withArgs(addr1.address, amountToStake, true)
      })

      it("Spend received", async () => {
        expect(await hhMockStakingReceipt.stakedAmount(addr1.address)).to.equal(
          amountToStake,
        )
      })

      it("Additional spend received", async () => {
        await expect(
          hhMockSpendableReceipt
            .connect(addr1)
            ["spend(address,uint256)"](
              hhMockStakingReceipt.address,
              amountToStake,
            ),
        )
          .to.emit(hhMockSpendableReceipt, "Receipt")
          .withArgs(addr1.address, amountToStake, true)

        expect(await hhMockStakingReceipt.stakedAmount(addr1.address)).to.equal(
          initialBalance,
        )
      })
    })

    context("Passed arguments", function () {
      const amountToStake = initialBalance / 2

      beforeEach(async function () {
        await expect(
          hhMockSpendableReceipt
            .connect(addr1)
            ["spend(address,uint256,bytes)"](
              hhMockStakingReceipt.address,
              amountToStake,
              sendArgs,
            ),
        )
          .to.emit(hhMockSpendableReceipt, "Receipt")
          .withArgs(addr1.address, amountToStake, true)
      })

      it("Spend received", async () => {
        expect(await hhMockStakingReceipt.stakedAmount(addr1.address)).to.equal(
          amountToStake,
        )
      })

      it("Additional spend received", async () => {
        await expect(
          hhMockSpendableReceipt
            .connect(addr1)
            ["spend(address,uint256,bytes)"](
              hhMockStakingReceipt.address,
              amountToStake,
              sendArgs,
            ),
        )
          .to.emit(hhMockSpendableReceipt, "Receipt")
          .withArgs(addr1.address, amountToStake, true)

        expect(await hhMockStakingReceipt.stakedAmount(addr1.address)).to.equal(
          initialBalance,
        )
      })
    })
  })
})
