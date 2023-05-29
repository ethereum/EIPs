const { assert } = require("chai");

const { BigNumber } = require("bignumber.js")

const ERC5007Demo = artifacts.require("ERC5007Demo");
const ERC5007ComposableTest = artifacts.require("ERC5007ComposableTest");

contract("test ERC5007", async accounts => {

    it("test ERC5007", async () => {
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


        console.log("IERC5007 InterfaceId:", await demo.getInterfaceId())
        let isSupport = await demo.supportsInterface('0x7a0cdf92');
        assert.equal(isSupport, true , "supportsInterface error");
        
    });

    it("test ERC5007Composable", async () => {
        const Alice = accounts[0];
        const Bob = accounts[1];
        const Carl = accounts[2];

        const instance = await ERC5007ComposableTest.deployed("ERC5007ComposableTest", "ERC5007ComposableTest");
        const demo = instance;

        let now = Math.floor(new Date().getTime()/1000);
        let token1InputStartTime =  new BigNumber(now - 10000);
        let token1InputEndTime = new BigNumber(now + 10000);
        let id1 = 1;
        let assetId = 1000;

        console.log("mint NFT:")
        await demo.mint(Alice, id1, assetId, token1InputStartTime.toFixed(0),
         token1InputEndTime.toFixed(0));

        let token1OutputStartTime = new BigNumber( await demo.startTime(id1));
        let token1OutputEndTime = new BigNumber( await demo.endTime(id1));
        let token1assetId = new BigNumber( await demo.assetId(id1));
        assert.equal(token1InputStartTime.comparedTo(token1OutputStartTime) == 0
        && token1InputEndTime.comparedTo(token1OutputEndTime) == 0 
        && token1assetId.comparedTo(assetId) == 0,
         true, "wrong data");

        let id2 = 2;
        let id3 = 3;
        let splitTime = token1InputStartTime.plus(5000);
        console.log("split NFT:")
        await demo.split(id1, id2, Bob, id3, Carl, splitTime.toFixed(0));

        let token2StartTime = new BigNumber( await demo.startTime(id2));
        let token2EndTime = new BigNumber( await demo.endTime(id2));

        let token3StartTime = new BigNumber( await demo.startTime(id3));
        let token3EndTime = new BigNumber( await demo.endTime(id3));

        assert.equal(token1InputStartTime.comparedTo(token2StartTime) == 0
        && token2EndTime.comparedTo(splitTime) == 0, true, "wrong data");

        assert.equal(token3StartTime.comparedTo(splitTime.plus(1)) == 0
        && token3EndTime.comparedTo(token1InputEndTime) == 0, true, "wrong data");

        let token2assetId = await demo.assetId(id2);
        let token3assetId = await demo.assetId(id3);
        assert.equal(token2assetId == assetId && token3assetId == assetId, true, 'wrong data');
    
        
        console.log("merge NFT:")
        let id4 = 4;
        await demo.setApprovalForAll(Alice, true,{from: Bob});
        await demo.setApprovalForAll(Alice, true,{from: Carl});
        await demo.merge(id2, id3, Alice, id4);

        let token4StartTime = new BigNumber( await demo.startTime(id4));
        let token4EndTime = new BigNumber( await demo.endTime(id4));
        let token4assetId = await demo.assetId(id4);
        let token4Owner = await demo.ownerOf(id4);

        assert.equal(token1InputStartTime.comparedTo(token4StartTime) == 0
        && token4EndTime.comparedTo(token1InputEndTime) == 0, true, "wrong start time or end time");

        assert.equal(token4assetId == assetId, true, 'wrong rootId');
        assert.equal(token4Owner == Alice, true, 'wrong owner');
        

        console.log("IERC5007Composable InterfaceId:", await demo.getInterfaceId())
        let isSupport = await demo.supportsInterface('0x75cf3842');
        assert.equal(isSupport, true , "supportsInterface error");
    });

});
