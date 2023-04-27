import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";
import { createHash } from 'node:crypto';
import { StandardMerkleTree } from "@openzeppelin/merkle-tree";
import { ERCxxxxAuthorization, ERCxxxxRole, merkleTestAnchors, NULLADDR, createAttestation} from "./commons";



export async function minimalAttestationExample() {
  // #################################### PRELIMINARIES
  const merkleTestAnchors = [
      ['0x' + createHash('sha256').update('TestAnchor123').digest('hex')],
      ['0x' + createHash('sha256').update('TestAnchor124').digest('hex')],
      ['0x' + createHash('sha256').update('TestAnchor125').digest('hex')],
      ['0x' + createHash('sha256').update('TestAnchor126').digest('hex')],
      ['0x' + createHash('sha256').update('SaltLeave').digest('hex')] // shall never be used on-chain!
      ]
  const merkleTree = StandardMerkleTree.of(merkleTestAnchors, ["bytes32"]);

  // #################################### ACCOUNTS
  // Alice shall get the NFT, oracle signs the attestation off-chain 
  const [alice, oracle] = await ethers.getSigners();

  // #################################### CREATE AN ATTESTATION
  const to = alice.address;
  const anchor = merkleTestAnchors[0][0];
  const proof = merkleTree.getProof([anchor]);
  const attestationTime = Math.floor(Date.now() / 1000.0); // Now in seconds UTC

  const validStartTime = 0;
  const validEndTime = attestationTime + 15 * 60; // 15 minutes valid from attestation

  // Hash and sign. In practice, oracle shall only sign when Proof-of-Control is established!
  const messageHash = ethers.utils.solidityKeccak256(["address", "bytes32", "uint256", 'uint256', "uint256", "bytes32[]"], [to, anchor, attestationTime, validStartTime, validEndTime, proof]);
  const sig = await oracle.signMessage(ethers.utils.arrayify(messageHash));
  // Encode
  return ethers.utils.defaultAbiCoder.encode(['address', 'bytes32', 'uint256', 'uint256', 'uint256', 'bytes32[]', 'bytes'], [to, anchor, attestationTime,  validStartTime, validStartTime, proof, sig]);
}


