const { expect } = require('chai');
const { ethers } = require('hardhat');

describe('MyNFT', function () {
	async function deployMyNFTFixture() {
		const [deployer, acc1, acc2, acc3] = await ethers.getSigners();
		const MyNFT = await ethers.getContractFactory('MyNFT');
		let myNFT = await MyNFT.deploy();
		await myNFT.deployed();

		return { myNFT, deployer, acc1, acc2, acc3 };
	}

	async function mintAndSetAuthority() {
		const { myNFT, deployer, acc1, acc2, acc3 } = await deployMyNFTFixture();
		await myNFT.connect(deployer).mint();
		await myNFT.connect(deployer).setLocker(0, acc1.address);
		return { myNFT, deployer, acc1, acc2, acc3 };
	}

	async function approveAcc2() {
		const { myNFT, deployer, acc1, acc2, acc3 } = await mintAndSetAuthority();
		await myNFT.connect(deployer).approve(acc2.address, 0);
		await myNFT.connect(deployer).setApprovalForAll(acc2.address, true);
		await myNFT.connect(acc2).lockApproved(0);
		return { myNFT, deployer, acc1, acc2, acc3 };
	}

	describe('SetLocker', function () {
		it('Should not allow anyone to set locker', async function () {
			const { myNFT, deployer, acc1, acc2 } = await deployMyNFTFixture();
			await myNFT.connect(deployer).mint();
			await expect(
				myNFT.connect(acc1).setLocker(0, acc1.address)
			).to.be.revertedWith('ERC721Lockable : Owner Required');
		});

		it('Should not allow to set locker when token is locked', async function () {
			const { myNFT, deployer, acc1, acc2 } = await deployMyNFTFixture();
			await myNFT.connect(deployer).mint();
			// set locker and let him lock the token
			await myNFT.connect(deployer).setLocker(0, acc1.address);
			await myNFT.connect(acc1).lock(0);

			//second check
			await expect(
				myNFT.connect(deployer).setLocker(0, acc2.address)
			).to.be.revertedWith('ERC721Lockable : Locked');
		});

		it('Should not allow to set locker when token is locked_approved', async function () {
			// minted token by deployer, acc1- locker, acc2- lock approved
			const { myNFT, deployer, acc1, acc2 } = await approveAcc2();
			await expect(
				myNFT.connect(deployer).setLocker(0, acc1.address)
			).to.be.revertedWith('ERC721Lockable : Locked');
		});
	});

	describe('RemoveLocker', function () {
		it('Should not allow anyone to remove locker', async () => {
			const { myNFT, deployer, acc1 } = await mintAndSetAuthority();
			await expect(myNFT.connect(acc1).removeLocker(0)).to.be.revertedWith(
				'ERC721Lockable : Owner Required'
			);
		});
		it('Should not allow to remove locker when token is locked', async () => {
			const { myNFT, deployer, acc1 } = await mintAndSetAuthority();
			// lock the token by locker
			await myNFT.connect(acc1).lock(0);

			await expect(myNFT.connect(deployer).removeLocker(0)).to.be.revertedWith(
				'ERC721Lockable : Locked'
			);
		});

		it('Should not allow to set locker when token is locked_approved', async function () {
			// minted token by deployer, acc1- locker, acc2- lock approved
			const { myNFT, deployer, acc1, acc2 } = await approveAcc2();
			await expect(myNFT.connect(deployer).removeLocker(0)).to.be.revertedWith(
				'ERC721Lockable : Locked'
			);
		});
	});

	describe('lockerOf', function () {
		it('Should get the correct locker address', async () => {
			const { myNFT, acc1 } = await mintAndSetAuthority();
			expect(await myNFT.connect(acc1).lockerOf(0)).to.equal(acc1.address);
		});
	});

	describe('lock', function () {
		it('Should not allow anyone to lock', async function () {
			const { myNFT, deployer, acc1, acc2 } = await mintAndSetAuthority();

			await expect(myNFT.connect(acc2).lock(0)).to.be.revertedWith(
				'ERC721Lockable : Locker Required'
			);
			await expect(myNFT.connect(deployer).lock(0)).to.be.revertedWith(
				'ERC721Lockable : Locker Required'
			);
		});

		it('Should not allow to lock when token is locked_approved', async function () {
			// minted token by deployer, acc1- lock authority, acc2- lock approved
			const { myNFT, deployer, acc1, acc2 } = await approveAcc2();
			await expect(myNFT.connect(acc1).lock(0)).to.be.revertedWith(
				'ERC721Lockable : Locked'
			);
		});

		it('Should not allow to lock when token is locked', async function () {
			const { myNFT, deployer, acc1, acc2 } = await mintAndSetAuthority();

			//lock the token by lock authority
			await myNFT.connect(acc1).lock(0);

			//second check
			await expect(myNFT.connect(acc1).lock(0)).to.be.revertedWith(
				'ERC721Lockable : Locked'
			);
		});
	});

	describe('unlock', function () {
		it('Should not allow anyone to unlock', async function () {
			const { myNFT, deployer, acc1, acc2 } = await mintAndSetAuthority();

			await expect(myNFT.connect(acc2).unlock(0)).to.be.revertedWith(
				'ERC721Lockable : Locker Required'
			);
			await expect(myNFT.connect(deployer).unlock(0)).to.be.revertedWith(
				'ERC721Lockable : Locker Required'
			);
		});

		it('Should not allow to lock when token is locked_approved', async function () {
			// minted token by deployer, acc1- lock authority, acc2- lock approved
			const { myNFT, deployer, acc1, acc2 } = await approveAcc2();
			await expect(myNFT.connect(acc1).unlock(0)).to.be.revertedWith(
				'ERC721Lockable : Locked by approved'
			);
		});

		it('Should not allow to unlock when token is not locked', async function () {
			const { myNFT, deployer, acc1, acc2 } = await mintAndSetAuthority();

			await expect(myNFT.connect(acc1).unlock(0)).to.be.revertedWith(
				'ERC721Lockable : Unlocked'
			);
		});
	});

	describe('approve', function () {
		it('Should not approve when token is locked', async function () {
			const { myNFT, deployer, acc1, acc2 } = await mintAndSetAuthority();

			await myNFT.connect(acc1).lock(0);

			await expect(
				myNFT.connect(deployer).approve(acc2.address, 0)
			).to.be.revertedWith('ERC721Lockable : Locked');
		});

		it('Should not approve when token is locked_approved', async function () {
			// minted token by deployer, acc1- lock authority, acc2- lock approved
			const { myNFT, deployer, acc1, acc2 } = await approveAcc2();
			await expect(
				myNFT.connect(acc1).approve(acc2.address, 0)
			).to.be.revertedWith('ERC721Lockable : Locked');
		});

		it('Should not allow anyone to approve', async function () {
			const { myNFT, deployer, acc1, acc2 } = await mintAndSetAuthority();

			await expect(
				myNFT.connect(acc1).approve(acc2.address, 0)
			).to.be.revertedWith(
				'ERC721: approve caller is not token owner or approved for all'
			);
		});
	});

	describe('lockApproved', async function () {
		it('Should not allow anyone without approval', async function () {
			const { myNFT, deployer, acc1, acc2 } = await mintAndSetAuthority();
			await expect(myNFT.connect(acc2).lockApproved(0)).to.be.revertedWith(
				'ERC721Lockable : Required approval'
			);
		});

		it('Should check if token is locked', async function () {
			const { myNFT, deployer, acc1, acc2 } = await mintAndSetAuthority();

			await myNFT.connect(deployer).approve(acc2.address, 0);
			await myNFT.connect(deployer).setApprovalForAll(acc2.address, true);
			await myNFT.connect(acc1).lock(0);

			await expect(myNFT.connect(acc2).lockApproved(0)).to.be.revertedWith(
				'ERC721Lockable : Locked'
			);
		});
	});

	describe('unlockApproved', async function () {
		it('Should not allow anyone without approval', async function () {
			const { myNFT, deployer, acc1, acc2 } = await mintAndSetAuthority();

			await expect(myNFT.connect(acc2).unlockApproved(0)).to.be.revertedWith(
				'ERC721Lockable : Required approval'
			);
		});

		it('Should not allow unlockApproved when token is locked', async function () {
			const { myNFT, deployer, acc1, acc2 } = await mintAndSetAuthority();

			await myNFT.connect(deployer).approve(acc2.address, 0);
			await myNFT.connect(deployer).setApprovalForAll(acc2.address, true);

			//lock the token by lock authority
			await myNFT.connect(acc1).lock(0);
			await expect(myNFT.connect(acc2).unlockApproved(0)).to.be.revertedWith(
				'ERC721Lockable : Locked by locker'
			);
		});

		it('Should check if token is in unlocked state', async function () {
			const { myNFT, deployer, acc1, acc2 } = await mintAndSetAuthority();

			await myNFT.connect(deployer).approve(acc2.address, 0);
			await myNFT.connect(deployer).setApprovalForAll(acc2.address, true);

			await expect(myNFT.connect(acc2).unlockApproved(0)).to.be.revertedWith(
				'ERC721Lockable : Unlocked'
			);
		});
	});

	describe('transferFrom', async function () {
		describe('Before Token Transfer', async function () {
			it('Should not allow transfer when token is locked', async function () {
				const { myNFT, deployer, acc1, acc2, acc3 } =
					await mintAndSetAuthority();

				await myNFT.connect(acc1).lock(0);
				await expect(
					myNFT
						.connect(deployer)
						.transferFrom(deployer.address, acc3.address, 0)
				).to.be.revertedWith('ERC721Lockable : Locked');
			});
			it('Should not allow transfer by anyone without approval(lock_approved,ERC721)', async function () {
				const { myNFT, deployer, acc1, acc2, acc3 } = await approveAcc2();

				await expect(
					myNFT.connect(acc1).transferFrom(deployer.address, acc3.address, 0)
				).to.be.revertedWith('ERC721: caller is not token owner or approved');
			});

			it('Should not allow transfer by anyone without approval(lock_approved,ERC721_Lockable)', async function () {
				const { myNFT, deployer, acc1, acc2, acc3 } = await approveAcc2();

				await expect(
					myNFT
						.connect(deployer)
						.transferFrom(deployer.address, acc3.address, 0)
				).to.be.revertedWith('ERC721Lockable : Required approval');
			});

			it('Should allow approved person to transfer token', async function () {
				const { myNFT, deployer, acc1, acc2, acc3 } = await approveAcc2();

				await myNFT
					.connect(acc2)
					.transferFrom(deployer.address, acc3.address, 0);
				expect(await myNFT.ownerOf(0)).to.equal(acc3.address);
			});
		});

		describe('After Token Transfer', async function () {
			it('Should check if token has new owner', async function () {
				const { myNFT, deployer, acc1, acc2, acc3 } =
					await mintAndSetAuthority();
				await myNFT
					.connect(deployer)
					.transferFrom(deployer.address, acc3.address, 0);

				expect(await myNFT.ownerOf(0)).to.equal(acc3.address);
			});

			it('Should check if token does not have a lock authority', async function () {
				const { myNFT, deployer, acc1, acc2, acc3 } =
					await mintAndSetAuthority();
				await myNFT
					.connect(deployer)
					.transferFrom(deployer.address, acc3.address, 0);
				await expect(myNFT.connect(acc1).lock(0)).to.be.revertedWith(
					'ERC721Lockable : Locker Required'
				);
			});

			it('Should check if token state is unlocked', async function () {
				const { myNFT, deployer, acc1, acc2, acc3 } =
					await mintAndSetAuthority();
				await myNFT
					.connect(deployer)
					.transferFrom(deployer.address, acc3.address, 0);
				await myNFT.connect(acc3).setLocker(0, acc1.address);
				await expect(myNFT.connect(acc1).unlock(0)).to.be.revertedWith(
					'ERC721Lockable : Unlocked'
				);
			});
		});
	});
});
