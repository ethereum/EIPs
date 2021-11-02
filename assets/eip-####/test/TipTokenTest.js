const { BigNumber } = require('@ethersproject/bignumber');
const { expect, assert } = require('chai');
const { ethers } = require('hardhat');

describe('TipToken contract', () => {
  let myTipToken, token1, uri, serviceProvider, myERC1155, myER721;
  const depositToken1 = ethers.utils.parseEther('30');
  const depositToken2 = ethers.utils.parseEther('30');
  const depositToken3 = ethers.utils.parseEther('40');
  const price = ethers.constants.WeiPerEther;

  beforeEach(async () => {
    [owner, serviceProvider, holder, user1, user2, user3, holder2, ...addrs] =
      await ethers.getSigners();

    const Token1 = await ethers.getContractFactory('SimpleToken');
    token1 = await Token1.deploy(depositToken1.add(depositToken2).mul(2).add(depositToken3));

    token1.transfer(user1.address, depositToken1.mul(2));
    token1.transfer(user2.address, depositToken2.mul(2));
    token1.transfer(user3.address, depositToken3);

    const blockNumber = await ethers.provider.getBlockNumber();
    const block = await ethers.provider.getBlock(blockNumber);

    const MyERC1155 = await ethers.getContractFactory('MyERC1155');
    myERC1155 = await MyERC1155.deploy();
    await myERC1155.deployed();

    const MyERC721 = await ethers.getContractFactory('MyERC721');
    myERC721 = await MyERC721.deploy();
    await myERC721.deployed();

    const MyTipToken = await ethers.getContractFactory('TipToken');
    myTipToken = await MyTipToken.deploy(token1.address);
    await myTipToken.deployed();

    await myTipToken.transferOwnership(serviceProvider.address);
    await myTipToken.connect(serviceProvider).setPrice(price);
  });

  describe('Balance checks', () => {
    it('check user 1 balance', async () => {
      const user1Balance = await token1.balanceOf(user1.address);
      expect(user1Balance).to.equal(depositToken1.mul(2));
    });
    it('check user 2 balance', async () => {
      const user2Balance = await token1.balanceOf(user2.address);
      expect(user2Balance).to.equal(depositToken2.mul(2));
    });
  });

  describe('Transactions', () => {
    it('test tip for ERC721 from one user', async () => {
      // NFT myERC721 authorises myTipToken to send it tips
      await myERC721.connect(holder).setApprovalForAll(myTipToken.address, true);

      const nftTokenId = 1;

      await myERC721.safeMint(holder.address, nftTokenId);

      // myTipToken approves users to send myTipToken tip tokens to NFT myERC721 that has id nftTokenId
      await expect(
        myTipToken
          .connect(serviceProvider)
          .setApprovalForNFT([holder.address], myERC721.address, nftTokenId, true)
      )
        .to.emit(myTipToken, 'ApprovalForNFT')
        .withArgs([holder.address], myERC721.address, nftTokenId, true);

      await token1.connect(user1).approve(myTipToken.address, depositToken1);

      // User deposits to receive tip tokens
      const user1BalanceBefore = await myTipToken.balanceOf(user1.address);
      const totalTipTokenAmount = depositToken1.mul(ethers.constants.WeiPerEther).div(price);

      await expect(myTipToken.connect(user1).deposit(user1.address, depositToken1))
        .to.emit(myTipToken, 'Deposit')
        .withArgs(user1.address, token1.address, depositToken1, totalTipTokenAmount);

      const user1BalanceAfter = await myTipToken.balanceOf(user1.address);

      // Check total tip balance
      expect(user1BalanceAfter.sub(user1BalanceBefore)).to.be.equal(totalTipTokenAmount);

      const amountToken1Reward = depositToken1
        .mul(ethers.constants.WeiPerEther)
        .div(ethers.utils.parseEther('3'));

      const amountToTip = totalTipTokenAmount
        .mul(ethers.constants.WeiPerEther)
        .div(ethers.utils.parseEther('3'));
      const tokenPendingHolderBalancePendingBefore = await myTipToken.rewardPendingOf(
        holder.address
      );

      const tokenPendingHolderPendingBalanceBefore = await myTipToken.rewardPendingOf(
        holder.address
      );

      // Tip a third of the tips
      await expect(myTipToken.connect(user1).tip(myERC721.address, nftTokenId, amountToTip))
        .to.emit(myTipToken, 'Tip')
        .withArgs(
          user1.address,
          [holder.address],
          myERC721.address,
          nftTokenId,
          amountToTip,
          token1.address,
          [amountToken1Reward]
        );

      // Check that correct amount of tips from user1 have been burned
      const user1BalanceFinal = await myTipToken.balanceOf(user1.address);
      expect(user1BalanceAfter.sub(user1BalanceFinal)).to.be.equal(amountToTip);

      const tokenPendingHolderPendingBalanceAfter = await myTipToken.rewardPendingOf(
        holder.address
      );

      // Check amount owed to holder of the rewards deposit
      expect(
        tokenPendingHolderPendingBalanceAfter.sub(tokenPendingHolderPendingBalanceBefore)
      ).to.be.equal(amountToken1Reward);

      const holderBalanceBefore = await token1.balanceOf(holder.address);

      await expect(myTipToken.connect(holder).withdraw(amountToken1Reward))
        .to.emit(myTipToken, 'Withdraw')
        .withArgs(holder.address, token1.address, amountToken1Reward);

      // Check amount holder receives of the rewards deposit
      const holderBalanceAfter = await token1.balanceOf(holder.address);
      expect(holderBalanceAfter.sub(holderBalanceBefore)).to.be.equal(amountToken1Reward);
    });

    it('test tip for ERC1155 from one user', async () => {
      // myERC1155 authorises myTipToken to send it tips
      await myERC1155.connect(holder).setApprovalForAll(myTipToken.address, true);

      const nftTokenId = 1;

      await myERC1155.mint(holder.address, nftTokenId, 1, []);

      // myTipToken approves users to send myTipToken tip tokens to myERC1155's token that has id nftTokenId
      await myTipToken
        .connect(serviceProvider)
        .setApprovalForNFT([holder.address], myERC1155.address, nftTokenId, true);

      await token1.connect(user1).approve(myTipToken.address, depositToken1);

      // user deposits to receive tip tokens
      const user1BalanceBefore = await myTipToken.balanceOf(user1.address);
      await myTipToken.connect(user1).deposit(user1.address, depositToken1);
      const user1BalanceAfter = await myTipToken.balanceOf(user1.address);

      // Check total tip balance
      const totalTipTokenAmount = depositToken1.mul(ethers.constants.WeiPerEther).div(price);
      expect(user1BalanceAfter.sub(user1BalanceBefore)).to.be.equal(totalTipTokenAmount);

      const amountToken1Reward = depositToken1
        .mul(ethers.constants.WeiPerEther)
        .div(ethers.utils.parseEther('3'));

      const amountToTip = totalTipTokenAmount
        .mul(ethers.constants.WeiPerEther)
        .div(ethers.utils.parseEther('3'));

      const tokenPendingHolderPendingBalanceBefore = await myTipToken.rewardPendingOf(
        holder.address
      );

      // Tip a third of the tips
      await myTipToken.connect(user1).tip(myERC1155.address, nftTokenId, amountToTip);

      // Check that correct amount of tips from user1 have been burned
      const user1BalanceFinal = await myTipToken.balanceOf(user1.address);
      expect(user1BalanceAfter.sub(user1BalanceFinal)).to.be.equal(amountToTip);

      const tokenPendingHolderPendingBalanceAfter = await myTipToken.rewardPendingOf(
        holder.address
      );

      expect(
        tokenPendingHolderPendingBalanceAfter.sub(tokenPendingHolderPendingBalanceBefore)
      ).to.be.equal(amountToken1Reward);

      const holderBalanceBefore = await token1.balanceOf(holder.address);
      await myTipToken.connect(holder).withdraw(amountToken1Reward);

      // check amount holder receives
      const holderBalanceAfter = await token1.balanceOf(holder.address);
      expect(holderBalanceAfter.sub(holderBalanceBefore)).to.be.equal(amountToken1Reward);
    });

    it('test revert for approval for tipping to account that is not holder of NFT', async () => {
      await myERC1155.connect(user1).setApprovalForAll(myTipToken.address, false);

      await token1.connect(user1).approve(myTipToken.address, depositToken1);

      await expect(
        myTipToken
          .connect(serviceProvider)
          .setApprovalForNFT([user1.address], myERC1155.address, 1, true)
      ).to.be.revertedWith('Unable to set approval');
    });

    it('test revert when tipping to NFT not approved by tip token contract', async () => {
      await myERC1155.connect(holder).setApprovalForAll(myTipToken.address, true);

      const nftTokenId = 1;

      await myERC1155.mint(holder.address, myERC1155.address, nftTokenId, 1, []);
      await myTipToken
        .connect(serviceProvider)
        .setApprovalForNFT([holder.address], myERC1155.address, nftTokenId, false);

      await token1.connect(user1).approve(myTipToken.address, depositToken1);

      // User deposits to receive tip tokens
      const user1BalanceBefore = await myTipToken.balanceOf(user1.address);
      await myTipToken.connect(user1).deposit(user1.address, depositToken1);
      const user1BalanceAfter = await myTipToken.balanceOf(user1.address);

      // Check total tip balance
      const totalTipTokenAmount = depositToken1.mul(ethers.constants.WeiPerEther).div(price);
      expect(user1BalanceAfter.sub(user1BalanceBefore)).to.be.equal(totalTipTokenAmount);

      const amountToken1Reward = depositToken1
        .mul(ethers.constants.WeiPerEther)
        .div(ethers.utils.parseEther('3'));

      const amountToTip = totalTipTokenAmount
        .mul(ethers.constants.WeiPerEther)
        .div(ethers.utils.parseEther('3'));
      const tokenPendingHolderBalancePendingBefore = await myTipToken.rewardPendingOf(
        holder.address
      );

      const tokenPendingHolderPendingBalanceBefore = await myTipToken.rewardPendingOf(
        holder.address
      );

      // tip a third of the tips
      await expect(
        myTipToken.connect(user1).tip(myERC1155.address, nftTokenId, amountToTip)
      ).to.be.revertedWith('NFT not approved');
    });

    it('test tipping to a mix of ERC721 and ERC1155', async () => {
      // For ERC721
      // NFT myERC721 gives approval that it can receive tips
      await myERC721.connect(holder).setApprovalForAll(myTipToken.address, true);

      const nftTokenId = 1;

      await myERC721.safeMint(holder.address, nftTokenId);

      // myTipToken gives approval that users can send myTipToken tips to NFT myERC721
      await myTipToken
        .connect(serviceProvider)
        .setApprovalForNFT([holder.address], myERC721.address, nftTokenId, true);

      await token1.connect(user1).approve(myTipToken.address, depositToken1);

      // User deposits to myTipToken to receive myTipToken tip tokens
      const user1BalanceBefore = await myTipToken.balanceOf(user1.address);
      await myTipToken.connect(user1).deposit(user1.address, depositToken1);
      const user1BalanceAfter = await myTipToken.balanceOf(user1.address);

      // Check total tip balance of user1
      const totalTipTokenAmount = depositToken1.mul(ethers.constants.WeiPerEther).div(price);
      expect(user1BalanceAfter.sub(user1BalanceBefore)).to.be.equal(totalTipTokenAmount);

      const amountToken1Reward = depositToken1
        .mul(ethers.constants.WeiPerEther)
        .div(ethers.utils.parseEther('3'));

      const amountToTip = totalTipTokenAmount
        .mul(ethers.constants.WeiPerEther)
        .div(ethers.utils.parseEther('3'));
      const tokenPendingHolderBalancePendingBefore = await myTipToken.rewardPendingOf(
        holder.address
      );

      const tokenPendingHolderPendingBalanceBefore = await myTipToken.rewardPendingOf(
        holder.address
      );

      // Tip a third of the tips to NFT myERC721
      await myTipToken.connect(user1).tip(myERC721.address, nftTokenId, amountToTip);

      const user1BalanceFinal = await myTipToken.balanceOf(user1.address);
      expect(user1BalanceAfter.sub(user1BalanceFinal)).to.be.equal(amountToTip);

      const tokenPendingHolderPendingBalanceAfter = await myTipToken.rewardPendingOf(
        holder.address
      );

      expect(
        tokenPendingHolderPendingBalanceAfter.sub(tokenPendingHolderPendingBalanceBefore)
      ).to.be.equal(amountToken1Reward);

      const holderBalanceBefore = await token1.balanceOf(holder.address);
      await myTipToken.connect(holder).withdraw(amountToken1Reward);

      // Check amount holder receives
      const holderBalanceAfter = await token1.balanceOf(holder.address);
      expect(holderBalanceAfter.sub(holderBalanceBefore)).to.be.equal(amountToken1Reward);

      // For ERC1155
      await myERC1155.connect(holder).setApprovalForAll(myTipToken.address, true);
      await myERC1155.connect(user1).setApprovalForAll(myTipToken.address, true);

      const nftTokenId2 = 1;

      await myERC1155.mint(holder.address, nftTokenId2, 1, []);
      await myTipToken
        .connect(serviceProvider)
        .setApprovalForNFT([holder.address], myERC1155.address, nftTokenId2, true);

      await token1.connect(user1).approve(myTipToken.address, depositToken1);

      // user deposits to receive tip tokens
      const user1BalanceBefore2 = await myTipToken.balanceOf(user1.address);
      await myTipToken.connect(user1).deposit(user1.address, depositToken1);
      const user1BalanceAfter2 = await myTipToken.balanceOf(user1.address);

      // check total tip balance
      const totalTipTokenAmount2 = depositToken1.mul(ethers.constants.WeiPerEther).div(price);
      expect(user1BalanceAfter2.sub(user1BalanceBefore2)).to.be.equal(totalTipTokenAmount2);

      const amountToken1Reward2 = depositToken1
        .mul(ethers.constants.WeiPerEther)
        .div(ethers.utils.parseEther('3'));

      const amountToTip2 = totalTipTokenAmount2
        .mul(ethers.constants.WeiPerEther)
        .div(ethers.utils.parseEther('3'));

      const tokenPendingHolderPendingBalanceBefore2 = await myTipToken.rewardPendingOf(
        holder.address
      );

      // Tip a third of the tips
      await myTipToken.connect(user1).tip(myERC1155.address, nftTokenId2, amountToTip2);

      const user1BalanceFinal2 = await myTipToken.balanceOf(user1.address);
      expect(user1BalanceAfter2.sub(user1BalanceFinal2)).to.be.equal(amountToTip2);

      const tokenPendingHolderPendingBalanceAfter2 = await myTipToken.rewardPendingOf(
        holder.address
      );

      // Check how much of the reward deposit is owed to the holder
      expect(
        tokenPendingHolderPendingBalanceAfter2.sub(tokenPendingHolderPendingBalanceBefore2)
      ).to.be.equal(amountToken1Reward2);

      const holderBalanceBefore2 = await token1.balanceOf(holder.address);
      await myTipToken.connect(holder).withdraw(amountToken1Reward2);
      const holderBalanceAfter2 = await token1.balanceOf(holder.address);

      // Check amount holder received of the reward deposit
      expect(holderBalanceAfter2.sub(holderBalanceBefore2)).to.be.equal(amountToken1Reward2);
    });

    it('test batch tips to ERC721 and ERC1155 tokens', async () => {
      // For ERC721
      await myERC721.connect(holder).setApprovalForAll(myTipToken.address, true);

      const nftTokenId = 1;

      await myERC721.safeMint(holder.address, nftTokenId);
      await myTipToken
        .connect(serviceProvider)
        .setApprovalForNFT([holder.address], myERC721.address, nftTokenId, true);

      await token1.connect(user1).approve(myTipToken.address, depositToken1);

      const user1BalanceBefore = await myTipToken.balanceOf(user1.address);
      await myTipToken.connect(user1).deposit(user1.address, depositToken1);
      const user1BalanceAfter = await myTipToken.balanceOf(user1.address);

      const totalTipTokenAmount = depositToken1.mul(ethers.constants.WeiPerEther).div(price);
      expect(user1BalanceAfter.sub(user1BalanceBefore)).to.be.equal(totalTipTokenAmount);

      const amountToken1Reward = depositToken1
        .mul(ethers.constants.WeiPerEther)
        .div(ethers.utils.parseEther('3'));

      const amountToTip = totalTipTokenAmount
        .mul(ethers.constants.WeiPerEther)
        .div(ethers.utils.parseEther('3'));

      const tokenPendingHolderPendingBalanceBefore = await myTipToken.rewardPendingOf(
        holder.address
      );

      // For ERC1155
      await myERC1155.connect(holder).setApprovalForAll(myTipToken.address, true);
      await myERC1155.connect(holder2).setApprovalForAll(myTipToken.address, true);

      const nftTokenId2 = 2;
      const nftTokenId3 = 3;

      await myERC1155.mint(holder.address, nftTokenId, 1, []);
      await myERC1155.mint(holder.address, nftTokenId2, 1, []);
      await myERC1155.mint(holder2.address, nftTokenId3, 1, []);

      await myTipToken
        .connect(serviceProvider)
        .setApprovalForNFT([holder.address], myERC1155.address, nftTokenId, true);
      await myTipToken
        .connect(serviceProvider)
        .setApprovalForNFT([holder.address], myERC1155.address, nftTokenId2, true);
      await myTipToken
        .connect(serviceProvider)
        .setApprovalForNFT([holder2.address], myERC1155.address, nftTokenId3, true);

      await token1.connect(user1).approve(myTipToken.address, depositToken1);
      await token1.connect(user3).approve(myTipToken.address, depositToken3);

      const user1BalanceBefore2 = await myTipToken.balanceOf(user1.address);
      await myTipToken.connect(user1).deposit(user1.address, depositToken1);
      const user1BalanceAfter2 = await myTipToken.balanceOf(user1.address);

      await myTipToken.connect(user3).deposit(user3.address, depositToken3);

      // Check total tip balance
      const totalTipTokenAmount2 = depositToken1.mul(ethers.constants.WeiPerEther).div(price);
      expect(user1BalanceAfter2.sub(user1BalanceBefore2)).to.be.equal(totalTipTokenAmount2);

      const amountToken1Reward2 = depositToken1
        .mul(ethers.constants.WeiPerEther)
        .div(ethers.utils.parseEther('3'));

      const amountToTip2 = totalTipTokenAmount2
        .mul(ethers.constants.WeiPerEther)
        .div(ethers.utils.parseEther('3'));

      const tokenPendingHolderPendingBalanceBefore2 = await myTipToken.rewardPendingOf(
        holder.address
      );

      amountToken1Reward3 = depositToken3;
      amountToTip3 = depositToken3;

      const holder2BalanceAfter = await token1.balanceOf(holder2.address);

      const users = [user1.address, user1.address, user1.address, user3.address];
      const nfts = [myERC721.address, myERC1155.address, myERC1155.address, myERC1155.address];
      const ids = [nftTokenId, nftTokenId2, nftTokenId, nftTokenId3];
      const amounts = [amountToTip, amountToTip2.div(2), amountToTip2.div(2), amountToTip3];

      // tipBatch of users tips for the NFTs that will be received by the holders of the NFTs
      await myTipToken.connect(serviceProvider).tipBatch(users, nfts, ids, amounts);

      const user1BalanceFinal = await myTipToken.balanceOf(user1.address);
      expect(user1BalanceAfter2.sub(user1BalanceFinal)).to.be.equal(amountToTip.add(amountToTip2));

      // Holder checks balance of all the ERC20 reward deposits owed for the holder's NFT and ERC-1155 token
      const tokenPendingHolderPendingBalanceAfter = await myTipToken.rewardPendingOf(
        holder.address
      );

      expect(
        tokenPendingHolderPendingBalanceAfter.sub(tokenPendingHolderPendingBalanceBefore)
      ).to.be.equal(amountToken1Reward.add(amountToken1Reward2));

      // Holder withdraws all the ERC20 reward deposits for the holder's NFT and ERC-1155 token
      const holderBalanceBefore = await token1.balanceOf(holder.address);
      await myTipToken.connect(holder).withdraw(amountToken1Reward.add(amountToken1Reward2));

      // Check amount holder receives is the total owed for holder's NFT and ERC-1155 token
      const holderBalanceAfter = await token1.balanceOf(holder.address);
      expect(holderBalanceAfter.sub(holderBalanceBefore)).to.be.equal(
        amountToken1Reward.add(amountToken1Reward2)
      );

      await myTipToken.connect(holder2).withdraw(amountToken1Reward3);

      const holder2BalanceFinal = await token1.balanceOf(holder2.address);
      expect(holder2BalanceFinal.sub(holder2BalanceAfter)).to.be.equal(amountToken1Reward3);

      const user3BalanceAfter = await token1.balanceOf(user3.address);
      expect(user3BalanceAfter).to.be.equal(0);
    });

    it('test transfer of tip tokens', async () => {
      // For ERC721
      await myERC721.connect(holder).setApprovalForAll(myTipToken.address, true);

      const user1Token1balanceBefore = await token1.balanceOf(user1.address);

      const nftTokenId = 1;

      await myERC721.safeMint(holder.address, nftTokenId);
      await myTipToken
        .connect(serviceProvider)
        .setApprovalForNFT([holder.address], myERC721.address, nftTokenId, true);

      await token1.connect(user1).approve(myTipToken.address, depositToken1);

      // user deposits to receive tip tokens
      const user1BalanceBefore = await myTipToken.balanceOf(user1.address);
      await myTipToken.connect(user1).deposit(user1.address, depositToken1);
      const user1BalanceAfter = await myTipToken.balanceOf(user1.address);

      // check total tip balance
      const totalTipTokenAmount = depositToken1
        .mul(ethers.constants.WeiPerEther)
        .div(await myTipToken.price());
      expect(user1BalanceAfter.sub(user1BalanceBefore)).to.be.equal(totalTipTokenAmount);

      await token1.connect(user3).approve(myTipToken.address, depositToken3);

      await myTipToken.connect(serviceProvider).setPrice(price.div(2));

      const user3BalanceBefore = await myTipToken.balanceOf(user3.address);
      await myTipToken.connect(user3).deposit(user3.address, depositToken3);
      const user3BalanceAfter = await myTipToken.balanceOf(user3.address);

      const user3Token1balanceAfter = await myTipToken.balanceDepositOf(user3.address);

      // check total tip balance
      const totalTipTokenAmount2 = depositToken3
        .mul(ethers.constants.WeiPerEther)
        .div(await myTipToken.price());
      expect(user3BalanceAfter.sub(user3BalanceBefore)).to.be.equal(totalTipTokenAmount2);

      // user1 transfer myTipToken tip tokens to user3's account using ERC20 transfer function
      await myTipToken.connect(user1).transfer(user3.address, totalTipTokenAmount);
      const user1BalanceFinal = await myTipToken.balanceOf(user1.address);
      const user3BalanceFinal = await myTipToken.balanceOf(user3.address);

      // Check that the myTipToken tip tokens have been received by user3 from user1
      expect(user1BalanceAfter.sub(user1BalanceFinal)).to.be.equal(totalTipTokenAmount);
      expect(user1Token1balanceBefore.sub(await token1.balanceOf(user1.address))).to.be.equal(
        depositToken1
      );

      expect(user3BalanceFinal.sub(user3BalanceAfter)).to.be.equal(totalTipTokenAmount.mul(2));
      expect(
        (await myTipToken.balanceDepositOf(user3.address)).sub(user3Token1balanceAfter)
      ).to.be.equal(depositToken1);
    });

    it('test revert for input arrays of different sizes to tipBatch', async () => {
      const users = [ethers.constants.AddressZero, ethers.constants.AddressZero];

      // Set up input arrays of different lengths
      const nfts = [
        ethers.constants.AddressZero,
        ethers.constants.AddressZero,
        ethers.constants.AddressZero,
      ];
      const ids = [0, 0];
      const amounts = [0, 0];

      // Check that tipBatch reverts
      await expect(
        myTipToken.connect(serviceProvider).tipBatch(users, nfts, ids, amounts)
      ).to.be.revertedWith('Number of users, nfts, ids and amounts are not equal');
    });

    it('test TipToken returns false on non-supported interface', async () => {
      let someRandomInterface = '0xd9b67a25';
      assert((await myTipToken.supportsInterface(someRandomInterface)) === false);
    });

    it('test TipToken supportsInterface: ERC165', async () => {
      let erc165interface = '0x01ffc9a7';
      assert((await myTipToken.supportsInterface(erc165interface)) === true);
    });

    it('test TipToken supportsInterface: ITipToken', async () => {
      let ITipTokenInterface = '0x985A3267';
      assert((await myTipToken.supportsInterface(ITipTokenInterface)) === true);
    });

    it('test TipToken constructor emits InitializeTipToken event', async () => {
      const MyTipToken2 = await ethers.getContractFactory('TipToken');
      myTipToken2 = await MyTipToken2.deploy(token1.address);

      await expect(myTipToken2.deployTransaction)
        .to.emit(myTipToken2, 'InitializeTipToken')
        .withArgs(myTipToken2.address, token1.address, owner.address);
    });

    it('test tip for ERC1155 from shared holders', async () => {
      // myERC1155 authorises myTipToken to send it tips
      await myERC1155.connect(holder).setApprovalForAll(myTipToken.address, true);
      await myERC1155.connect(holder2).setApprovalForAll(myTipToken.address, true);

      const nftTokenId = 1;

      const holderPercentHoldings = 25;
      const holder2PercentHoldings = 75;
      await myERC1155.mint(holder.address, nftTokenId, holderPercentHoldings, []);
      await myERC1155.mint(holder2.address, nftTokenId, holder2PercentHoldings, []);

      // myTipToken approves users to send myTipToken tip tokens to myERC1155's token that has id nftTokenId
      await expect(
        myTipToken
          .connect(serviceProvider)
          .setApprovalForNFT([holder.address, holder2.address], myERC1155.address, nftTokenId, true)
      )
        .to.emit(myTipToken, 'ApprovalForNFT')
        .withArgs([holder.address, holder2.address], myERC1155.address, nftTokenId, true);

      await token1.connect(user1).approve(myTipToken.address, depositToken1);

      // user deposits to receive tip tokens
      const user1BalanceBefore = await myTipToken.balanceOf(user1.address);
      await myTipToken.connect(user1).deposit(user1.address, depositToken1);
      const user1BalanceAfter = await myTipToken.balanceOf(user1.address);

      // Check total tip balance
      const totalTipTokenAmount = depositToken1.mul(ethers.constants.WeiPerEther).div(price);
      expect(user1BalanceAfter.sub(user1BalanceBefore)).to.be.equal(totalTipTokenAmount);

      const amountToken1Reward = depositToken1
        .mul(ethers.constants.WeiPerEther)
        .div(ethers.utils.parseEther('3'));

      const amountToTip = totalTipTokenAmount
        .mul(ethers.constants.WeiPerEther)
        .div(ethers.utils.parseEther('3'));

      const holderToken1Reward = amountToken1Reward
        .mul(BigNumber.from(holderPercentHoldings))
        .div(BigNumber.from(100));
      const holder2Token1Reward = amountToken1Reward
        .mul(BigNumber.from(holder2PercentHoldings))
        .div(BigNumber.from(100));

      const tokenPendingHolderPendingBalanceBefore = await myTipToken.rewardPendingOf(
        holder.address
      );

      const tokenPendingHolder2PendingBalanceBefore = await myTipToken.rewardPendingOf(
        holder2.address
      );

      // Tip a third of the tips
      await expect(myTipToken.connect(user1).tip(myERC1155.address, nftTokenId, amountToTip))
        .to.emit(myTipToken, 'Tip')
        .withArgs(
          user1.address,
          [holder.address, holder2.address],
          myERC1155.address,
          nftTokenId,
          amountToTip,
          token1.address,
          [holderToken1Reward, holder2Token1Reward]
        );

      // Check that correct amount of tips from user1 have been burned
      const user1BalanceFinal = await myTipToken.balanceOf(user1.address);
      expect(user1BalanceAfter.sub(user1BalanceFinal)).to.be.equal(amountToTip);

      const tokenPendingHolderPendingBalanceAfter = await myTipToken.rewardPendingOf(
        holder.address
      );

      const tokenPendingHolder2PendingBalanceAfter = await myTipToken.rewardPendingOf(
        holder2.address
      );

      expect(
        tokenPendingHolderPendingBalanceAfter.sub(tokenPendingHolderPendingBalanceBefore)
      ).to.be.equal(holderToken1Reward);

      expect(
        tokenPendingHolder2PendingBalanceAfter.sub(tokenPendingHolder2PendingBalanceBefore)
      ).to.be.equal(holder2Token1Reward);

      const holderBalanceBefore = await token1.balanceOf(holder.address);
      await myTipToken.connect(holder).withdraw(holderToken1Reward);

      const holder2BalanceBefore = await token1.balanceOf(holder2.address);
      await myTipToken.connect(holder2).withdraw(holder2Token1Reward);

      // check amount holder receives
      const holderBalanceAfter = await token1.balanceOf(holder.address);
      expect(holderBalanceAfter.sub(holderBalanceBefore)).to.be.equal(holderToken1Reward);

      const holder2BalanceAfter = await token1.balanceOf(holder2.address);
      expect(holder2BalanceAfter.sub(holder2BalanceBefore)).to.be.equal(holder2Token1Reward);
    });
  });
});
