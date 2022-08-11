// "ethers": "5.6.9"
import { utils } from "ethers";

// See: https://docs.ethers.io/v5/api/signer/#Signer-signTypedData for more
// detailed instructions.
export async function generateCompactSignature(
  signer,
  types,
  domain,
  agreement
) {
  const signature = await signer._signTypedData(domain, types, agreement);
  const { compact } = utils.splitSignature(signature);
  return compact;
}
