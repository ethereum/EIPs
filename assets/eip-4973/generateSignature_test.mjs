// @format
// "ava": "4.3.1"
import test from "ava";

// "ethers": "5.6.9"
import { Wallet } from "ethers";

import { generateCompactSignature } from "../src/index.mjs";

test("generating a compact signature for function give", async (t) => {
  // from: https://docs.ethers.io/v5/api/signer/#Wallet--methods
  const passiveAddress = "0x0f6A79A579658E401E0B81c6dde1F2cd51d97176";
  const passivePrivateKey =
    "0xad54bdeade5537fb0a553190159783e45d02d316a992db05cbed606d3ca36b39";
  const signer = new Wallet(passivePrivateKey);
  t.is(signer.address, passiveAddress);

  const types = {
    Agreement: [
      { name: "active", type: "address" },
      { name: "passive", type: "address" },
      { name: "tokenURI", type: "string" },
    ],
  };
  const domain = {
    name: "Name",
    version: "Version",
    chainId: 31337, // the chainId of foundry
    verifyingContract: "0xce71065d4017f316ec606fe4422e11eb2c47c246",
  };

  const agreement = {
    active: "0xb4c79dab8f259c7aee6e5b2aa729821864227e84",
    passive: passiveAddress,
    tokenURI: "https://contenthash.com",
  };
  const compactSignature = await generateCompactSignature(
    signer,
    types,
    domain,
    agreement
  );
  t.truthy(compactSignature);
  // For length of compact signature, see https://eips.ethereum.org/EIPS/eip-2098#backwards-compatibility
  t.is(compactSignature.length, 64 * 2 + 2);
  t.is(
    compactSignature,
    "0x238e1616c507f9779469b0276eef73a3a438b65706ca18c6ab38062c588674f9719c9f5412b0379e7918f19da1de71b9370ed9917fadcb6690e71f5a1de24816"
  );
});
