import {
  createTestClient,
  http,
  createWalletClient,
  createPublicClient,
  hashDomain,
  Hex,
  keccak256,
  concat,
  recoverAddress,
  TypedDataDomain,
} from "viem";
import { foundry } from "viem/chains";
import { describe, it, beforeEach, expect } from "vitest";
import { getTypesForEIP712Domain } from "viem";
import {
  delegatedErc721ABI
} from "./abi";
import { bytecode as delegatedErc721ByteCode }  from "../out/DelegatedErc721.sol/DelegatedErc721.json";


const walletClient = createWalletClient({
  chain: foundry,
  transport: http(),
});

export const walletClientWithAccount = createWalletClient({
  chain: foundry,
  transport: http(),
});

const testClient = createTestClient({
  chain: foundry,
  mode: "anvil",
  transport: http(),
});

const publicClient = createPublicClient({
  chain: foundry,
  transport: http(),
});

type Address = `0x${string}`;


const deployContractAndGetAddress = async (
  args: Parameters<typeof walletClient.deployContract>[0]
) => {
  const hash = await walletClient.deployContract(args);
  return (
    await publicClient.waitForTransactionReceipt({
      hash,
    })
  ).contractAddress!;
};

type TestContext = {
  creator: Address,
  contractAddress: Address,
}


// JSON-RPC Account
const [
  creatorAccount, minter, randomAccount
] = (await walletClient.getAddresses()) as [Address, Address, Address, Address];

describe("DelegatedErc721", () => {
  beforeEach<TestContext>(async (ctx) => {
    const creator = creatorAccount;

    const contractAddress = await deployContractAndGetAddress({
      abi: delegatedErc721ABI,
      bytecode: delegatedErc721ByteCode.object as `0x${string}`,
      args: [creator],
      account: creatorAccount,
    })
  
    ctx.contractAddress = contractAddress;
    ctx.creator = creator;
  }, 20 * 1000);

  // skip for now - we need to make this work on zora testnet chain too
  it<TestContext>(
    "can sign and mint a token and recover the signer from the CreatorAttribution event",
    async ({ creator, contractAddress }) => {
      
      // 1. Have the creator sign a message to create a token
      // sign a message for the CreatorAttribution, which has a TYPEHASH of CreatorAttribution(string uri,uint256 nonce)
      
      const tokenUri = 'ipfs://QmYXJ5Y2FzdC5qcGc';
      const nonce = 1n;

      // eipDomain params
      const chainId = await walletClient.getChainId();
      
      // have creator sign a message permitting a token to be created on the contract
      const signature = await walletClient.signTypedData({
        types: {
          CreatorAttribution: [
            { name: "uri", type: "string" },
            { name: "nonce", type: "uint256" },
          ],
        },
        primaryType: "CreatorAttribution",
        message: {
          uri: tokenUri,
          nonce,
        },
        // signer of the message; the contract requires
        // this to match the owner of the contract
        account: creator,
        domain: {
          chainId: await walletClient.getChainId(),
          verifyingContract: contractAddress,
          // these two need to match the domain name and version in the erc712 contract
          name: "ERC7015",
          version: "1"
        }
      });

      // 2. Have a collector submit the signature and mint the token

      const tx = await walletClient.writeContract({
        abi: delegatedErc721ABI,
        address: contractAddress,
        account: minter,
        functionName: 'delegatedSafeMint',
        args: [
          minter, tokenUri, nonce, signature
        ]
      });

      const receipt = await publicClient.waitForTransactionReceipt({
        hash: tx
      });

      // check that the transaction succeeded
      expect(receipt.status).toBe('success');

      // 3. Get the CreatorAttribution event from the contract and recover the signer/creator from the emitted signature and params:

      // get the CreatorAttribution event from the erc1155 contract:
      const topics = await publicClient.getContractEvents({
        abi: delegatedErc721ABI,
        address: contractAddress,
        eventName: "CreatorAttribution"
      });

      expect(topics.length).toBe(1);

      const creatorAttributionEventArgs = topics[0]!.args;

      const domain: TypedDataDomain = {
        chainId,
        name: creatorAttributionEventArgs.domainName!,
        verifyingContract: contractAddress,
        version: creatorAttributionEventArgs.version!
      }

      // hash the eip712 domain based on the parameters emitted from the event:
      const hashedDomain = hashDomain({
        domain,
        types: {
          EIP712Domain: getTypesForEIP712Domain({ domain })
        }
      });

      // re-build the eip-712 typed data hash, consisting of the hashed domain and the structHash emitted from the event:
      const parts: Hex[] = ["0x1901", hashedDomain, creatorAttributionEventArgs.structHash!];

      const hashedTypedData = keccak256(concat(parts));

      // recover the signer from the hashed typed data and the signature:
      const recoveredSigner = await recoverAddress({
        hash: hashedTypedData,
        signature: signature!,
      });

      expect(recoveredSigner).toBe(creator);

    },
    20 * 1000
  );

});
