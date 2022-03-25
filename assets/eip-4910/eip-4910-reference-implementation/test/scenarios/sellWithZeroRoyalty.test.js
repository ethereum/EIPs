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
    const tokenId = 4;

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

    describe('Transfer NFT with 0% royalty', async () => {
        it('Create new NFT with few generations and few prints. Set royalty 0%', async () => {
            await token.mint(accSeller, [[0x0, true, 10, 1000, 'uri_1']], 'ST2', { from: accAdmin });
            await token.mint(accSeller, [[1, true, 10, 1000, 'uri_1']], 'ST2', { from: accAdmin });
            await token.mint(accSeller, [[2, true, 10, 0, 'uri_1']], 'ST2', { from: accAdmin }); // id=3 royalty from children = 0%
            await token.mint(accSeller, [[3, true, 10, 1000, 'uri_1']], 'ST2', { from: accAdmin }); //id=4 royalty to parent  = 0%
        });

        it('seller make listNFT', async () => {
            await token.listNFT([tokenId], costOfNFT, 'ST2', { from: accSeller });
        });

        it('buyer (Bob) approve ERC20 transfer for NFT Contract', async () => {
            await someToken2.approve(token.address, costOfNFT, { from: accBuyer });
            assert.equal((await someToken2.allowance(accBuyer, token.address, { from: accBuyer })).toString(), costOfNFT);
        });
        it('buyer execute the ERC20 payment with trxnt = 0 and buy tokens', async () => {
            await token.executePayment(accOwner4, accSeller, [tokenId], costOfNFT, 'ST2', 0, { from: accBuyer });
            assert.equal(await token.getApproved(tokenId), accBuyer, 'Token approved for owner');
        });
    });
});
