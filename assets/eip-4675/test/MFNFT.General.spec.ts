import { expect } from "chai";
import hre, { deployments, ethers, waffle } from "hardhat";
import { BigNumber } from "ethers";
import { AddressZero } from "@ethersproject/constants";
import { parseEther } from "@ethersproject/units";
import { setMFNFTwithNFT, deployFTContract, getMFContract, getNFTContract, mintNFT } from "./utils/setup";
import { transferFrom ,balanceOf, transfer, safeTransferFrom, addToken, approve, increaseAllowance, decreaseAllowance } from "./utils/execution";


describe("Multi-Fractional Non-Fungible Token", async () => {

    const [admin, user1, user2, user3] = waffle.provider.getWallets();

    // Scalar variable that gets incremented when token is added to MFNFT
    const scalar_tokenId = 1;

    // token ID of the NFT
    const tokenId = 1;

    // total supply of FT derived from NFT
    const totalSupply = 1000;

    const setupTests = deployments.createFixture(async ({deployments}) => {
        await deployments.fixture();
        return {
            MFNFT: await getMFContract(),
            NFT: await getNFTContract(),
        }
    });

    describe("NFT Ownership", async () => {
        it("should revert if NFT ownership is not given before token addition", async () => {
            const { MFNFT, NFT } = await setupTests()

            await NFT.safeMint(user1.address, tokenId);

            await expect(
                addToken(MFNFT, NFT.address, tokenId, totalSupply)
            ).to.be.revertedWith("Verifier::verifyOwnership: NFT ownership verification failed")
        });

        it("should accept NFT after taking the ownership", async () => {
            const { MFNFT, NFT } = await setupTests()

            await mintNFT(NFT, MFNFT.address, tokenId);

            await addToken(MFNFT, NFT.address, tokenId, totalSupply)
        });

        it("should emit event for token addition", async () => {
            const { MFNFT, NFT } = await setupTests()

            await mintNFT(NFT, MFNFT.address, tokenId);

            await expect(
                addToken(MFNFT, NFT.address, tokenId, totalSupply)
            ).to.emit(MFNFT, "TokenAddition").withArgs(NFT.address, tokenId, 1, totalSupply)
        });

        it("should revert if given parentNFTContractAddress is zero", async () => {
            const { MFNFT } = await setupTests()

            await expect(
                addToken(MFNFT, AddressZero, tokenId, totalSupply)
            ).to.be.revertedWith("MFNFT::setParentNFT: Parent NFT Contract should not be zero")
        });

        it("should revert if given parentNFTContractAddress doesn't support ERC-721", async() => {
            const { MFNFT } = await setupTests();
            const FT = await deployFTContract(totalSupply);

            await expect (
                addToken(MFNFT, FT.address, tokenId, totalSupply)
            ).to.be.reverted
        });

        it("should revert if setParentNFT() is called twice for the same NFT", async () => {
            const { MFNFT, NFT } = await setupTests()

            await setMFNFTwithNFT(MFNFT, NFT, tokenId, totalSupply);

            await expect(
                addToken(MFNFT, NFT.address, tokenId, totalSupply)
            ).to.be.revertedWith("MFNFT::setParentNFT: Already owned(fractionalized) by this contract")
        });

        it("should return true if NFT is owned & registered by MNFTContract -> isRegistered()", async () => {
            const { MFNFT, NFT } = await setupTests()

            await setMFNFTwithNFT(MFNFT, NFT, tokenId, totalSupply);

            expect(await MFNFT.isRegistered(NFT.address, tokenId)).to.be.eq(true)
        });

        it("should check if parentTokenContractAddress is set right", async () => {
            const { MFNFT, NFT } = await setupTests()

            await setMFNFTwithNFT(MFNFT, NFT, tokenId, totalSupply)

            expect(await MFNFT.parentToken(scalar_tokenId)).to.be.eq(NFT.address)
        });

        it("should check if parentTokenId is set right", async () => {
            const { MFNFT, NFT } = await setupTests()

            await setMFNFTwithNFT(MFNFT, NFT, tokenId, totalSupply)

            expect(await MFNFT.parentTokenId(scalar_tokenId)).to.be.eq(tokenId)
        });

        it("should check if totalSupply complys with designated value", async () => {
            const { MFNFT, NFT } = await setupTests()

            await setMFNFTwithNFT(MFNFT, NFT, tokenId, totalSupply)

            expect(await MFNFT.totalSupply(scalar_tokenId)).to.be.equal(totalSupply)
        });
        it("should check if _id is a scalar value that increases when token is added", async () => {
            const { MFNFT, NFT } = await setupTests()

            await setMFNFTwithNFT(MFNFT, NFT, tokenId, totalSupply)

            const _id = await MFNFT.getTokenId(NFT.address, tokenId);

            await setMFNFTwithNFT(MFNFT, NFT, tokenId+1, totalSupply)

            expect(await MFNFT.getTokenId(NFT.address, tokenId+1)).to.be.equal(BigNumber.from(_id).add(1));
        });

    });

    describe("Admin", async () => {

        it("should check if admin can add new token", async () => {
            const { MFNFT, NFT } = await setupTests()

            await mintNFT(NFT, MFNFT.address, tokenId)

            await addToken(MFNFT, NFT.address, tokenId, totalSupply, {from: admin});
        });

        it("should revert if non-admin tries to add token", async () => {
            const { MFNFT, NFT } = await setupTests()

            await mintNFT(NFT, MFNFT.address, tokenId)

            await expect(
                addToken(MFNFT, NFT.address, tokenId, totalSupply, {from: user1})
            ).to.be.reverted
        });

    });

    describe("onERC721Received", async () => {

        it("should be able to accept ERC-721 token with safeTransferFrom()", async () => {
            const { MFNFT, NFT } = await setupTests()

            await mintNFT(NFT, admin.address, tokenId)

            expect(
                await safeTransferFrom(NFT, admin.address, MFNFT.address, tokenId)
            ).to.emit(NFT, "Transfer").withArgs(admin.address, MFNFT.address, tokenId)

            expect(await NFT.ownerOf(tokenId)).to.be.equal(MFNFT.address)
        });

        it("should return expected value for onERC721Received()", async () => {
            const { MFNFT } = await setupTests()
            expect(await MFNFT.onERC721Received(admin.address, user1.address, tokenId, 0x0)).to.be.equal("0x150b7a02")
        });

        it("should return true if supportsInterface() receives supporting interface ID", async () => {
            const { MFNFT } = await setupTests()
            expect(await MFNFT.supportsInterface(0x01ffc9a7)).to.be.equal(true)
        })

    });

    describe("Transfer & Allowance", async () => {

        const approvedValue = 100;

        it("should transfer exact amount of share to recipient", async () => {
            const { MFNFT, NFT } = await setupTests()

            const transferAmount = 100;

            await setMFNFTwithNFT(MFNFT, NFT, tokenId, totalSupply)

            await expect(
                transfer(MFNFT, user1.address, scalar_tokenId, transferAmount)
            ).to.emit(MFNFT, "Transfer").withArgs(admin.address, user1.address, scalar_tokenId, transferAmount)

            expect(await balanceOf(MFNFT, user1.address, scalar_tokenId)).to.be.equal(transferAmount)
        });

        it("should not be able to transfer more than balance", async () => {
            const { MFNFT, NFT } = await setupTests()

            const transferAmount = 100;

            await setMFNFTwithNFT(MFNFT, NFT, tokenId, totalSupply)

            await expect(
                transfer(MFNFT, user1.address, scalar_tokenId, transferAmount + totalSupply)
            ).to.be.reverted
        });

        it("should revert when trying to transfer to address zero", async () => {
            const { MFNFT, NFT } = await setupTests()

            const transferAmount = 100;

            await setMFNFTwithNFT(MFNFT, NFT, tokenId, totalSupply)

            await expect(
                transfer(MFNFT, AddressZero, scalar_tokenId, transferAmount)
            ).to.be.reverted
        });

        it("should check if approved user can spend on behalf", async () => {
            const { MFNFT, NFT } = await setupTests()
            
            const spender = user1;

            await setMFNFTwithNFT(MFNFT, NFT, tokenId, totalSupply)

            await expect(
                approve(MFNFT, spender.address, scalar_tokenId, approvedValue)
            ).to.emit(MFNFT, "Approval").withArgs(admin.address, spender.address, scalar_tokenId, approvedValue)
            
            await expect(
                transferFrom(MFNFT, admin.address, user2.address, scalar_tokenId, approvedValue, {from: spender})
            ).to.emit(MFNFT, "Transfer").withArgs(admin.address, user2.address, scalar_tokenId, approvedValue)
        });

        it("should revert if user tries to approve address zero", async () => {
            const { MFNFT, NFT } = await setupTests()
            
            const spender = AddressZero;

            await setMFNFTwithNFT(MFNFT, NFT, tokenId, totalSupply)

            await expect(
                approve(MFNFT, spender, scalar_tokenId, approvedValue)
            ).to.be.reverted
        });

        it("should revert if user tries to use over approved amount", async () => {
            const { MFNFT, NFT } = await setupTests()
            
            const spender = user1;

            await setMFNFTwithNFT(MFNFT, NFT, tokenId, totalSupply)

            await expect(
                approve(MFNFT, spender.address, scalar_tokenId, approvedValue)
            ).to.emit(MFNFT, "Approval").withArgs(admin.address, spender.address, scalar_tokenId, approvedValue)
            
            await expect(
                transferFrom(MFNFT, admin.address, user2.address, scalar_tokenId, approvedValue+100, {from: spender})
            ).to.be.reverted
        });

        it("should be able to increase allowance", async () => {
            const { MFNFT, NFT } = await setupTests()
            
            const spender = user1;

            await setMFNFTwithNFT(MFNFT, NFT, tokenId, totalSupply)

            await expect(
                approve(MFNFT, spender.address, scalar_tokenId, approvedValue)
            ).to.emit(MFNFT, "Approval").withArgs(admin.address, spender.address, scalar_tokenId, approvedValue)
            
            await expect(
                increaseAllowance(MFNFT, spender.address, scalar_tokenId, approvedValue)
            ).to.emit(MFNFT, "Approval").withArgs(admin.address, spender.address, scalar_tokenId, approvedValue * 2)

            expect(await MFNFT.allowance(admin.address, spender.address, tokenId)).to.be.equal(approvedValue * 2)
        });

        it("should revert if user tries to increase allowance for address zero", async () => {
            const { MFNFT, NFT } = await setupTests()
            
            const spender = AddressZero;

            await setMFNFTwithNFT(MFNFT, NFT, tokenId, totalSupply)

            await expect(
                increaseAllowance(MFNFT, AddressZero, scalar_tokenId, approvedValue * 2)
            ).to.be.reverted

            expect(await MFNFT.allowance(admin.address, AddressZero, tokenId)).to.be.equal(0)
        })

        it("should be able to decrease allowance", async () => {
            const { MFNFT, NFT } = await setupTests()
            
            const spender = user1;

            await setMFNFTwithNFT(MFNFT, NFT, tokenId, totalSupply)

            await expect(
                approve(MFNFT, spender.address, scalar_tokenId, approvedValue)
            ).to.emit(MFNFT, "Approval").withArgs(admin.address, spender.address, scalar_tokenId, approvedValue)
            
            await expect(
                decreaseAllowance(MFNFT, spender.address, scalar_tokenId, approvedValue / 2)
            ).to.emit(MFNFT, "Approval").withArgs(admin.address, spender.address, scalar_tokenId, approvedValue / 2)

            expect(await MFNFT.allowance(admin.address, spender.address, tokenId)).to.be.equal(approvedValue / 2)
        });

        it("should revert if user tries to decrease allowance more than approved", async () => {
            const { MFNFT, NFT } = await setupTests()
            
            const spender = user1;

            await setMFNFTwithNFT(MFNFT, NFT, tokenId, totalSupply)

            await expect(
                approve(MFNFT, spender.address, scalar_tokenId, approvedValue)
            ).to.emit(MFNFT, "Approval").withArgs(admin.address, spender.address, scalar_tokenId, approvedValue)
            
            await expect(
                decreaseAllowance(MFNFT, spender.address, scalar_tokenId, approvedValue * 2)
            ).to.be.reverted

            expect(await MFNFT.allowance(admin.address, spender.address, tokenId)).to.be.equal(approvedValue)
        })

        it("should revert if user tries to decrease allowance for address zero", async () => {
            const { MFNFT, NFT } = await setupTests()
            
            const spender = AddressZero;

            await setMFNFTwithNFT(MFNFT, NFT, tokenId, totalSupply)

            await expect(
                decreaseAllowance(MFNFT, AddressZero, scalar_tokenId, approvedValue)
            ).to.be.reverted

            expect(await MFNFT.allowance(admin.address, AddressZero, tokenId)).to.be.equal(0)
        })
    });

});