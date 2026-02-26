// Right click on the script name and hit "Run" to execute
const { expect } = require("chai");
const { ethers } = require("hardhat");

const TOKEN_NAME = "ERC_5521_NAME";
const TOKEN_SYMBOL = "ERC_5521_SYMBOL";
const TOKEN_NAME1 = "ERC_5521_NAME1";
const TOKEN_SYMBOL1 = "ERC_5521_SYMBOL1";
const TOKEN_NAME2 = "ERC_5521_NAME2";
const TOKEN_SYMBOL2 = "ERC_5521_SYMBOL2";

function tokenIds2Number(tokenIds) {
    return tokenIds.map(tIds => tIds.map(tId => tId.toNumber()));
}

function assertRelationship(rel, tokenAddresses, tokenIds) {
    expect(rel[0]).to.deep.equal(tokenAddresses);
    expect(tokenIds2Number(rel[1])).to.deep.equal(tokenIds);
}

describe("ERC_5521 - single token contract scenario", function () {
    let tokenContract1;

    beforeEach(async () => {
        const RNFT = await ethers.getContractFactory("ERC_5521");
        const rNFT = await RNFT.deploy(TOKEN_NAME,TOKEN_SYMBOL);
        await rNFT.deployed();
        console.log('ERC_5521 deployed at:'+ rNFT.address);
        tokenContract1 = rNFT;
    });

    it("should report correct token name and symbol", async function () {
        expect((await tokenContract1.symbol())).to.equal(TOKEN_SYMBOL);
        expect((await tokenContract1.name())).to.equal(TOKEN_NAME);
    });

    it("can mint a token with empty referredOf and referringOf", async function () {
        await tokenContract1.safeMint(1, [], []);
        assertRelationship(await tokenContract1.referredOf(tokenContract1.address, 1), [], []);
        assertRelationship(await tokenContract1.referringOf(tokenContract1.address, 1), [], []);
    })

    it("cannot query relationships of a non-existent token", async function () {
        const mintToken1Tx = await tokenContract1.safeMint(1, [], []);
        // mint tx of token 1 must be mined before it can be referred to
        await mintToken1Tx.wait();
        // wait 1 sec to ensure that token 2 is minted at a later block timestamp (block timestamp is in second)
        await new Promise(r => setTimeout(r, 1000));
        await tokenContract1.safeMint(2, [tokenContract1.address], [[1]]);

        // tokenContract1 didn't mint any token with id 3
        await expect(tokenContract1.referringOf(tokenContract1.address, 3)).to.be.revertedWith("token ID not existed");
        await expect(tokenContract1.referredOf(tokenContract1.address, 3)).to.be.revertedWith("token ID not existed");
    })

    it("must not mint two tokens with the same token id", async function () {
        await tokenContract1.safeMint(1, [], []);
        await expect(tokenContract1.safeMint(1, [], [])).to.be.revertedWith("ERC721: token already minted");
    })

    it("can mint a token referring to another minted token", async function () {
        const mintToken1Tx = await tokenContract1.safeMint(1, [], []);
        // mint tx of token 1 must be mined before it can be referred to
        await mintToken1Tx.wait();
        // wait 1 sec to ensure that token 2 is minted at a later block timestamp (block timestamp is in second)
        await new Promise(r => setTimeout(r, 1000));
        await tokenContract1.safeMint(2, [tokenContract1.address], [[1]]);

        const referringOfT2 = await tokenContract1.referringOf(tokenContract1.address, 2)
        assertRelationship(referringOfT2, [tokenContract1.address], [[1]]);

        const referredOfT2 = await tokenContract1.referredOf(tokenContract1.address, 2)
        assertRelationship(referredOfT2, [], []);

        const referringOfT1 = await tokenContract1.referringOf(tokenContract1.address, 1)
        assertRelationship(referringOfT1, [], []);

        const referredOfT1 = await tokenContract1.referredOf(tokenContract1.address, 1)
        assertRelationship(referredOfT1, [tokenContract1.address], [[2]]);
    })

    it("cannot mint a token referring to a token that is not yet minted", async function () {
        await expect(tokenContract1.safeMint(2, [tokenContract1.address], [[1]])).to.be.revertedWith("invalid token ID");
    })

    it("can mint 3 tokens forming a simple DAG", async function () {
        const mintToken1Tx = await tokenContract1.safeMint(1, [], []);
        // mint tx of token 1 must be mined before it can be referred to
        await mintToken1Tx.wait();
        // wait 1 sec to ensure that token 2 is minted at a later block timestamp (block timestamp is in second)
        await new Promise(r => setTimeout(r, 1000));
        const mintToken2Tx = await tokenContract1.safeMint(2, [tokenContract1.address], [[1]]);
        await mintToken2Tx.wait();
        await new Promise(r => setTimeout(r, 1000));
        const mintToken3Tx = await tokenContract1.safeMint(3, [tokenContract1.address], [[1, 2]]);
        await mintToken3Tx.wait();

        const referringOfT2 = await tokenContract1.referringOf(tokenContract1.address, 2)
        assertRelationship(referringOfT2, [tokenContract1.address], [[1]]);

        const referredOfT2 = await tokenContract1.referredOf(tokenContract1.address, 2)
        assertRelationship(referredOfT2, [tokenContract1.address], [[3]]);

        const referringOfT1 = await tokenContract1.referringOf(tokenContract1.address, 1)
        assertRelationship(referringOfT1, [], []);

        const referredOfT1 = await tokenContract1.referredOf(tokenContract1.address, 1)
        assertRelationship(referredOfT1, [tokenContract1.address], [[2, 3]]);

        const referringOfT3 = await tokenContract1.referringOf(tokenContract1.address, 3)
        assertRelationship(referringOfT3, [tokenContract1.address], [[1, 2]]);

        const referredOfT3 = await tokenContract1.referredOf(tokenContract1.address, 3)
        assertRelationship(referredOfT3, [], []);
    })

    it("should revert when trying to create a cycle in the relationship DAG", async function () {
        const mintToken1Tx = await tokenContract1.safeMint(1, [], []);
        // mint tx of token 1 must be mined before it can be referred to
        await mintToken1Tx.wait();
        // wait 1 sec to ensure that token 2 is minted at a later block timestamp (block timestamp is in second)
        await new Promise(r => setTimeout(r, 1000));
        await tokenContract1.safeMint(2, [tokenContract1.address], [[1]]);
        await expect(tokenContract1.safeMint(1, [tokenContract1.address], [[2]])).to.be.reverted;    
    })

    it("should revert when attempting to create an invalid relationship", async function () {
        const mintToken1Tx = await tokenContract1.safeMint(1, [], []);
        // mint tx of token 1 must be mined before it can be referred to
        await mintToken1Tx.wait();
        // wait 1 sec to ensure that token 2 is minted at a later block timestamp (block timestamp is in second)
        await new Promise(r => setTimeout(r, 1000));
        // Intentionally creating an invalid relationship
        await expect(tokenContract1.safeMint(2, [tokenContract1.address], [[1, 2, 3]])).to.be.revertedWith("ERC_5521: self-reference not allowed");
        await expect(tokenContract1.safeMint(2, [tokenContract1.address], [[1, 3]])).to.be.revertedWith("invalid token ID");
        await expect(tokenContract1.safeMint(2, [tokenContract1.address], [])).to.be.revertedWith("Addresses and TokenID arrays must have the same length");
        await expect(tokenContract1.safeMint(2, [tokenContract1.address], [[]])).to.be.revertedWith("the referring list cannot be empty");
    });
});

