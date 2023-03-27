require("@nomicfoundation/hardhat-toolbox");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
    solidity: {
        compilers: [
            {
                version: "0.8.17"
            }
        ]
    },
    networks: {
        hardhat: {
            forking: {
                url: 'https://rpc-mumbai.maticvigil.com/',
            },
            chainId: 80001,
            gas: 'auto',
            gasMultiplier: 1,
        },
    }
};
