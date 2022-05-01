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

        
        let isValidNow =   await demo.isValidNow(id1);
    
        assert.equal(isValidNow, true, "token id1 should be valid now");
    
        let outputStartTime1 = await demo.startTime(id1);
        let outputEndTime1 = await demo.endTime(id1);
        assert.equal(inputStartTime1.comparedTo(outputStartTime1) == 0  && inputEndTime1.comparedTo(outputEndTime1) == 0, true, "wrong data");


        let inputStartTime2 = new BigNumber(now + 10);
        let inputEndTime2 = new BigNumber(now + 20);

        let id2 = 2
        await demo.mint(Alice, id2, inputStartTime2.toFixed(0), inputEndTime2.toFixed(0));
        isValidNow =   await demo.isValidNow(id2);
        assert.equal(isValidNow, false, "token id2 should not be valid now");


        let inputStartTime3 = new BigNumber(now - 10);
        let inputEndTime3 = new BigNumber(now - 5);

        let id3 = 3;
        await demo.mint(Alice, id3, inputStartTime3.toFixed(0), inputEndTime3.toFixed(0));
        isValidNow =   await demo.isValidNow(id3);
        assert.equal(isValidNow, false, "token id3 should not be valid now");

        let isSupport = await demo.supportsInterface('0x4337c836');
        assert.equal(isSupport, true , "supportsInterface error");
        
    });
});