describe("ERC_5521 - multi token contracts scenario", function () {
    let tokenContract1;
    let tokenContract2;

    beforeEach(async () => {
        const RNFT = await ethers.getContractFactory("ERC_5521");

        const rNFT1 = await RNFT.deploy(TOKEN_NAME1,TOKEN_SYMBOL1);
        await rNFT1.deployed();
        console.log('ERC_5521 deployed at:'+ rNFT1.address);
        tokenContract1 = rNFT1;

        const rNFT2 = await RNFT.deploy(TOKEN_NAME2,TOKEN_SYMBOL2);
        await rNFT2.deployed();
        console.log('ERC_5521 deployed at:'+ rNFT2.address);
        tokenContract2 = rNFT2;
    });

    it("should revert when referring and referred lists have mismatched lengths", async function () {
        await expect(tokenContract1.safeMint(1, [tokenContract1.address], [[1], [2]])).to.be.reverted;
    });

    it("can mint a token referring to another minted token", async function () {
        const mintToken1Tx = await tokenContract1.safeMint(1, [], []);
        // mint tx of token 1 must be mined before it can be referred to
        await mintToken1Tx.wait();
        // wait 1 sec to ensure that token 2 is minted at a later block timestamp (block timestamp is in second)
        await new Promise(r => setTimeout(r, 1000));
        await tokenContract2.safeMint(2, [tokenContract1.address], [[1]]);

        // relationships of token 2 can be queried using any ERC5521 contract, not necessarily the contract that minted token 2
        const referringOfT2QueriedByC1 = await tokenContract1.referringOf(tokenContract2.address, 2)
        const referringOfT2QueriedByByC2 = await tokenContract2.referringOf(tokenContract2.address, 2)
        assertRelationship(referringOfT2QueriedByC1, [tokenContract1.address], [[1]]);
        assertRelationship(referringOfT2QueriedByByC2, [tokenContract1.address], [[1]]);

        const referredOfT2QueriedByC1 = await tokenContract1.referredOf(tokenContract2.address, 2)
        const referredOfT2QueriedByC2 = await tokenContract2.referredOf(tokenContract2.address, 2)
        assertRelationship(referredOfT2QueriedByC1, [], []);
        assertRelationship(referredOfT2QueriedByC2, [], []);

        const referringOfT1QueriedByC1 = await tokenContract1.referringOf(tokenContract1.address, 1)
        const referringOfT1QueriedByC2 = await tokenContract2.referringOf(tokenContract1.address, 1)
        assertRelationship(referringOfT1QueriedByC1, [], []);
        assertRelationship(referringOfT1QueriedByC2, [], []);

        const referredOfT1QueriedByC1 = await tokenContract1.referredOf(tokenContract1.address, 1)
        const referredOfT1QueriedByC2 = await tokenContract2.referredOf(tokenContract1.address, 1)
        assertRelationship(referredOfT1QueriedByC1, [tokenContract2.address], [[2]]);
        assertRelationship(referredOfT1QueriedByC2, [tokenContract2.address], [[2]]);
    })

    it("cannot query relationships of a non-existent token", async function () {
        const mintToken1Tx = await tokenContract1.safeMint(1, [], []);
        // mint tx of token 1 must be mined before it can be referred to
        await mintToken1Tx.wait();
        // wait 1 sec to ensure that token 2 is minted at a later block timestamp (block timestamp is in second)
        await new Promise(r => setTimeout(r, 1000));
        await tokenContract2.safeMint(2, [tokenContract1.address], [[1]]);

        // tokenContract1 didn't mint any token with id 2
        await expect(tokenContract1.referringOf(tokenContract1.address, 2)).to.be.revertedWith("token ID not existed");
        await expect(tokenContract1.referredOf(tokenContract1.address, 2)).to.be.revertedWith("token ID not existed");
    })

    it("cannot mint a token referring to a token that is not yet minted", async function () {
        await expect(tokenContract2.safeMint(2, [tokenContract1.address], [[1]])).to.be.revertedWith("invalid token ID");
    })

    it("can mint 3 tokens forming a simple DAG", async function () {
        const mintToken1Tx = await tokenContract1.safeMint(1, [], []);
        // mint tx of token 1 must be mined before it can be referred to
        await mintToken1Tx.wait();
        // wait 1 sec to ensure that token 2 is minted at a later block timestamp (block timestamp is in second)
        await new Promise(r => setTimeout(r, 1000));
        const mintToken2Tx = await tokenContract2.safeMint(2, [tokenContract1.address], [[1]]);
        await mintToken2Tx.wait();
        await new Promise(r => setTimeout(r, 1000));
        const mintToken3Tx = await tokenContract2.safeMint(3, [tokenContract1.address, tokenContract2.address], [[1], [2]]);
        await mintToken3Tx.wait();

        const referringOfT2 = await tokenContract1.referringOf(tokenContract2.address, 2)
        assertRelationship(referringOfT2, [tokenContract1.address], [[1]]);

        const referredOfT2 = await tokenContract1.referredOf(tokenContract2.address, 2)
        assertRelationship(referredOfT2, [tokenContract2.address], [[3]]);

        const referringOfT1 = await tokenContract1.referringOf(tokenContract1.address, 1)
        assertRelationship(referringOfT1, [], []);

        const referredOfT1 = await tokenContract1.referredOf(tokenContract1.address, 1)
        assertRelationship(referredOfT1, [tokenContract2.address], [[2, 3]]);

        const referringOfT3 = await tokenContract1.referringOf(tokenContract2.address, 3)
        assertRelationship(referringOfT3, [tokenContract1.address, tokenContract2.address], [[1], [2]]);

        const referringOfT3fromContract2 = await tokenContract2.referringOf(tokenContract2.address, 3)
        assertRelationship(referringOfT3fromContract2, [tokenContract1.address, tokenContract2.address], [[1], [2]]);

        const referredOfT3 = await tokenContract1.referredOf(tokenContract2.address, 3)
        assertRelationship(referredOfT3, [], []);
    })

});