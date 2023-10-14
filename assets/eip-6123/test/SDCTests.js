const { ethers } = require("hardhat");
const { expect } = require("chai");
const AbiCoder = ethers.utils.AbiCoder;
const Keccak256 = ethers.utils.keccak256;

describe("Livecycle Unit-Tests for SDC Plege Balance", () => {

    // Define objects for TradeState enum, since solidity enums cannot provide their member names...
  const TradeState = {
      Inactive: 0,
      Incepted: 1,
      Confirmed: 2,
      Valuation: 3,
      InTransfer: 4,
      Settled: 5,
      Terminated: 6
  };

  const abiCoder = new AbiCoder();
  const trade_data = "<xml>here are the trade specification</xml";

  let token;
  let tokenManager;
  let counterparty1;
  let counterparty2;
  let trade_id;
  let initialLiquidityBalance = 5000;
  let terminationFee = 100;
  let marginBufferAmount = 900;
  const settlementAmount1 = 200; // successful settlement in favour to CP1
  const settlementAmount2 = -1400; // failing settlement larger than buffer in favour to CP1
  const upfront = 10;
  let SDCFactory;
  let ERC20Factory;

  before(async () => {
    const [_tokenManager, _counterparty1, _counterparty2] = await ethers.getSigners();
    tokenManager = _tokenManager;
    counterparty1 = _counterparty1;
    counterparty2 = _counterparty2;
    ERC20Factory = await ethers.getContractFactory("ERC20Settlement");
    SDCFactory = await ethers.getContractFactory("SDCPledgedBalance");
    token = await ERC20Factory.deploy();
    await token.deployed();
  });

  it("Initial minting and approvals for SDC", async () => {
    await token.connect(counterparty1).mint(counterparty1.address,initialLiquidityBalance);
    await token.connect(counterparty2).mint(counterparty2.address,initialLiquidityBalance);
  });

  it("Counterparties incept and confirm a trade successfully, upfront is transferred", async () => {
     let sdc = await SDCFactory.deploy(counterparty1.address, counterparty2.address,token.address,marginBufferAmount,terminationFee);
     await sdc.deployed();
     console.log("SDC Address: %s", sdc.address);
     await token.connect(counterparty1).approve(sdc.address,terminationFee+marginBufferAmount);
     await token.connect(counterparty2).approve(sdc.address,terminationFee+marginBufferAmount+upfront);
     let trade_id ="";
     const incept_call = await sdc.connect(counterparty1).inceptTrade(counterparty2.address, trade_data, 1, upfront, "initialMarketData");
     await expect(incept_call).to.emit(sdc, "TradeIncepted");
     const confirm_call = await sdc.connect(counterparty2).confirmTrade(counterparty1.address, trade_data, -1, -upfront, "initialMarketData");
     await expect(confirm_call).to.emit(sdc, "TradeConfirmed");
     let trade_state =  await sdc.connect(counterparty1).getTradeState();
     await expect(trade_state).equal(TradeState.Settled);
   });

   it("Not enough approval to transfer upfront payment", async () => {
        let sdc = await SDCFactory.deploy(counterparty1.address, counterparty2.address,token.address,marginBufferAmount,terminationFee);
        await sdc.deployed();
        console.log("SDC Address: %s", sdc.address);
        await token.connect(counterparty1).approve(sdc.address,terminationFee+marginBufferAmount);
        await token.connect(counterparty2).approve(sdc.address,terminationFee+marginBufferAmount);
        const incept_call = await sdc.connect(counterparty1).inceptTrade(counterparty2.address, trade_data, 1, upfront, "initialMarketData");
        await expect(incept_call).to.emit(sdc, "TradeIncepted");
        const confirm_call = await sdc.connect(counterparty2).confirmTrade(counterparty1.address, trade_data, -1, -upfront, "initialMarketData");
        await expect(confirm_call).to.emit(sdc, "TradeConfirmed");
        let trade_state =  await sdc.connect(counterparty1).getTradeState();
        await expect(trade_state).equal(TradeState.Inactive);
   });

    it("Trade Matching fails", async () => {
        let sdc = await SDCFactory.deploy(counterparty1.address, counterparty2.address,token.address,marginBufferAmount,terminationFee);
        await sdc.deployed();
        console.log("SDC Address: %s", sdc.address);
        await token.connect(counterparty1).approve(sdc.address,terminationFee+marginBufferAmount);
        await token.connect(counterparty2).approve(sdc.address,terminationFee+marginBufferAmount);
        const incept_call = await sdc.connect(counterparty1).inceptTrade(counterparty2.address, trade_data, 1, upfront, "initialMarketData");
        await expect(incept_call).to.emit(sdc, "TradeIncepted");
        const confirm_call = sdc.connect(counterparty2).confirmTrade(counterparty1.address, "none", -1, -upfront, "initialMarketData23");
        await expect(confirm_call).to.be.revertedWith("Confirmation fails due to inconsistent trade data or wrong party address");
    });


  it("Successful Settlement", async () => {
     let sdc = await SDCFactory.deploy(counterparty1.address, counterparty2.address,token.address,marginBufferAmount,terminationFee);
     await sdc.deployed();
     console.log("SDC Address: %s", sdc.address);
     await token.connect(counterparty1).approve(sdc.address,terminationFee+10*marginBufferAmount); //Approve for 10*margin amount
     await token.connect(counterparty2).approve(sdc.address,terminationFee+10*marginBufferAmount+upfront);
     let trade_id ="";
     const incept_call = await sdc.connect(counterparty1).inceptTrade(counterparty2.address, trade_data, 1, upfront, "initialMarketData");
     await expect(incept_call).to.emit(sdc, "TradeIncepted");
     const confirm_call = await sdc.connect(counterparty2).confirmTrade(counterparty1.address, trade_data, -1, -upfront, "initialMarketData");
     await expect(confirm_call).to.emit(sdc, "TradeConfirmed");
     const initSettlementPhase = sdc.connect(counterparty2).initiateSettlement();
     await expect(initSettlementPhase).to.emit(sdc, "TradeSettlementRequest");
     const balance_call = await token.connect(counterparty2).balanceOf(counterparty2.address);
     console.log("Balance: %s", balance_call);
     const performSettlementCall = sdc.connect(counterparty1).performSettlement(1,"settlementData");
     await expect(performSettlementCall).to.emit(sdc, "TradeSettlementPhase");
     let trade_state =  await sdc.connect(counterparty1).getTradeState();
     await expect(trade_state).equal(TradeState.Settled);

   });



});