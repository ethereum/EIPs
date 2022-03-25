const PaymentModule = artifacts.require('PaymentModule');
const truffleAssert = require('truffle-assertions');

const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';
contract('PaymentModule', (accounts) => {
    const accAdmin = accounts[0];
    const accUser1 = accounts[1];
    const accUser2 = accounts[2];

    let paymentModule;

    before(async () => {
        paymentModule = await PaymentModule.deployed();
    });

    describe('Only owner can call update functions', async () => {
        it('addListNFT', async () => {
            await truffleAssert.reverts(paymentModule.addListNFT(ZERO_ADDRESS, [0], 0, '', { from: accAdmin }), '');
        });
        it('addRegisterPayment', async () => {
            await truffleAssert.reverts(paymentModule.addRegisterPayment(ZERO_ADDRESS, [0], 0, '', { from: accAdmin }), '');
        });
        it('removeRegisterPayment', async () => {
            await truffleAssert.reverts(paymentModule.removeRegisterPayment(ZERO_ADDRESS, [0], { from: accAdmin }), '');
        });
    });
    describe('Getter functions', async () => {
        it('getRegisterPayment for empty token', async () => {
            const result = await paymentModule.getRegisterPayment(1, { from: accAdmin });
            assert.equal(result.payment, 0);
        });
        it('checkRegisterPayment for empty token', async () => {
            const payment = await paymentModule.checkRegisterPayment(1, accUser1, { from: accAdmin });
            assert.equal(payment, 0);
        });
    });
});
