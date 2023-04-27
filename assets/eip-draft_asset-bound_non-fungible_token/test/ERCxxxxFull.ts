import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";
import { createHash } from 'node:crypto';
import { StandardMerkleTree } from "@openzeppelin/merkle-tree";
import { float } from "hardhat/internal/core/params/argumentTypes";
import { ERCxxxxAuthorization, ERCxxxxRole, merkleTestAnchors, NULLADDR, createAttestation, AttestedTransferLimitUpdatePolicy, invalidAnchor} from "./commons";

describe("ERCxxxx: Asset-Bound NFT --- Full", function () {
  // Fixture to deploy the MetaAnchor contract and assigne roles.
  // Besides owner there's user, minter and burner with appropriate roles.
  async function deployPTNFTFixture() {
    // Contracts are deployed using the first signer/account by default
    const [owner, maintainer, oracle, alice, bob, mallory, hacker, carl, gasProvider ] = await ethers.getSigners();

    const MetaAnchor = await ethers.getContractFactory("ERCxxxxFull");
    const burnAuthorization = ERCxxxxAuthorization.ALL;
    const approveAuthorization = ERCxxxxAuthorization.ALL;
    const attestationLimitPerAnchor = 10;

    return actuallyDeploy(burnAuthorization, approveAuthorization, true, 10, AttestedTransferLimitUpdatePolicy.FLEXIBLE);
  }

  async function deployABTandMintTokenToAlice() {
    // Contracts are deployed using the first signer/account by default
    const {metaAnchor, merkleTree, owner, maintainer, oracle, alice, bob, mallory, hacker, carl, gasProvider} = await deployPTNFTFixture();
  
    const anchor = merkleTestAnchors[0][0];
    const mintAttestationAlice = await createAttestation(alice.address, anchor, oracle, merkleTree); // Mint to alice

    await expect(metaAnchor.connect(gasProvider).transferAnchor(mintAttestationAlice))
    .to.emit(metaAnchor, "Transfer") // Standard ERC721 event
    .withArgs(NULLADDR, alice.address, 1);

    return { metaAnchor, merkleTree, owner, maintainer, oracle, mintAttestationAlice, anchor, alice, bob, mallory, hacker, carl, gasProvider };
  }

  async function actuallyDeploy(burnAuthorization: ERCxxxxAuthorization, approveAuthorization: ERCxxxxAuthorization, floatable: boolean, attestationLimitPerAnchor: number, limitUpdatePolicy: AttestedTransferLimitUpdatePolicy) {
    const [owner, maintainer, oracle, alice, bob, mallory, hacker, carl, gasProvider ] = await ethers.getSigners();

    const MetaAnchor = await ethers.getContractFactory("ERCxxxxFull");

    const metaAnchor = await MetaAnchor.connect(owner).deploy("Physical Transferable NFT test", "PTNFT", burnAuthorization, approveAuthorization, floatable, attestationLimitPerAnchor, limitUpdatePolicy);
    await metaAnchor.connect(owner).grantRole(metaAnchor.MAINTAINER_ROLE(), maintainer.address);

    // Create Merkle Tree
    const merkleTree = StandardMerkleTree.of(merkleTestAnchors, ["bytes32"]);
    await metaAnchor.connect(maintainer).updateValidAnchors(merkleTree.root);

    await expect(metaAnchor.connect(maintainer).updateOracle(oracle.address, true))
    .to.emit(metaAnchor, "OracleUpdate")
    .withArgs(oracle.address, true);

    // Uncomment to see the merkle tree.
    // console.log(merkleTree.dump());

    return { metaAnchor, merkleTree, owner, maintainer, oracle, alice, bob, mallory, hacker, carl, gasProvider };
  }

  async function deployForAttestationLimit(limit: number, policy: AttestedTransferLimitUpdatePolicy) {
    return actuallyDeploy(ERCxxxxAuthorization.ALL, ERCxxxxAuthorization.ALL, true, limit, policy);
  }

  /*
  describe("Deployment & Settings", function () {
    it("Should implement EIP-165 support the EIP-XXXX interface", async function () {
      const { metaAnchor } = await loadFixture(deployPTNFTFixture);
      expect("TODO not implemented yet").to.be.equal(true);
      // FIXME
      // expect(await metaAnchor.supportsInterface('0x0489b56f')).to.equal(true);
    });
  });
*/

describe("Anchor-Floating", function () {

  it("SHOULDN't allow floating when contract not floatable", async function () {
    const [owner, maintainer ] = await ethers.getSigners();
    const MyContract = await ethers.getContractFactory("ERCxxxxFull");
    const burnAuthorization = ERCxxxxAuthorization.ALL;
    const approveAuthorization = ERCxxxxAuthorization.ALL;
    const floatable = false; // Make it non-floatable for this test
    const myContract = await MyContract.connect(owner).deploy("Physical Transferable NFT test", "PTNFT", burnAuthorization, approveAuthorization, floatable, 10, AttestedTransferLimitUpdatePolicy.FLEXIBLE);
    await myContract.connect(owner).grantRole(myContract.MAINTAINER_ROLE(), maintainer.address);
    
    expect(await myContract.canFloat())
    .to.be.equal(false);

    await expect(myContract.canStartFloating(ERCxxxxAuthorization.ALL))
    .to.revertedWith("ERC-XXXX: Tokens not floatable");
  });

  it("SHOULD only allow maintainer to specify canStartFloating and canStopFloating", async function () {
    const { metaAnchor, merkleTree, owner, maintainer, mallory } = await loadFixture(deployABTandMintTokenToAlice);

    await expect(metaAnchor.canStartFloating(ERCxxxxAuthorization.ALL))
    .to.revertedWith("AccessControl: account 0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266 is missing role 0x339759585899103d2ace64958e37e18ccb0504652c81d4a1b8aa80fe2126ab95");

    await expect(metaAnchor.connect(maintainer).canStartFloating(ERCxxxxAuthorization.ALL))
    .to.emit(metaAnchor, "CanStartFloating")
    .withArgs(ERCxxxxAuthorization.ALL, maintainer.address);

  });

  it("SHOULD allow owner to float token only when OWNER is allowed", async function () {
    const { metaAnchor, anchor, maintainer, alice, mallory } = await loadFixture(deployABTandMintTokenToAlice);
    const tokenId = await metaAnchor.tokenByAnchor(anchor);

    await expect(metaAnchor.connect(maintainer).canStartFloating(ERCxxxxAuthorization.ASSET_AND_ISSUER))
    .to.emit(metaAnchor, "CanStartFloating")
    .withArgs(ERCxxxxAuthorization.ASSET_AND_ISSUER, maintainer.address);

    await expect(metaAnchor.connect(alice).allowFloating(anchor, true))
    .to.revertedWith("ERC-XXXX: No permission to start floating")

    await expect(metaAnchor.connect(maintainer).canStartFloating(ERCxxxxAuthorization.OWNER_AND_ASSET))
    .to.emit(metaAnchor, "CanStartFloating")
    .withArgs(ERCxxxxAuthorization.OWNER_AND_ASSET, maintainer.address);

    await expect(metaAnchor.connect(alice).allowFloating(anchor, true))
    .to.emit(metaAnchor, "AnchorFloatingState")
    .withArgs(anchor, tokenId, true);
  });

  it("SHOULD only allow owner to transfer token when floating", async function () {
    const { metaAnchor, anchor, maintainer, alice, bob, mallory } = await loadFixture(deployABTandMintTokenToAlice);
    const tokenId = await metaAnchor.tokenByAnchor(anchor);

    await expect(metaAnchor.connect(maintainer).canStartFloating(ERCxxxxAuthorization.OWNER_AND_ASSET))
    .to.emit(metaAnchor, "CanStartFloating")
    .withArgs(ERCxxxxAuthorization.OWNER_AND_ASSET, maintainer.address);

    await expect(metaAnchor.connect(alice).allowFloating(anchor, true))
    .to.emit(metaAnchor, "AnchorFloatingState")
    .withArgs(anchor, tokenId, true);

    await expect(metaAnchor.connect(mallory).transferFrom(alice.address, mallory.address, tokenId))
    .to.revertedWith("ERC721: caller is not token owner or approved");

    await expect(metaAnchor.connect(alice).transferFrom(alice.address, bob.address, tokenId))
    .to.emit(metaAnchor, "Transfer")
    .withArgs(alice.address,bob.address, tokenId);
    
  });


  it("SHOULD allow maintainer to float ANY token only when ISSUER is allowed", async function () {
    const { metaAnchor, anchor, maintainer, mallory } = await loadFixture(deployABTandMintTokenToAlice);
    const tokenId = await metaAnchor.tokenByAnchor(anchor);

    await expect(metaAnchor.connect(maintainer).canStartFloating(ERCxxxxAuthorization.OWNER))
    .to.emit(metaAnchor, "CanStartFloating")
    .withArgs(ERCxxxxAuthorization.OWNER, maintainer.address);

    await expect(metaAnchor.connect(maintainer).allowFloating(anchor, true))
    .to.revertedWith("ERC-XXXX: No permission to start floating")

    await expect(metaAnchor.connect(maintainer).canStartFloating(ERCxxxxAuthorization.ISSUER))
    .to.emit(metaAnchor, "CanStartFloating")
    .withArgs(ERCxxxxAuthorization.ISSUER, maintainer.address);

    await expect(metaAnchor.connect(maintainer).allowFloating(anchor, true))
    .to.emit(metaAnchor, "AnchorFloatingState")
    .withArgs(anchor, tokenId, true);
  });

  it("SHOULD allow maintainer to float HIS OWN token when ISSUER is allowed", async function () {
    const { metaAnchor, anchor, alice, maintainer, oracle, merkleTree, gasProvider } = await loadFixture(deployABTandMintTokenToAlice);
    const tokenId = await metaAnchor.tokenByAnchor(anchor);

    await expect(metaAnchor.connect(maintainer).canStartFloating(ERCxxxxAuthorization.OWNER))
    .to.emit(metaAnchor, "CanStartFloating")
    .withArgs(ERCxxxxAuthorization.OWNER, maintainer.address);

    await expect(metaAnchor.connect(maintainer).allowFloating(anchor, true))
    .to.revertedWith("ERC-XXXX: No permission to start floating")

    const attestationMaintainer = await createAttestation(maintainer.address, anchor, oracle, merkleTree); 
    await expect(metaAnchor.connect(gasProvider).transferAnchor(attestationMaintainer))
    .to.emit(metaAnchor, "Transfer")
    .withArgs(alice.address, maintainer.address, tokenId)
    
    await expect(metaAnchor.connect(maintainer).allowFloating(anchor, true))
    .to.emit(metaAnchor, "AnchorFloatingState")
    .withArgs(anchor, tokenId, true);
  });

  it("SHOULD allow approveAnchor followed by safeTransfer when anchor IS floating", async function() {
    const { metaAnchor, anchor, maintainer, oracle, merkleTree, alice, bob, gasProvider, mallory,carl} = await loadFixture(deployABTandMintTokenToAlice);      
    const tokenId = await metaAnchor.tokenByAnchor(anchor);
    const attestationBob = await createAttestation(bob.address, anchor, oracle, merkleTree); // Mint to alice

    // somebody approves himself via attestation approves bob to act on her behalf
    await expect(metaAnchor.connect(gasProvider).approveAnchor(attestationBob))
    .to.emit(metaAnchor, "Approval") // Standard ERC721 event
    .withArgs(await metaAnchor.ownerOf(tokenId), bob.address, tokenId);
    
    // Should not allow mallory to transfer, since only bob is approved
    await expect(metaAnchor.connect(mallory).transferFrom(alice.address, bob.address, 1)) 
    .to.revertedWith("ERC721: caller is not token owner or approved");

    await expect(metaAnchor.connect(maintainer).canStartFloating(ERCxxxxAuthorization.OWNER))
    .to.emit(metaAnchor, "CanStartFloating")
    .withArgs(ERCxxxxAuthorization.OWNER, maintainer.address);

    await expect(metaAnchor.connect(alice).allowFloating(anchor, true))
    .to.emit(metaAnchor, "AnchorFloatingState")
    .withArgs(anchor, tokenId, true);
    
    await expect(metaAnchor.connect(bob).transferFrom(alice.address, carl.address, tokenId))
    .to.emit(metaAnchor, "Transfer")
    .withArgs(alice.address,carl.address, tokenId);        
  })

});

describe("Attested Transfer Limits", function () {
  it("SHOULD count attested transfers (transfer, burn, approve)", async function () {
    const { metaAnchor, anchor, maintainer, oracle, merkleTree, alice, bob, gasProvider, mallory,carl} = await loadFixture(deployABTandMintTokenToAlice);      
    const tokenId = await metaAnchor.tokenByAnchor(anchor);
    const attestationBob = await createAttestation(bob.address, anchor, oracle, merkleTree); // Mint to alice
    const attestationCarl = await createAttestation(carl.address, anchor, oracle, merkleTree); // Mint to alice

    
    // Transfers shall be counted - also the one from the fixture
    expect(await metaAnchor.attestationsUsedByAnchor(anchor))
    .to.be.equal(1);

    // Should increase count by 1
    await expect(metaAnchor.approveAnchor(attestationBob))
    .to.emit(metaAnchor, "Approval") // Standard ERC721 event
    .withArgs(await metaAnchor.ownerOf(tokenId), bob.address, tokenId);

    // Should increase count by 1
    await expect(metaAnchor.burnAnchor(attestationCarl))
    .to.emit(metaAnchor, "Transfer")
    .withArgs(alice.address, NULLADDR, tokenId);

    // InitialMint + Approve + Burns shall also be counted - also the one from the fixture
    expect(await metaAnchor.attestationsUsedByAnchor(anchor))
    .to.be.equal(3);

    // Should return 0 for invalid anchors
    expect(await metaAnchor.attestationsUsedByAnchor(invalidAnchor))
    .to.be.equal(0);
  });

  it("SHOULD allow maintainer to update global attestation limit", async function () {
    const { metaAnchor, maintainer, oracle, merkleTree, alice, bob, gasProvider, mallory,carl} = await deployForAttestationLimit(10, AttestedTransferLimitUpdatePolicy.FLEXIBLE);

    await expect(metaAnchor.connect(mallory).updateGlobalAttestedTransferLimit(5))
    .to.revertedWith("AccessControl: account 0x9965507d1a55bcc2695c58ba16fb37d819b0a4dc is missing role 0x339759585899103d2ace64958e37e18ccb0504652c81d4a1b8aa80fe2126ab95");

    // Should be able to update
    await expect(metaAnchor.connect(maintainer).updateGlobalAttestedTransferLimit(5))
    .to.emit(metaAnchor, "GlobalAttestedTransferLimitUpdate") // Standard ERC721 event
    .withArgs(5, maintainer.address);

    // Check effect, but requesting transfers left from a non-existent anchor
    expect(await metaAnchor.attestatedTransfersLeft(invalidAnchor))
    .to.be.equal(5);
  });

  it("Should allow maintainer to update anchor-based attestation limit w/o changing global limits", async function () {
    const globalLimit = 10;
    const specificAnchorLimit = 5;
    const { metaAnchor, maintainer, oracle, merkleTree, alice, bob, gasProvider, mallory,carl} = await deployForAttestationLimit(globalLimit, AttestedTransferLimitUpdatePolicy.FLEXIBLE);
    const anchor = merkleTestAnchors[0][0];

    // Note that an anchor does not need to exist yet for playing with the limits
    // Check effect, but requesting transfers left from a non-existent anchor
    expect(await metaAnchor.attestatedTransfersLeft(invalidAnchor))
    .to.be.equal(globalLimit);
    
    // Should be able to update
    await expect(metaAnchor.connect(maintainer).updateAttestedTransferLimit(anchor, specificAnchorLimit))
    .to.emit(metaAnchor, "AttestedTransferLimitUpdate") // Standard ERC721 event
    .withArgs(specificAnchorLimit, anchor, maintainer.address);

    // Check unchanged global effect, but requesting transfers left from a non-existent anchor
    expect(await metaAnchor.attestatedTransfersLeft(invalidAnchor))
    .to.be.equal(globalLimit);
    
    // Check verify effect
    expect(await metaAnchor.attestatedTransfersLeft(anchor))
    .to.be.equal(specificAnchorLimit);
  });

  it("Should enforce anchor limits (global + local)", async function () {
    const globalLimit = 2;
    const specificAnchorLimit = 1;
    const { metaAnchor, maintainer, oracle, merkleTree, alice, bob, gasProvider, mallory,carl, hacker} = await deployForAttestationLimit(globalLimit, AttestedTransferLimitUpdatePolicy.FLEXIBLE);
    const anchor = merkleTestAnchors[0][0]; // can be transferred twice
    const limitedAnchor = merkleTestAnchors[1][0]; // can be transferred once

    const anchorToAlice = await createAttestation(alice.address, anchor, oracle, merkleTree); // Mint to alice
    const anchorToBob = await createAttestation(bob.address, anchor, oracle, merkleTree); // Transfer to bob
    const anchorToHacker = await createAttestation(hacker.address, anchor, oracle, merkleTree); // Limit reached!

    const limitedAnchorToCarl = await createAttestation(carl.address, limitedAnchor, oracle, merkleTree); // Mint to carl
    const limitedAnchorToMallory = await createAttestation(mallory.address, limitedAnchor, oracle, merkleTree); // Limit reached!
        
    // Update anchor based limit
    await expect(metaAnchor.connect(maintainer).updateAttestedTransferLimit(limitedAnchor, specificAnchorLimit))
    .to.emit(metaAnchor, "AttestedTransferLimitUpdate") // Standard ERC721 event
    .withArgs(specificAnchorLimit, limitedAnchor, maintainer.address);

    expect(await metaAnchor.attestatedTransfersLeft(anchor))
    .to.be.equal(globalLimit);

    expect(await metaAnchor.attestatedTransfersLeft(limitedAnchor))
    .to.be.equal(specificAnchorLimit);

    // ####################################### FIRST ANCHOR
    await expect(metaAnchor.connect(gasProvider).transferAnchor(anchorToAlice))
    .to.emit(metaAnchor, "Transfer");

    await expect(metaAnchor.connect(gasProvider).transferAnchor(anchorToBob))
    .to.emit(metaAnchor, "Transfer");

    await expect(metaAnchor.connect(gasProvider).transferAnchor(anchorToHacker))
    .to.revertedWith("ERC-XXXX: No attested transfers left");

    // ###################################### SECOND ANCHOR
    await expect(metaAnchor.connect(gasProvider).transferAnchor(limitedAnchorToCarl))
    .to.emit(metaAnchor, "Transfer");

    await expect(metaAnchor.connect(gasProvider).transferAnchor(limitedAnchorToMallory))
    .to.revertedWith("ERC-XXXX: No attested transfers left");
  });
});
  
});
