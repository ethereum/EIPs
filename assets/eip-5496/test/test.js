const { assert } = require("chai");
const { expectRevert } = require('@openzeppelin/test-helpers');

const ERC5496Demo = artifacts.require("ERC5496Demo");

contract("ERC5496", async accounts => {
    const Alice = accounts[0];
    const Bob = accounts[1];
    const Tom = accounts[2];
    let demoContract;

    before(async function() {
        const instance = await ERC5496Demo.deployed("ERC5496Demo", "EPD");
        demoContract = instance;
        await demoContract.mint(1, Alice);
        await demoContract.mint(2, Alice);
        await demoContract.mint(3, Alice);
        await demoContract.increasePrivileges(false);
        await demoContract.increasePrivileges(false);
    })

    it("Should set privilege 0 to Bob", async () => {
        let expires = Math.floor(new Date().getTime()/1000) + 5000;
        await demoContract.setPrivilege(1, 0, Bob, BigInt(expires));

        let user_hasP0 = await demoContract.hasPrivilege(1, 0, Bob);
        assert.equal(
            user_hasP0,
            true,
            "Privilege 0 of NFT 1 should be Bob"
        );
    });

    it("Privilege should belong to the owner by default", async () => {
        let owner_1 = await demoContract.ownerOf(1);
        assert.equal(
            owner_1,
            Alice ,
            "Owner of NFT 1 should be Alice"
        );
        let user_hasP1 = await demoContract.hasPrivilege(1, 1, Alice);
        assert.equal(
            user_hasP1,
            true,
            "Privilege 1 of NFT 1 should be Alice"
        );
    });

    it("The privilege holder is allowed to transfer the privilege to others", async () => {
        let expires = Math.floor(new Date().getTime()/1000) + 5000;
        await demoContract.setPrivilege(2, 0, Bob, BigInt(expires));
        let user_hasP0 = await demoContract.hasPrivilege(2, 0, Bob);
        assert.equal(
            user_hasP0,
            true,
            "Privilege 0 of NFT 2 should be Bob"
        );
        await demoContract.setPrivilege(2, 0, Tom, BigInt(expires + 100), { from: Bob })
        user_hasP0 = await demoContract.hasPrivilege(2, 0, Tom);
        assert.equal(
            user_hasP0,
            true,
            "Privilege 0 of NFT 2 should be Tom"
        );
        let privilege_info = await demoContract.getPrivilegeInfo(2, 0);
        assert.equal(
            privilege_info.expiresAt,
            expires,
            "Only owner can set the expiresAt"
        )
    });

    it("User is allowed to transfer NFT while privileges on renting", async () => {
        await demoContract.transferFrom(Alice, Bob, 1);
        let owner_1 = await demoContract.ownerOf(1);
        assert.equal(
            owner_1,
            Bob,
            "Owner of NFT 1 should be Bob"
        );
        let expires = Math.floor(new Date().getTime()/1000) + 1000;
        await demoContract.setPrivilege(1, 1, Tom, BigInt(expires), { from: Bob });
        let user_hasP1 = await demoContract.hasPrivilege(1, 1, Tom);
        assert.equal(
            user_hasP1,
            true,
            "Bob should be allowed to set the unassigned privilege to Tom"
        );
    });

    it("NFT owner may change the privileges total for each tokenId", async () => {
        await demoContract.increasePrivileges(false);
        let owner_1 = await demoContract.ownerOf(1);
        let user_hasP2 = await demoContract.hasPrivilege(1, 2, owner_1);
        assert.equal(
            user_hasP2,
            true,
            "privilege 2 available after NFT owner update the privilege total"
        );
    });

    it("NFT owner should not change the privilege if it has been assigned", async () => {
        let expires = Math.floor(new Date().getTime()/1000) + 5000;
        await demoContract.setPrivilege(3, 0, Bob, BigInt(expires));
        await expectRevert(
            demoContract.setPrivilege(3, 0, Tom, BigInt(expires)),
            "ERC721: transfer caller is not owner nor approved",
        );
    });
    
    it("NFT should support interface IERC5496", async () => {
        const interfaceIds = {
            IERC165: "0x01ffc9a7",
            IERC721: "0x80ac58cd",
            IERC5496: "0x076e1bbb",
        }
        for(let interfaceName in interfaceIds) {
            let isSupport = await demoContract.supportsInterface(interfaceIds[interfaceName]);
            assert.equal(isSupport, true, "NFT should support interface "+interfaceName);
        }
    })
});
