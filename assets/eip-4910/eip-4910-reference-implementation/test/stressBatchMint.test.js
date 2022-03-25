const RoyaltyBearingToken = artifacts.require('RoyaltyBearingToken');
const SomeERC20_1 = artifacts.require('SomeERC20_1');
const SomeERC20_2 = artifacts.require('SomeERC20_2');

contract('RoyaltyBearingToken', (accounts) => {
    const accAdmin = accounts[0];
    const accOwner1 = accounts[1];
    const accOwner2 = accounts[2];
    const accOwner3 = accounts[3];
    const accOwner4 = accounts[4];
    const accBuyer = accounts[5];
    const accSeller = accounts[6];

    const costOfNFT = 100;
    const tokenRootId = 1;
    const tokenId_1 = 2;
    const tokenId_2 = 3;

    const maxChildren = 10000000;
    const steps = [10, 20, 40, 50, 60, 70, 80, 90, 100];

    let token;
    let someToken1;
    let someToken2;

    before(async () => {
        someToken1 = await SomeERC20_1.deployed();
        someToken2 = await SomeERC20_2.deployed();
        token = await RoyaltyBearingToken.deployed();
    });

    describe('Stress test batch token mint', async () => {
        it('updateMaxGenerations success', async () => {
            await token.updateMaxGenerations(5000000, { from: accAdmin });
        });

        it('mint root token to accOwner1', async () => {
            await token.mint(accOwner1, [[0x0, true, maxChildren, 100, 'uri_1']], 'ETH', { from: accAdmin });
            assert.equal((await token.balanceOf(token.address)).toString(), 1, 'Token balance must changed');
            assert.equal(await token.getApproved(tokenRootId), accOwner1, 'Token approved for owner');
        });

        for (let n = 0; n < steps.length; n++) {
            const count = steps[n];
            const tokens = [];
            for (let i = 0; i < count; i++) {
                tokens.push([1, true, maxChildren, 100, 'uri_' + (i + 1)]);
            }
            it(`mint ${count} children`, async () => {
                //const balanceBefore = (await token.balanceOf(token.address)).toNumber();
                await token.mint(accOwner1, tokens, 'ETH', { from: accAdmin });
                //const balanceAfter = (await token.balanceOf(token.address)).toNumber();

                //assert.equal(balanceAfter - balanceBefore, accOwner1, 'Token approved for owner');
            });
        }
    });
});
