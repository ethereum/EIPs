import { expect } from "chai";
import { ethers } from "hardhat";
import hre from "hardhat";

describe("Test 1155 User Role", function () {
    let alice, bob, carl;
    let contract;
    let expiry;

    async function checkRecord(rid,tokenId,amount,owner,user,expiry_) {
        let record = await contract.userRecordOf(rid);
            expect(record[0]).equals(tokenId,"tokenId");
            expect(record[1]).equals(owner,"owner");
            expect(record[2]).equals(amount,"amount");
            expect(record[3]).equals(user,"user");
            expect(record[4]).equals(expiry_,"expiry_");
    }

    beforeEach(async function () {
        [alice, bob, carl] = await ethers.getSigners();

        const ERC5006Demo = await ethers.getContractFactory("ERC5006Demo");

        contract = await ERC5006Demo.deploy("", 3);

        expiry = Math.floor(new Date().getTime() / 1000) + 3600;
    });

    

    describe("", function () {
        
        it("InterfaceId should equals 0xc26d96cc", async function () {
            expect(await contract.getInterfaceId()).equals("0xc26d96cc");
        });

        it("Should set user to bob success", async function () {

            await contract.mint(alice.address, 1, 100);

            await contract.createUserRecord(alice.address, bob.address, 1, 10, expiry);

            await checkRecord(1,1,10,alice.address,bob.address,expiry);

            expect(await contract.usableBalanceOf(bob.address, 1)).equals(10);

            expect(await contract.balanceOf(alice.address, 1)).equals(90);

            expect(await contract.frozenBalanceOf(alice.address, 1)).equals(10);

        });

        it("Should set user to bob fail", async function () {

            await contract.mint(alice.address, 1, 100);

            await contract.createUserRecord(alice.address, bob.address, 1, 10, expiry);
            await contract.createUserRecord(alice.address, bob.address, 1, 10, expiry);
            await contract.createUserRecord(alice.address, bob.address, 1, 10, expiry);
            await expect(contract.createUserRecord(alice.address, bob.address, 1, 10, expiry)).to.be.revertedWith("user cannot have more records");

        });

        it("Should set user to bob fail : balance is not enough", async function () {

            await contract.mint(alice.address, 1, 100);

            await expect(contract.createUserRecord(alice.address, bob.address, 1, 101, expiry)).to.be.revertedWith('ERC1155: insufficient balance for transfer');

        });

        it("Should set user to bob fail : only owner or approved", async function () {

            await contract.mint(alice.address, 1, 100);
            await contract.mint(carl.address, 1, 100);

            await expect(contract.createUserRecord(carl.address, bob.address, 1, 110, expiry)).to.be.revertedWith('only owner or approved');

        });

        it("Should deleteUserRecord success", async function () {

            await contract.mint(alice.address, 1, 100);

            await contract.createUserRecord(alice.address, bob.address, 1, 10, expiry);

            // await hre.network.provider.send("hardhat_mine", ["0x5a0", "0x3c"]);

            await contract.deleteUserRecord(1);

            await checkRecord(1,0,0,"0x0000000000000000000000000000000000000000","0x0000000000000000000000000000000000000000",0);

            expect(await contract.usableBalanceOf(bob.address, 1)).equals(0);

            expect(await contract.balanceOf(alice.address, 1)).equals(100);

            expect(await contract.frozenBalanceOf(alice.address, 1)).equals(0);

        });


        it("bob should deleteUserRecord fail", async function () {

            await contract.mint(alice.address, 1, 100);

            await contract.createUserRecord(alice.address, bob.address, 1, 10, expiry);

            await expect(contract.connect(bob).deleteUserRecord(1)).to.be.revertedWith("only owner or approved");

        });


    });


});
