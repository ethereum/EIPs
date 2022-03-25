const RoyaltyBearingToken = artifacts.require('RoyaltyBearingToken');
const PaymentModule = artifacts.require('PaymentModule');
const SomeERC20_1 = artifacts.require('SomeERC20_1');
const SomeERC20_2 = artifacts.require('SomeERC20_2');

const truffleAssert = require('truffle-assertions');
const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';
const MINTER_ROLE = web3.utils.keccak256('MINTER_ROLE');

contract('RoyaltyBearingToken', (accounts) => {
    const accAdmin = accounts[0];
    const accSeller = accounts[1];
    const accBuyer = accounts[2];
    const accReceiver = accounts[3];
    const accOtherBuyer = accounts[4];
    const accSomeOther = accounts[5];

    const costOfNFT = 100;
    const token_1 = 1;
    const token_1_1 = 2;
    const token_1_1_1 = 3;
    const token_1_1_2 = 4;
    const token_2 = 5;
    const token_not_exists = 999;

    let token;
    let someToken1;
    let someToken2;
    let paymentModule;

    before(async () => {
        someToken1 = await SomeERC20_1.deployed();
        someToken2 = await SomeERC20_2.deployed();
        token = await RoyaltyBearingToken.deployed();

        paymentModule = await PaymentModule.deployed();

        //Mint some  ERC20 tokens
        await someToken1.mint(accBuyer, 100000000, { from: accAdmin });
        await someToken2.mint(accBuyer, 100000000, { from: accAdmin });
        await someToken2.mint(accOtherBuyer, 100000000, { from: accAdmin });
    });

    describe('addAllowedTokenType restrictions', async () => {
        it('Caller must have admin role', async () => {
            await truffleAssert.reverts(token.addAllowedTokenType('ST1', someToken1.address, { from: accSomeOther }), 'Admin role required');
        });
        it('Duplicate not allowed', async () => {
            await truffleAssert.reverts(token.addAllowedTokenType('ST1_1', someToken1.address), 'Token is duplicate');
        });
        it('Token address must be contract', async () => {
            await truffleAssert.reverts(token.addAllowedTokenType('ST_Err', accSomeOther, { from: accAdmin }), 'Token must be contact');
        });
    });

    describe('Mint restrictions', async () => {
        it('Caller must have minter role', async () => {
            await truffleAssert.reverts(token.mint(accSeller, [[0x0, true, 10, 1000, 'uri_1']], 'ST2', { from: accSeller }), 'Minter or Creator role required');
        });
        it('To must not be zero', async () => {
            await truffleAssert.reverts(token.mint(ZERO_ADDRESS, [[0x0, true, 10, 1000, 'uri_1']], 'ST2', { from: accAdmin }), 'Zero Address cannot have active NFTs!');
        });
        it('To must not be contract', async () => {
            await truffleAssert.reverts(token.mint(someToken2.address, [[0x0, true, 10, 1000, 'uri_1']], 'ST2', { from: accAdmin }), ' To must not be contracts');
        });
        it('Parent must be zero or existing token', async () => {
            await truffleAssert.reverts(token.mint(accSeller, [[999, true, 10, 1000, 'uri_1']], 'ST2', { from: accAdmin }), 'Parent NFT does not exist');
        });
        it('Royalty split must be < 10000', async () => {
            await truffleAssert.reverts(token.mint(accSeller, [[0, true, 10, 10000 + 1, 'uri_1']], 'ST2', { from: accAdmin }), 'Royalty Split is > 100%');
        });
        it('Token list required', async () => {
            await truffleAssert.reverts(token.mint(accSeller, [], 'ST2', { from: accAdmin }), 'nfttokens has no value');
        });
        it('Token for payment must be registered', async () => {
            await truffleAssert.reverts(token.mint(accSeller, [[0x0, true, 10, 1000, 'uri_1']], 'ST3', { from: accAdmin }), 'Token Type not supported!');
        });
        it('Mint some tokens', async () => {
            //ERC20 tokens
            await token.mint(
                accSeller,
                [
                    [0x0, true, 10, 1000, 'uri_1'], // id = 1
                    [0x1, true, 10, 1000, 'uri_1.1'], // id = 2
                    [0x2, false, 10, 1000, 'uri_1.1.1'], // id = 3
                    [0x2, false, 10, 1000, 'uri_1.1.2'], // id = 4
                ],
                'ST2',
                { from: accAdmin },
            );
            //ETH tokens
            await token.mint(
                accSeller,
                [
                    [0x0, true, 10, 1000, 'uri_2'], // id = 5
                ],
                'ETH',
                { from: accAdmin },
            );
            assert.equal((await token.balanceOf(token.address)).toString(), 5, 'Token balance must changed');
            assert.equal(await token.hasRole(MINTER_ROLE, accSeller), true, 'CREATOR role must granted');
            assert.equal(await token.getApproved(1), accSeller, 'Token approved for owner');
            assert.equal(await token.getApproved(2), accSeller, 'Token approved for owner');
            assert.equal(await token.getApproved(3), accSeller, 'Token approved for owner');
        });
    });
    describe('listNFT restriction', async () => {
        it('Caller must be token owner', async () => {
            await truffleAssert.reverts(token.listNFT([1, 2, 3], costOfNFT, 'ST2', { from: accBuyer }), 'Must be token owner');
        });
        it('Token must exists', async () => {
            await truffleAssert.reverts(token.listNFT([1, 2, 99], costOfNFT, 'ST2', { from: accSeller }), 'ERC721: approved query for nonexistent token');
        });
        it('Payment token must be supported', async () => {
            await truffleAssert.reverts(token.listNFT([1, 2, 3], costOfNFT, 'ST3', { from: accSeller }), 'Unsupported token type');
        });
        it('Numbers of tokens must be less than limit', async () => {
            await token.updatelistinglimit(1, { from: accAdmin });
            await truffleAssert.reverts(token.listNFT([2, 3], costOfNFT, 'ST2', { from: accSeller }), 'Too many NFTs listed');
            await token.updatelistinglimit(10, { from: accAdmin });
        });
        it('List NFT (2,3)', async () => {
            await token.listNFT([2, 3], costOfNFT, 'ST2', { from: accSeller });
        });
        it('Only one list allowed. Try list (2,3) when (2,3) are listed', async () => {
            await truffleAssert.reverts(token.listNFT([2, 3], costOfNFT, 'ST2', { from: accSeller }), 'Already exists');
        });
        it('Token can listed only once in bundles. Try (1,2) when (2,3) are listed', async () => {
            await truffleAssert.reverts(token.listNFT([1, 2], costOfNFT, 'ST2', { from: accSeller }), 'Already exists');
        });
        it('List NFT (1)', async () => {
            await token.listNFT([1], costOfNFT, 'ST2', { from: accSeller });
        });
        it('List NFT (5) by ETH', async () => {
            await token.listNFT([5], costOfNFT, 'ETH', { from: accSeller });
        });
    });
    describe('removeNFTListing restriction', async () => {
        it('Caller must be token owner', async () => {
            await truffleAssert.reverts(token.removeNFTListing(1, { from: accBuyer }), 'Must be token owner');
        });
        it('Unlist NFT (1)', async () => {
            await token.removeNFTListing(1, { from: accSeller });
        });
        it('List NFT (1)', async () => {
            await token.listNFT([1], costOfNFT, 'ST2', { from: accSeller });
        });
    });
    describe('PaymentModule', async () => {
        it('getListNFT function', async () => {
            const result = await paymentModule.getListNFT(1);
            assert.equal(result.seller, accSeller);
            assert.equal(result.tokenType, 'ST2');
            assert.equal(result.price, 100);
        });
        it('getAllListNFT function', async () => {
            const result = await paymentModule.getAllListNFT();
            assert.equal(result[0].toNumber(), 2);
            assert.equal(result[1].toNumber(), 5);
            assert.equal(result[2].toNumber(), 1);
        });
    });

    describe('executePayment restriction', (async) => {
        it('Only supported transaction type allowed', async () => {
            await truffleAssert.reverts(token.executePayment(accReceiver, accSeller, [2, 3], costOfNFT, 'ST2', 2, { from: accBuyer }), 'Trxn type not supported');
        });
        it('Receiver must be non zero', async () => {
            await truffleAssert.reverts(token.executePayment(ZERO_ADDRESS, accSeller, [2, 3], costOfNFT, 'ST2', 0, { from: accBuyer }), 'Receiver must not be zero');
        });
        it('Only supported token type allowed', async () => {
            await truffleAssert.reverts(token.executePayment(accReceiver, accSeller, [2, 3], costOfNFT, 'ST1', 0, { from: accBuyer }), 'Payment token does not match list token type');
        });
        it('Token allowance must be set', async () => {
            await truffleAssert.reverts(token.executePayment(accReceiver, accSeller, [2, 3], costOfNFT, 'ST2', 0, { from: accBuyer }), 'Insufficient token allowance');
        });
        it('Payment must be for existing list', async () => {
            await truffleAssert.reverts(token.executePayment(accReceiver, accSeller, [token_not_exists], costOfNFT, 'ST2', 0, { from: accBuyer }), 'Token does not exist');
        });
        it('Seller must be equals to seller in list', async () => {
            await truffleAssert.reverts(token.executePayment(accReceiver, accSomeOther, [2, 3], costOfNFT, 'ST2', 0, { from: accBuyer }), 'Seller is not owner');
        });
        it('Payment must be not low', async () => {
            await truffleAssert.reverts(token.executePayment(accReceiver, accSeller, [2, 3], costOfNFT * 0.5, 'ST2', 0, { from: accBuyer }), 'Payment is too low');
        });
        it('Token list must mach to listed tokens', async () => {
            await truffleAssert.reverts(token.executePayment(accReceiver, accSeller, [2, 1], costOfNFT, 'ST2', 0, { from: accBuyer }), 'One or more tokens are not listed');
        });
        it('Payment nust be > 0', async () => {
            await truffleAssert.reverts(token.executePayment(accReceiver, accSeller, [2, 3], 0, 'ST2', 0, { from: accBuyer }), 'Payments cannot be 0!');
        });
        it('Payment ignore other trxntype', async () => {
            await truffleAssert.reverts(token.executePayment(accReceiver, accSeller, [2, 3], costOfNFT, 'ST2', 4, { from: accBuyer }), 'Trxn type not supported');
        });

        it('Payment for (2,3) trxntype=0 success', async () => {
            await someToken2.approve(token.address, costOfNFT, { from: accBuyer });
            await token.executePayment(accReceiver, accSeller, [2, 3], costOfNFT, 'ST2', 0, { from: accBuyer });
            assert.equal(await token.getApproved(2), accBuyer, 'Token must transfer to buyer');
            assert.equal(await token.getApproved(3), accBuyer, 'Token must transfer to buyer');
        });
        it('Only 1 payment allowed for (2,3). (2,3) was already sold', async () => {
            await someToken2.approve(token.address, costOfNFT, { from: accBuyer });
            await truffleAssert.reverts(token.executePayment(accReceiver, accSeller, [2, 3], costOfNFT, 'ST2', 0, { from: accBuyer }), 'Seller is not owner');
        });
        it('Payment for (1) trxntype=1 must have right token type', async () => {
            await someToken1.approve(token.address, costOfNFT, { from: accBuyer });
            await truffleAssert.reverts(token.executePayment(accReceiver, accSeller, [1], costOfNFT, 'ST1', 1, { from: accBuyer }), 'Payment token does not match list token type');
        });
        it('Payment for (1) trxntype=1 success', async () => {
            await someToken2.approve(token.address, costOfNFT, { from: accBuyer });
            await token.executePayment(accReceiver, accSeller, [1], costOfNFT, 'ST2', 1, { from: accBuyer });
            assert.equal(await token.getApproved(1), accSeller, 'Token must transfer manual later');
        });
        it('Undo payment for (1) trxntype=1 success', async () => {
            await token.reversePayment(1, 'ST2', { from: accBuyer });
        });
        it('Retry payment for (1) trxntype=1 success', async () => {
            await someToken2.approve(token.address, costOfNFT, { from: accBuyer });
            await token.executePayment(accReceiver, accSeller, [1], costOfNFT, 'ST2', 1, { from: accBuyer });
        });
        it('Second payment for (1) trxntype=1 not allowed', async () => {
            await someToken2.approve(token.address, costOfNFT, { from: accOtherBuyer });
            await truffleAssert.reverts(token.executePayment(accReceiver, accSeller, [1], costOfNFT, 'ST2', 1, { from: accOtherBuyer }), 'RegisterPayment already exists');
        });
        it('Can not unlist token after pay', async () => {
            await truffleAssert.reverts(token.removeNFTListing(1, { from: accSeller }), 'RegisterPayment exists for NFT');
        });
        it('checkPayment must have valid token type', async () => {
            await truffleAssert.reverts(token.checkPayment(1, 'ST1', accBuyer, { from: accSeller }), 'TokenType mismatch');
        });
        it('reversePayment fails if payment not exists', async () => {
            await truffleAssert.reverts(token.reversePayment(1, 'ST2', { from: accSomeOther }), 'No payment registered');
        });
        it('Payment for (5) must have right transaction type', async () => {
            const data = web3.eth.abi.encodeParameters(['address', 'uint256[]', 'address', 'int256'], [accSeller, [5], accBuyer, 3]);
            await truffleAssert.reverts(web3.eth.sendTransaction({ from: accBuyer, to: token.address, value: costOfNFT, data: data, gas: 1000000 }), 'Trxn type not supported');
        });

        it('Payment for (5) trxntype=1 success', async () => {
            const data = web3.eth.abi.encodeParameters(['address', 'uint256[]', 'address', 'int256'], [accSeller, [5], accBuyer, 1]);
            await web3.eth.sendTransaction({ from: accBuyer, to: token.address, value: costOfNFT, data: data, gas: 1000000 });
            assert.equal(await token.getApproved(5), accSeller, 'Token must transfer manual later');
            const payment = await token.checkPayment(5, 'ETH', accBuyer, { from: accSeller });
            assert.equal(payment.toNumber(), costOfNFT);
        });
        it('reversePayment for (5) success', async () => {
            await token.reversePayment(5, 'ETH', { from: accBuyer });
            const payment = await token.checkPayment(5, 'ETH', accBuyer, { from: accSeller });
            assert.equal(payment.toNumber(), 0);
        });
    });
    describe('safeTransferFrom restrictions', async () => {
        it('Wrong metadata: seller address', async () => {
            const data = web3.eth.abi.encodeParameters(
                ['address', 'address', 'address', 'uint256[]', 'string', 'uint256', 'address', 'uint256'],
                [accSomeOther, accBuyer, accBuyer, [1], 'ST2', costOfNFT, someToken2.address, 1],
            );
            await truffleAssert.reverts(token.methods['safeTransferFrom(address,address,uint256,bytes)'](accSeller, accBuyer, 1, data, { from: accSeller }), 'Seller not From address');
        });
        it('Wrong metadata: receiver address', async () => {
            const data = web3.eth.abi.encodeParameters(
                ['address', 'address', 'address', 'uint256[]', 'string', 'uint256', 'address', 'uint256'],
                [accSeller, accBuyer, accSomeOther, [1], 'ST2', costOfNFT, someToken2.address, 1],
            );
            await truffleAssert.reverts(token.methods['safeTransferFrom(address,address,uint256,bytes)'](accSeller, accBuyer, 1, data, { from: accSeller }), 'Receiver not To address');
        });

        it('Wrong metadata: wrong payment', async () => {
            const data = web3.eth.abi.encodeParameters(
                ['address', 'address', 'address', 'uint256[]', 'string', 'uint256', 'address', 'uint256'],
                [accSeller, accBuyer, accBuyer, [1], 'ST2', costOfNFT + 1, someToken2.address, 1],
            );
            await truffleAssert.reverts(token.methods['safeTransferFrom(address,address,uint256,bytes)'](accSeller, accBuyer, 1, data, { from: accSeller }), 'Payment not match');
        });

        it('Wrong metadata: token ids', async () => {
            const data = web3.eth.abi.encodeParameters(
                ['address', 'address', 'address', 'uint256[]', 'string', 'uint256', 'address', 'uint256'],
                [accSeller, accBuyer, accBuyer, [2], 'ST2', costOfNFT, someToken2.address, 1],
            );
            await truffleAssert.reverts(token.methods['safeTransferFrom(address,address,uint256,bytes)'](accSeller, accBuyer, 1, data, { from: accSeller }), 'Wrong NFT listing');
        });
        it('Wrong metadata: pay token symbol', async () => {
            const data = web3.eth.abi.encodeParameters(
                ['address', 'address', 'address', 'uint256[]', 'string', 'uint256', 'address', 'uint256'],
                [accSeller, accBuyer, accBuyer, [1], 'ST1', costOfNFT, someToken2.address, 1],
            );
            await truffleAssert.reverts(token.methods['safeTransferFrom(address,address,uint256,bytes)'](accSeller, accBuyer, 1, data, { from: accSeller }), 'TokenType not match');
        });
        it('Wrong metadata: wrong chain id', async () => {
            const data = web3.eth.abi.encodeParameters(
                ['address', 'address', 'address', 'uint256[]', 'string', 'uint256', 'address', 'uint256'],
                [accSeller, accBuyer, accBuyer, [1], 'ST2', costOfNFT, someToken2.address, 999],
            );
            await truffleAssert.reverts(token.methods['safeTransferFrom(address,address,uint256,bytes)'](accSeller, accBuyer, 1, data, { from: accSeller }), 'Transfer on wrong Blockchain');
        });
        it('Token list must be owned by seller', async () => {
            const data = web3.eth.abi.encodeParameters(
                ['address', 'address', 'address', 'uint256[]', 'string', 'uint256', 'address', 'uint256'],
                [accSeller, accBuyer, accBuyer, [1, 2], 'ST2', costOfNFT, someToken2.address, 1],
            );
            await truffleAssert.reverts(token.methods['safeTransferFrom(address,address,uint256,bytes)'](accSeller, accBuyer, 1, data, { from: accSeller }), 'Seller is not owner');
        });

        it('Transfer (1) success', async () => {
            const data = web3.eth.abi.encodeParameters(
                ['address', 'address', 'address', 'uint256[]', 'string', 'uint256', 'address', 'uint256'],
                [accSeller, accBuyer, accBuyer, [1], 'ST2', costOfNFT, someToken2.address, 1],
            );
            //truffle fail to select valid method safeTransferFrom
            //await token.safeTransferFrom(accSeller, accOwner3, tokenId, data,{from:accSeller});
            //workaround for this
            await token.methods['safeTransferFrom(address,address,uint256,bytes)'](accSeller, accBuyer, 1, data, { from: accSeller });
            assert.equal(await token.getApproved(1), accBuyer, 'Token must transferred');
        });

        it('Repeat transfer not allowed', async () => {
            const data = web3.eth.abi.encodeParameters(
                ['address', 'address', 'address', 'uint256[]', 'string', 'uint256', 'address', 'uint256'],
                [accSeller, accBuyer, accBuyer, [1], 'ST2', costOfNFT, someToken2.address, 1],
            );
            await truffleAssert.reverts(token.methods['safeTransferFrom(address,address,uint256,bytes)'](accSeller, accBuyer, 1, data, { from: accSeller }), 'RegisterPayment not found');
        });
    });
    describe('royaltyPayOut restrictions', async () => {
        it('Only subaccount owner can run payout', async () => {
            await truffleAssert.reverts(token.royaltyPayOut(token_1, accBuyer, accBuyer, 1, { from: accOtherBuyer }), 'Sender must be subaccount owner');
            await truffleAssert.reverts(token.royaltyPayOut(token_1_1, accBuyer, accBuyer, 1, { from: accOtherBuyer }), 'Sender must be subaccount owner');
            await truffleAssert.reverts(token.royaltyPayOut(token_1_1_1, accBuyer, accBuyer, 1, { from: accOtherBuyer }), 'Sender must be subaccount owner');
        });
        it('Payout limited to royalty balance', async () => {
            await truffleAssert.reverts(token.royaltyPayOut(token_1_1, accBuyer, accBuyer, 999, { from: accBuyer }), 'Insufficient royalty balance');
        });
        it('Payout for non exist NFT restricted', async () => {
            await truffleAssert.reverts(token.royaltyPayOut(token_not_exists, accBuyer, accBuyer, 1, { from: accBuyer }), 'Subaccount not found');
        });
        it('Success payout', async () => {
            const ra_1_1_before = await token.getRoyaltyAccount(token_1_1);
            await token.royaltyPayOut(2, accBuyer, accBuyer, 1, { from: accBuyer });
            const ra_1_1_after = await token.getRoyaltyAccount(token_1_1);
            assert.equal(ra_1_1_before.subaccounts[0].royaltyBalance - 1, ra_1_1_after.subaccounts[0].royaltyBalance, 'Royalty changed after payout');
        });
    });
    describe('burn restrictions', async () => {
        it('Burn restricted for MINTER_ROLE', async () => {
            await truffleAssert.reverts(token.burn(token_1_1_1, { from: accSomeOther }), 'Sender not authorized to burn');
        });
        it('Burn token with royalty ballance not allowed', async () => {
            await truffleAssert.reverts(token.burn(token_1_1_1, { from: accBuyer }), "Can't delete non empty royalty account");
        });
        it('Burn token with children not allowed', async () => {
            await truffleAssert.reverts(token.burn(token_1_1, { from: accBuyer }), 'NFT must not have children');
        });
        it('Burn token must exists', async () => {
            await truffleAssert.reverts(token.burn(token_not_exists, { from: accBuyer }), 'ERC721: approved query for nonexistent token');
        });
        it('Payout TT royalty from (3)', async () => {
            const ra_1_1_1_before = await token.getRoyaltyAccount(token_1_1_1);
            await token.royaltyPayOut(token_1_1_1, accAdmin, accAdmin, ra_1_1_1_before.subaccounts[1].royaltyBalance, { from: accAdmin });
            const ra_1_1_1_after = await token.getRoyaltyAccount(token_1_1_1);
            assert.equal(ra_1_1_1_after.subaccounts[1].royaltyBalance, 0);
        });
        it('Burn token without children and 0 royalty success', async () => {
            await token.burn(token_1_1_1, { from: accBuyer });
        });
    });
    describe('Other transfer function restrictions', async () => {
        it('transferFrom(address,address,uint256) not allowed', async () => {
            await truffleAssert.reverts(token.transferFrom(ZERO_ADDRESS, ZERO_ADDRESS, 0, { from: accBuyer }), 'Function not allowed');
        });
        it('safeTransferFrom(address,address,uint256) not allowed', async () => {
            await truffleAssert.reverts(token.safeTransferFrom(ZERO_ADDRESS, ZERO_ADDRESS, 0, { from: accBuyer }), 'Function not allowed');
        });
    });
    describe('updateMaxChildren restrictions', async () => {
        it('updateMaxChildren not allowed without CREATOR_ROLE', async () => {
            await truffleAssert.reverts(token.updateMaxChildren(token_1_1, 0, { from: accSomeOther }), 'Creator role required');
        });
        it('updateMaxChildren not allowed new limit bellow actual children', async () => {
            await truffleAssert.reverts(token.updateMaxChildren(token_1_1, 0, { from: accAdmin }), 'Max < Actual');
        });
        it('updateMaxChildren success', async () => {
            await token.updateMaxChildren(token_1_1, 3, { from: accAdmin });
        });
    });
    describe('updateMaxGenerations restrictions', async () => {
        it('updateMaxGenerations not allowed without CREATOR_ROLE', async () => {
            await truffleAssert.reverts(token.updateMaxGenerations(5, { from: accSomeOther }), 'Creator role required');
        });
        it('updateMaxGenerations success', async () => {
            await token.updateMaxGenerations(1, { from: accAdmin });
        });
        it('mint not allowed for new generations', async () => {
            await truffleAssert.reverts(token.mint(accSeller, [[token_1_1, true, 10, 1000, 'uri_1.1.1.1']], 'ST2', { from: accAdmin }), 'Generation limit');
        });
        it('updateMaxGenerations success', async () => {
            await token.updateMaxGenerations(5, { from: accAdmin });
        });
    });
    describe('Minor function coverage', async () => {
        it('getAllowedTokens', async () => {
            const result = await token.getAllowedTokens();
            assert.equal(result.length, 3);
            assert.equal(result[0], token.address);
            assert.equal(result[1], someToken1.address);
            assert.equal(result[2], someToken2.address);
        });
        it('getModules', async () => {
            const modules = await token.getModules();
            assert.equal(Object.keys(modules).length, 2);
        });
        it('tokenURI', async () => {
            const uri = await token.tokenURI(token_1_1);
            assert.equal(uri, 'https:\\\\some.base.url\\uri_1.1');
        });
        it('tokenURI for burned not allowed', async () => {
            await await truffleAssert.reverts(token.tokenURI(token_1_1_1), 'URI query for nonexistent token');
        });
        it('pause not allowed without PAUSER_ROLE', async () => {
            await truffleAssert.reverts(token.pause({ from: accSomeOther }), 'Pauser role required');
        });
        it('unpause not allowed without PAUSER_ROLE', async () => {
            await truffleAssert.reverts(token.unpause({ from: accSomeOther }), 'Pauser role required');
        });
        it('pause success for PAUSER_ROLE', async () => {
            await token.pause({ from: accAdmin });
        });
        it('unpause success for PAUSER_ROLE', async () => {
            await token.unpause({ from: accAdmin });
        });
        it('supportsInterface', async () => {
            const result = await token.supportsInterface('0x0000');
            assert.equal(result, false);
        });
        it('second init call not allowed', async () => {
            await truffleAssert.reverts(token.init(ZERO_ADDRESS, ZERO_ADDRESS, { from: accAdmin }), 'Init was called before');
        });
        it('updatelistinglimit caller must be creator', async () => {
            await truffleAssert.reverts(token.updatelistinglimit(10, { from: accSomeOther }), 'Creator role required');
        });
        it('updateRAccountLimits caller must be creator', async () => {
            await truffleAssert.reverts(token.updateRAccountLimits(10, 10, { from: accSomeOther }), 'Creator role required');
        });
        it('onERC721Received accept only own tokens', async () => {
            await truffleAssert.reverts(token.onERC721Received(ZERO_ADDRESS, accSomeOther, 1, '0x0', { from: accSomeOther }), 'Only minted');
        });
        it('getRoyaltyAccount cant get not exist token', async () => {
            await truffleAssert.reverts(token.getRoyaltyAccount(token_not_exists, { from: accSomeOther }), 'NFT does not exist');
        });
    });
    describe('Delegate call', async () => {
        const funcSig1 = web3.utils.keccak256('updateMaxGenerations(uint256)').substring(0, 6);
        const funcSig2 = web3.utils.keccak256('updatelistinglimit(uint256)').substring(0, 6);
        console.log('funcSig2', funcSig2);
        it('Only creator can call setFunctionSignature', async () => {
            await truffleAssert.reverts(token.setFunctionSignature(funcSig1, { from: accSomeOther }), 'Admin or Creator role required');
        });
        it('Set signatures', async () => {
            await token.setFunctionSignature(funcSig1, { from: accAdmin });
        });

        it('Only registered function can be called', async () => {
            await truffleAssert.reverts(
                token.delegateAuthority(
                    funcSig2,
                    web3.utils.randomHex(32), //
                    web3.utils.randomHex(32),
                    [0,1,2],
                    [web3.utils.randomHex(32)],
                    [web3.utils.randomHex(32)],
                    1,
                    { from: accAdmin },
                ),
                'Not a valid function',
            );
        });
        it('Invalid signature not allowed', async () => {
            await truffleAssert.reverts(
                token.delegateAuthority(
                    funcSig1,
                    web3.utils.randomHex(32), //
                    web3.utils.randomHex(32),
                    [0,1,2],
                    [web3.utils.randomHex(32)],
                    [web3.utils.randomHex(32)],
                    1,
                    { from: accAdmin },
                ),
                'Signature',
            );
        });
    });
});
