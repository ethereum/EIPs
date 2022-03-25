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
    const bathCount = 10;
    const bathSize = 10;

    let token;
    let someToken1;
    let someToken2;

    before(async () => {
        someToken1 = await SomeERC20_1.deployed();
        someToken2 = await SomeERC20_2.deployed();
        token = await RoyaltyBearingToken.deployed();

        //Mint some  ERC20 tokens
        await someToken2.mint(accBuyer, 100000000, { from: accAdmin });
    });

    describe('Stress test royalty calculation', async () => {
        it('updateMaxGenerations success', async () => {
            await token.updateMaxGenerations(5000000, { from: accAdmin });
        });
        it('mint root token to accOwner1', async () => {
            await token.mint(accOwner1, [[0x0, true, maxChildren, 100, 'uri_1']], 'ST2', { from: accAdmin });
            assert.equal((await token.balanceOf(token.address)).toString(), 1, 'Token balance must changed');
            assert.equal(await token.getApproved(tokenRootId), accOwner1, 'Token approved for owner');
        });

        it(`mint ${bathSize * bathCount} nested children`, async () => {
            let lastId = 1;
            for (let n = 0; n < bathCount; n++) {
                const tokens = [];
                for (let i = 0; i < bathSize; i++) {
                    tokens.push([lastId, true, maxChildren, 100, 'uri_' + (lastId + 1)]);
                    lastId++;
                }
                await token.mint(accSeller, tokens, 'ST2', { from: accAdmin });
            }
        });
        const step = 10;
        for (let level = step; level < bathSize * bathCount; level += step) {
            it(`transfer token with ${level} nesting`, async () => {
                const tokenId = level;
                await token.listNFT([tokenId], costOfNFT, 'ST2', { from: accSeller });
                await someToken2.approve(token.address, costOfNFT, { from: accBuyer });
                await token.executePayment(accOwner4, accSeller, [tokenId], costOfNFT, 'ST2', 0, { from: accBuyer });
                
            });
        }
    });
});
