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

    describe('Transfer NFT token using ERC20', async () => {
        before('', async () => {});

        it('mint root token to accOwner1', async () => {
            await token.mint(accOwner1, [[0x0, true, 10, 1000,"uri_1"]], 'ST2', { from: accAdmin });
            assert.equal((await token.balanceOf(token.address)).toString(), 1, 'Token balance must changed');
            assert.equal(await token.getApproved(tokenRootId), accOwner1, 'Token approved for owner');
        });

        it('mint first offspring token to accSeller', async () => {
            await token.mint(
                accSeller,
                [
                    [tokenRootId, true, 10, 200,"uri_2"],
                    [tokenRootId, true, 10, 200,"uri_3"],
                ],
                'ST2',
                { from: accAdmin },
            );
            assert.equal((await token.balanceOf(token.address)).toString(), 1 + 2, 'Token balance must changed');
            assert.equal(await token.getApproved(tokenId_1), accSeller, 'Token approved for owner');
            assert.equal(await token.getApproved(tokenId_2), accSeller, 'Token approved for owner');
        });

        it('seller make listNFT', async () => {
            await token.listNFT([tokenId_1, tokenId_2], costOfNFT, 'ST2', { from: accSeller });
        });

        it('buyer (Bob) approve ERC20 transfer for NFT Contract', async () => {
            await someToken2.approve(token.address, costOfNFT, { from: accBuyer });
            assert.equal((await someToken2.allowance(accBuyer, token.address, { from: accBuyer })).toString(), costOfNFT);
        });

        it('buyer execute the ERC20 payment with trxnt = 0 and buy tokens', async () => {
            const balanceBefore = {
                accSeller: await someToken2.balanceOf(accSeller),
                accBuyer: await someToken2.balanceOf(accBuyer),
            };

            const royaltyBefore = {
                t1: await token.getRoyaltyAccount(tokenId_1),
                t2: await token.getRoyaltyAccount(tokenId_2),
            };
            assert.equal(royaltyBefore.t1.subaccounts[0].accountId, accSeller);
            assert.equal(royaltyBefore.t2.subaccounts[0].accountId, accSeller);

            await token.executePayment(accOwner4, accSeller, [tokenId_1, tokenId_2], costOfNFT, 'ST2', 0, { from: accBuyer });

            assert.equal(await token.getApproved(tokenId_1), accBuyer, 'Token approved for owner');
            assert.equal(await token.getApproved(tokenId_2), accBuyer, 'Token approved for owner');

            const royaltyAfter = {
                root: await token.getRoyaltyAccount(tokenRootId),
                t1: await token.getRoyaltyAccount(tokenId_1),
                t2: await token.getRoyaltyAccount(tokenId_2),
            };
            assert.equal(royaltyAfter.t1.subaccounts[0].accountId, accBuyer);
            assert.equal(royaltyAfter.t2.subaccounts[0].accountId, accBuyer);

            const balanceAfter = {
                accSeller: await someToken2.balanceOf(accSeller),
                accBuyer: await someToken2.balanceOf(accBuyer),
            };
            assert.equal(royaltyAfter.root.subaccounts[0].royaltyBalance, 8, 'Royalty for parent must received'); //(90% of 5) x2 for owner
            assert.equal(royaltyAfter.root.subaccounts[1].royaltyBalance, 2, 'TT Royalty for parent must received'); //(10% of 5) x2 for TT
            assert.equal(royaltyAfter.t1.subaccounts[1].royaltyBalance, 5, 'TT Royalty for token1 must received'); //(10% of 50)  for TT
            assert.equal(royaltyAfter.t2.subaccounts[1].royaltyBalance, 5, 'TT Royalty for token2 must received'); //(10% of 50)  for TT

            assert.equal(balanceAfter.accSeller.toNumber() - balanceBefore.accSeller.toNumber(), costOfNFT - 10 - 10, 'Payout for Seller');
        });
    });
});
