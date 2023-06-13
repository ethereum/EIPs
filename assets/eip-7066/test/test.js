const { expect } = require('chai');
const { ethers } = require('hardhat');

describe('NewToken', function () {
	let LOCK1 = 'lock(uint256)';
	let LOCK2 = 'lock(uint256,address)';
	async function deployMyNFTFixture() {
		const [deployer, acc1, acc2, acc3] = await ethers.getSigners();
		const MyNFT = await ethers.getContractFactory('MyNFT');
		let myNFT = await MyNFT.deploy();
		await myNFT.deployed();
		await myNFT.connect(deployer).mint();

		return { myNFT, deployer, acc1, acc2, acc3 };
	}

	async function approveUser1() {
		const { myNFT, deployer, acc1, acc2, acc3 } = await deployMyNFTFixture();
		await myNFT.connect(deployer).approve(acc1.address, 0);
		await myNFT.connect(deployer).setApprovalForAll(acc1.address, true);
		return { myNFT, deployer, acc1, acc2, acc3 };
	}

	describe('lockerOf', () => {
		it('Should return zero address for an unlocked token', async () => {
			const { myNFT } = await deployMyNFTFixture();
			expect(await myNFT.lockerOf(0)).to.equal(ethers.constants.AddressZero);
		});

		it('Should revert as token does not exist', async () => {
			const { myNFT } = await deployMyNFTFixture();
			await expect(myNFT.lockerOf(1)).to.be.revertedWith(
				'ERC7066: Nonexistent token'
			);
		});
	});

	describe('lock - with one parameter', () => {
		it('Should not lock if already locked', async () => {
			const { myNFT, deployer } = await deployMyNFTFixture();
			await myNFT.connect(deployer)[LOCK1](0);
			await expect(myNFT.connect(deployer)[LOCK1](0)).to.be.revertedWith(
				'ERC7066: Locked'
			);
		});

		it('Should not allow random user to lock', async () => {
			const { myNFT, acc1 } = await deployMyNFTFixture();
			await expect(myNFT.connect(acc1)[LOCK1](0)).to.be.revertedWith(
				'Require owner or approved'
			);
		});

		it('Should be able to lock token by owner', async () => {
			const { myNFT, deployer } = await deployMyNFTFixture();
			await myNFT.connect(deployer)[LOCK1](0);
			expect(await myNFT.lockerOf(0)).to.equal(deployer.address);
		});

		it('Should be able to lock token by approved_user', async () => {
			const { myNFT, acc1 } = await approveUser1();
			await myNFT.connect(acc1)[LOCK1](0);
			expect(await myNFT.lockerOf(0)).to.equal(acc1.address);
		});
	});

	describe('lock - with two parameters', () => {
		it('Should not lock token if already locked', async () => {
			const { myNFT, deployer } = await deployMyNFTFixture();
			await myNFT.connect(deployer)[LOCK2](0, deployer.address);
			await expect(
				myNFT.connect(deployer)[LOCK2](0, deployer.address)
			).to.be.revertedWith('ERC7066: Locked');
		});

		it('Should not allow random user to lock', async () => {
			const { myNFT, acc1 } = await deployMyNFTFixture();
			await expect(
				myNFT.connect(acc1)[LOCK2](0, acc1.address)
			).to.be.revertedWith('ERC7066: Require owner');
		});

		it('Should not allow approved_user to lock', async () => {
			const { myNFT, acc1 } = await approveUser1();
			await expect(
				myNFT.connect(acc1)[LOCK2](0, acc1.address)
			).to.be.revertedWith('ERC7066: Require owner');
		});

		it('Should allow token owner to lock, locker is owner', async () => {
			const { myNFT, deployer } = await deployMyNFTFixture();
			await myNFT.connect(deployer)[LOCK2](0, deployer.address);
			expect(await myNFT.lockerOf(0)).to.equal(deployer.address);
		});

		it('Should allow token owner to lock, locker is zero-address', async () => {
			const { myNFT, deployer } = await deployMyNFTFixture();
			await myNFT.connect(deployer)[LOCK2](0, ethers.constants.AddressZero);
			expect(await myNFT.lockerOf(0)).to.equal(ethers.constants.AddressZero);
		});
	});

	describe('unlock', () => {
		it('Should not unlock token if not locked', async () => {
			const { myNFT, deployer } = await deployMyNFTFixture();
			await expect(myNFT.connect(deployer).unlock(0)).to.be.revertedWith(
				'ERC7066: Unlocked'
			);
		});

		it('Should not unlock token if msg.sender is not the locker', async () => {
			const { myNFT, deployer, acc1 } = await deployMyNFTFixture();
			await myNFT.connect(deployer)[LOCK1](0);
			await expect(myNFT.connect(acc1).unlock(0)).to.be.reverted;
		});

		it('Should allow owner to unlock', async () => {
			const { myNFT, deployer } = await deployMyNFTFixture();
			await myNFT.connect(deployer)[LOCK1](0);
			await myNFT.connect(deployer).unlock(0);
			expect(await myNFT.lockerOf(0)).to.equal(ethers.constants.AddressZero);
		});

		it('Should allow approver to unlock', async () => {
			const { myNFT, acc1 } = await approveUser1();
			await myNFT.connect(acc1)[LOCK1](0);
			await myNFT.connect(acc1).unlock(0);
			expect(await myNFT.lockerOf(0)).to.equal(ethers.constants.AddressZero);
		});
	});

	describe('transferAndLock', () => {
		it('Should not allow if the user is not owner or approved', async () => {
			const { myNFT, deployer, acc1 } = await deployMyNFTFixture();
			await expect(
				myNFT
					.connect(acc1)
					.transferAndLock(0, deployer.address, acc1.address, false)
			).to.be.reverted;
		});

		it('Should transfer and lock, msg.sender - owner ,setApproval - true', async () => {
			const { myNFT, deployer, acc1 } = await deployMyNFTFixture();
			await myNFT
				.connect(deployer)
				.transferAndLock(0, deployer.address, acc1.address, true);
			expect(await myNFT.ownerOf(0)).to.equal(acc1.address);
			expect(await myNFT.lockerOf(0)).to.equal(deployer.address);
			expect(await myNFT.getApproved(0)).to.equal(deployer.address);
		});

		it('Should transfer and lock,msg.sender - owner, setApproval - false', async () => {
			const { myNFT, deployer, acc1 } = await deployMyNFTFixture();
			await myNFT
				.connect(deployer)
				.transferAndLock(0, deployer.address, acc1.address, false);
			expect(await myNFT.ownerOf(0)).to.equal(acc1.address);
			expect(await myNFT.lockerOf(0)).to.equal(deployer.address);
			expect(await myNFT.getApproved(0)).to.equal(ethers.constants.AddressZero);
		});

		it('Should transfer and lock, msg.sender - approved_user, setApproval - true', async () => {
			const { myNFT, deployer, acc1 } = await approveUser1();
			await myNFT
				.connect(acc1)
				.transferAndLock(0, deployer.address, acc1.address, true);
			expect(await myNFT.ownerOf(0)).to.equal(acc1.address);
			expect(await myNFT.lockerOf(0)).to.equal(acc1.address);
			expect(await myNFT.getApproved(0)).to.equal(acc1.address);
		});

		it('Should transfer and lock, msg.sender - approved_user,setApproval - false', async () => {
			const { myNFT, deployer, acc1 } = await approveUser1();
			await myNFT
				.connect(acc1)
				.transferAndLock(0, deployer.address, acc1.address, false);
			expect(await myNFT.ownerOf(0)).to.equal(acc1.address);
			expect(await myNFT.lockerOf(0)).to.equal(acc1.address);
			expect(await myNFT.getApproved(0)).to.equal(ethers.constants.AddressZero);
		});
	});

	describe('approve', () => {
		it('Should not allow if the user is not owner/approved_user', async () => {
			const { myNFT, acc1 } = await deployMyNFTFixture();
			await expect(myNFT.connect(acc1).approve(acc1.address, 0)).to.be.reverted;
		});

		it('Should not allow if token is locked', async () => {
			const { myNFT, deployer, acc1 } = await deployMyNFTFixture();
			await myNFT.connect(deployer)[LOCK1](0);
			await expect(
				myNFT.connect(deployer).approve(acc1.address, 0)
			).to.be.revertedWith('ERC7066: Locked');
		});

		it('Should allow user with isApprovedForAll to approve', async () => {
			const { myNFT, acc1, acc2 } = await approveUser1();
			await myNFT.connect(acc1).approve(acc2.address, 0);
			expect(await myNFT.getApproved(0)).to.equal(acc2.address);
		});
	});

	describe('transferFrom', () => {
		describe('beforeTokenTransfer', () => {
			it('Should not allow transfer if the token is locked', async () => {
				const { myNFT, deployer, acc1 } = await deployMyNFTFixture();
				await myNFT.connect(deployer)[LOCK1](0);
				await expect(
					myNFT
						.connect(deployer)
						.transferFrom(deployer.address, acc1.address, 0)
				).to.be.revertedWith('ERC7066: Locked');
			});

			it('Should not allow transfer if user is not owner/approved_user', async () => {
				const { myNFT, deployer, acc1, acc2 } = await approveUser1();
				await expect(
					myNFT.connect(acc2).transferFrom(deployer.address, acc1.address, 0)
				).to.be.revertedWith('ERC721: caller is not token owner or approved');
			});
		});

		describe('afterTokenTransfer', async () => {
			it('Should check if token has a locker', async () => {
				const { myNFT, deployer, acc1 } = await deployMyNFTFixture();
				await myNFT
					.connect(deployer)
					.transferFrom(deployer.address, acc1.address, 0);
				expect(await myNFT.lockerOf(0)).to.equal(ethers.constants.AddressZero);
				expect(await myNFT.ownerOf(0)).to.equal(acc1.address);
			});

			it('Should be able to transfer by approved_user', async () => {
				const { myNFT, deployer, acc1 } = await approveUser1();
				await myNFT
					.connect(acc1)
					.transferFrom(deployer.address, acc1.address, 0);
				expect(await myNFT.lockerOf(0)).to.equal(ethers.constants.AddressZero);
				expect(await myNFT.ownerOf(0)).to.equal(acc1.address);
			});
		});
	});
});
