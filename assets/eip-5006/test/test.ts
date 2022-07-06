import { expect } from "chai";
import { ethers } from "hardhat";

describe("Test ERC5006", function () {
    let alice, bob, carl;
    let contract;

    beforeEach(async function () {
        [alice, bob, carl] = await ethers.getSigners();

        const ERC5006Demo = await ethers.getContractFactory("ERC5006Demo");

        contract = await ERC5006Demo.deploy();
    });

    describe("", function () {
        it("Should set user to bob", async function () {

            await contract.mint(alice.address, 1, 100);

            const interfaceId = await contract.getInterfaceId();
            expect(interfaceId).equals('0x208994f8');

            await contract.setUser(alice.address, bob.address, 1, 10);

            expect(await contract.balanceOfUser(bob.address, 1)).equals(10);

            expect(await contract.balanceOfUserFromOwner(bob.address, alice.address, 1)).equals(10);

            expect(await contract.frozenAmountOfOwner(alice.address, 1)).equals(10);

            await contract.setUser(alice.address, bob.address, 1, 80);

            expect(await contract.balanceOfUser(bob.address, 1)).equals(80);

            expect(await contract.balanceOfUserFromOwner(bob.address, alice.address, 1)).equals(80);

            expect(await contract.frozenAmountOfOwner(alice.address, 1)).equals(80);

            await contract.setUser(alice.address, bob.address, 1, 0);

            expect(await contract.balanceOfUser(bob.address, 1)).equals(0);

            expect(await contract.balanceOfUserFromOwner(bob.address, alice.address, 1)).equals(0);

            expect(await contract.frozenAmountOfOwner(alice.address, 1)).equals(0);

        });

        it("Should transfer success", async function () {

            await contract.mint(alice.address, 1, 100);

            await contract.setUser(alice.address, bob.address, 1, 10);

            await contract.safeTransferFrom(alice.address, carl.address, 1, 90, "0x");

            expect(await contract.balanceOfUser(bob.address, 1)).equals(10);

            expect(await contract.balanceOfUserFromOwner(bob.address, alice.address, 1)).equals(10);

            expect(await contract.frozenAmountOfOwner(alice.address, 1)).equals(10);

            expect(await contract.balanceOf(alice.address, 1)).equals(10);

        });

        it("Should burn success", async function () {

            await contract.mint(alice.address, 1, 100);

            await contract.setUser(alice.address, bob.address, 1, 10);

            await contract.burn(alice.address, 1, 90);

            expect(await contract.balanceOfUser(bob.address, 1)).equals(10);

            expect(await contract.balanceOfUserFromOwner(bob.address, alice.address, 1)).equals(10);

            expect(await contract.frozenAmountOfOwner(alice.address, 1)).equals(10);

            expect(await contract.balanceOf(alice.address, 1)).equals(10);
        });

    });
});
