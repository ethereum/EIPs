const {deployContracts} = require("../scripts/deploy_contracts");
const {expect} = require('chai');

describe('ERC6785', () => {
    let erc6785;
    const tokenId = 123;
    const utilityUrl1 = 'https://utility.url';

    beforeEach(async () => {
        erc6785 = await deployContracts();
    });

    it('should support ERC6785 interface', async () => {
        await expect(await erc6785.supportsInterface(
            await erc6785._INTERFACE_ID_ERC6785(),
        )).to.be.true;
    });

    it('should allow setting first utility NFT', async () => {
        await expect(erc6785.setUtilityUri(
            tokenId,
            utilityUrl1,
        )).to.emit(erc6785, 'UpdateUtility').withArgs(tokenId, utilityUrl1);
    });

    it('should allow retrieving initial royalties amount for a NFT',
        async () => {
            await expect(erc6785.setUtilityUri(
                tokenId,
                utilityUrl1,
            )).to.emit(erc6785, 'UpdateUtility').withArgs(tokenId, utilityUrl1);

            await expect(await erc6785.utilityUriOf(
                tokenId,
            )).to.equal(utilityUrl1);
    })

    it('should allow retrieving utility history for the NFT', async () => {
        await expect(erc6785.setUtilityUri(
            tokenId,
            utilityUrl1,
        )).to.emit(erc6785, 'UpdateUtility').withArgs(tokenId, utilityUrl1);
        let utilityUrl2 = utilityUrl1 + '_2';
        await expect(erc6785.setUtilityUri(
            tokenId,
            utilityUrl2,
        )).to.emit(erc6785, 'UpdateUtility').withArgs(tokenId, utilityUrl2);

        let history = await erc6785.utilityHistoryOf(
            tokenId,
        );
        await expect(history.length).to.equal(2);
        await expect(history[0]).to.equal(utilityUrl1);
        await expect(history[1]).to.equal(utilityUrl2);
    })
});
