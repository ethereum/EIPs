import {ethers} from "hardhat";
import {expect} from 'chai';
import {SignerWithAddress} from "@nomiclabs/hardhat-ethers/signers";
import {Erc721Consumable} from "../typechain";

describe("ERC721Consumable", async () => {
	let owner: SignerWithAddress, approved: SignerWithAddress, operator: SignerWithAddress, consumer: SignerWithAddress,
		other: SignerWithAddress;
	let token: Erc721Consumable;
	let snapshotId: any;
	const tokenID = 1; // The first minted NFT

	before(async () => {
		const signers = await ethers.getSigners();
		owner = signers[0];
		approved = signers[1];
		operator = signers[2];
		consumer = signers[3];
		other = signers[4];

		const ConsumableToken = await ethers.getContractFactory("ExampleToken");
		const deployedContract = await ConsumableToken.deploy();
		await deployedContract.deployed();
		token = deployedContract as Erc721Consumable;

		await token.mint();
	})

	beforeEach(async function () {
		snapshotId = await ethers.provider.send('evm_snapshot', []);
	});

	afterEach(async function () {
		await ethers.provider.send('evm_revert', [snapshotId]);
	});

	it('should implement ERC165', async () => {
		expect(await token.supportsInterface("0x953c8dfa")).to.be.true;
	})

	it('should successfully change consumer', async () => {
		// when:
		await token.changeConsumer(consumer.address, tokenID);
		// then:
		expect(await token.consumerOf(tokenID)).to.equal(consumer.address);
	});

	it('should emit event with args', async () => {
		// when:
		const tx = await token.changeConsumer(consumer.address, tokenID);

		// then:
		await expect(tx)
			.to.emit(token, 'ConsumerChanged')
			.withArgs(owner.address, consumer.address, tokenID);
	});

	it('should successfully change consumer when caller is approved', async () => {
		// given:
		await token.approve(approved.address, tokenID);
		// when:
		const tx = await token.connect(approved).changeConsumer(consumer.address, tokenID);

		// then:
		await expect(tx)
			.to.emit(token, 'ConsumerChanged')
			.withArgs(owner.address, consumer.address, tokenID);
		// and:
		expect(await token.consumerOf(tokenID)).to.equal(consumer.address);
	});

	it('should successfully change consumer when caller is operator', async () => {
		// given:
		await token.setApprovalForAll(operator.address, true);
		// when:
		const tx = await token.connect(operator).changeConsumer(consumer.address, tokenID);

		// then:
		await expect(tx)
			.to.emit(token, 'ConsumerChanged')
			.withArgs(owner.address, consumer.address, tokenID);
		// and:
		expect(await token.consumerOf(tokenID)).to.equal(consumer.address);
	});

	it('should revert when caller is not owner, not approved', async () => {
		const expectedRevertMessage = 'ERC721Consumable: changeConsumer caller is not owner nor approved';
		await expect(token.connect(other).changeConsumer(consumer.address, tokenID))
			.to.be.revertedWith(expectedRevertMessage);
	});

	it('should revert when caller is approved for the token', async () => {
		// given:
		await token.changeConsumer(consumer.address, tokenID);
		// then:
		const expectedRevertMessage = 'ERC721Consumable: changeConsumer caller is not owner nor approved';
		await expect(token.connect(consumer).changeConsumer(consumer.address, tokenID))
			.to.be.revertedWith(expectedRevertMessage);
	});

	it('should revert when tokenID is nonexistent', async () => {
		const invalidTokenID = 2;
		const expectedRevertMessage = 'ERC721: owner query for nonexistent token';
		await expect(token.changeConsumer(consumer.address, invalidTokenID))
			.to.be.revertedWith(expectedRevertMessage);
	});

	it('should revert when calling consumerOf with nonexistent tokenID', async () => {
		const invalidTokenID = 2;
		const expectedRevertMessage = 'ERC721Consumable: consumer query for nonexistent token';
		await expect(token.consumerOf(invalidTokenID))
			.to.be.revertedWith(expectedRevertMessage);
	});

	it('should clear consumer on transfer', async () => {
		await token.changeConsumer(consumer.address, tokenID);
		await expect(token.transferFrom(owner.address, other.address, tokenID))
			.to.emit(token, 'ConsumerChanged')
				.withArgs(owner.address, ethers.constants.AddressZero, tokenID);
	})

	it('should emit ConsumerChanged on mint', async () => {
		await expect(token.mint())
			.to.emit(token, 'ConsumerChanged')
				.withArgs(ethers.constants.AddressZero, ethers.constants.AddressZero, tokenID + 1);
	})

	it('should not be able to transfer from consumer', async () => {
		const expectedRevertMessage = 'ERC721: transfer caller is not owner nor approved';
		await token.changeConsumer(consumer.address, tokenID);
		await expect(token.connect(consumer).transferFrom(owner.address, other.address, tokenID))
			.to.revertedWith(expectedRevertMessage)
	})
});