const { expect } = require("chai");
const { ethers, waffle } = require("hardhat");

// Deploy and mint
describe("ERC1155", function() {

  this.beforeAll(async function(){
    try{
      provider = waffle.provider;
      [owner,u1,u2] = await ethers.getSigners();

      const __1155 = await ethers.getContractFactory("ExampleToken");
      _1155 = await __1155.deploy();
      await _1155.deployed();
    } 
    catch(ex){
      console.error(ex);
    }
  });

  it("Mint 100 of 0,1,2 from 1155 to Owner", async function(){
    const amount = 80;
    const ids = [ 0, 1 ];
    const amounts = Array(ids.length).fill(amount);
  
    await expect(_1155.mintBatch(owner.address, ids, amounts, "0x00"),"mint 1155 to owner").not.to.be.reverted;
  
    const realValue0 = await _1155.balanceOf(owner.address,0);
    const realValue1 = await _1155.balanceOf(owner.address,1);
  
    expect(realValue0).to.equal(amount);
    expect(realValue1).to.equal(amount);
  });
})

// Test suite ERC1155ApprovalByAmount
describe("ERC1155ApprovalByAmount", function(){
  describe("approve", function(){
    it("Approve id 0 for U1 with an amount of 10", async function(){
      const from = owner.address;
      const operator = u1.address;
      const id = 0;
      const amount = 10;
      const allowanceBefore = parseInt(await _1155.allowance(from, operator, id));
      await expect(_1155.connect(owner).approve(operator,id,amount)).to.emit(_1155, "ApprovalByAmount");
      expect(allowanceBefore + amount,'New allowance for U1').to.equal(await _1155.allowance(from, operator, id));
    });

    it("Should revert when owner try to approve himself", async function(){
      const operator = owner.address;
      const id = 0;
      const amount = 10;
      await expect(_1155.connect(owner).approve(operator,id,amount)).to.be.revertedWith("ERC1155ApprovalByAmount: setting approval status for self");
    });
  });

  describe("safeTransferFrom", function(){
    it("Should revert when caller isn't the from param", async function(){
      const from = u1.address;
      const to = u2.address;
      const id = 0;
      const amount = 10;
      const data = 0x00;
      await expect(_1155.connect(owner).safeTransferFrom(from, to, id, amount, data)).to.be.revertedWith("ERC1155: caller is not owner nor approved nor approved for amount");
    });

    it("Should revert when id to transfer is not approved and caller != from", async function(){
      const from = owner.address;
      const to = u1.address;
      const id = 1;
      const amount = 10;
      const data = 0x00;
      await expect(_1155.connect(u2).safeTransferFrom(from, to, id, amount, data)).to.be.revertedWith("ERC1155: caller is not owner nor approved nor approved for amount");
    });

    it("Transfer 10 1155-0 to U2 by owner", async function(){
      const from = owner.address;
      const to = u2.address;
      const id = 0;
      const amount = 10;
      const data = 0x00;

      const balanceBefore = parseInt(await _1155.balanceOf(to, id));
      
      await expect(_1155.connect(owner).safeTransferFrom(from, to, id, amount, data),'Transfer 10-0 to U2 by owner').to.emit(_1155, "TransferSingle");

      const balanceAfter = parseInt(await _1155.balanceOf(to, id));

      expect(balanceBefore + amount,'New balance of U2').to.equal(balanceAfter);
    });

    it("Transfer 10 1155-0 to U1 call by himself", async function(){
      const from = owner.address;
      const to = u1.address;
      const id = 0;
      const amount = 10;
      const data = 0x00;

      const allowanceBefore = parseInt(await _1155.allowance(from, to, id));
      const balanceBefore = parseInt(await _1155.balanceOf(to, id));

      await expect(_1155.connect(u1).safeTransferFrom(from, to, id, amount, data),'Transfer 10-0').to.emit(_1155, "TransferSingle");

      const allowanceAfter = parseInt(await _1155.allowance(from, to, id));
      const balanceAfter = parseInt(await _1155.balanceOf(to, id));

      expect(balanceBefore + amount,'New balance of U1').to.equal(balanceAfter);
      expect(allowanceBefore - amount,'New allowance of U1').to.equal(allowanceAfter);
    });

    it("Should revert when U1 try to transfer 1 1155-0 to himself with allowance actual in 0", async function(){
      const from = owner.address;
      const to = u1.address;
      const id = 0;
      const amount = 1;
      const data = 0x00;

      await expect(_1155.connect(u1).safeTransferFrom(from, to, id, amount, data),'Transfer 10-0').to.be.revertedWith("ERC1155: caller is not owner nor approved nor approved for amount");
    });
  });

  describe("safeBatchTransferFrom", function(){
    it("Approve id 1 for U1 with an amount of 10", async function(){
      const from = owner.address;
      const operator = u1.address;
      const id = 1;
      const amount = 10;

      const allowanceBefore = parseInt(await _1155.allowance(from, operator, id));
      await expect(_1155.connect(owner).approve(operator,id,amount)).to.emit(_1155, "ApprovalByAmount");
      expect(allowanceBefore + amount,'New allowance for U1').to.equal(await _1155.allowance(from, operator, id));
    });

    
    it("Should be reverted because Id 0 is not approved for U1", async function(){
      const from = owner.address;
      const to = u1.address;
      const amount = 10;
      const ids = [ 0, 1 ];
      const amounts = [ amount, amount ];
      const data = 0x00;
      await expect(_1155.connect(u1).safeBatchTransferFrom(from, to, ids, amounts, data)).to.be.revertedWith("ERC1155ApprovalByAmount: operator is not approved for that id or amount");
    });

    it("Transfer 10 of 0 and 1 from owner to U2", async function(){
      // safeTransfer
      const from = owner.address;
      const to = u2.address;
      const amount = 10;
      const ids = [ 0, 1 ];
      const amounts = [ amount, amount ];
      const data = 0x00;
      
      const balanceBefore = [];
      for (let i = 0; i < ids.length; i++) {
        balanceBefore.push(await _1155.balanceOf(to, ids[i]));
      }

      await expect(_1155.connect(owner).safeBatchTransferFrom(from, to, ids, amounts, data)).to.emit(_1155, "TransferBatch");

      for (let i = 0; i < ids.length; i++) {
        expect(await _1155.balanceOf(to, ids[i]),'New balance of U1 of id ' + ids[i]).to.equal(parseInt(balanceBefore[i]) + amount);       
      }
    });
    
    it("Approve for Id 0 and transfer 10 of 0 and 1 to U1", async function(){
      // Approve
      const operator = u1.address;
      const id = 0;
      const amount = 10;
      await expect(_1155.connect(owner).approve(operator,id,amount)).to.emit(_1155, "ApprovalByAmount");

      // safeTransfer
      const from = owner.address;
      const to = u1.address;
      const ids = [ 0, 1 ];
      const amounts = [ amount, amount ];
      const data = 0x00;
      
      const balanceBefore = [];
      for (let i = 0; i < ids.length; i++) {
        balanceBefore.push(await _1155.balanceOf(to, ids[i]));
      }

      const allowanceBefore = [];
      for (let i = 0; i < ids.length; i++) {
        allowanceBefore.push(await _1155.allowance(from, to, ids[i]));
      }

      await expect(_1155.connect(u1).safeBatchTransferFrom(from, to, ids, amounts, data)).to.emit(_1155, "TransferBatch");

      for (let i = 0; i < ids.length; i++) {
        expect(await _1155.balanceOf(to, ids[i]),'New balance of U1 of id ' + ids[i]).to.equal(parseInt(balanceBefore[i]) + amount);       
        expect(await _1155.allowance(from, to, ids[i]),'New allowance of U1 of id ' + ids[i]).to.equal(parseInt(allowanceBefore[i]) - amount);       
      }
    });
  });
});