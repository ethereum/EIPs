const {
    time,
    loadFixture,
} = require("@nomicfoundation/hardhat-network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");
const { BigNumber } = require("ethers");

async function deployVerifierFixture() {
    const Verifier = await ethers.getContractFactory("MockVerifier");
    const verifier = await Verifier.deploy();
    await verifier.deployed();
    return verifier;
}
const prompt = ethers.utils.toUtf8Bytes("test");
const aigcData = ethers.utils.toUtf8Bytes("test");
const uri = '"name": "test", "description": "test", "image": "test", "aigc_type": "test"';
const validProof = ethers.utils.toUtf8Bytes("valid");
const invalidProof = ethers.utils.toUtf8Bytes("invalid");
const tokenId = BigNumber.from("70622639689279718371527342103894932928233838121221666359043189029713682937432");

describe("ERC7007.sol", function () {

    async function deployERC7007Fixture() {
        const verifier = await deployVerifierFixture();

        const ERC7007 = await ethers.getContractFactory("ERC7007");
        const erc7007 = await ERC7007.deploy("testing", "TEST", verifier.address);
        await erc7007.deployed();
        return erc7007;
    }

    describe("mint", function () {
        it("should mint a token", async function () {
            const erc7007 = await deployERC7007Fixture();
            const [owner] = await ethers.getSigners();
            await erc7007.mint(prompt, aigcData, uri, validProof);
            expect(await erc7007.balanceOf(owner.address)).to.equal(1);
        });

        it("should not mint a token with invalid proof", async function () {
            const erc7007 = await deployERC7007Fixture();
            await expect(erc7007.mint(prompt, aigcData, uri, invalidProof)).to.be.revertedWith("ERC7007: invalid proof");
        });

        it("should not mint a token with same data twice", async function () {
            const erc7007 = await deployERC7007Fixture();
            await erc7007.mint(prompt, aigcData, uri, validProof);
            await expect(erc7007.mint(prompt, aigcData, uri, validProof)).to.be.revertedWith("ERC721: token already minted");
        });

        it("should emit a Mint event", async function () {
            const erc7007 = await deployERC7007Fixture();
            await expect(erc7007.mint(prompt, aigcData, uri, validProof))
                .to.emit(erc7007, "Mint")
        });
    });

    describe("metadata", function () {
        it("should return token metadata", async function () {
            const erc7007 = await deployERC7007Fixture();
            await erc7007.mint(prompt, aigcData, uri, validProof);
            expect(await erc7007.tokenURI(tokenId)).to.equal('{"name": "test", "description": "test", "image": "test", "aigc_type": "test", "prompt": "test", "aigc_data": "test"}');
        });
    });
});

describe("ERC7007Enumerable.sol", function () {

    async function deployERC7007EnumerableFixture() {
        const verifier = await deployVerifierFixture();

        const ERC7007Enumerable = await ethers.getContractFactory("MockERC7007Enumerable");
        const erc7007Enumerable = await ERC7007Enumerable.deploy("testing", "TEST", verifier.address);
        await erc7007Enumerable.deployed();
        await erc7007Enumerable.mint(prompt, aigcData, uri, validProof);
        return erc7007Enumerable;
    }
    
    it("should return token id by prompt", async function () {
        const erc7007Enumerable = await deployERC7007EnumerableFixture();
        expect(await erc7007Enumerable.tokenId(prompt)).to.equal(tokenId);
    });

    it("should return token prompt by id", async function () {
        const erc7007Enumerable = await deployERC7007EnumerableFixture();
        expect(await erc7007Enumerable.prompt(tokenId)).to.equal("test");
    });

});