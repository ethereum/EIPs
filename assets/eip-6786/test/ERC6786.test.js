const {deployContracts} = require("../scripts/deploy_contracts");
const {expect} = require('chai');

describe("ERC6786", () => {

    let erc721Royalty;
    let erc721;
    let royaltyDebtRegistry;
    const tokenId = 666;

    beforeEach(async () => {
        const contracts = await deployContracts();
        erc721Royalty = contracts.erc721Royalty;
        erc721 = contracts.erc721;
        royaltyDebtRegistry = contracts.royaltyDebtRegistry;
    })

    it('should support ERC6786 interface', async () => {
        await expect(await royaltyDebtRegistry.supportsInterface("0x253b27b0")).to.be.true;
    })

    it('should allow paying royalties for a ERC2981 NFT', async () => {
        await expect(royaltyDebtRegistry.payRoyalties(
            erc721Royalty.address,
            tokenId,
            {value: 1000}
        )).to.emit(royaltyDebtRegistry, 'RoyaltiesPaid')
            .withArgs(erc721Royalty.address, tokenId, 1000);
    })

    it('should not allow paying royalties for a non-ERC2981 NFT', async () => {
        await expect(royaltyDebtRegistry.payRoyalties(
            erc721.address,
            tokenId,
            {value: 1000}
        )).to.be.revertedWithCustomError(royaltyDebtRegistry,'CreatorError')
            .withArgs(erc721.address, tokenId);
    })

    it('should allow retrieving initial royalties amount for a NFT', async () => {
        await expect(await royaltyDebtRegistry.getPaidRoyalties(
            erc721Royalty.address,
            tokenId
        )).to.equal(0);
    })

    it('should allow retrieving royalties amount after payments for a NFT', async () => {
        await royaltyDebtRegistry.payRoyalties(
            erc721Royalty.address,
            tokenId,
            {value: 2000}
        );

        await royaltyDebtRegistry.payRoyalties(
            erc721Royalty.address,
            tokenId,
            {value: 3666}
        )

        await expect(await royaltyDebtRegistry.getPaidRoyalties(
            erc721Royalty.address,
            tokenId
        )).to.equal(5666);
    })
});
