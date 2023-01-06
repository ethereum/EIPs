import { utils } from "ethers";

// See: https://docs.ethers.io/v5/api/signer/#Signer-signTypedData for more
// detailed instructions.
export async function generateSignature(signer, types, domain, agreement) {
  const signature = await signer._signTypedData(domain, types, agreement);
  const { r, s, v } = utils.splitSignature(signature);
  return utils.solidityPack(["bytes32", "bytes32", "uint8"], [r, s, v]);
}
