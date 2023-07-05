const { assert } = require("chai");

const ERC4907Demo = artifacts.require("ERC4907Demo");

contract("test", async (accounts) => {
  it("should set user to Bob", async () => {
    // Get initial balances of first and second account.
    const Alice = accounts[0];
    const Bob = accounts[1];

    const instance = await ERC4907Demo.deployed("T", "T");
    const demo = instance;

    await demo.mint(1, Alice);
    let expires = Math.floor(new Date().getTime() / 1000) + 1000;
    await demo.setUser(1, Bob, BigInt(expires));

    let user_1 = await demo.userOf(1);

    assert.equal(user_1, Bob, "User of NFT 1 should be Bob");

    let owner_1 = await demo.ownerOf(1);
    assert.equal(owner_1, Alice, "Owner of NFT 1 should be Alice");
  });
});
