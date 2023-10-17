const { expect } = require("chai");
const { ethers } = require("hardhat");

describe('Compile: Test charity donation configuration ', function() {
    before(async function() {
        [owner, user, charity1, charity2, charity3, user2]= await ethers.getSigners();
    });
    it("Deploy contract ", async function() {
        charityTokenContract = await ethers.getContractFactory("CharityToken");
        charity = await charityTokenContract.deploy();
        decimals = await charity.decimals();

        console.log("CharityToken Contract : ", await charity.address);
        console.log("Owner : ", owner.address);
        console.log("User : ", user.address);
        console.log("User2 : ", user2.address);
        console.log("Charity 1 : ", charity1.address);
        console.log("Charity 2 : ", charity2.address);
        console.log("Charity 3 : ", charity3.address);
    });

    it("Owner: Whitelist a charity address ", async function () {
        const amount_send= 10000;
        const amnt = ethers.utils.parseEther(amount_send.toString());
        await charity.mint(user.address,amnt.toString() );

        await charity.addToWhitelist(charity1.address);

        //console.log((await charity.whitelistedRate(charity1)).toString());

        expect(await charity.whitelistedRate(charity1.address)).to.equal( 10, "Failed to store defaultRate");
        
        await charity.addToWhitelist(charity2.address);
    });

    it("Owner: custom rate for charity address ", async function () {

        await charity.setSpecificRate(charity2.address,200);
        expect(await charity.whitelistedRate(charity2.address)).to.equal( 200, "Failed to custom ate");
    });

    it("Fails: User Whitelist a charity address ", async function () {
        await expect(charity.connect(user).addToWhitelist(charity1.address)).to.be.revertedWith( "Ownable: caller is not the owner");
    });

    it("User: custom rate for default charity ", async function () {
        expect(await charity.connect(user).specificDefaultAddress()).to.equal('0x0000000000000000000000000000000000000000',"The address isn't set yet it should be 0x0000000000000000000000000000000000000000 ");
        //console.log("default charity adress" , await charity.connect(user).specificDefaultAddress());
        //set
        await charity.connect(user).setSpecificDefaultAddressAndRate(charity1.address,20); //rate is set to 2% for charity1
        expect(await charity.connect(user).specificDefaultAddress()).to.equal(charity1.address,"The address isn't set to charity1 ");
        //console.log("default charity adress" , await charity.connect(user).specificDefaultAddress());
    });

    it("Fails: User Whitelist a charity address that is not whitelisted ", async function () {
        await  expect(charity.connect(user).setSpecificDefaultAddressAndRate(charity3.address,20)).to.be.revertedWith( "ERC20Charity: invalid whitelisted address");
    });

    it("Fails: User Whitelist a charity address with an insufficient rate", async function () {
        await  expect(charity.connect(user).setSpecificDefaultAddressAndRate(charity1.address,5)).to.be.revertedWith( "ERC20Charity: rate fee must exceed default rate");
        await  expect(charity.connect(user).setSpecificDefaultAddressAndRate(charity2.address,100)).to.be.revertedWith( "ERC20Charity: rate fee must exceed the fee set by the owner");
    });

    it("User: transfer an amount to charity when token is transferred", async function () {
        const amount_send= 100;
        const amnt = ethers.utils.parseEther(amount_send.toString());
        await charity.connect(user).transfer(user2.address,amnt); //default address is charity1 with 2% rate

        console.log("user 1 balance: " + (await charity.balanceOf(user.address)/ (10 ** decimals)));
        console.log("user 2 balance: " + (await charity.balanceOf(user2.address)/ (10 ** decimals)));
        console.log("charity 1 balance: " + (await charity.balanceOf(charity1.address)/ (10 ** decimals)));
        expect(await charity.balanceOf(charity1.address)/ (10 ** decimals)).to.equal( 0.2, "Failed : charity balance should be increased to 0.2");

    });

    it("User: transfer (from) an amount to charity when token is transferred", async function () {
        const amount_send= 100;
        const amnt = ethers.utils.parseEther(amount_send.toString());
        await charity.connect(user).approve(owner.address,amnt);
        await charity.connect( owner).transferFrom(user.address,user2.address,amnt);

        console.log("user 1 balance: " + (await charity.balanceOf(user.address)/ (10 ** decimals)));
        console.log("user 2 balance: " + (await charity.balanceOf(user2.address)/ (10 ** decimals)));
        console.log("charity 1 balance: " + (await charity.balanceOf(charity1.address)/ (10 ** decimals)));
        expect(await charity.balanceOf(charity1.address)/ (10 ** decimals)).to.equal( 0.4, "Failed : charity balance should be increased to 0.4");
    });

    it("User: User deactivate/activate donation", async function () {
        //deactivate donnation
        await charity.connect(user).deleteDefaultAddress();
        expect(await charity.connect(user).specificDefaultAddress()).to.equal( '0x0000000000000000000000000000000000000000', "Failed : address shloud be null");

        //try to transfer now
        const amount_send= 100;
        const amnt = ethers.utils.parseEther(amount_send.toString());
        await charity.connect(user).transfer(user2.address,amnt);

        //console.log("user 1 balance: " + (await charity.balanceOf(user.address)/ (10 ** decimals)));
        //console.log("user 2 balance: " + (await charity.balanceOf(user2.address)/ (10 ** decimals)));
        //console.log("charity 1 balance: " + (await charity.balanceOf(charity1.address)/ (10 ** decimals)));
        //the default address of user1 is no longer whitelisted , the donation shouldn't happen.
        expect(await charity.balanceOf(charity1.address)/ (10 ** decimals)).to.equal( 0.4, "Failed : charity balance should be of 0.4");
        
        //activate donnation and transfer
        await charity.connect(user).setSpecificDefaultAddressAndRate(charity1.address,20); //rate is reset to 2% for charity1
        console.log("custom rate changed", (await charity.connect(user).getRate()).toString());
        await charity.connect(user).transfer(user2.address,amnt);

        //console.log("user 1 balance: " + (await charity.balanceOf(user.address)/ (10 ** decimals)));
        //console.log("user 2 balance: " + (await charity.balanceOf(user2.address)/ (10 ** decimals)));
        //console.log("charity 1 balance: " + (await charity.balanceOf(charity1.address)/ (10 ** decimals)));
        
        expect(await charity.balanceOf(charity1.address)/ (10 ** decimals)).to.equal( 0.6, "Failed : charity balance should be of 0.6");
        
    });

    it("Owner: delete charity ", async function () {
        await charity.deleteFromWhitelist(charity1.address);
        //console.log("Charity 1 rate: "(await charity.whitelistedRate.call(charity1)).toString());
        expect(await charity.whitelistedRate(charity1.address)).to.equal(0, "Failed to delete defaultRate for charity");

        //try to transfer now
        const amount_send= 100;
        const amnt = ethers.utils.parseEther(amount_send.toString());
        await charity.connect(user).transfer(user2.address,amnt);

        console.log("user 1 balance: " + (await charity.balanceOf(user.address)/ (10 ** decimals)));
        console.log("user 2 balance: " + (await charity.balanceOf(user2.address)/ (10 ** decimals)));
        console.log("charity 1 balance: " + (await charity.balanceOf(charity1.address)/ (10 ** decimals)));
        //the default address of user1 is no longer whitelisted , the donation shouldn't happen.
        expect(await charity.balanceOf(charity1.address)/ (10 ** decimals)).to.equal( 0.6, "Failed : charity balance should be of 0.6");
    });

    it("Interface test ", async function () {
        // const support = await charity.checkInterface.call(charity.address);
        const support = await charity.callStatic.checkInterface(charity.address); // to correct
        //console.log(typeof support);
        console.log(support);
        expect(support).to.equal( true);                                                                                          

        // see if the charity address is whitelisted
        const info1 = await charity.charityInfo(charity1.address);
        const info2 = await charity.charityInfo(charity2.address);

        console.log("charity 1: ",info1[0],info1[1].toString());

        expect(info1[0]).to.equal( false, "Failed : charity should'nt be whitelisted");
        expect(info1[1]).to.equal( 0, "Failed : charity rate should be null");

        console.log("charity 2: ",info2[0],info2[1].toString());

        expect(info2[0]).to.equal( true, "Failed : charity should be whitelisted");
        expect(info2[1]).to.equal( 200, "Failed : charity rate should be set to 200 (2%)");

    });

    it("Charity list (add/delete) test ", async function () {
        await charity.addToWhitelist(charity1.address);
        await charity.addToWhitelist(charity3.address);

        listAddr = await charity.getAllWhitelistedAddresses();
        console.log(listAddr);

        await charity.deleteFromWhitelist(charity1.address);
        console.log( await charity.getAllWhitelistedAddresses());

        await charity.deleteFromWhitelist(charity2.address);
        console.log( await charity.getAllWhitelistedAddresses());

        await charity.deleteFromWhitelist(charity3.address);
        console.log( await charity.getAllWhitelistedAddresses());
    });
});
