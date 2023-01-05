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

        await demo.mint(Alice, id1, token1InputStartTime.toFixed(0), token1InputEndTime.toFixed(0));

        let token1OutputStartTime = new BigNumber( await demo.startTime(id1));
        let token1OutputEndTime = new BigNumber( await demo.endTime(id1));
        assert.equal(token1InputStartTime.comparedTo(token1OutputStartTime) == 0
        && token1InputEndTime.comparedTo(token1OutputEndTime) == 0, true, "wrong data");

        let id2 = 2;
        let token2InputStartTime = token1InputStartTime.plus(5000);
        await demo.split(id1, id2, Bob, token2InputStartTime.toFixed(0));

        token1OutputStartTime = new BigNumber( await demo.startTime(id1));
        token1OutputEndTime = new BigNumber( await demo.endTime(id1));

        let token2OutputStartTime = new BigNumber( await demo.startTime(id2));
        let token2OutputEndTime = new BigNumber( await demo.endTime(id2));

        assert.equal(token1InputStartTime.comparedTo(token1OutputStartTime) == 0
        && token1OutputEndTime.comparedTo(token2InputStartTime.minus(1)) == 0, true, "wrong data");

        assert.equal(token2InputStartTime.comparedTo(token2OutputStartTime) == 0
        && token2OutputEndTime.comparedTo(token1InputEndTime) == 0, true, "wrong data");

        let token1RootId = await demo.rootTokenId(id1);
        let token2RootId = await demo.rootTokenId(id2);
        assert.equal(token1RootId == id1 && token2RootId == id1, true, 'wrong data');

        let id3 = 3;
        await demo.setApprovalForAll(Alice, true,{from: Bob});
        await demo.merge(id1, id2, Carl, id3);

        let token3OutputStartTime = new BigNumber( await demo.startTime(id3));
        let token3OutputEndTime = new BigNumber( await demo.endTime(id3));
        let token3RootId = await demo.rootTokenId(id3);
        let token3Owner = await demo.ownerOf(id3);

        assert.equal(token1InputStartTime.comparedTo(token3OutputStartTime) == 0
        && token3OutputEndTime.comparedTo(token1InputEndTime) == 0, true, "wrong start time or end time");

        assert.equal(token3RootId == id1, true, 'wrong rootId');
        assert.equal(token3Owner == Carl, true, 'wrong owner');

        console.log("IERC5007Composable InterfaceId:", await demo.getInterfaceId())
        let isSupport = await demo.supportsInterface('0x620063db');
        assert.equal(isSupport, true , "supportsInterface error");
    });

});
