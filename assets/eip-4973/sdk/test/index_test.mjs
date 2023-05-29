// @format
import test from "ava";

import { Wallet, utils } from "ethers";

import { generateSignature } from "../src/index.mjs";

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
      { name: "metadata", type: "bytes" },
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
    metadata: utils.toUtf8Bytes("https://example.com/metadata.json"),
  };

  const signature = await generateSignature(signer, types, domain, agreement);
  t.truthy(signature);
  t.is(signature.length, 64 + 64 + 2 + 2);
  t.is(
    signature,
    "0x4473afdec84287f10aa0b5eb608d360e2e9220bee657a4a5ca468e69a4de255c38691fca0c52f295d1831beaa0b7f079c1ab7959257578d2fb8d98740d9b0e111c"
  );
});
