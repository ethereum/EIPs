import { ethers } from "hardhat";
import { createHash } from 'node:crypto';
import { StandardMerkleTree } from "@openzeppelin/merkle-tree";
import { float } from "hardhat/internal/core/params/argumentTypes";


export enum ERC6956Authorization {
    NONE,// = 0, // None of the above - a 1:1 relationship is maintained
    OWNER,// = (1 << 1), // The owner of the token, i.e. the digital representation
    ISSUER,// = (1 << 2), // The issuer of the tokens, i.e. this smart contract
    ASSET,// = (1<< 3), // The asset, i.e. via attestation
    OWNER_AND_ISSUER,// = (1<<1) | (1<<2),
    OWNER_AND_ASSET,// = (1<<1) | (1<<3),
    ASSET_AND_ISSUER,// = (1<<3) | (1<<2),
    ALL// = (1<<1) | (1<<2) | (1<<3) // Owner + Issuer + Asset
    }
    
export enum ERC6956Role {
    OWNER,
    ISSUER,
    ASSET
    }

export enum AttestedTransferLimitUpdatePolicy {
        IMMUTABLE,
        INCREASE_ONLY,
        DECREASE_ONLY,
        FLEXIBLE
    }
    
export const invalidAnchor = '0x' + createHash('sha256').update('TestAnchor1239').digest('hex');
export const NULLADDR = ethers.utils.getAddress('0x0000000000000000000000000000000000000000');
    
    // Needs to be an odd number of anchors to test the edge case of the merkle-
    // tree: Nodes with only one leaf.
    // Also: When building the tree (see buildMerkleTree fixture) those hashes are
    // hashed again. This is intended because of the way Merkle-Proof and our
    // smart contract works:
    // Proof = H(leave) + H(L1) + H(L0)
    // Our contract uses hashed anchor numbers as identifiers.
    // Hence if we use direct anchor number checksums, H(leave) would 
    // be an actually valid anchor number on the smart contract.
    export const merkleTestAnchors = [
    ['0x' + createHash('sha256').update('TestAnchor123').digest('hex')],
    ['0x' + createHash('sha256').update('TestAnchor124').digest('hex')],
    ['0x' + createHash('sha256').update('TestAnchor125').digest('hex')],
    ['0x' + createHash('sha256').update('TestAnchor126').digest('hex')],
    ['0x' + createHash('sha256').update('TestAnchor127').digest('hex')]
    ]


export async function createAttestation(to, anchor, signer, validStartTime= 0) {
    const attestationTime = Math.floor(Date.now() / 1000.0); // Now in seconds
    const expiryTime = attestationTime + 5 * 60; // 5min valid

    const messageHash = ethers.utils.solidityKeccak256(["address", "bytes32", "uint256", 'uint256', "uint256"], [to, anchor, attestationTime, validStartTime, expiryTime]);
    const sig = await signer.signMessage(ethers.utils.arrayify(messageHash));

    return ethers.utils.defaultAbiCoder.encode(['address', 'bytes32', 'uint256', 'uint256', 'uint256', 'bytes'], [to, anchor, attestationTime,  validStartTime, expiryTime, sig]);
}


export async function createAttestationWithData(to, anchor, signer, merkleTree, validStartTime= 0) {

        const attestation = await createAttestation(to, anchor, signer, validStartTime); // Now in seconds
        
        const proof = merkleTree.getProof([anchor]);
        const data = ethers.utils.defaultAbiCoder.encode(['bytes32[]'], [proof])
              
        return  [attestation, data];
}


export const IERC6956InterfaceId = '0xa9cf7635';
export const IERC6956AttestationLimitedInterfaceId ='0x75a2e933'
export const IERC6956FloatableInterfaceId = '0xf82773f7';
export const IERC6956ValidAnchorsInterfaceId = '0x051c9bd8';
