import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";
import { createHash } from 'node:crypto';
import { StandardMerkleTree } from "@openzeppelin/merkle-tree";
import { float } from "hardhat/internal/core/params/argumentTypes";
import { ERC6956Authorization, merkleTestAnchors, NULLADDR, AttestedTransferLimitUpdatePolicy, invalidAnchor, createAttestationWithData} from "./commons";
import { IERC6956AttestationLimitedInterfaceId, IERC6956InterfaceId, IERC6956FloatableInterfaceId, IERC6956ValidAnchorsInterfaceId} from "./commons";

export enum FloatState {
  Default, // 0, inherits from floatAll
  Floating, // 1
  Anchored // 2
}

describe("ERC6956: Asset-Bound NFT --- Full", function () {
  // Fixture to deploy the abnftContract contract and assigne roles.
  // Besides owner there's user, minter and burner with appropriate roles.
  async function deployAbNftFixture() {
    // Contracts are deployed using the first signer/account by default
    const [owner, maintainer, oracle, alice, bob, mallory, hacker, carl, gasProvider ] = await ethers.getSigners();

    return actuallyDeploy(10, AttestedTransferLimitUpdatePolicy.FLEXIBLE);
  }

  async function deployAbNftAndMintTokenToAliceFixture() {
    // Contracts are deployed using the first signer/account by default
    const {abnftContract, merkleTree, owner, maintainer, oracle, alice, bob, mallory, hacker, carl, gasProvider} = await deployAbNftFixture();
  
    const anchor = merkleTestAnchors[0][0];
    const [mintAttestationAlice, dataAlice] = await createAttestationWithData(alice.address, anchor, oracle, merkleTree); // Mint to alice

    const expectedTokenId = 1;
    await expect(abnftContract.connect(gasProvider)["transferAnchor(bytes,bytes)"](mintAttestationAlice, dataAlice))
    .to.emit(abnftContract, "Transfer") // Standard ERC721 event
    .withArgs(NULLADDR, alice.address, expectedTokenId)

    return { abnftContract, merkleTree, owner, maintainer, oracle, mintAttestationAlice, anchor, alice, bob, mallory, hacker, carl, gasProvider };
  }

  async function actuallyDeploy(attestationLimitPerAnchor: number, limitUpdatePolicy: AttestedTransferLimitUpdatePolicy) {
    const [owner, maintainer, oracle, alice, bob, mallory, hacker, carl, gasProvider ] = await ethers.getSigners();

    const AbNftContract = await ethers.getContractFactory("ERC6956Full");

    const abnftContract = await AbNftContract.connect(owner).deploy("Asset-Bound NFT test", "ABNFT", limitUpdatePolicy);
    await abnftContract.connect(owner).updateMaintainer(maintainer.address, true);

    // set attestation Limit per anchor
    await abnftContract.connect(maintainer).updateGlobalAttestationLimit(attestationLimitPerAnchor);

    // Create Merkle Tree
    const merkleTree = StandardMerkleTree.of(merkleTestAnchors, ["bytes32"]);
    await abnftContract.connect(maintainer).updateValidAnchors(merkleTree.root);

    await expect(abnftContract.connect(maintainer).updateOracle(oracle.address, true))
    .to.emit(abnftContract, "OracleUpdate")
    .withArgs(oracle.address, true);

    // Uncomment to see the merkle tree.
    // console.log(merkleTree.dump());

    return { abnftContract, merkleTree, owner, maintainer, oracle, alice, bob, mallory, hacker, carl, gasProvider };
  }

  async function deployForAttestationLimit(limit: number, policy: AttestedTransferLimitUpdatePolicy) {
    return actuallyDeploy(limit, policy);
  }
  
  describe("Deployment & Settings", function () {
    it("Should implement EIP-165 support the EIP-6956 interface", async function () {
      const { abnftContract } = await loadFixture(deployAbNftFixture);
    
      expect(await abnftContract.supportsInterface(IERC6956InterfaceId)).to.equal(true);
      expect(await abnftContract.supportsInterface(IERC6956FloatableInterfaceId)).to.equal(true);
      expect(await abnftContract.supportsInterface(IERC6956ValidAnchorsInterfaceId)).to.equal(true);
      expect(await abnftContract.supportsInterface(IERC6956AttestationLimitedInterfaceId)).to.equal(true);
    });
  });


describe("Valid Anchors (merkle-trees)", function () {
  it("SHOULDN't allow attesting arbitrary anchors", async function() {
    const { abnftContract, merkleTree, maintainer, oracle, alice, hacker } = await loadFixture(deployAbNftFixture);      

    // Publish root node of a made up tree, s.t. all proofs we use are from a different tree
    const madeUpRootNode = '0xaaaaaaaab0c754f1c68c699990a456c6073aaa28109c1bd83880c49dcece3f65'; // random string
    abnftContract.connect(maintainer).updateValidAnchors(madeUpRootNode)
    const anchor = merkleTestAnchors[0][0];

    // Let the oracle create an valid attestation (from the oracle's view)
    const [attestationAlice, dataAlice] = await createAttestationWithData(alice.address, anchor, oracle, merkleTree); // Mint to alice  
    await expect(abnftContract.connect(hacker)["transferAnchor(bytes,bytes)"](attestationAlice, dataAlice))
    .to.revertedWith("ERC6956-E26")
  });
});

describe("Anchor-Floating", function () {
  it("SHOULD only allow maintainer to specify canStartFloating and canStopFloating", async function () {
    const { abnftContract, merkleTree, owner, maintainer, mallory } = await loadFixture(deployAbNftAndMintTokenToAliceFixture);

    await expect(abnftContract.connect(mallory).updateFloatingAuthorization(ERC6956Authorization.ALL, ERC6956Authorization.ALL))
    .to.revertedWith("ERC6956-E1");

    await expect(abnftContract.connect(maintainer).updateFloatingAuthorization(ERC6956Authorization.OWNER_AND_ASSET, ERC6956Authorization.ISSUER))
    .to.emit(abnftContract, "FloatingAuthorizationChange")
    .withArgs(ERC6956Authorization.OWNER_AND_ASSET, ERC6956Authorization.ISSUER, maintainer.address);
  });

  it("SHOULD only allow maintainer to modify floatAll behavior w/o affecting previous tokens", async function () {
    const { abnftContract, merkleTree, anchor, owner, maintainer, alice, bob, oracle, mallory, gasProvider } = await loadFixture(deployAbNftAndMintTokenToAliceFixture);

    // --------------------------------------------------------------------------------- ALL FLOATING = FALSE
    await expect(abnftContract.connect(maintainer).updateFloatingAuthorization(ERC6956Authorization.OWNER_AND_ASSET, ERC6956Authorization.ISSUER))
    .to.emit(abnftContract, "FloatingAuthorizationChange")
    .withArgs(ERC6956Authorization.OWNER_AND_ASSET, ERC6956Authorization.ISSUER, maintainer.address);

    // anchor does not float by default
    // FLOATING ALL, so both have to float
    expect(await abnftContract.floating(anchor))
    .to.be.equal(false); // one was used to mint

    // Now alice, as the owner decides to make it explicitely floatable
    expect(await abnftContract.connect(alice).float(anchor, FloatState.Floating))
    .to.emit(abnftContract, "FloatingStateChange")
    .withArgs(anchor, 1, FloatState.Floating, alice.address)

    // It is now explicitely floatable
    expect(await abnftContract.floating(anchor))
    .to.be.equal(true); // one was used to mint

  
    // Mallory mustnot be able to change default behavior
    await expect(abnftContract.connect(mallory).floatAll(true))
    .to.revertedWith("ERC6956-E1");

    // --------------------------------------------------------------------------------- ALL FLOATING = TRUE
    // Maintainer must be able to update
    await expect(abnftContract.connect(maintainer).floatAll(true))
    .to.emit(abnftContract, "FloatingAllStateChange")
    .withArgs(true, maintainer.address);

    const implicitFloatingAnchor = merkleTestAnchors[1][0];
    const [mintToBobAttestation, mintToBobData] = await createAttestationWithData(bob.address, implicitFloatingAnchor, oracle, merkleTree); // Mint to alice
    const expectedTokenId = 2;

    // Mint a new token...
    await expect(abnftContract.connect(gasProvider)["transferAnchor(bytes,bytes)"](mintToBobAttestation, mintToBobData))
    .to.emit(abnftContract, "Transfer")
    .withArgs(NULLADDR, bob.address, expectedTokenId)

    // FLOATING ALL, so both have to float
    expect(await abnftContract.floating(anchor))
    .to.be.equal(true); // one was used to mint

    expect(await abnftContract.floating(implicitFloatingAnchor))
    .to.be.equal(true); // one was used to mint

    // --------------------------------------------------------------------------------- ALL FLOATING = FALSE
    // REVERT THE FLOATING .... Maintainer must be able to update
    await expect(abnftContract.connect(maintainer).floatAll(false))
    .to.emit(abnftContract, "FloatingAllStateChange")
    .withArgs(false, maintainer.address);


    // we expect the original anchor for alice to not be floating, and the new anchor from float to be floating
    expect(await abnftContract.floating(anchor))
    .to.be.equal(true); 

    expect(await abnftContract.floating(implicitFloatingAnchor))
    .to.be.equal(false); // this was only floating because of floatAll at the time of mint...
  });

  it("SHOULD allow owner to float token only when OWNER is allowed", async function () {
    const { abnftContract, anchor, maintainer, alice, mallory } = await loadFixture(deployAbNftAndMintTokenToAliceFixture);
    const tokenId = await abnftContract.tokenByAnchor(anchor);

    await expect(abnftContract.connect(maintainer).updateFloatingAuthorization(ERC6956Authorization.ASSET_AND_ISSUER, ERC6956Authorization.ASSET_AND_ISSUER))
    .to.emit(abnftContract, "FloatingAuthorizationChange")
    .withArgs(ERC6956Authorization.ASSET_AND_ISSUER, ERC6956Authorization.ASSET_AND_ISSUER, maintainer.address);

    await expect(abnftContract.connect(alice).float(anchor, FloatState.Floating))
    .to.revertedWith("ERC6956-E21")

    await expect(abnftContract.connect(maintainer).updateFloatingAuthorization(ERC6956Authorization.OWNER_AND_ASSET, ERC6956Authorization.OWNER_AND_ASSET))
    .to.emit(abnftContract, "FloatingAuthorizationChange")
    .withArgs(ERC6956Authorization.OWNER_AND_ASSET, ERC6956Authorization.OWNER_AND_ASSET, maintainer.address);

    await expect(abnftContract.connect(alice).float(anchor, FloatState.Floating))
    .to.emit(abnftContract, "FloatingStateChange")
    .withArgs(anchor, tokenId, FloatState.Floating, alice.address);
  });

  it("SHOULD only allow owner to transfer token when floating", async function () {
    const { abnftContract, anchor, maintainer, alice, bob, mallory } = await loadFixture(deployAbNftAndMintTokenToAliceFixture);
    const tokenId = await abnftContract.tokenByAnchor(anchor);

    await expect(abnftContract.connect(maintainer).updateFloatingAuthorization(ERC6956Authorization.OWNER_AND_ASSET, ERC6956Authorization.OWNER_AND_ASSET))
    .to.emit(abnftContract, "FloatingAuthorizationChange")
    .withArgs(ERC6956Authorization.OWNER_AND_ASSET, ERC6956Authorization.OWNER_AND_ASSET, maintainer.address);

    await expect(abnftContract.connect(alice).float(anchor, FloatState.Floating))
    .to.emit(abnftContract, "FloatingStateChange")
    .withArgs(anchor, tokenId, FloatState.Floating, alice.address);

    await expect(abnftContract.connect(mallory).transferFrom(alice.address, mallory.address, tokenId))
    .to.revertedWith("ERC721: caller is not token owner or approved");

    await expect(abnftContract.connect(alice).transferFrom(alice.address, bob.address, tokenId))
    .to.emit(abnftContract, "Transfer")
    .withArgs(alice.address,bob.address, tokenId);
  });

  it("SHOULDN'T allow owner to transfer token when explicitely marked anchored", async function () {
    const { abnftContract, anchor, maintainer, alice, bob, mallory } = await loadFixture(deployAbNftAndMintTokenToAliceFixture);
    const tokenId = await abnftContract.tokenByAnchor(anchor);

    await expect(abnftContract.connect(maintainer).updateFloatingAuthorization(ERC6956Authorization.ISSUER, ERC6956Authorization.ISSUER))
    .to.emit(abnftContract, "FloatingAuthorizationChange")
    .withArgs(ERC6956Authorization.ISSUER, ERC6956Authorization.ISSUER, maintainer.address);

     // Maintainer must be able to update
     await expect(abnftContract.connect(maintainer).floatAll(true))
     .to.emit(abnftContract, "FloatingAllStateChange")
     .withArgs(true, maintainer.address);

     expect(await abnftContract.floating(anchor))
     .to.be.equal(true); // one was used to mint

     await expect(abnftContract.connect(maintainer).float(anchor, FloatState.Anchored))
     .to.emit(abnftContract, "FloatingStateChange")
     .withArgs(anchor, tokenId, FloatState.Anchored, maintainer.address);

     expect(await abnftContract.floating(anchor))
     .to.be.equal(false); // one was used to mint

    await expect(abnftContract.connect(alice).transferFrom(alice.address, bob.address, tokenId))
    .to.revertedWith("ERC6956-E5")
  });


  it("SHOULD allow maintainer to float ANY token only when ISSUER is allowed", async function () {
    const { abnftContract, anchor, maintainer, mallory } = await loadFixture(deployAbNftAndMintTokenToAliceFixture);
    const tokenId = await abnftContract.tokenByAnchor(anchor);

    await expect(abnftContract.connect(maintainer).updateFloatingAuthorization(ERC6956Authorization.OWNER_AND_ASSET, ERC6956Authorization.OWNER_AND_ASSET))
    .to.emit(abnftContract, "FloatingAuthorizationChange")
    .withArgs(ERC6956Authorization.OWNER_AND_ASSET, ERC6956Authorization.OWNER_AND_ASSET, maintainer.address);

    await expect(abnftContract.connect(maintainer).float(anchor, FloatState.Floating))
    .to.revertedWith("ERC6956-E21")

    await expect(abnftContract.connect(maintainer).updateFloatingAuthorization(ERC6956Authorization.ISSUER, ERC6956Authorization.ISSUER))
    .to.emit(abnftContract, "FloatingAuthorizationChange")
    .withArgs(ERC6956Authorization.ISSUER, ERC6956Authorization.ISSUER, maintainer.address);

    await expect(abnftContract.connect(maintainer).float(anchor, FloatState.Floating))
    .to.emit(abnftContract, "FloatingStateChange")
    .withArgs(anchor, tokenId, FloatState.Floating, maintainer.address);
  });

  it("SHOULD allow maintainer to float HIS OWN token when OWNER is allowed", async function () {
    const { abnftContract, anchor, alice, maintainer, oracle, merkleTree, gasProvider } = await loadFixture(deployAbNftAndMintTokenToAliceFixture);
    const tokenId = await abnftContract.tokenByAnchor(anchor);

    // Anchor should not be floating by default...
    expect(await abnftContract.floating(anchor))
    .to.be.equal(false); // one was used to mint

    await expect(abnftContract.connect(maintainer).updateFloatingAuthorization(ERC6956Authorization.OWNER, ERC6956Authorization.OWNER))
    .to.emit(abnftContract, "FloatingAuthorizationChange")
    .withArgs(ERC6956Authorization.OWNER, ERC6956Authorization.OWNER, maintainer.address);

    await expect(abnftContract.connect(maintainer).float(anchor, FloatState.Floating))
    .to.revertedWith("ERC6956-E21")
    
    const [attestationMaintainer, dataMaintainer] = await createAttestationWithData(maintainer.address, anchor, oracle, merkleTree); 
    await expect(abnftContract.connect(gasProvider)["transferAnchor(bytes,bytes)"](attestationMaintainer, dataMaintainer))
    .to.emit(abnftContract, "Transfer")
    .withArgs(alice.address, maintainer.address, tokenId)
           
    // Now maintainer owns the token, hence he is owner and can indeed change floating
    await expect(abnftContract.connect(maintainer).float(anchor, FloatState.Floating))
    .to.emit(abnftContract, "FloatingStateChange")
    .withArgs(anchor, tokenId, FloatState.Floating, maintainer.address);

    expect(await abnftContract.floating(anchor))
    .to.be.equal(true); // one was used to mint
  });

  it("SHOULD allow approveAnchor followed by safeTransfer when anchor IS floating", async function() {
    const { abnftContract, anchor, maintainer, oracle, merkleTree, alice, bob, gasProvider, mallory,carl} = await loadFixture(deployAbNftAndMintTokenToAliceFixture);      
    const tokenId = await abnftContract.tokenByAnchor(anchor);
    const [attestationBob, dataBob] = await createAttestationWithData(bob.address, anchor, oracle, merkleTree); // Transfer to bob

    await expect(abnftContract.connect(maintainer).updateFloatingAuthorization(ERC6956Authorization.OWNER, ERC6956Authorization.OWNER))
    .to.emit(abnftContract, "FloatingAuthorizationChange")
    .withArgs(ERC6956Authorization.OWNER, ERC6956Authorization.OWNER, maintainer.address);

    // somebody approves himself via attestation approves bob to act on her behalf
    await expect(abnftContract.connect(gasProvider)["approveAnchor(bytes,bytes)"](attestationBob,dataBob))
    .to.emit(abnftContract, "Approval") // Standard ERC721 event
    .withArgs(await abnftContract.ownerOf(tokenId), bob.address, tokenId);
    
    // Should not allow mallory to transfer, since only bob is approved
    await expect(abnftContract.connect(mallory).transferFrom(alice.address, bob.address, 1)) 
    .to.revertedWith("ERC721: caller is not token owner or approved");

    // Bob makes it floatable (which is possible, because he is approved)
    await expect(abnftContract.connect(bob).float(anchor, FloatState.Floating))
    .to.emit(abnftContract, "FloatingStateChange")
    .withArgs(anchor, tokenId, FloatState.Floating, bob.address);
    
    // Bob transfers it...
    await expect(abnftContract.connect(bob).transferFrom(alice.address, carl.address, tokenId))
    .to.emit(abnftContract, "Transfer")
    .withArgs(alice.address,carl.address, tokenId);        
  })
});

describe("Attested Transfer Limits", function () {
  it("SHOULD count attested transfers (transfer, burn, approve)", async function () {
    const { abnftContract, anchor, maintainer, oracle, merkleTree, alice, bob, gasProvider, mallory,carl} = await loadFixture(deployAbNftAndMintTokenToAliceFixture);      
    const tokenId = await abnftContract.tokenByAnchor(anchor);
    const [attestationBob, dataBob] = await createAttestationWithData(bob.address, anchor, oracle, merkleTree); // Mint to alice
    const [attestationCarl, dataCarl] = await createAttestationWithData(carl.address, anchor, oracle, merkleTree); // Mint to alice

    
    // Transfers shall be counted - also the one from the fixture
    expect(await abnftContract.attestationsUsedByAnchor(anchor))
    .to.be.equal(1);

    // Should increase count by 1
    await expect(abnftContract["approveAnchor(bytes,bytes)"](attestationBob, dataBob))
    .to.emit(abnftContract, "Approval") // Standard ERC721 event
    .withArgs(await abnftContract.ownerOf(tokenId), bob.address, tokenId);

    // Should increase count by 1
    await expect(abnftContract["burnAnchor(bytes,bytes)"](attestationCarl, dataCarl))
    .to.emit(abnftContract, "Transfer")
    .withArgs(alice.address, NULLADDR, tokenId);

    // InitialMint + Approve + Burns shall also be counted - also the one from the fixture
    expect(await abnftContract.attestationsUsedByAnchor(anchor))
    .to.be.equal(3);

    // Should return 0 for invalid anchors
    expect(await abnftContract.attestationsUsedByAnchor(invalidAnchor))
    .to.be.equal(0);
  });

  it("SHOULD allow maintainer to update global attestation limit", async function () {
    const { abnftContract, maintainer, oracle, merkleTree, alice, bob, gasProvider, mallory,carl} = await deployForAttestationLimit(10, AttestedTransferLimitUpdatePolicy.FLEXIBLE);

    await expect(abnftContract.connect(mallory).updateGlobalAttestationLimit(5))
    .to.revertedWith("ERC6956-E1");

    // Should be able to update
    await expect(abnftContract.connect(maintainer).updateGlobalAttestationLimit(5))
    .to.emit(abnftContract, "GlobalAttestationLimitUpdate") // Standard ERC721 event
    .withArgs(5, maintainer.address);

    // Check effect, but requesting transfers left from a non-existent anchor
    expect(await abnftContract.attestationUsagesLeft(invalidAnchor))
    .to.be.equal(5);
  });

  it("Should allow maintainer to update anchor-based attestation limit w/o changing global limits", async function () {
    const globalLimit = 10;
    const specificAnchorLimit = 5;
    const { abnftContract, maintainer, oracle, merkleTree, alice, bob, gasProvider, mallory,carl} = await deployForAttestationLimit(globalLimit, AttestedTransferLimitUpdatePolicy.FLEXIBLE);

    const anchor = merkleTestAnchors[0][0];
    const [mintAttestationAlice, mintDataAlice] = await createAttestationWithData(alice.address, anchor, oracle, merkleTree); // Mint to alice
    const tokenId = 1;

    await expect(abnftContract.connect(gasProvider)["transferAnchor(bytes,bytes)"](mintAttestationAlice, mintDataAlice))
    .to.emit(abnftContract, "Transfer") // Standard ERC721 event
    .withArgs(NULLADDR, alice.address, tokenId);


    // Note that an anchor does not need to exist yet for playing with the limits
    // Check effect, but requesting transfers left from a non-existent anchor
    expect(await abnftContract.attestationUsagesLeft(invalidAnchor))
    .to.be.equal(globalLimit);
    
    // Should be able to update
    await expect(abnftContract.connect(maintainer).updateAttestationLimit(anchor, specificAnchorLimit))
    .to.emit(abnftContract, "AttestationLimitUpdate") // Standard ERC721 event
    .withArgs(anchor, tokenId, specificAnchorLimit, maintainer.address);

    // Check unchanged global effect, but requesting transfers left from a non-existent anchor
    expect(await abnftContract.attestationUsagesLeft(invalidAnchor))
    .to.be.equal(globalLimit);
    
    // Check verify effect
    expect(await abnftContract.attestationUsagesLeft(anchor))
    .to.be.equal(specificAnchorLimit-1); // 1 has been used to mint
  });

  it("Should enforce anchor limits (global + local)", async function () {
    const globalLimit = 2;
    const specificAnchorLimit = 1;
    const { abnftContract, maintainer, oracle, merkleTree, alice, bob, gasProvider, mallory,carl, hacker} = await deployForAttestationLimit(globalLimit, AttestedTransferLimitUpdatePolicy.FLEXIBLE);
    const anchor = merkleTestAnchors[0][0]; // can be transferred twice
    const limitedAnchor = merkleTestAnchors[1][0]; // can be transferred once

    const [anchorToAlice, anchorToAliceData] = await createAttestationWithData(alice.address, anchor, oracle, merkleTree); // Mint to alice
    const [anchorToBob, anchorToBobData] = await createAttestationWithData(bob.address, anchor, oracle, merkleTree); // Transfer to bob
    const [anchorToHacker, anchorToHackerData] = await createAttestationWithData(hacker.address, anchor, oracle, merkleTree); // Limit reached!

    const [limitedAnchorToCarl, limitedAnchorToCarlData] = await createAttestationWithData(carl.address, limitedAnchor, oracle, merkleTree); // Mint to carl
    const [limitedAnchorToMallory, limitedAnchorToMalloryData] = await createAttestationWithData(mallory.address, limitedAnchor, oracle, merkleTree); // Limit reached!
        
    expect(await abnftContract.attestationUsagesLeft(anchor))
    .to.be.equal(globalLimit);

    // ####################################### FIRST ANCHOR
    await expect(abnftContract.connect(gasProvider)["transferAnchor(bytes,bytes)"](anchorToAlice, anchorToAliceData))
    .to.emit(abnftContract, "Transfer");

    await expect(abnftContract.connect(gasProvider)["transferAnchor(bytes,bytes)"](anchorToBob, anchorToBobData))
    .to.emit(abnftContract, "Transfer");

    await expect(abnftContract.connect(gasProvider)["transferAnchor(bytes,bytes)"](anchorToHacker, anchorToHackerData))
    .to.revertedWith("ERC6956-E24");

    // ###################################### SECOND ANCHOR
    await expect(abnftContract.connect(gasProvider)["transferAnchor(bytes,bytes)"](limitedAnchorToCarl, limitedAnchorToCarlData))
    .to.emit(abnftContract, "Transfer");

    // Update anchor based limit
    await expect(abnftContract.connect(maintainer).updateAttestationLimit(limitedAnchor, specificAnchorLimit))
    .to.emit(abnftContract, "AttestationLimitUpdate") 
    .withArgs(limitedAnchor, 2, specificAnchorLimit, maintainer.address);
    
    expect(await abnftContract.attestationUsagesLeft(limitedAnchor))
    .to.be.equal(specificAnchorLimit-1); // one was used to mint

    await expect(abnftContract.connect(gasProvider)["transferAnchor(bytes,bytes)"](limitedAnchorToMallory, limitedAnchorToMalloryData))
    .to.revertedWith("ERC6956-E24");
  });
});
  
});
