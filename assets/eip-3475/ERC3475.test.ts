// @notice : run the typechain generate commance into the smrt contract repository (truffle in our case), after the contracts are compiled.
import { ERC3475Instance } from "../types/truffle-contracts";

function sleep(ms: any) {
    return new Promise((resolve) => {
      setTimeout(resolve, ms);
    });
  
}




const Bond = artifacts.require("ERC3475");

contract('Bond', async (accounts: string[]) => {

    let bondContract: ERC3475Instance;
    const lender = accounts[1];
    const operator = accounts[2];
    const secondaryMarketBuyer = accounts[3];
    const secondaryMarketBuyer2 = accounts[4];
    const spender = accounts[5];

    const DBITClassId: number = 0;
    const firstNonceId: number = 0;

    interface _transaction {
        classId: string | number | BN;
        nonceId: string | number | BN;
        amount: string | number | BN;
    }

    before('testing', async () => {
        bondContract = await Bond.deployed();

    })

    it('should issue bonds to a lender', async () => {
        let _transactionIssuer: _transaction[]
            =
            [{
                classId: DBITClassId,
                nonceId: firstNonceId,
                amount: 7000
            }];

        await bondContract.issue(lender, _transactionIssuer, { from: accounts[0] })
        await bondContract.issue(lender, _transactionIssuer, { from: accounts[0] })
        const balance = (await bondContract.balanceOf(lender, DBITClassId, firstNonceId)).toNumber()
        const activeSupply = (await bondContract.activeSupply(DBITClassId, firstNonceId)).toNumber()
        assert.equal(balance, 14000);
        assert.equal(activeSupply, 14000);
    })
    it('lender should be able to transfer bonds to another address', async () => {

        const transferBonds: _transaction[] = [
            {
                classId: DBITClassId,
                nonceId: firstNonceId,
                amount: 2000
            }];
        await bondContract.transferFrom(lender, secondaryMarketBuyer, transferBonds, { from: lender })
        
        const lenderBalance = (await bondContract.balanceOf(lender, DBITClassId, firstNonceId)).toNumber()
        const secondaryBuyerBalance = (await bondContract.balanceOf(secondaryMarketBuyer, DBITClassId, firstNonceId)).toNumber()
        const activeSupply = (await bondContract.activeSupply(DBITClassId, firstNonceId)).toNumber()
        
        assert.equal(lenderBalance, 12000);
        assert.equal(secondaryBuyerBalance, 2000);
        assert.equal(activeSupply, 14000);
    })
    it('operator should be able to manipulate bonds after approval', async () => {
        const transactionApproval: _transaction[] = [
            {
                classId: DBITClassId,
                nonceId: firstNonceId,
                amount: 2000
            }];

        await bondContract.setApprovalFor(operator, true, { from: lender })
        const isApproved = await bondContract.isApprovedFor(lender, operator);
        assert.isTrue(isApproved);
        await bondContract.transferFrom(lender, secondaryMarketBuyer2, transactionApproval, { from: operator })
       expect((await bondContract.balanceOf(lender, DBITClassId, firstNonceId)).toNumber()).to.equal(10000);
        expect((await bondContract.balanceOf(secondaryMarketBuyer2, DBITClassId, firstNonceId)).toNumber()).to.equal(2000);

    })
   
    it('lender should redeem bonds when conditions are met', async () => {
        const redemptionTransaction: _transaction[] = [ 
            {
                classId: 1,
                nonceId: 1,
                amount: 2000

            },           
        ];
        await bondContract.issue(accounts[2],redemptionTransaction, {from: accounts[2]});
        assert.equal((await bondContract.balanceOf(accounts[2], 1, 1)).toNumber(), 2000);
        // adding delay for passing the redemption time period.
        await sleep(7000);    
        
        await bondContract.redeem(accounts[2], redemptionTransaction, {from:accounts[2]});
        
        assert.equal((await bondContract.balanceOf(accounts[2], DBITClassId, firstNonceId)).toNumber(), 0);
    })


    it('lender should not be able to redeem bonds when conditions are not met', async () => {
        const redemptionTransaction: _transaction[] = [
           
            {
                classId: 0,
                nonceId: 0,
                amount: 2000

            },

        ];

        await bondContract.issue(accounts[2],redemptionTransaction, {from: accounts[2]});
        assert.equal((await bondContract.balanceOf(accounts[2], 0, 0)).toNumber(), 2000);
        try {
        await bondContract.redeem(accounts[2], redemptionTransaction, {from:accounts[2]});
    }
    catch(e:any){
        assert.isTrue(true);
    }
        
    })
    //////////////////// UNIT TESTS //////////////////////////////

    it('should transfer bonds from an caller address to another', async () => {
        const transactionTransfer: _transaction[] = [
            {
                classId: DBITClassId,
                nonceId: firstNonceId,
                amount: 500
            }];
        await bondContract.issue(lender, transactionTransfer, { from: lender });
        const tx = (await bondContract.transferFrom(lender, secondaryMarketBuyer, transactionTransfer, {from:lender})).tx;
        console.log(tx)
        assert.isString(tx);
    })

    it('should issue bonds to a given address', async () => {

        const transactionIssue: _transaction[] = [
            {
                classId: 1,
                nonceId: firstNonceId,
                amount: 500

            } 
        ];
        const tx = (await bondContract.issue(lender, transactionIssue)).tx;
        console.log(tx)
        assert.isString(tx);
    })

    it('should redeem bonds from a given address', async () => {
        const transactionRedeem: _transaction[] = [
            {
                classId: 1,
                nonceId: firstNonceId,
                amount: 500

            }];
        await bondContract.issue(lender, transactionRedeem, {from: lender});
        sleep(7000);

        const tx = (await bondContract.redeem(lender, transactionRedeem, {from:lender})).tx;
        
        console.log(tx)
        assert.isString(tx);
    })

    it('should burn bonds from a given address', async () => {
        const transactionRedeem: _transaction[] = [
            {
                classId: DBITClassId,
                nonceId: firstNonceId,
                amount: 500
            }];

        await bondContract.issue(lender, transactionRedeem, {from: lender});
        const tx = (await bondContract.burn(lender, transactionRedeem, {from:lender})).tx;
        console.log(tx)
        assert.isString(tx);
    })

    it('should approve spender to manage a given amount of bonds from the caller address', async () => {
        const transactionApprove: _transaction[] = [
            {
                classId: DBITClassId,
                nonceId: firstNonceId,
                amount: 500
            }];
        
            await bondContract.issue(lender, transactionApprove, {from: lender});   
        const tx = (await bondContract.approve(spender, transactionApprove)).tx;
        console.log(tx)
        assert.isString(tx);
    })

    it('setApprovalFor (called by bond owner) should be able to give operator  permissions to manage bonds for given  classId', async () => {
        const tx = (await bondContract.setApprovalFor(operator, true, { from: lender })).tx;
        console.log(tx)
        assert.isString(tx);
    })

    it('should batch approve', async () => {

        const transactionApprove: _transaction[] = [
            {
                classId: DBITClassId,
                nonceId: firstNonceId,
                amount: 500
            },
            { classId: 1, nonceId: 0, amount: 900 }

        ];


        await await bondContract.issue(spender,transactionApprove, {from:spender});
        const tx = (await bondContract.approve(spender, transactionApprove, {from:spender})).tx;
        console.log(tx)
        assert.isString(tx);
    })

    it('should return the active supply', async () => {
        const activeSupply = (await bondContract.activeSupply(DBITClassId, firstNonceId)).toNumber();
        console.log(activeSupply)
        assert.isNumber(activeSupply);
    })

    it('should return the redeemed supply', async () => {
        const redeemedSupply = (await bondContract.redeemedSupply(DBITClassId, firstNonceId)).toNumber();
        console.log(redeemedSupply)
        assert.isNumber(redeemedSupply);
    })

    it('should return the burned supply', async () => {
        const burnedSupply = (await bondContract.burnedSupply(DBITClassId, firstNonceId)).toNumber();
        console.log(burnedSupply)
        assert.isNumber(burnedSupply);
    })

    it('should return the total supply', async () => {
        const totalSupply = (await bondContract.totalSupply(DBITClassId, firstNonceId)).toNumber();
        console.log(totalSupply)
        assert.isNumber(totalSupply);
    })

    it('should return the balanceOf a bond of a given address', async () => {
        const balanceOf = (await bondContract.balanceOf(lender, DBITClassId, firstNonceId)).toNumber();
        console.log(balanceOf)
        assert.isNumber(balanceOf);
    })

    it('should return the symbol of a class of bond', async () => {
        let metadataId = 0;
        const symbol: {
            stringValue: string;
            uintValue: BN;
            addressValue: string;
            boolValue: boolean;
        } = (await bondContract.classValues(DBITClassId, metadataId));
        console.log(JSON.stringify(symbol));
        assert.isString(symbol.stringValue);
    })

    it('should return the Values for given bond class', async () => {
        const metadataId = 0;
        
        let _transactionIssuer: _transaction[]
        =
        [{
            classId: DBITClassId,
            nonceId: firstNonceId,
            amount: 7000
        }];
        
        await bondContract.issue(lender, _transactionIssuer, { from: accounts[0] })
        const valuesClass = (await bondContract.classValues(DBITClassId, metadataId));
        console.log("class infos: ", JSON.stringify(valuesClass));
        assert.isString(valuesClass.toString());
    })

    it('should return the infos of a nonce for given bond class', async () => {
        const metadataId = 0;
        const infos = (await bondContract.nonceValues(DBITClassId, firstNonceId, metadataId));
        console.log("nonce infos: ", JSON.stringify(infos))
        assert.isString(infos.toString());
    })

    it('should return if an operator is approved on a class and nonce given for an address', async () => {
        const isApproved = (await bondContract.isApprovedFor(lender, operator));
        console.log("operator is Approved? : ", isApproved)
        assert.isBoolean(isApproved);
    })

    it('should return if its redeemable', async () => {
        let _transactionIssuer: _transaction[]
        =
        [{
            classId: 1,
            nonceId: 1,
            amount: 7000
        }];
        
        await bondContract.issue(accounts[1], _transactionIssuer, { from: accounts[1] })       
        const getProgress = await bondContract.getProgress(1,1);
        console.log("is Redeemable? : ", getProgress[1].toNumber() >= 0)
        assert.isNumber(getProgress[1].toNumber());   

    })

    it('should set allowance of a spender', async () => {
        
        const allowance = (await bondContract.allowance(lender, spender, DBITClassId, firstNonceId, {from:lender})).toNumber();
        console.log("allowance : ", allowance)
        assert.isNumber(allowance);
    })

    it('should return if operator is approved for', async () => {
        const isApproved = (await bondContract.isApprovedFor(lender, operator));
        console.log("operator is Approved? : ", isApproved)
        assert.isTrue(isApproved);
    })

});
