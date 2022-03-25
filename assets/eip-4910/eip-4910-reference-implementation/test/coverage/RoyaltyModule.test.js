const RoyaltyModule = artifacts.require('RoyaltyModule');
const truffleAssert = require('truffle-assertions');

const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';
contract('RoyaltyModule', (accounts) => {
    const accAdmin = accounts[0];
    const accUser1 = accounts[1];
    const accUser2 = accounts[2];

    let royaltyModule, token;

    before(async () => {
        royaltyModule = await RoyaltyModule.deployed();
    });

    describe('Only owner can call update functions', async () => {
        it('createRoyaltyAccount', async () => {
            await truffleAssert.reverts(royaltyModule.createRoyaltyAccount(ZERO_ADDRESS, 0, 0, '', 0, { from: accAdmin }), '');
        });
        it('updateRoyaltyAccount', async () => {
            await truffleAssert.reverts(royaltyModule.updateRoyaltyAccount(0, [], ZERO_ADDRESS, true, { from: accAdmin }), '');
        });
        it('deleteRoyaltyAccount', async () => {
            await truffleAssert.reverts(royaltyModule.deleteRoyaltyAccount(0, { from: accAdmin }), '');
        });
        it('distributePayment', async () => {
            await truffleAssert.reverts(royaltyModule.distributePayment(0, 0, { from: accAdmin }), '');
        });
        it('withdrawBalance', async () => {
            await truffleAssert.reverts(royaltyModule.withdrawBalance(0, ZERO_ADDRESS, 0, { from: accAdmin }), '');
        });
        it('transferRAOwnership', async () => {
            await truffleAssert.reverts(royaltyModule.transferRAOwnership(ZERO_ADDRESS, 0, ZERO_ADDRESS, { from: accAdmin }), '');
        });
    });
    describe('Getter functions', async () => {
        it('getBalance for empty token', async () => {
            const balance = await royaltyModule.getBalance(1, ZERO_ADDRESS, { from: accAdmin });
            assert.equal(balance, 0);
        });
    });
});
