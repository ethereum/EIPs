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
    console.log('seller', accSeller);

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
    });

    describe('Transfer NFT token using ETH', async () => {
        before('', async () => {});

        it('mint root token to accOwner1', async () => {
            await token.mint(accOwner1, [[0x0, true, 10, 1000, 'uri_1']], 'ETH', { from: accAdmin });
            assert.equal((await token.balanceOf(token.address)).toString(), 1, 'Token balance must changed');
            assert.equal(await token.getApproved(tokenRootId), accOwner1, 'Token approved for owner');
        });

        it('mint first offspring token to accSeller', async () => {
            await token.mint(
                accSeller,
                [
                    [tokenRootId, true, 10, 200, 'uri_2'],
                    [tokenRootId, true, 10, 200, 'uri_3'],
                ],
                'ETH',
                { from: accAdmin },
            );
            assert.equal((await token.balanceOf(token.address)).toString(), 1 + 2, 'Token balance must changed');
            assert.equal(await token.getApproved(tokenId_1), accSeller, 'Token approved for owner');
            assert.equal(await token.getApproved(tokenId_2), accSeller, 'Token approved for owner');
        });

        it('seller make listNFT', async () => {
            await token.listNFT([tokenId_1, tokenId_2], costOfNFT, 'ETH', { from: accSeller });
        });

        it('buyer execute the ETH payment to Token contract and receive tokens', async () => {
            const balanceBefore = {
                accSeller: await web3.eth.getBalance(accSeller),
                accBuyer: await web3.eth.getBalance(accBuyer),
                token: await web3.eth.getBalance(token.address),
            };

            const royaltyBefore = {
                t1: await token.getRoyaltyAccount(tokenId_1),
                t2: await token.getRoyaltyAccount(tokenId_2),
            };
            assert.equal(royaltyBefore.t1.subaccounts[0].accountId, accSeller);
            assert.equal(royaltyBefore.t2.subaccounts[0].accountId, accSeller);

            const data = web3.eth.abi.encodeParameters(['address', 'uint256[]', 'address', 'int256'], [accSeller, [tokenId_1, tokenId_2], accBuyer, 0]);
            await web3.eth.sendTransaction({ from: accBuyer, to: token.address, value: costOfNFT, data: data, gas: 6000000 });

            const royaltyAfter = {
                root: await token.getRoyaltyAccount(tokenRootId),
                t1: await token.getRoyaltyAccount(tokenId_1),
                t2: await token.getRoyaltyAccount(tokenId_2),
            };
            assert.equal(royaltyAfter.t1.subaccounts[0].accountId, accBuyer);
            assert.equal(royaltyAfter.t2.subaccounts[0].accountId, accBuyer);

            const balanceAfter = {
                accSeller: await web3.eth.getBalance(accSeller),
                accBuyer: await web3.eth.getBalance(accBuyer),
                token: await web3.eth.getBalance(token.address),
            };

            assert.equal(royaltyAfter.root.subaccounts[0].royaltyBalance, 8, 'Royalty for parent must received'); //(90% of 5) x2 for owner
            assert.equal(royaltyAfter.root.subaccounts[1].royaltyBalance, 2, 'TT Royalty for parent must received'); //(10% of 5) x2 for TT
            assert.equal(royaltyAfter.t1.subaccounts[1].royaltyBalance, 5, 'TT Royalty for token1 must received'); //(10% of 50)  for TT
            assert.equal(royaltyAfter.t2.subaccounts[1].royaltyBalance, 5, 'TT Royalty for token2 must received'); //(10% of 50)  for TT
            assert.equal(balanceAfter.token - balanceBefore.token, 10 + 10, 'Balance changed only for royalty');
        });
    });
});
