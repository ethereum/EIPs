const RoyaltyModule = artifacts.require('RoyaltyModule');
const PaymentModule = artifacts.require('PaymentModule');
const RoyaltyBearingToken = artifacts.require('RoyaltyBearingToken');
const SomeERC20_1 = artifacts.require('SomeERC20_1');
const SomeERC20_2 = artifacts.require('SomeERC20_2');

const numGenerations = 100;

module.exports = function (deployer, network, accounts) {
    console.log('Deploy to network:', network);
    if (network == 'development' || network == 'soliditycoverage' || network == 'mumbai') {
        deployer.then(async () => {
            const ERC20_1 = await deployer.deploy(SomeERC20_1, 'Some test token #1', 'ST1');
            const ERC20_2 = await deployer.deploy(SomeERC20_2, 'Some test token #2', 'ST2');

            const token = await deployer.deploy(
                RoyaltyBearingToken,
                'RoyaltyBearingToken',
                'RBT',
                'https:\\\\some.base.url\\',
                ['ETH', 'ST1', 'ST2'],
                ['0x0000000000000000000000000000000000000000', ERC20_1.address, ERC20_2.address],
                accounts[0],
                100, //numGenerations
            );

            const royaltyModule = await deployer.deploy(
                RoyaltyModule,
                token.address,
                accounts[0], //TT Royalty,
                1000, // royaltySplitTT 1000 = 10%,
                500, //minRoyaltySplit
                5, //maxSubAccount
            );
            const paymentModule = await deployer.deploy(
                PaymentModule,
                token.address,
                10, //maxListingNumber
            );

            await token.init(royaltyModule.address, paymentModule.address);

            console.log('token:', token.address);
        });
        /*
        deployer.deploy(RoyaltyBearingToken, 'A', 'RBT', 'C').then((contract) => {
            console.log("Token deployed with address", contract.address);
        });
        */
    }
};
