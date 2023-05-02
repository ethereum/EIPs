import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";
import { createHash } from 'node:crypto';
import { StandardMerkleTree } from "@openzeppelin/merkle-tree";
import { ERC6956Authorization, ERC6956Role, merkleTestAnchors, NULLADDR, createAttestation} from "./commons";



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


describe("ERC6956: Asset-Bound NFT --- Basics", function () {
  // Fixture to deploy the abnftContract contract and assigne roles.
  // Besides owner there's user, minter and burner with appropriate roles.
  async function deployAbNftFixture() {
    // Contracts are deployed using the first signer/account by default
    const [owner, maintainer, oracle, alice, bob, mallory, hacker, carl, gasProvider ] = await ethers.getSigners();

    const AbNftContract = await ethers.getContractFactory("ERC6956");
    //const burnAuthorization = ERC6956Authorization.ALL;
    //const approveAuthorization = ERC6956Authorization.ALL;

    const abnftContract = await AbNftContract.connect(owner).deploy("Asset-Bound NFT test", "ABNFT");
    await abnftContract.connect(owner).updateMaintainer(maintainer.address, true);

    // Create Merkle Tree
    const merkleTree = StandardMerkleTree.of(merkleTestAnchors, ["bytes32"]);
    await expect(abnftContract.connect(maintainer).updateValidAnchors(merkleTree.root))
      .to.emit(abnftContract, "ValidAnchorsUpdate")
      .withArgs(merkleTree.root, maintainer.address);

    await expect(abnftContract.connect(maintainer).updateOracle(oracle.address, true))
      .to.emit(abnftContract, "OracleUpdate")
      .withArgs(oracle.address, true);

    // Uncomment to see the merkle tree.
    // console.log(merkleTree.dump());

    return { abnftContract, merkleTree, owner, maintainer, oracle, alice, bob, mallory, hacker, carl, gasProvider };
  }

  async function deployABTandMintTokenToAlice() {
    // Contracts are deployed using the first signer/account by default
    const {abnftContract, merkleTree, owner, maintainer, oracle, alice, bob, mallory, hacker, carl, gasProvider} = await deployAbNftFixture();
  
    const anchor = merkleTestAnchors[0][0];
    const mintAttestationAlice = await createAttestation(alice.address, anchor, oracle, merkleTree); // Mint to alice

    await expect(abnftContract.connect(gasProvider).transferAnchor(mintAttestationAlice))
    .to.emit(abnftContract, "Transfer") // Standard ERC721 event
    .withArgs(NULLADDR, alice.address, 1);

    return { abnftContract, merkleTree, owner, maintainer, oracle, mintAttestationAlice, anchor, alice, bob, mallory, hacker, carl, gasProvider };
  }

  /*
  describe("Deployment & Settings", function () {
    it("Should implement EIP-165 support the EIP-6956 interface", async function () {
      const { abnftContract } = await loadFixture(deployPTNFTFixture);
      expect("TODO not implemented yet").to.be.equal(true);
      // FIXME
      // expect(await abnftContract.supportsInterface('0x0489b56f')).to.equal(true);
    });
  });
*/

describe("Authorization Map tests", function () {
  it("SHOULD interpret ERC6956Authorization correctly", async function () {
    // Create the message to sign
    const { abnftContract } = await loadFixture(deployAbNftFixture);      

    // OWNER
    await expect(await abnftContract.hasAuthorization(ERC6956Role.OWNER, await abnftContract.createAuthorizationMap(ERC6956Authorization.NONE)))
      .to.be.equal(false);
    await expect(await abnftContract.hasAuthorization(ERC6956Role.OWNER, await abnftContract.createAuthorizationMap(ERC6956Authorization.OWNER)))
    .to.be.equal(true);
    await expect(await abnftContract.hasAuthorization(ERC6956Role.OWNER, await abnftContract.createAuthorizationMap(ERC6956Authorization.ISSUER)))
    .to.be.equal(false);
    await expect(await abnftContract.hasAuthorization(ERC6956Role.OWNER, await abnftContract.createAuthorizationMap(ERC6956Authorization.ASSET)))
    .to.be.equal(false);
    await expect(await abnftContract.hasAuthorization(ERC6956Role.OWNER, await abnftContract.createAuthorizationMap(ERC6956Authorization.OWNER_AND_ASSET)))
    .to.be.equal(true);
    await expect(await abnftContract.hasAuthorization(ERC6956Role.OWNER, await abnftContract.createAuthorizationMap(ERC6956Authorization.OWNER_AND_ISSUER)))
    .to.be.equal(true);
    await expect(await abnftContract.hasAuthorization(ERC6956Role.OWNER, await abnftContract.createAuthorizationMap(ERC6956Authorization.ASSET_AND_ISSUER)))
    .to.be.equal(false);
    await expect(await abnftContract.hasAuthorization(ERC6956Role.OWNER, await abnftContract.createAuthorizationMap(ERC6956Authorization.ALL)))
    .to.be.equal(true);

    // ISSUER
    await expect(await abnftContract.hasAuthorization(ERC6956Role.ISSUER, await abnftContract.createAuthorizationMap(ERC6956Authorization.NONE)))
      .to.be.equal(false);
    await expect(await abnftContract.hasAuthorization(ERC6956Role.ISSUER, await abnftContract.createAuthorizationMap(ERC6956Authorization.OWNER)))
    .to.be.equal(false);
    await expect(await abnftContract.hasAuthorization(ERC6956Role.ISSUER, await abnftContract.createAuthorizationMap(ERC6956Authorization.ISSUER)))
    .to.be.equal(true);
    await expect(await abnftContract.hasAuthorization(ERC6956Role.ISSUER, await abnftContract.createAuthorizationMap(ERC6956Authorization.ASSET)))
    .to.be.equal(false);
    await expect(await abnftContract.hasAuthorization(ERC6956Role.ISSUER, await abnftContract.createAuthorizationMap(ERC6956Authorization.OWNER_AND_ASSET)))
    .to.be.equal(false);
    await expect(await abnftContract.hasAuthorization(ERC6956Role.ISSUER, await abnftContract.createAuthorizationMap(ERC6956Authorization.OWNER_AND_ISSUER)))
    .to.be.equal(true);
    await expect(await abnftContract.hasAuthorization(ERC6956Role.ISSUER, await abnftContract.createAuthorizationMap(ERC6956Authorization.ASSET_AND_ISSUER)))
    .to.be.equal(true);
    await expect(await abnftContract.hasAuthorization(ERC6956Role.ISSUER, await abnftContract.createAuthorizationMap(ERC6956Authorization.ALL)))
    .to.be.equal(true);


    // ASSET
    await expect(await abnftContract.hasAuthorization(ERC6956Role.ASSET, await abnftContract.createAuthorizationMap(ERC6956Authorization.NONE)))
      .to.be.equal(false);
    await expect(await abnftContract.hasAuthorization(ERC6956Role.ASSET, await abnftContract.createAuthorizationMap(ERC6956Authorization.OWNER)))
    .to.be.equal(false);
    await expect(await abnftContract.hasAuthorization(ERC6956Role.ASSET, await abnftContract.createAuthorizationMap(ERC6956Authorization.ISSUER)))
    .to.be.equal(false);
    await expect(await abnftContract.hasAuthorization(ERC6956Role.ASSET, await abnftContract.createAuthorizationMap(ERC6956Authorization.ASSET)))
    .to.be.equal(true);
    await expect(await abnftContract.hasAuthorization(ERC6956Role.ASSET, await abnftContract.createAuthorizationMap(ERC6956Authorization.OWNER_AND_ASSET)))
    .to.be.equal(true);
    await expect(await abnftContract.hasAuthorization(ERC6956Role.ASSET, await abnftContract.createAuthorizationMap(ERC6956Authorization.OWNER_AND_ISSUER)))
    .to.be.equal(false);
    await expect(await abnftContract.hasAuthorization(ERC6956Role.ASSET, await abnftContract.createAuthorizationMap(ERC6956Authorization.ASSET_AND_ISSUER)))
    .to.be.equal(true);
    await expect(await abnftContract.hasAuthorization(ERC6956Role.ASSET, await abnftContract.createAuthorizationMap(ERC6956Authorization.ALL)))
    .to.be.equal(true);
  });
});


    describe("Attestation-based transfers", function () {
      it("SHOULD only allow oracle to issue attestation", async function () {
        // Create the message to sign
        const { abnftContract, merkleTree, oracle, mallory, gasProvider } = await loadFixture(deployAbNftFixture);      

        const to = "0x1234567890123456789012345678901234567890";
        const anchor = merkleTestAnchors[0][0];
        const attestation = await createAttestation(to, anchor, oracle, merkleTree);
        expect(await abnftContract.assertAttestation(attestation))
          .to.be.equal(true);

        const fraudAttestation = await createAttestation(to, anchor, mallory, merkleTree);
        await expect(abnftContract.assertAttestation(fraudAttestation))
          .to.be.revertedWith("EIP-6956 Attestation not signed by trusted oracle");
      });

      it("SHOULD allow mint and transfer with valid attestations", async function() {
        const { abnftContract, merkleTree, oracle, mintAttestationAlice, anchor, alice, bob, hacker, gasProvider } = await loadFixture(deployABTandMintTokenToAlice);      
  
        const attestationBob = await createAttestation(bob.address, anchor, oracle, merkleTree); // Mint to alice
        
        await expect(abnftContract.connect(gasProvider).transferAnchor(attestationBob))
        .to.emit(abnftContract, "Transfer") // Standard ERC721 event
        .withArgs(alice.address, bob.address, 1)
        .to.emit(abnftContract, "AnchorTransfer")
        .withArgs(alice.address, bob.address, anchor, 1);

        // Token is now at bob... so alice may hire a hacker quickly and re-use her attestation to get 
        // the token back from Bob ... which shall of course not work
        await expect(abnftContract.connect(hacker).transferAnchor(mintAttestationAlice))
        .to.revertedWith("EIP-6956 Attestation already used") // Standard ERC721 event
      })    
      

      it("SHOULDN'T allow safeTransfer per default", async function() {
        const { abnftContract, alice, bob} = await loadFixture(deployABTandMintTokenToAlice);      
  
        await expect(abnftContract.connect(alice).transferFrom(alice.address, bob.address, 1)) 
        .to.revertedWith("EIP-6956: Token not transferable");
      })
      
      it("SHOULDN'T allow approveAnchor followed by safeTransfer when anchor not floating", async function() {
        const { abnftContract, anchor, oracle, merkleTree, alice, bob, gasProvider, mallory,carl} = await loadFixture(deployABTandMintTokenToAlice);      
        const tokenId = await abnftContract.tokenByAnchor(anchor);

        const attestationBob = await createAttestation(bob.address, anchor, oracle, merkleTree); // Mint to alice

        // somebody approves himself via attestation approves bob to act on her behalf
        await expect(abnftContract.connect(gasProvider).approveAnchor(attestationBob))
        .to.emit(abnftContract, "Approval") // Standard ERC721 event
        .withArgs(await abnftContract.ownerOf(tokenId), bob.address, tokenId);
        
        // Should not allow mallory to transfer, since only bob is approved
        await expect(abnftContract.connect(mallory).transferFrom(alice.address, bob.address, 1)) 
        .to.revertedWith("ERC721: caller is not token owner or approved");

        // Even though Bob is approved, cannot transfer, since anchor is not floating
        await expect(abnftContract.connect(bob).transferFrom(alice.address, carl.address, tokenId))
        .to.revertedWith("EIP-6956: Token not transferable");
      })

      it("SHOULDN't allow to attesting arbitrary anchors", async function() {
        const { abnftContract, merkleTree, maintainer, oracle, alice, hacker } = await loadFixture(deployAbNftFixture);      

        // Publish root node of a made up tree, s.t. all proofs we use are from a different tree
        const madeUpRootNode = '0xaaaaaaaab0c754f1c68c699990a456c6073aaa28109c1bd83880c49dcece3f65'; // random string
        abnftContract.connect(maintainer).updateValidAnchors(madeUpRootNode)
        const anchor = merkleTestAnchors[0][0];
  
        // Let the oracle create an valid attestation (from the oracle's view)
        const attestationAlice = await createAttestation(alice.address, anchor, oracle, merkleTree); // Mint to alice  
        await expect(abnftContract.connect(hacker).transferAnchor(attestationAlice))
        .to.revertedWith("ERC-6956 Anchor not valid")
      })

      it("SHOULDN't allow using attestations before validity ", async function() {
        const { abnftContract, merkleTree, maintainer, oracle, alice } = await loadFixture(deployAbNftFixture);      

        // Publish root node of a made up tree, s.t. all proofs we use are from a different tree
        const madeUpRootNode = '0xaaaaaaaab0c754f1c68c699990a456c6073aaa28109c1bd83880c49dcece3f65'; // random string
        abnftContract.connect(maintainer).updateValidAnchors(madeUpRootNode)
        const anchor = merkleTestAnchors[0][0];
  
        // Let the oracle create an valid attestation (from the oracle's view)
        const curTime =  Math.floor(Date.now() / 1000.0);
        const twoMinInFuture =  curTime + 2 * 60;
        const attestationAlice = await createAttestation(alice.address, anchor, oracle, merkleTree, twoMinInFuture); // Mint to alice  
        await expect(abnftContract.connect(alice).transferAnchor(attestationAlice))
        .to.revertedWith("ERC-6956 Attestation not valid yet")
      })
  });

  describe("ERC721Burnable-compatible behavior", function () {
    it("SHOULD burn like ERC-721 (direct)", async function() {
      const { abnftContract, anchor, alice, bob} = await loadFixture(deployABTandMintTokenToAlice);      
      const tokenId = await abnftContract.tokenByAnchor(anchor);

      // Let bob try to burn... should not work
      await expect(abnftContract.connect(bob).burn(tokenId))
      .to.revertedWith("ERC-6956: No permission to burn");

      // Alice then burns, which shall be transaction to 0x0
      await expect(abnftContract.connect(alice).burn(tokenId))
      .to.emit(abnftContract, "Transfer")
      .withArgs( alice.address,NULLADDR, tokenId);  
    })
    it("SHOULD burn like ERC-721 (approved)", async function() {
      const { abnftContract, merkleTree, owner, maintainer, oracle, mintAttestationAlice, anchor, alice, bob, mallory, hacker } = await loadFixture(deployABTandMintTokenToAlice);      
      const tokenId = await abnftContract.tokenByAnchor(anchor);

      // alice approves bob to act on her behalf
      await expect(abnftContract.connect(alice).setApprovalForAll(bob.address, true))
      .to.emit(abnftContract, "ApprovalForAll") // Standard ERC721 event
      .withArgs(alice.address, bob.address, true);

      // Let mallory try to burn... should not work
      await expect(abnftContract.connect(mallory).burn(tokenId))
      .to.revertedWith("ERC-6956: No permission to burn");

      // Bob is approved, so bob can burn
      await expect(abnftContract.connect(bob).burn(tokenId))
      .to.emit(abnftContract, "Transfer")
      .withArgs(alice.address,NULLADDR, tokenId)
      .to.emit(abnftContract, "AnchorTransfer")
      .withArgs(alice.address,NULLADDR, anchor, tokenId);  
    })

    it("SHOULD allow issuer to burn", async function() {
      const { abnftContract, merkleTree, owner, maintainer, oracle, mintAttestationAlice, anchor, alice, bob, mallory, hacker } = await loadFixture(deployABTandMintTokenToAlice);      
      
      const tokenId = await abnftContract.tokenByAnchor(anchor);

      await abnftContract.connect(maintainer).updateBurnAuthorization(ERC6956Authorization.ISSUER);

      // Let mallory try to burn... should not work
      await expect(abnftContract.connect(mallory).burn(tokenId))
      .to.revertedWith("ERC-6956: No permission to burn");

      // Bob is approved, so bob can burn
      await expect(abnftContract.connect(maintainer).burn(tokenId))
      .to.emit(abnftContract, "Transfer")
      .withArgs(alice.address,NULLADDR, tokenId);  
    })

    it("SHOULD burn like ERC-721 (via attestation-approved)", async function() {
      const { abnftContract, merkleTree, oracle, anchor, alice, bob, mallory, hacker } = await loadFixture(deployABTandMintTokenToAlice);      
      const tokenId = await abnftContract.tokenByAnchor(anchor);
      const attestationBob = await createAttestation(bob.address, anchor, oracle, merkleTree); // Mint to alice

      // somebody approves himself via attestation approves bob to act on her behalf
      await expect(abnftContract.connect(hacker).approveAnchor(attestationBob))
      .to.emit(abnftContract, "Approval") // Standard ERC721 event
      .withArgs(await abnftContract.ownerOf(tokenId), bob.address, tokenId);

      // Let mallory try to burn... should not work
      await expect(abnftContract.connect(mallory).burn(tokenId))
      .to.revertedWith("ERC-6956: No permission to burn");

      // Bob is approved, so bob can burn
      await expect(abnftContract.connect(bob).burn(tokenId))
      .to.emit(abnftContract, "Transfer")
      .withArgs(alice.address,NULLADDR, tokenId);  
    })

    it("SHOULD burn like ERC-721 (attestation)", async function() {
      const { abnftContract, merkleTree, oracle, mintAttestationAlice, anchor, alice, bob, mallory } = await loadFixture(deployABTandMintTokenToAlice);      
      const tokenId = await abnftContract.tokenByAnchor(anchor);
      const burnAttestation = await createAttestation(bob.address, anchor, oracle, merkleTree); // Mint to alice

      // Let mallory try to burn a token based on the creation anchor..
      await expect(abnftContract.connect(mallory).burnAnchor(mintAttestationAlice))
      .to.revertedWith("EIP-6956 Attestation already used");

      // Now, using a fresh attestation, the same guy can burn
      await expect(abnftContract.connect(mallory).burnAnchor(burnAttestation))
      .to.emit(abnftContract, "Transfer")
      .withArgs(alice.address,NULLADDR, tokenId);  
    })


    it("SHOULD use same tokenId when anchor is used again after burning", async function() {
      const { abnftContract, merkleTree, oracle, anchor, alice, bob, mallory } = await loadFixture(deployABTandMintTokenToAlice);      
      const tokenId = await abnftContract.tokenByAnchor(anchor);

      // Alice then burns her token, since she does no longer like it in her wallet. This shall be a transaction to 0x0
      await expect(abnftContract.connect(alice).burn(tokenId))
      .to.emit(abnftContract, "Transfer")
      .withArgs( alice.address,NULLADDR, tokenId);  

      // Bob gets the ASSET, confirmed by ORACLE. Since Alice burned tokenId 1 before, but we have the same anchor
      // it is expected that BOB gets a new NFT with same tokenId
      const attestationBob = await createAttestation(bob.address, anchor, oracle, merkleTree); // Mint to alice
      await expect(abnftContract.connect(mallory).transferAnchor(attestationBob))
      .to.emit(abnftContract, "Transfer") // Standard ERC721 event
      .withArgs(NULLADDR, bob.address, tokenId);
    })
});  


describe("Metadata tests", function () {
  it("SHOULD allow only maintainer to update baseURI", async function () {
    // Create the message to sign
    const { abnftContract, maintainer, mallory } = await loadFixture(deployABTandMintTokenToAlice);      

    await expect(abnftContract.connect(mallory).updateBaseURI("http://test.xyz/"))
    .to.revertedWith("ERC6956: Only maintainer allowed");

    await abnftContract.connect(maintainer).updateBaseURI("http://test.xyz/");
    // FIXME event would be nice    
  });

  it("SHOULD use anchor for tokenURI", async function () {
    // Create the message to sign
    const { abnftContract, anchor, maintainer, alice, mallory } = await loadFixture(deployABTandMintTokenToAlice);      
    await abnftContract.connect(maintainer).updateBaseURI("http://test.xyz/collection/");

    expect(await abnftContract.tokenURI(1))
    .to.be.equal("http://test.xyz/collection/0xaa0c61ccb0c754f1c68c699990a456c6073aaa28109c1bd83880c49dcece3d65");
  });
});


});
