const Faucet = artifacts.require('Faucet');
const WETH_Mock = artifacts.require('WETH_Mock');

//const WETHaddress = '0xb225B1a0873B933004AcF480Bc62cBF67533c2Bd';
const TokenToMint = '10000000000000000000000000000000000000';

module.exports = function (deployer, network, accounts) {
    if (network == 'mumbai') {
        console.log('Deploy Faucet to network:', network);
        /*
        deployer.then(async () => {
            const mockWETH = await deployer.deploy(WETH_Mock,'WETH Mock token', 'WETH');
            const faucet = await deployer.deploy(Faucet, mockWETH.address);
            await mockWETH.mint(faucet.address, TokenToMint);
            const balance = await faucet.getBalance();

            console.log('WETH mock:', mockWETH.address);
            console.log('Faucet:', faucet.address);
            console.log('Faucet balance:', balance.toString());
            
        });
        */

        deployer.then(async () => {
            const faucet = await Faucet.at('0xf1D50435131169e4A176ef502917eCaAeA958b62');
            const mockWETH = await WETH_Mock.at('0xF087BBD87Dc6188914572C4F184998bD509c480f');
            //const faucet = await deployer.deploy(Faucet, mockWETH.address);
            await mockWETH.mint(faucet.address, TokenToMint);

            const listToMint = [
                //'0x93F4c85915BCbe0dAF8C5466D9Ec796672336584',
                //'0x7Dfc51EB31eaE117d4c81E8C61622d8407bA1C0e',
                //'0xB22cD6298c234f7Ca2e9eE34D7B24E0A80f71C5b',
                //'0x9D2E14F6E616d1348c9ddb89883fE73ae0Ca5BE5',
                //'0x6e58E675F0D05bC5ab14806246cb7EA41D4C6dc2',
                //'0xB22cD6298c234f7Ca2e9eE34D7B24E0A80f71C5b',
                //'0xd2a54f534D65bb1C34fC8c63Adc3c91E963390E8',
                //'0xcd3497E7769aD22Aab2470DC5CA4494433c08180',
            ];

            console.log('Faucet:', faucet.address);
            for (let i = 0; i < listToMint.length; i++) {
                try {
                    await faucet.requestTokensTo(listToMint[i]);
                    console.log('Token sent to:', listToMint[i], (await mockWETH.balanceOf(listToMint[i])).toString());
                } catch (ex) {
                    console.log('Token not sent:', listToMint[i], ex);
                }
            }
        });
    }
};
