const RoyaltyBearingToken = artifacts.require('RoyaltyBearingToken');
const SomeERC20_1 = artifacts.require('SomeERC20_1');
const SomeERC20_2 = artifacts.require('SomeERC20_2');

const truffleAssert = require('truffle-assertions');
const MINTER_ROLE = web3.utils.keccak256('MINTER_ROLE');

contract('RoyaltyBearingToken', (accounts) => {
    const accAdmin = accounts[0];
    const accSeller = accounts[1];
    const accBuyer = accounts[2];
    const accSomeone1 = accounts[3];
    const accSomeone2 = accounts[4];
    const accNewRoyalty = accounts[4];

    const costOfNFT = 100;
    const tokenRootId = 1;
    const tokenId_1_1 = 2;
    const tokenId_1_1_1 = 3;

    let token;
    let someToken1;
    let someToken2;

    before(async () => {
        someToken1 = await SomeERC20_1.deployed();
        someToken2 = await SomeERC20_2.deployed();
        token = await RoyaltyBearingToken.deployed();
    });

    describe('Prepare tokens for test', async () => {
        it('mint tokens to accSeller', async () => {
            await token.mint(
                accSeller,
                [
                    [0x0, true, 10, 1000, 'uri_1'],
                    [0x1, true, 10, 1000, 'uri_1.1'],
                    [0x2, true, 10, 1000, 'uri_1.1.1'],
                ],
                'ETH',
                { from: accAdmin },
            );
            assert.equal((await token.balanceOf(token.address)).toString(), 3, 'Token balance must changed');
            assert.equal(await token.hasRole(MINTER_ROLE, accSeller), true, 'CREATOR role must granted');
            assert.equal(await token.getApproved(1), accSeller, 'Token approved for owner');
            assert.equal(await token.getApproved(2), accSeller, 'Token approved for owner');
            assert.equal(await token.getApproved(3), accSeller, 'Token approved for owner');
        });
        it('seller make listNFT (2)', async () => {
            await token.listNFT([tokenId_1_1], costOfNFT, 'ETH', { from: accSeller });
        });

        it('buyer execute the ETH payment to Token contract and receive tokens (2)', async () => {
            const data = web3.eth.abi.encodeParameters(['address', 'uint256[]', 'address', 'int256'], [accSeller, [tokenId_1_1], accBuyer, 0]);
            await web3.eth.sendTransaction({ from: accBuyer, to: token.address, value: costOfNFT, data: data, gas: 6000000 });
        });
    });

    describe('Edit royalty split functionality', async () => {
        //Token 1.1 royalty after init
        //Owner/TT/parent
        //8000/1000/1000

        it('updateRoyaltyAccount not allowed for if caller is not token owner or royalty receiver', async () => {
            await truffleAssert.reverts(token.updateRoyaltyAccount(tokenId_1_1, [[true, 1000, 0, accSomeone1]], { from: accSomeone1 }), 'Total royaltySplit must be 10000');
        });
        it('Sum of royalty split must be = 10000', async () => {
            const updates = [
                [true, 8000, 0, accBuyer],
                [true, 1000, 0, accSomeone1],
            ];
            await truffleAssert.reverts(token.updateRoyaltyAccount(tokenId_1_1, updates, { from: accSomeone1 }), 'Total royaltySplit must be 10000');
        });
        it('Only subaccount owner can reduce own royalty split', async () => {
            const updates = [
                [true, 7000, 0, accBuyer],
                [true, 1000, 0, accSomeone1],
            ];
            await truffleAssert.reverts(token.updateRoyaltyAccount(tokenId_1_1, updates, { from: accSomeone1 }), 'Only individual subaccount owner can decrease royaltySplit');
        });
        it('Only parent token owner can reduce royalty split for parent', async () => {
            const ra = await token.getRoyaltyAccount(tokenId_1_1);
            assert.equal(ra.subaccounts[2].isIndividual, false);
            const updates = [
                [true, 500, 0, ra.subaccounts[2].accountId],
                [true, 8500, 0, accBuyer],
            ];
            await truffleAssert.reverts(token.updateRoyaltyAccount(tokenId_1_1, updates, { from: accSomeone1 }), 'Only parent token owner can decrease royalty subaccount royaltySplit');
        });
        it('Parent owner decrease royalty and transfer royaltySplit to token owner', async () => {
            //8000/1000/1000 >> 8500/1000/500
            const ra = await token.getRoyaltyAccount(tokenId_1_1);
            assert.equal(ra.subaccounts[2].isIndividual, false);
            const updates = [
                [false, 500, 0, ra.subaccounts[2].accountId],
                [true, 8500, 0, accBuyer],
            ];
            await token.updateRoyaltyAccount(tokenId_1_1, updates, { from: accSeller });

            const ra_after = await token.getRoyaltyAccount(tokenId_1_1);
            assert.equal(ra_after.subaccounts[0].royaltySplit, 8500);
            assert.equal(ra_after.subaccounts[1].royaltySplit, 1000);
            assert.equal(ra_after.subaccounts[2].royaltySplit, 500);
        });
        it('Only individual account allowed as new', async () => {
            //8500/1000/500
            const ra = await token.getRoyaltyAccount(tokenId_1_1);
            assert.equal(ra.subaccounts[2].isIndividual, false);
            const updates = [
                [false, 1000, 0, ra.subaccounts[2].accountId],
                [true, 6000, 0, accBuyer],
                [false, 2000, 0, accNewRoyalty],
            ];
            await truffleAssert.reverts(token.updateRoyaltyAccount(tokenId_1_1, updates, { from: accBuyer }), 'New subaccounts must be individual');
        });
        it('Token owner transfer royaltySplit back to parent and split royalty to new account', async () => {
            //8500/1000/500 >> 6000/1000/1000/2000
            const ra = await token.getRoyaltyAccount(tokenId_1_1);
            assert.equal(ra.subaccounts[2].isIndividual, false);
            const updates = [
                [false, 1000, 0, ra.subaccounts[2].accountId],
                [true, 6000, 0, accBuyer],
                [true, 2000, 0, accNewRoyalty],
            ];
            await token.updateRoyaltyAccount(tokenId_1_1, updates, { from: accBuyer });

            const ra_after = await token.getRoyaltyAccount(tokenId_1_1);
            assert.equal(ra_after.subaccounts[0].royaltySplit, 6000);
            assert.equal(ra_after.subaccounts[1].royaltySplit, 1000);
            assert.equal(ra_after.subaccounts[2].royaltySplit, 1000);
            assert.equal(ra_after.subaccounts[3].royaltySplit, 2000);
        });
        it('Royalty split for TT + minimal must be <= 100%', async () => {
            await truffleAssert.reverts(token.updateRAccountLimits(5, 9500, { from: accAdmin }), 'Royalty Split to TT + Minimal Split is > 100%');
        });
        it('Update royalty limits to 5 max subaccount and 5% min royalty split', async () => {
            await token.updateRAccountLimits(5, 500, { from: accAdmin });
        });
        it('Token owner can not split royalty less than limit (5%)', async () => {
            const ra = await token.getRoyaltyAccount(tokenId_1_1);
            assert.equal(ra.subaccounts[2].isIndividual, false);
            const updates = [
                [true, 7900, 0, accBuyer],
                [true, 100, 0, accNewRoyalty],
            ];
            await truffleAssert.reverts(token.updateRoyaltyAccount(tokenId_1_1, updates, { from: accBuyer }), 'Royalty Split is smaller then set limit');
        });
        it('Token owner can not split royalty to more than limit account numbers (5)', async () => {
            //Token already have 4 subaccounts (Parent royalty, TT fee, )
            const ra = await token.getRoyaltyAccount(tokenId_1_1);
            assert.equal(ra.subaccounts[2].isIndividual, false);
            const updates = [
                [true, 2000, 0, accBuyer],
                [true, 1000, 0, accounts[5]],
                [true, 1000, 0, accounts[6]],
                [true, 1000, 0, accounts[7]],
                [true, 1000, 0, accounts[8]],
            ];
            await truffleAssert.reverts(token.updateRoyaltyAccount(tokenId_1_1, updates, { from: accBuyer }), 'Too many Royalty subaccounts');
        });
    });
});
