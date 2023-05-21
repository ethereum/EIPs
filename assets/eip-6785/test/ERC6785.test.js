const {deployContracts} = require("../scripts/deploy_contracts");
const {expect} = require('chai');

describe('ERC5678', () => {
    let erc5678;
    const tokenId = 123;
    const utilityUrl1 = 'https://utility.url';

    beforeEach(async () => {
        erc5678 = await deployContracts();
    });

    it('should support ERC5678 interface', async () => {
        await expect(await erc5678.supportsInterface(
            await erc5678._INTERFACE_ID_ERC5678(),
        )).to.be.true;
    });

    it('should allow setting first utility NFT', async () => {
        await expect(erc5678.setUtilityUri(
            tokenId,
            utilityUrl1,
        )).to.emit(erc5678, 'UpdateUtility').withArgs(tokenId, utilityUrl1);
    });

    it('should allow retrieving initial royalties amount for a NFT',
        async () => {
            await expect(erc5678.setUtilityUri(
                tokenId,
                utilityUrl1,
            )).to.emit(erc5678, 'UpdateUtility').withArgs(tokenId, utilityUrl1);

            await expect(await erc5678.utilityUriOf(
                tokenId,
            )).to.equal(utilityUrl1);
    })

    it('should allow retrieving utility history for the NFT', async () => {
        await expect(erc5678.setUtilityUri(
            tokenId,
            utilityUrl1,
        )).to.emit(erc5678, 'UpdateUtility').withArgs(tokenId, utilityUrl1);
        let utilityUrl2 = utilityUrl1 + '_2';
        await expect(erc5678.setUtilityUri(
            tokenId,
            utilityUrl2,
        )).to.emit(erc5678, 'UpdateUtility').withArgs(tokenId, utilityUrl2);

        let history = await erc5678.utilityHistoryOf(
            tokenId,
        );
        await expect(history.length).to.equal(2);
        await expect(history[0]).to.equal(utilityUrl1);
        await expect(history[1]).to.equal(utilityUrl2);
    })
});
