import { ethers } from 'hardhat';
import { expect } from 'chai';
import {
  ERC721ReceiverMock,
  MultiResourceReceiverMock,
  MultiResourceTokenMock,
  NonReceiverMock,
  MultiResourceRenderUtils,
} from '../typechain-types';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';

describe('MultiResource', async () => {
  let token: MultiResourceTokenMock;
  let renderUtils: MultiResourceRenderUtils;
  let nonReceiver: NonReceiverMock;
  let receiver721: ERC721ReceiverMock;

  let owner: SignerWithAddress;
  let addrs: SignerWithAddress[];

  const name = 'RmrkTest';
  const symbol = 'RMRKTST';

  const metaURIDefault = 'metaURI';

  beforeEach(async () => {
    const [signersOwner, ...signersAddr] = await ethers.getSigners();
    owner = signersOwner;
    addrs = signersAddr;

    const multiresourceFactory = await ethers.getContractFactory('MultiResourceTokenMock');
    token = await multiresourceFactory.deploy(name, symbol);
    await token.deployed();

    const renderFactory = await ethers.getContractFactory('MultiResourceRenderUtils');
    renderUtils = await renderFactory.deploy();
    await renderUtils.deployed();
  });

  describe('Init', async function () {
    it('Name', async function () {
      expect(await token.name()).to.equal(name);
    });

    it('Symbol', async function () {
      expect(await token.symbol()).to.equal(symbol);
    });
  });

  describe('ERC165 check', async function () {
    it('can support IERC165', async function () {
      expect(await token.supportsInterface('0x01ffc9a7')).to.equal(true);
    });

    it('can support IERC721', async function () {
      expect(await token.supportsInterface('0x80ac58cd')).to.equal(true);
    });

    it('can support IMultiResource', async function () {
      expect(await token.supportsInterface('0xb0ecc5ae')).to.equal(true);
    });

    it('cannot support other interfaceId', async function () {
      expect(await token.supportsInterface('0xffffffff')).to.equal(false);
    });
  });

  describe('Check OnReceived ERC721 and Multiresource', async function () {
    it('Revert on transfer to non onERC721/onMultiresource implementer', async function () {
      const tokenId = 1;
      await token.mint(owner.address, tokenId);

      const NonReceiver = await ethers.getContractFactory('NonReceiverMock');
      nonReceiver = await NonReceiver.deploy();
      await nonReceiver.deployed();

      await expect(
        token
          .connect(owner)
          ['safeTransferFrom(address,address,uint256)'](owner.address, nonReceiver.address, 1),
      ).to.be.revertedWith('MultiResource: transfer to non ERC721 Receiver implementer');
    });

    it('onERC721Received callback on transfer', async function () {
      const tokenId = 1;
      await token.mint(owner.address, tokenId);

      const ERC721Receiver = await ethers.getContractFactory('ERC721ReceiverMock');
      receiver721 = await ERC721Receiver.deploy();
      await receiver721.deployed();

      await token
        .connect(owner)
        ['safeTransferFrom(address,address,uint256)'](owner.address, receiver721.address, 1);
      expect(await token.ownerOf(1)).to.equal(receiver721.address);
    });
  });

  describe('Resource storage', async function () {
    it('can add resource', async function () {
      const id = 10;

      await expect(token.addResourceEntry(id, metaURIDefault))
        .to.emit(token, 'ResourceSet')
        .withArgs(id);
    });

    it('cannot get non existing resource', async function () {
      const tokenId = 1;
      const resId = 10;
      await token.mint(owner.address, tokenId);
      await expect(token.getResourceMetadata(tokenId, resId)).to.be.revertedWith(
        'MultiResource: Token does not have resource',
      );
    });

    it('cannot add resource entry if not issuer', async function () {
      const id = 10;
      await expect(token.connect(addrs[1]).addResourceEntry(id, metaURIDefault)).to.be.revertedWith(
        'RMRK: Only issuer',
      );
    });

    it('can set and get issuer', async function () {
      const newIssuerAddr = addrs[1].address;
      expect(await token.getIssuer()).to.equal(owner.address);

      await token.setIssuer(newIssuerAddr);
      expect(await token.getIssuer()).to.equal(newIssuerAddr);
    });

    it('cannot set issuer if not issuer', async function () {
      const newIssuer = addrs[1];
      await expect(token.connect(newIssuer).setIssuer(newIssuer.address)).to.be.revertedWith(
        'RMRK: Only issuer',
      );
    });

    it('cannot overwrite resource', async function () {
      const id = 10;

      await token.addResourceEntry(id, metaURIDefault);
      await expect(token.addResourceEntry(id, metaURIDefault)).to.be.revertedWith(
        'RMRK: resource already exists',
      );
    });

    it('cannot add resource with id 0', async function () {
      const id = ethers.utils.hexZeroPad('0x0', 8);

      await expect(token.addResourceEntry(id, metaURIDefault)).to.be.revertedWith(
        'RMRK: Write to zero',
      );
    });

    it('cannot add same resource twice', async function () {
      const id = 10;

      await expect(token.addResourceEntry(id, metaURIDefault))
        .to.emit(token, 'ResourceSet')
        .withArgs(id);

      await expect(token.addResourceEntry(id, metaURIDefault)).to.be.revertedWith(
        'RMRK: resource already exists',
      );
    });
  });

  describe('Adding resources', async function () {
    it('can add resource to token', async function () {
      const resId = 1;
      const resId2 = 2;
      const tokenId = 1;

      await token.mint(owner.address, tokenId);
      await addResources([resId, resId2]);
      await expect(token.addResourceToToken(tokenId, resId, 0)).to.emit(
        token,
        'ResourceAddedToToken',
      );
      await expect(token.addResourceToToken(tokenId, resId2, 0)).to.emit(
        token,
        'ResourceAddedToToken',
      );

      const pendingIds = await token.getPendingResources(tokenId);
      expect(await renderUtils.getResourcesById(token.address, tokenId, pendingIds)).to.be.eql([
        metaURIDefault,
        metaURIDefault,
      ]);
    });

    it('cannot add non existing resource to token', async function () {
      const resId = 1;
      const tokenId = 1;

      await token.mint(owner.address, tokenId);
      await expect(token.addResourceToToken(tokenId, resId, 0)).to.be.revertedWith(
        'MultiResource: Resource not found in storage',
      );
    });

    it('can add resource to non existing token and it is pending when minted', async function () {
      const resId = 1;
      const tokenId = 1;
      await addResources([resId]);

      await token.addResourceToToken(tokenId, resId, 0);
      await token.mint(owner.address, tokenId);
      expect(await token.getPendingResources(tokenId)).to.eql([ethers.BigNumber.from(resId)]);
    });

    it('cannot add resource twice to the same token', async function () {
      const resId = 1;
      const tokenId = 1;

      await token.mint(owner.address, tokenId);
      await addResources([resId]);
      await token.addResourceToToken(tokenId, resId, 0);
      await expect(
        token.addResourceToToken(tokenId, ethers.BigNumber.from(resId), 0),
      ).to.be.revertedWith('MultiResource: Resource already exists on token');
    });

    it('cannot add too many resources to the same token', async function () {
      const tokenId = 1;

      await token.mint(owner.address, tokenId);
      for (let i = 1; i <= 128; i++) {
        await addResources([i]);
        await token.addResourceToToken(tokenId, i, 0);
      }

      // Now it's full, next should fail
      const resId = 129;
      await addResources([resId]);
      await expect(token.addResourceToToken(tokenId, resId, 0)).to.be.revertedWith(
        'MultiResource: Max pending resources reached',
      );
    });

    it('can add same resource to 2 different tokens', async function () {
      const resId = 1;
      const tokenId1 = 1;
      const tokenId2 = 2;

      await token.mint(owner.address, tokenId1);
      await token.mint(owner.address, tokenId2);
      await addResources([resId]);
      await token.addResourceToToken(tokenId1, resId, 0);
      await token.addResourceToToken(tokenId2, resId, 0);
    });
  });

  describe('Accepting resources', async function () {
    it('can accept resource if owner', async function () {
      const { tokenOwner, tokenId } = await mintSampleToken();
      const approved = tokenOwner;

      await checkAcceptFromAddress(approved, tokenId);
    });

    it('can accept resource if approved for resources', async function () {
      const { tokenId } = await mintSampleToken();
      const approved = addrs[1];

      await token.approveForResources(approved.address, tokenId);
      await checkAcceptFromAddress(approved, tokenId);
    });

    it('can accept resource if approved for resources for all', async function () {
      const { tokenId } = await mintSampleToken();
      const approved = addrs[2];

      await token.setApprovalForAllForResources(approved.address, true);
      await checkAcceptFromAddress(approved, tokenId);
    });

    it('can accept multiple resources', async function () {
      const resId = 1;
      const resId2 = 2;
      const tokenId = 1;

      await token.mint(owner.address, tokenId);
      await addResources([resId, resId2]);
      await token.addResourceToToken(tokenId, resId, 0);
      await token.addResourceToToken(tokenId, resId2, 0);
      await expect(token.acceptResource(tokenId, 1, resId2))
        .to.emit(token, 'ResourceAccepted')
        .withArgs(tokenId, resId2, 0);
      await expect(token.acceptResource(tokenId, 0, resId))
        .to.emit(token, 'ResourceAccepted')
        .withArgs(tokenId, resId, 0);

      expect(await token.getPendingResources(tokenId)).to.be.eql([]);

      const activeIds = await token.getActiveResources(tokenId);
      expect(await renderUtils.getResourcesById(token.address, tokenId, activeIds)).to.eql([
        metaURIDefault,
        metaURIDefault,
      ]);
    });

    it('cannot accept resource twice', async function () {
      const resId = 1;
      const tokenId = 1;

      await token.mint(owner.address, tokenId);
      await addResources([resId]);
      await token.addResourceToToken(tokenId, resId, 0);
      await token.acceptResource(tokenId, 0, resId);
    });

    it('cannot accept resource if not owner', async function () {
      const resId = 1;
      const tokenId = 1;

      await token.mint(owner.address, tokenId);
      await addResources([resId]);
      await token.addResourceToToken(tokenId, resId, 0);
      await expect(token.connect(addrs[1]).acceptResource(tokenId, 0, resId)).to.be.revertedWith(
        'MultiResource: not owner or approved',
      );
    });

    it('cannot accept non existing resource', async function () {
      const tokenId = 1;

      await token.mint(owner.address, tokenId);
      await expect(token.acceptResource(tokenId, 0, 1)).to.be.revertedWith(
        'MultiResource: index out of bounds',
      );
    });
  });

  describe('Overwriting resources', async function () {
    it('can add resource to token overwritting an existing one', async function () {
      const resId = 1;
      const resId2 = 2;
      const tokenId = 1;

      await token.mint(owner.address, tokenId);
      await addResources([resId, resId2]);
      await token.addResourceToToken(tokenId, resId, 0);
      await token.acceptResource(tokenId, 0, resId);

      // Add new resource to overwrite the first, and accept
      const activeResources = await token.getActiveResources(tokenId);
      await expect(token.addResourceToToken(tokenId, resId2, activeResources[0])).to.emit(token, 'ResourceAddedToToken')
          .withArgs(tokenId, resId2, resId);
      const pendingResources = await token.getPendingResources(tokenId);

      expect(await token.getResourceOverwrites(tokenId, pendingResources[0])).to.eql(
        activeResources[0],
      );
      await expect(token.acceptResource(tokenId, 0, resId2)).to.emit(token, 'ResourceAccepted')
          .withArgs(tokenId, resId2, resId);

      const activeIds = await token.getActiveResources(tokenId);
      expect(await renderUtils.getResourcesById(token.address, tokenId, activeIds)).to.eql([metaURIDefault]);
      // Overwrite should be gone
      expect(await token.getResourceOverwrites(tokenId, pendingResources[0])).to.eql(
        ethers.BigNumber.from(0),
      );
    });

    it('can overwrite non existing resource to token, it could have been deleted', async function () {
      const resId = 1;
      const tokenId = 1;

      await token.mint(owner.address, tokenId);
      await addResources([resId]);
      await token.addResourceToToken(tokenId, resId, ethers.utils.hexZeroPad('0x1', 8));
      await token.acceptResource(tokenId, 0, resId);

      const activeIds = await token.getActiveResources(tokenId);
      expect(await renderUtils.getResourcesById(token.address, tokenId, activeIds)).to.eql([metaURIDefault]);
    });
  });

  describe('Rejecting resources', async function () {
    it('can reject resource if owner', async function () {
      const { tokenOwner, tokenId } = await mintSampleToken();
      const approved = tokenOwner;

      await checkRejectFromAddress(approved, tokenId);
    });

    it('can reject resource if approved for resources', async function () {
      const { tokenId } = await mintSampleToken();
      const approved = addrs[1];

      await token.approveForResources(approved.address, tokenId);
      await checkRejectFromAddress(approved, tokenId);
    });

    it('can reject resource if approved for resources for all', async function () {
      const { tokenId } = await mintSampleToken();
      const approved = addrs[2];

      await token.setApprovalForAllForResources(approved.address, true);
      await checkRejectFromAddress(approved, tokenId);
    });

    it('can reject all resources if owner', async function () {
      const { tokenOwner, tokenId } = await mintSampleToken();
      const approved = tokenOwner;

      await checkRejectAllFromAddress(approved, tokenId);
    });

    it('can reject all resources if approved for resources', async function () {
      const { tokenId } = await mintSampleToken();
      const approved = addrs[1];

      await token.approveForResources(approved.address, tokenId);
      await checkRejectAllFromAddress(approved, tokenId);
    });

    it('can reject all resources if approved for resources for all', async function () {
      const { tokenId } = await mintSampleToken();
      const approved = addrs[2];

      await token.setApprovalForAllForResources(approved.address, true);
      await checkRejectAllFromAddress(approved, tokenId);
    });

    it('can reject resource and overwrites are cleared', async function () {
      const resId = 1;
      const resId2 = 2;
      const tokenId = 1;

      await token.mint(owner.address, tokenId);
      await addResources([resId, resId2]);
      await token.addResourceToToken(tokenId, resId, 0);
      await token.acceptResource(tokenId, 0, resId);

      // Will try to overwrite but we reject it
      await token.addResourceToToken(tokenId, resId2, resId);
      await token.rejectResource(tokenId, 0, resId2);

      expect(await token.getResourceOverwrites(tokenId, resId2)).to.eql(ethers.BigNumber.from(0));
    });

    it('can reject all resources and overwrites are cleared', async function () {
      const resId = 1;
      const resId2 = 2;
      const tokenId = 1;

      await token.mint(owner.address, tokenId);
      await addResources([resId, resId2]);
      await token.addResourceToToken(tokenId, resId, 0);
      await token.acceptResource(tokenId, 0, resId);

      // Will try to overwrite but we reject all
      await token.addResourceToToken(tokenId, resId2, resId);
      await token.rejectAllResources(tokenId, 1);

      expect(await token.getResourceOverwrites(tokenId, resId2)).to.eql(ethers.BigNumber.from(0));
    });

    it('can reject all pending resources at max capacity', async function () {
      const tokenId = 1;
      const resArr = [];

      for (let i = 1; i < 128; i++) {
        resArr.push(i);
      }

      await token.mint(owner.address, tokenId);
      await addResources(resArr);

      for (let i = 1; i < 128; i++) {
        await token.addResourceToToken(tokenId, i, 1);
      }
      await token.rejectAllResources(tokenId, 128);

      expect(await token.getResourceOverwrites(1, 2)).to.eql(ethers.BigNumber.from(0));
    });

    it('cannot reject resource twice', async function () {
      const resId = 1;
      const tokenId = 1;

      await token.mint(owner.address, tokenId);
      await addResources([resId]);
      await token.addResourceToToken(tokenId, resId, 0);
      await token.rejectResource(tokenId, 0, resId);
    });

    it('cannot reject resource nor reject all if not owner', async function () {
      const resId = 1;
      const tokenId = 1;

      await token.mint(owner.address, tokenId);
      await addResources([resId]);
      await token.addResourceToToken(tokenId, resId, 0);

      await expect(token.connect(addrs[1]).rejectResource(tokenId, 0, resId)).to.be.revertedWith(
        'MultiResource: not owner or approved',
      );
      await expect(token.connect(addrs[1]).rejectAllResources(tokenId, 1)).to.be.revertedWith(
        'MultiResource: not owner or approved',
      );
    });

    it('cannot reject non existing resource', async function () {
      const tokenId = 1;

      await token.mint(owner.address, tokenId);
      await expect(token.rejectResource(tokenId, 0, 1)).to.be.revertedWith(
        'MultiResource: index out of bounds',
      );
    });
  });

  describe('Priorities', async function () {
    it('can set and get priorities', async function () {
      const tokenId = 1;
      await addResourcesToToken(tokenId);

      expect(await token.getActiveResourcePriorities(tokenId)).to.be.eql([0, 0]);
      await expect(token.setPriority(tokenId, [2, 1]))
        .to.emit(token, 'ResourcePrioritySet')
        .withArgs(tokenId);
      expect(await token.getActiveResourcePriorities(tokenId)).to.be.eql([2, 1]);
    });

    it('cannot set priorities for non owned token', async function () {
      const tokenId = 1;
      await addResourcesToToken(tokenId);
      await expect(token.connect(addrs[1]).setPriority(tokenId, [2, 1])).to.be.revertedWith(
        'MultiResource: not owner or approved',
      );
    });

    it('cannot set different number of priorities', async function () {
      const tokenId = 1;
      await addResourcesToToken(tokenId);
      await expect(token.connect(addrs[1]).setPriority(tokenId, [1])).to.be.revertedWith(
        'MultiResource: Bad priority list length',
      );
      await expect(token.connect(addrs[1]).setPriority(tokenId, [2, 1, 3])).to.be.revertedWith(
        'MultiResource: Bad priority list length',
      );
    });

    it('cannot set priorities for non existing token', async function () {
      const tokenId = 1;
      await expect(token.connect(addrs[1]).setPriority(tokenId, [])).to.be.revertedWith(
        'MultiResource: approved query for nonexistent token',
      );
    });
  });

  describe('Approval Cleaning', async function () {
    it('cleans token and resources approvals on transfer', async function () {
      const tokenId = 1;
      const tokenOwner = addrs[1];
      const newOwner = addrs[2];
      const approved = addrs[3];
      await token.mint(tokenOwner.address, tokenId);
      await token.connect(tokenOwner).approve(approved.address, tokenId);
      await token.connect(tokenOwner).approveForResources(approved.address, tokenId);

      expect(await token.getApproved(tokenId)).to.eql(approved.address);
      expect(await token.getApprovedForResources(tokenId)).to.eql(approved.address);

      await token.connect(tokenOwner).transfer(newOwner.address, tokenId);

      expect(await token.getApproved(tokenId)).to.eql(ethers.constants.AddressZero);
      expect(await token.getApprovedForResources(tokenId)).to.eql(ethers.constants.AddressZero);
    });

    it('cleans token and resources approvals on burn', async function () {
      const tokenId = 1;
      const tokenOwner = addrs[1];
      const approved = addrs[3];
      await token.mint(tokenOwner.address, tokenId);
      await token.connect(tokenOwner).approve(approved.address, tokenId);
      await token.connect(tokenOwner).approveForResources(approved.address, tokenId);

      expect(await token.getApproved(tokenId)).to.eql(approved.address);
      expect(await token.getApprovedForResources(tokenId)).to.eql(approved.address);

      await token.connect(tokenOwner).burn(tokenId);

      await expect(token.getApproved(tokenId)).to.be.revertedWith(
        'MultiResource: approved query for nonexistent token',
      );
      await expect(token.getApprovedForResources(tokenId)).to.be.revertedWith(
        'MultiResource: approved query for nonexistent token',
      );
    });
  });

  async function mintSampleToken(): Promise<{ tokenOwner: SignerWithAddress; tokenId: number }> {
    const tokenOwner = owner;
    const tokenId = 1;
    await token.mint(tokenOwner.address, tokenId);

    return { tokenOwner, tokenId };
  }

  async function addResources(ids: number[]): Promise<void> {
    ids.forEach(async (resId) => {
      await token.addResourceEntry(resId, metaURIDefault);
    });
  }

  async function addResourcesToToken(tokenId: number): Promise<void> {
    const resId = 1;
    const resId2 = 2;
    await token.mint(owner.address, tokenId);
    await addResources([resId, resId2]);
    await token.addResourceToToken(tokenId, resId, 0);
    await token.addResourceToToken(tokenId, resId2, 0);
    await token.acceptResource(tokenId, 0, resId);
    await token.acceptResource(tokenId, 0, resId2);
  }

  async function checkAcceptFromAddress(
    accepter: SignerWithAddress,
    tokenId: number,
  ): Promise<void> {
    const resId = 1;

    await addResources([resId]);
    await token.addResourceToToken(tokenId, resId, 0);
    await expect(token.connect(accepter).acceptResource(tokenId, 0, resId))
      .to.emit(token, 'ResourceAccepted')
      .withArgs(tokenId, resId, 0);

    expect(await token.getPendingResources(tokenId)).to.be.eql([]);

    const activeIds = await token.getActiveResources(tokenId);
    expect(await renderUtils.getResourcesById(token.address, tokenId, activeIds)).to.eql([metaURIDefault]);
  }

  async function checkRejectFromAddress(
    rejecter: SignerWithAddress,
    tokenId: number,
  ): Promise<void> {
    const resId = 1;

    await addResources([resId]);
    await token.addResourceToToken(tokenId, resId, 0);

    await expect(token.connect(rejecter).rejectResource(tokenId, 0, resId)).to.emit(
      token,
      'ResourceRejected',
    );

    expect(await token.getPendingResources(tokenId)).to.be.eql([]);
    expect(await token.getActiveResources(tokenId)).to.be.eql([]);
  }

  async function checkRejectAllFromAddress(
    rejecter: SignerWithAddress,
    tokenId: number,
  ): Promise<void> {
    const resId = 1;
    const resId2 = 2;

    await addResources([resId, resId2]);
    await token.addResourceToToken(tokenId, resId, 0);
    await token.addResourceToToken(tokenId, resId2, 0);

    await expect(token.connect(rejecter).rejectAllResources(tokenId, 2)).to.emit(
      token,
      'ResourceRejected',
    );

    expect(await token.getPendingResources(tokenId)).to.be.eql([]);
    expect(await token.getActiveResources(tokenId)).to.be.eql([]);
  }
});
