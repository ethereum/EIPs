const { ethers } = require("hardhat");
const { expect } = require("chai");
const AbiCoder = ethers.utils.AbiCoder;
const Keccak256 = ethers.utils.keccak256;

describe("Livecycle Unit-Tests for Smart Derivative Contract", () => {

    // Define objects for TradeState enum, since solidity enums cannot provide their member names...
  const TradeState = {
      Inactive: 0,
      Incepted: 1,
      Confirmed: 2,
      Active: 3,
      Terminated: 4,
  };

  const abiCoder = new AbiCoder();
  const trade_data = "<xml>here are the trade specification</xml";
  let sdc;
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

  before(async () => {
    const [_tokenManager, _counterparty1, _counterparty2] = await ethers.getSigners();
    tokenManager = _tokenManager;
    counterparty1 = _counterparty1;
    counterparty2 = _counterparty2;
    const ERC20Factory = await ethers.getContractFactory("SDCToken");
    const SDCFactory = await ethers.getContractFactory("SDC");
    token = await ERC20Factory.deploy();
    await token.deployed();
    sdc = await SDCFactory.deploy(counterparty1.address, counterparty2.address,counterparty1.address, token.address,marginBufferAmount,terminationFee);
    await sdc.deployed();
    console.log("SDC Address: %s", sdc.address);
  });

  it("Initial minting and approvals for SDC", async () => {
    await token.connect(counterparty1).mint(counterparty1.address,initialLiquidityBalance);
    await token.connect(counterparty2).mint(counterparty2.address,initialLiquidityBalance);
    await token.connect(counterparty1).approve(sdc.address,terminationFee+marginBufferAmount);
    await token.connect(counterparty2).approve(sdc.address,terminationFee+marginBufferAmount);
    let allowanceSDCParty1 = await token.connect(counterparty1).allowance(counterparty1.address, sdc.address);
    let allowanceSDCParty2 = await token.connect(counterparty2).allowance(counterparty2.address, sdc.address);
    await expect(allowanceSDCParty1).equal(terminationFee+marginBufferAmount);
  });

  it("Counterparty1 incepts a trade", async () => {
     const incept_call = await sdc.connect(counterparty1).inceptTrade(trade_data, "initialMarketData", 0);
     let tradeid =  await sdc.connect(counterparty1).getTradeID();
     //console.log("TradeId: %s", tradeid);
     await expect(incept_call).to.emit(sdc, "TradeIncepted").withArgs(counterparty1.address, tradeid, trade_data);
     let trade_state =  await sdc.connect(counterparty1).getTradeState();
     await expect(trade_state).equal(TradeState.Incepted);
   });


  it("Counterparty2 confirms a trade", async () => {
     const confirm_call = await sdc.connect(counterparty2).confirmTrade(trade_data,"initialMarketData");
     //console.log("TradeId: %s", await sdc.callStatic.getTradeState());
     let balanceSDC = await token.connect(counterparty2).balanceOf(sdc.address);
     await expect(confirm_call).to.emit(sdc, "TradeConfirmed");
     await expect(balanceSDC).equal(2*terminationFee);
     let trade_state =  await sdc.connect(counterparty1).getTradeState();
     await expect(trade_state).equal(TradeState.Active);
   });

   it("Processing first prefunding phase", async () => {
     const call = await sdc.connect(counterparty2).initiatePrefunding();
     let balanceSDC = await token.connect(counterparty2).balanceOf(sdc.address);
     let balanceCP2 = await token.connect(counterparty2).balanceOf(counterparty2.address);
     await expect(balanceSDC).equal(2*(terminationFee+marginBufferAmount));
     await expect(balanceCP2).equal(initialLiquidityBalance-(terminationFee+marginBufferAmount));
     await expect(call).to.emit(sdc, "ProcessFunded");
   });

   it("Initiate and perform first successful settlement in favour to counterparty 1", async () => {
     const callInitSettlement = await sdc.connect(counterparty2).initiateSettlement();
     await expect(callInitSettlement).to.emit(sdc, "ProcessSettlementRequest");
     let balanceCP1 = parseInt(await token.connect(counterparty1).balanceOf(counterparty1.address));
     let balanceCP2 = parseInt(await token.connect(counterparty2).balanceOf(counterparty1.address));
     const callPerformSettlement = await sdc.connect(counterparty2).performSettlement(settlementAmount1,"settlementData");
     await expect(callPerformSettlement).to.emit(sdc, "ProcessSettled");
     let balanceSDC_afterSettlement = await token.connect(counterparty2).balanceOf(sdc.address);
     let balanceCP1_afterSettlement = await token.connect(counterparty1).balanceOf(counterparty1.address);
     let balanceCP2_afterSettlement = await token.connect(counterparty2).balanceOf(counterparty2.address);
     await expect(balanceSDC_afterSettlement).equal(2*(terminationFee+marginBufferAmount)-settlementAmount1); // SDC balance less settlement
     await expect(balanceCP1_afterSettlement).equal(balanceCP1+settlementAmount1);  // settlement in favour to CP1
     await expect(balanceCP2_afterSettlement).equal(balanceCP2); // CP2 balance is not touched as transfer is booked from SDC balance
   });

   it("Process successfully second prefunding phase successful ", async () => {
     await token.connect(counterparty2).approve(sdc.address,settlementAmount1);  // CP2 increases allowance
     const call = await sdc.connect(counterparty1).initiatePrefunding(); //Prefunding: SDC transfers missing gap amount from CP2
     let balanceSDC = await token.connect(counterparty2).balanceOf(sdc.address);
     let balanceCP2 = await token.connect(counterparty2).balanceOf(counterparty2.address);
     await expect(balanceSDC).equal(2*(terminationFee+marginBufferAmount));
     await expect(balanceCP2).equal(initialLiquidityBalance-(terminationFee+marginBufferAmount)-settlementAmount1);
     await expect(call).to.emit(sdc, "ProcessFunded");
   });


   it("Second settlement fails due to high transfer amount in favour to counteparty 2 - Trade terminates", async () => {
     const callInitSettlement = await sdc.connect(counterparty2).initiateSettlement();
     await expect(callInitSettlement).to.emit(sdc, "ProcessSettlementRequest");
     const callPerformSettlement = await sdc.connect(counterparty2).performSettlement(settlementAmount2,"settlementData");
     await expect(callPerformSettlement).to.emit(sdc, "TradeTerminated");

     let balanceSDC = parseInt(await token.connect(counterparty2).balanceOf(sdc.address));
     let balanceCP1 = await token.connect(counterparty1).balanceOf(counterparty1.address);
     let balanceCP2 = await token.connect(counterparty2).balanceOf(counterparty2.address);
     let expectedBalanceCP1 = initialLiquidityBalance + settlementAmount1 - (marginBufferAmount + terminationFee); //CP1 received settlementAmount1 and paid margin buffer and termination fee
     let expectedBalanceCP2 = initialLiquidityBalance - settlementAmount1 + (marginBufferAmount + terminationFee); //CP2 paid settlementAmount1 and receives margin buffer and termination fee
     await expect(balanceCP1).equal(expectedBalanceCP1);
     await expect(balanceCP2).equal(expectedBalanceCP2);
     await expect(balanceSDC).equal(0);
   });



});