describe("ERCxxxx: Asset-Bound NFT --- Basics", function () {
  // Fixture to deploy the MetaAnchor contract and assigne roles.
  // Besides owner there's user, minter and burner with appropriate roles.
  async function deployPTNFTFixture() {
    // Contracts are deployed using the first signer/account by default
    const [owner, maintainer, oracle, alice, bob, mallory, hacker, carl, gasProvider ] = await ethers.getSigners();

    const MetaAnchor = await ethers.getContractFactory("ERCxxxx");
    const burnAuthorization = ERCxxxxAuthorization.ALL;
    const approveAuthorization = ERCxxxxAuthorization.ALL;

    const metaAnchor = await MetaAnchor.connect(owner).deploy("Physical Transferable NFT test", "PTNFT", burnAuthorization, approveAuthorization);
    await metaAnchor.connect(owner).grantRole(metaAnchor.MAINTAINER_ROLE(), maintainer.address);

    // Create Merkle Tree
    const merkleTree = StandardMerkleTree.of(merkleTestAnchors, ["bytes32"]);
    await expect(metaAnchor.connect(maintainer).updateValidAnchors(merkleTree.root))
      .to.emit(metaAnchor, "ValidAnchorsUpdate")
      .withArgs(merkleTree.root, maintainer.address);

    await expect(metaAnchor.connect(maintainer).updateOracle(oracle.address, true))
      .to.emit(metaAnchor, "OracleUpdate")
      .withArgs(oracle.address, true);

    // Uncomment to see the merkle tree.
    // console.log(merkleTree.dump());

    return { metaAnchor, merkleTree, owner, maintainer, oracle, alice, bob, mallory, hacker, carl, gasProvider };
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

describe("Authorization Map tests", function () {
  it("SHOULD interpret ERCxxxxAuthorization correctly", async function () {
    // Create the message to sign
    const { metaAnchor } = await loadFixture(deployPTNFTFixture);      

    // OWNER
    await expect(await metaAnchor.hasAuthorization(ERCxxxxRole.OWNER, await metaAnchor.createAuthorizationMap(ERCxxxxAuthorization.NONE)))
      .to.be.equal(false);
    await expect(await metaAnchor.hasAuthorization(ERCxxxxRole.OWNER, await metaAnchor.createAuthorizationMap(ERCxxxxAuthorization.OWNER)))
    .to.be.equal(true);
    await expect(await metaAnchor.hasAuthorization(ERCxxxxRole.OWNER, await metaAnchor.createAuthorizationMap(ERCxxxxAuthorization.ISSUER)))
    .to.be.equal(false);
    await expect(await metaAnchor.hasAuthorization(ERCxxxxRole.OWNER, await metaAnchor.createAuthorizationMap(ERCxxxxAuthorization.ASSET)))
    .to.be.equal(false);
    await expect(await metaAnchor.hasAuthorization(ERCxxxxRole.OWNER, await metaAnchor.createAuthorizationMap(ERCxxxxAuthorization.OWNER_AND_ASSET)))
    .to.be.equal(true);
    await expect(await metaAnchor.hasAuthorization(ERCxxxxRole.OWNER, await metaAnchor.createAuthorizationMap(ERCxxxxAuthorization.OWNER_AND_ISSUER)))
    .to.be.equal(true);
    await expect(await metaAnchor.hasAuthorization(ERCxxxxRole.OWNER, await metaAnchor.createAuthorizationMap(ERCxxxxAuthorization.ASSET_AND_ISSUER)))
    .to.be.equal(false);
    await expect(await metaAnchor.hasAuthorization(ERCxxxxRole.OWNER, await metaAnchor.createAuthorizationMap(ERCxxxxAuthorization.ALL)))
    .to.be.equal(true);

    // ISSUER
    await expect(await metaAnchor.hasAuthorization(ERCxxxxRole.ISSUER, await metaAnchor.createAuthorizationMap(ERCxxxxAuthorization.NONE)))
      .to.be.equal(false);
    await expect(await metaAnchor.hasAuthorization(ERCxxxxRole.ISSUER, await metaAnchor.createAuthorizationMap(ERCxxxxAuthorization.OWNER)))
    .to.be.equal(false);
    await expect(await metaAnchor.hasAuthorization(ERCxxxxRole.ISSUER, await metaAnchor.createAuthorizationMap(ERCxxxxAuthorization.ISSUER)))
    .to.be.equal(true);
    await expect(await metaAnchor.hasAuthorization(ERCxxxxRole.ISSUER, await metaAnchor.createAuthorizationMap(ERCxxxxAuthorization.ASSET)))
    .to.be.equal(false);
    await expect(await metaAnchor.hasAuthorization(ERCxxxxRole.ISSUER, await metaAnchor.createAuthorizationMap(ERCxxxxAuthorization.OWNER_AND_ASSET)))
    .to.be.equal(false);
    await expect(await metaAnchor.hasAuthorization(ERCxxxxRole.ISSUER, await metaAnchor.createAuthorizationMap(ERCxxxxAuthorization.OWNER_AND_ISSUER)))
    .to.be.equal(true);
    await expect(await metaAnchor.hasAuthorization(ERCxxxxRole.ISSUER, await metaAnchor.createAuthorizationMap(ERCxxxxAuthorization.ASSET_AND_ISSUER)))
    .to.be.equal(true);
    await expect(await metaAnchor.hasAuthorization(ERCxxxxRole.ISSUER, await metaAnchor.createAuthorizationMap(ERCxxxxAuthorization.ALL)))
    .to.be.equal(true);


    // ASSET
    await expect(await metaAnchor.hasAuthorization(ERCxxxxRole.ASSET, await metaAnchor.createAuthorizationMap(ERCxxxxAuthorization.NONE)))
      .to.be.equal(false);
    await expect(await metaAnchor.hasAuthorization(ERCxxxxRole.ASSET, await metaAnchor.createAuthorizationMap(ERCxxxxAuthorization.OWNER)))
    .to.be.equal(false);
    await expect(await metaAnchor.hasAuthorization(ERCxxxxRole.ASSET, await metaAnchor.createAuthorizationMap(ERCxxxxAuthorization.ISSUER)))
    .to.be.equal(false);
    await expect(await metaAnchor.hasAuthorization(ERCxxxxRole.ASSET, await metaAnchor.createAuthorizationMap(ERCxxxxAuthorization.ASSET)))
    .to.be.equal(true);
    await expect(await metaAnchor.hasAuthorization(ERCxxxxRole.ASSET, await metaAnchor.createAuthorizationMap(ERCxxxxAuthorization.OWNER_AND_ASSET)))
    .to.be.equal(true);
    await expect(await metaAnchor.hasAuthorization(ERCxxxxRole.ASSET, await metaAnchor.createAuthorizationMap(ERCxxxxAuthorization.OWNER_AND_ISSUER)))
    .to.be.equal(false);
    await expect(await metaAnchor.hasAuthorization(ERCxxxxRole.ASSET, await metaAnchor.createAuthorizationMap(ERCxxxxAuthorization.ASSET_AND_ISSUER)))
    .to.be.equal(true);
    await expect(await metaAnchor.hasAuthorization(ERCxxxxRole.ASSET, await metaAnchor.createAuthorizationMap(ERCxxxxAuthorization.ALL)))
    .to.be.equal(true);
  });
});


    describe("Attestation-based transfers", function () {
      it("SHOULD only allow oracle to issue attestation", async function () {
        // Create the message to sign
        const { metaAnchor, merkleTree, oracle, mallory, gasProvider } = await loadFixture(deployPTNFTFixture);      

        const to = "0x1234567890123456789012345678901234567890";
        const anchor = merkleTestAnchors[0][0];
        const attestation = await createAttestation(to, anchor, oracle, merkleTree);
        expect(await metaAnchor.assertAttestation(attestation))
          .to.be.equal(true);

        const fraudAttestation = await createAttestation(to, anchor, mallory, merkleTree);
        await expect(metaAnchor.assertAttestation(fraudAttestation))
          .to.be.revertedWith("EIP-XXXX Attestation not signed by trusted oracle");
      });

      it("SHOULD allow mint and transfer with valid attestations", async function() {
        const { metaAnchor, merkleTree, oracle, mintAttestationAlice, anchor, alice, bob, hacker, gasProvider } = await loadFixture(deployABTandMintTokenToAlice);      
  
        const attestationBob = await createAttestation(bob.address, anchor, oracle, merkleTree); // Mint to alice
        
        await expect(metaAnchor.connect(gasProvider).transferAnchor(attestationBob))
        .to.emit(metaAnchor, "Transfer") // Standard ERC721 event
        .withArgs(alice.address, bob.address, 1)
        .to.emit(metaAnchor, "AnchorTransfer")
        .withArgs(alice.address, bob.address, anchor, 1);

        // Token is now at bob... so alice may hire a hacker quickly and re-use her attestation to get 
        // the token back from Bob ... which shall of course not work
        await expect(metaAnchor.connect(hacker).transferAnchor(mintAttestationAlice))
        .to.revertedWith("EIP-XXXX Attestation already used") // Standard ERC721 event
      })    
      

      it("SHOULDN'T allow safeTransfer per default", async function() {
        const { metaAnchor, alice, bob} = await loadFixture(deployABTandMintTokenToAlice);      
  
        await expect(metaAnchor.connect(alice).transferFrom(alice.address, bob.address, 1)) 
        .to.revertedWith("EIP-XXXX: Token not transferable");
      })
      
      it("SHOULDN'T allow approveAnchor followed by safeTransfer when anchor not floating", async function() {
        const { metaAnchor, anchor, oracle, merkleTree, alice, bob, gasProvider, mallory,carl} = await loadFixture(deployABTandMintTokenToAlice);      
        const tokenId = await metaAnchor.tokenByAnchor(anchor);

        const attestationBob = await createAttestation(bob.address, anchor, oracle, merkleTree); // Mint to alice

        // somebody approves himself via attestation approves bob to act on her behalf
        await expect(metaAnchor.connect(gasProvider).approveAnchor(attestationBob))
        .to.emit(metaAnchor, "Approval") // Standard ERC721 event
        .withArgs(await metaAnchor.ownerOf(tokenId), bob.address, tokenId);
        
        // Should not allow mallory to transfer, since only bob is approved
        await expect(metaAnchor.connect(mallory).transferFrom(alice.address, bob.address, 1)) 
        .to.revertedWith("ERC721: caller is not token owner or approved");

        // Even though Bob is approved, cannot transfer, since anchor is not floating
        await expect(metaAnchor.connect(bob).transferFrom(alice.address, carl.address, tokenId))
        .to.revertedWith("EIP-XXXX: Token not transferable");
      })

      it("SHOULDN't allow to attesting arbitrary anchors", async function() {
        const { metaAnchor, merkleTree, maintainer, oracle, alice, hacker } = await loadFixture(deployPTNFTFixture);      

        // Publish root node of a made up tree, s.t. all proofs we use are from a different tree
        const madeUpRootNode = '0xaaaaaaaab0c754f1c68c699990a456c6073aaa28109c1bd83880c49dcece3f65'; // random string
        metaAnchor.connect(maintainer).updateValidAnchors(madeUpRootNode)
        const anchor = merkleTestAnchors[0][0];
  
        // Let the oracle create an valid attestation (from the oracle's view)
        const attestationAlice = await createAttestation(alice.address, anchor, oracle, merkleTree); // Mint to alice  
        await expect(metaAnchor.connect(hacker).transferAnchor(attestationAlice))
        .to.revertedWith("ERC-XXXX Anchor not valid")
      })

      it("SHOULDN't allow using attestations before validity ", async function() {
        const { metaAnchor, merkleTree, maintainer, oracle, alice } = await loadFixture(deployPTNFTFixture);      

        // Publish root node of a made up tree, s.t. all proofs we use are from a different tree
        const madeUpRootNode = '0xaaaaaaaab0c754f1c68c699990a456c6073aaa28109c1bd83880c49dcece3f65'; // random string
        metaAnchor.connect(maintainer).updateValidAnchors(madeUpRootNode)
        const anchor = merkleTestAnchors[0][0];
  
        // Let the oracle create an valid attestation (from the oracle's view)
        const curTime =  Math.floor(Date.now() / 1000.0);
        const twoMinInFuture =  curTime + 2 * 60;
        const attestationAlice = await createAttestation(alice.address, anchor, oracle, merkleTree, twoMinInFuture); // Mint to alice  
        await expect(metaAnchor.connect(alice).transferAnchor(attestationAlice))
        .to.revertedWith("ERC-XXXX Attestation not valid yet")
      })
  });

  describe("ERC721Burnable-compatible behavior", function () {
    it("SHOULD burn like ERC-721 (direct)", async function() {
      const { metaAnchor, anchor, alice, bob} = await loadFixture(deployABTandMintTokenToAlice);      
      const tokenId = await metaAnchor.tokenByAnchor(anchor);

      // Let bob try to burn... should not work
      await expect(metaAnchor.connect(bob).burn(tokenId))
      .to.revertedWith("ERC-XXXX: No permission to burn");

      // Alice then burns, which shall be transaction to 0x0
      await expect(metaAnchor.connect(alice).burn(tokenId))
      .to.emit(metaAnchor, "Transfer")
      .withArgs( alice.address,NULLADDR, tokenId);  
    })
    it("SHOULD burn like ERC-721 (approved)", async function() {
      const { metaAnchor, merkleTree, owner, maintainer, oracle, mintAttestationAlice, anchor, alice, bob, mallory, hacker } = await loadFixture(deployABTandMintTokenToAlice);      
      const tokenId = await metaAnchor.tokenByAnchor(anchor);

      // alice approves bob to act on her behalf
      await expect(metaAnchor.connect(alice).setApprovalForAll(bob.address, true))
      .to.emit(metaAnchor, "ApprovalForAll") // Standard ERC721 event
      .withArgs(alice.address, bob.address, true);

      // Let mallory try to burn... should not work
      await expect(metaAnchor.connect(mallory).burn(tokenId))
      .to.revertedWith("ERC-XXXX: No permission to burn");

      // Bob is approved, so bob can burn
      await expect(metaAnchor.connect(bob).burn(tokenId))
      .to.emit(metaAnchor, "Transfer")
      .withArgs(alice.address,NULLADDR, tokenId)
      .to.emit(metaAnchor, "AnchorTransfer")
      .withArgs(alice.address,NULLADDR, anchor, tokenId);  
    })

    it("SHOULD allow issuer to burn", async function() {
      const { metaAnchor, merkleTree, owner, maintainer, oracle, mintAttestationAlice, anchor, alice, bob, mallory, hacker } = await loadFixture(deployABTandMintTokenToAlice);      
      const tokenId = await metaAnchor.tokenByAnchor(anchor);

      // Let mallory try to burn... should not work
      await expect(metaAnchor.connect(mallory).burn(tokenId))
      .to.revertedWith("ERC-XXXX: No permission to burn");

      // Bob is approved, so bob can burn
      await expect(metaAnchor.connect(maintainer).burn(tokenId))
      .to.emit(metaAnchor, "Transfer")
      .withArgs(alice.address,NULLADDR, tokenId);  
    })

    it("SHOULD burn like ERC-721 (via attestation-approved)", async function() {
      const { metaAnchor, merkleTree, oracle, anchor, alice, bob, mallory, hacker } = await loadFixture(deployABTandMintTokenToAlice);      
      const tokenId = await metaAnchor.tokenByAnchor(anchor);
      const attestationBob = await createAttestation(bob.address, anchor, oracle, merkleTree); // Mint to alice

      // somebody approves himself via attestation approves bob to act on her behalf
      await expect(metaAnchor.connect(hacker).approveAnchor(attestationBob))
      .to.emit(metaAnchor, "Approval") // Standard ERC721 event
      .withArgs(await metaAnchor.ownerOf(tokenId), bob.address, tokenId);

      // Let mallory try to burn... should not work
      await expect(metaAnchor.connect(mallory).burn(tokenId))
      .to.revertedWith("ERC-XXXX: No permission to burn");

      // Bob is approved, so bob can burn
      await expect(metaAnchor.connect(bob).burn(tokenId))
      .to.emit(metaAnchor, "Transfer")
      .withArgs(alice.address,NULLADDR, tokenId);  
    })

    it("SHOULD burn like ERC-721 (attestation)", async function() {
      const { metaAnchor, merkleTree, oracle, mintAttestationAlice, anchor, alice, bob, mallory } = await loadFixture(deployABTandMintTokenToAlice);      
      const tokenId = await metaAnchor.tokenByAnchor(anchor);
      const burnAttestation = await createAttestation(bob.address, anchor, oracle, merkleTree); // Mint to alice

      // Let mallory try to burn a token based on the creation anchor..
      await expect(metaAnchor.connect(mallory).burnAnchor(mintAttestationAlice))
      .to.revertedWith("EIP-XXXX Attestation already used");

      // Now, using a fresh attestation, the same guy can burn
      await expect(metaAnchor.connect(mallory).burnAnchor(burnAttestation))
      .to.emit(metaAnchor, "Transfer")
      .withArgs(alice.address,NULLADDR, tokenId);  
    })


    it("SHOULD use same tokenId when anchor is used again after burning", async function() {
      const { metaAnchor, merkleTree, oracle, anchor, alice, bob, mallory } = await loadFixture(deployABTandMintTokenToAlice);      
      const tokenId = await metaAnchor.tokenByAnchor(anchor);

      // Alice then burns her token, since she does no longer like it in her wallet. This shall be a transaction to 0x0
      await expect(metaAnchor.connect(alice).burn(tokenId))
      .to.emit(metaAnchor, "Transfer")
      .withArgs( alice.address,NULLADDR, tokenId);  

      // Bob gets the ASSET, confirmed by ORACLE. Since Alice burned tokenId 1 before, but we have the same anchor
      // it is expected that BOB gets a new NFT with same tokenId
      const attestationBob = await createAttestation(bob.address, anchor, oracle, merkleTree); // Mint to alice
      await expect(metaAnchor.connect(mallory).transferAnchor(attestationBob))
      .to.emit(metaAnchor, "Transfer") // Standard ERC721 event
      .withArgs(NULLADDR, bob.address, tokenId);
    })
});  


describe("Metadata tests", function () {
  it("SHOULD allow only maintainer to update baseURI", async function () {
    // Create the message to sign
    const { metaAnchor, maintainer, mallory } = await loadFixture(deployABTandMintTokenToAlice);      

    await expect(metaAnchor.connect(mallory).updateBaseURI("http://test.xyz/"))
    .to.revertedWith("AccessControl: account 0x9965507d1a55bcc2695c58ba16fb37d819b0a4dc is missing role 0x339759585899103d2ace64958e37e18ccb0504652c81d4a1b8aa80fe2126ab95");

    await metaAnchor.connect(maintainer).updateBaseURI("http://test.xyz/");
    // FIXME event would be nice    
  });

  it("SHOULD use anchor for tokenURI", async function () {
    // Create the message to sign
    const { metaAnchor, anchor, maintainer, alice, mallory } = await loadFixture(deployABTandMintTokenToAlice);      
    await metaAnchor.connect(maintainer).updateBaseURI("http://test.xyz/collection/");

    expect(await metaAnchor.tokenURI(1))
    .to.be.equal("http://test.xyz/collection/0xaa0c61ccb0c754f1c68c699990a456c6073aaa28109c1bd83880c49dcece3d65");
  });
});


});
