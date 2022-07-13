const { assert } = require("chai");

const { BigNumber } = require("bignumber.js")

const ERC5007Demo = artifacts.require("ERC5007Demo");

contract("test ERC5007", async accounts => {

    it("test TimeNFT", async () => {
        const Alice = accounts[0];

        const instance = await ERC5007Demo.deployed("ERC5007Demo", "ERC5007Demo");
        const demo = instance;

        let now = Math.floor(new Date().getTime()/1000);
        let inputStartTime1 =  new BigNumber(now - 10000);
        let inputEndTime1 = new BigNumber(now + 10000);
        let id1 = 1;
        
        await demo.mint(Alice, id1, inputStartTime1.toFixed(0), inputEndTime1.toFixed(0));

    
        let outputStartTime1 = await demo.startTime(id1);
        let outputEndTime1 = await demo.endTime(id1);
        assert.equal(inputStartTime1.comparedTo(outputStartTime1) == 0  && inputEndTime1.comparedTo(outputEndTime1) == 0, true, "wrong data");


        console.log("InterfaceId:", await demo.getInterfaceId())
        let isSupport = await demo.supportsInterface('0x7a0cdf92');
        assert.equal(isSupport, true , "supportsInterface error");
        
    });
});