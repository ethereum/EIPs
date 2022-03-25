const RoyaltyBearingToken = artifacts.require('RoyaltyBearingToken');
const SomeERC20_1 = artifacts.require('SomeERC20_1');
const SomeERC20_2 = artifacts.require('SomeERC20_2');
const DIGITS = 1000000000;

contract('RoyaltyBearingToken', (accounts) => {
    const accAdmin = accounts[0];
    const accOwner1 = accounts[1];
    const accOwner2 = accounts[2];
    const accOwner3 = accounts[3];
    const accOwner4 = accounts[4];
    const accBuyer = accounts[5];
    const accSeller = accounts[6];

    const costOfNFT = 100 * DIGITS;
    const tokenId_1 = 1;
    const tokenId_1_1 = 2;
    const tokenId_1_1_1 = 3;

    let token;
    let someToken1;
    let someToken2;

    before(async () => {
        someToken1 = await SomeERC20_1.deployed();
        someToken2 = await SomeERC20_2.deployed();
        token = await RoyaltyBearingToken.deployed();

        //Mint some  ERC20 tokens
        //await someToken2.mint(accBuyer, cost, { from: accAdmin });
    });

    describe('Royalty split scenario', async () => {
        it('accOwner1 mint root token_1 with 20%', async () => {
            await token.mint(accOwner1, [[0x0, true, 10, 2000, 'uri_1']], 'ST2', { from: accAdmin });
            assert.equal(await token.getApproved(tokenId_1), accOwner1, 'Token approved for owner');
        });
        it('accOwner1 sell token_1 to accOwner2 -- (accOwner1 receive 90% directly)', async () => {
            await token.listNFT([tokenId_1], costOfNFT, 'ST2', { from: accOwner1 });
            //Mint and approve ERC20
            await someToken2.mint(accOwner2, costOfNFT, { from: accAdmin });
            await someToken2.approve(token.address, costOfNFT, { from: accOwner2 });
            //Buy NFT
            await token.executePayment(accOwner2, accOwner1, [tokenId_1], costOfNFT, 'ST2', 0, { from: accOwner2 });

            const a1_after = await someToken2.balanceOf(accOwner1);
            const a2_after = await someToken2.balanceOf(accOwner2);

            assert.equal(a1_after.toNumber(), 0.9 * costOfNFT);
            assert.equal(a2_after.toNumber(), 0);
        });
        it('accOwner2 mint token_1_1 to with 50%', async () => {
            await token.mint(accOwner2, [[tokenId_1, true, 10, 5000, 'uri_1_1']], 'ST2', { from: accAdmin });
            assert.equal(await token.getApproved(tokenId_1_1), accOwner2, 'Token approved for owner');
        });
        it('accOwner2 sell token_1_1 to accOwner3 -- (accOwner2 receive 70% directly; accOwner2 receive 20% on royalty acc for token_1)', async () => {
            const a1_before = (await someToken2.balanceOf(accOwner1)).toNumber();
            const a2_before = (await someToken2.balanceOf(accOwner2)).toNumber();
            const a3_before = (await someToken2.balanceOf(accOwner3)).toNumber();

            const ra1_before = await token.getRoyaltyAccount(tokenId_1);

            await token.listNFT([tokenId_1_1], costOfNFT, 'ST2', { from: accOwner2 });
            //Mint and approve ERC20
            await someToken2.mint(accOwner3, costOfNFT, { from: accAdmin });
            await someToken2.approve(token.address, costOfNFT, { from: accOwner3 });
            //Buy NFT
            await token.executePayment(accOwner3, accOwner2, [tokenId_1_1], costOfNFT, 'ST2', 0, { from: accOwner3 });

            const a1_after = (await someToken2.balanceOf(accOwner1)).toNumber();
            const a2_after = (await someToken2.balanceOf(accOwner2)).toNumber();
            const a3_after = (await someToken2.balanceOf(accOwner3)).toNumber();

            const ra1_after = await token.getRoyaltyAccount(tokenId_1);

            assert.equal(a1_after - a1_before, 0);
            assert.equal(a2_after - a2_before, 0.7 * costOfNFT);
            assert.equal(a3_after - a3_before, 0);

            assert.equal(ra1_after.subaccounts[0].accountId, accOwner2); //accOwner2 own token_1 anf receive 20%
            assert.equal(ra1_after.subaccounts[0].royaltyBalance - ra1_before.subaccounts[0].royaltyBalance, Math.floor(0.2 * 0.9 * costOfNFT)); // 90% of 20% royalty
        });
    });
});
