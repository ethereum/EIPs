import {ethers} from "hardhat";
import {expect} from 'chai';
import {SignerWithAddress} from "@nomiclabs/hardhat-ethers/signers";
import {Erc721Consumable} from "../typechain";

describe("ERC721Consumable", async () => {
	let owner: SignerWithAddress, approved: SignerWithAddress, operator: SignerWithAddress, consumer: SignerWithAddress,
		other: SignerWithAddress;
	let erc721Consumable: Erc721Consumable;
	let snapshotId: any;
	const tokenID = 1; // The first minted NFT

	before(async () => {
		const signers = await ethers.getSigners();
		owner = signers[0];
		approved = signers[1];
		operator = signers[2];
		consumer = signers[3];
		other = signers[4];

		const ERC721Consumable = await ethers.getContractFactory("ERC721Consumable");
		const deployedContract = await ERC721Consumable.deploy();
		await deployedContract.deployed();
		erc721Consumable = deployedContract as Erc721Consumable;

		await erc721Consumable.mint();
	})

	beforeEach(async function () {
		snapshotId = await ethers.provider.send('evm_snapshot', []);
	});

	afterEach(async function () {
		await ethers.provider.send('evm_revert', [snapshotId]);
	});

	it('should successfully change consumer', async () => {
		// when:
		await erc721Consumable.changeConsumer(consumer.address, tokenID);
		// then:
		expect(await erc721Consumable.consumerOf(tokenID)).to.equal(consumer.address);
	});

	it('should emit event with args', async () => {
		// when:
		const tx = await erc721Consumable.changeConsumer(consumer.address, tokenID);

		// then:
		await expect(tx)
			.to.emit(erc721Consumable, 'ConsumerChanged')
			.withArgs(owner.address, consumer.address, tokenID);
	});

	it('should successfully change consumer when caller is approved', async () => {
		// given:
		await erc721Consumable.approve(approved.address, tokenID);
		// when:
		const tx = await erc721Consumable.connect(approved).changeConsumer(consumer.address, tokenID);

		// then:
		await expect(tx)
			.to.emit(erc721Consumable, 'ConsumerChanged')
			.withArgs(owner.address, consumer.address, tokenID);
		// and:
		expect(await erc721Consumable.consumerOf(tokenID)).to.equal(consumer.address);
	});

	it('should successfully change consumer when caller is operator', async () => {
		// given:
		await erc721Consumable.setApprovalForAll(operator.address, true);
		// when:
		const tx = await erc721Consumable.connect(operator).changeConsumer(consumer.address, tokenID);

		// then:
		await expect(tx)
			.to.emit(erc721Consumable, 'ConsumerChanged')
			.withArgs(owner.address, consumer.address, tokenID);
		// and:
		expect(await erc721Consumable.consumerOf(tokenID)).to.equal(consumer.address);
	});

	it('should revert when caller is not owner, not approved', async () => {
		const expectedRevertMessage = 'ERC721Consumable: changeConsumer caller is not owner nor approved';
		await expect(erc721Consumable.connect(other).changeConsumer(consumer.address, tokenID))
			.to.be.revertedWith(expectedRevertMessage);
	});

	it('should revert when caller is approved for the token', async () => {
		// given:
		await erc721Consumable.changeConsumer(consumer.address, tokenID);
		// then:
		const expectedRevertMessage = 'ERC721Consumable: changeConsumer caller is not owner nor approved';
		await expect(erc721Consumable.connect(consumer).changeConsumer(consumer.address, tokenID))
			.to.be.revertedWith(expectedRevertMessage);
	});

	it('should revert when tokenID is nonexistent', async () => {
		const invalidTokenID = 2;
		const expectedRevertMessage = 'ERC721: owner query for nonexistent token';
		await expect(erc721Consumable.changeConsumer(consumer.address, invalidTokenID))
			.to.be.revertedWith(expectedRevertMessage);
	});

	it('should revert when calling consumerOf with nonexistent tokenID', async () => {
		const invalidTokenID = 2;
		const expectedRevertMessage = 'ERC721Consumable: consumer query for nonexistent token';
		await expect(erc721Consumable.consumerOf(invalidTokenID))
			.to.be.revertedWith(expectedRevertMessage);
	});

	it('should clear consumer on transfer', async () => {
		await erc721Consumable.changeConsumer(consumer.address, tokenID);
		await expect(erc721Consumable.transferFrom(owner.address, other.address, tokenID))
			.to.emit(erc721Consumable, 'ConsumerChanged')
				.withArgs(owner.address, ethers.constants.AddressZero, tokenID);
	})

	it('should emit ConsumerChanged on mint', async () => {
		await expect(erc721Consumable.mint())
			.to.emit(erc721Consumable, 'ConsumerChanged')
				.withArgs(ethers.constants.AddressZero, ethers.constants.AddressZero, tokenID + 1);
	})

	it('should not be able to transfer from consumer', async () => {
		const expectedRevertMessage = 'ERC721: transfer caller is not owner nor approved';
		await erc721Consumable.changeConsumer(consumer.address, tokenID);
		await expect(erc721Consumable.connect(consumer).transferFrom(owner.address, other.address, tokenID))
			.to.revertedWith(expectedRevertMessage)
	})
});