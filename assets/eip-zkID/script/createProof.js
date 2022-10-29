// CC0 license.
// taken from (credits): https://soliditydeveloper.com/merkle-tree 
const keccak256 = require("keccak256");
const { MerkleTree } = require("merkletreejs");
const Web3 = require("web3");

const web3 = new Web3();

let balances = [
  {
    addr: "0xb7e390864a90b7b923c9f9310c6f98aafe43f707",
    amount: web3.eth.abi.encodeParameter(
      "uint256",
      "10000000000000000000000000"
    ),
  },
  {
    addr: "0xea674fdde714fd979de3edf0f56aa9716b898ec8",
    amount: web3.eth.abi.encodeParameter(
      "uint256",
      "20000000000000000000000000"
    ),
  },
];

const leafNodes = balances.map((balance) =>
  keccak256(
    Buffer.concat([
      Buffer.from(balance.addr.replace("0x", ""), "hex"),
      Buffer.from(balance.amount.replace("0x", ""), "hex"),
    ])
  )
);

const merkleTree = new MerkleTree(leafNodes, keccak256, { sortPairs: true });

console.log("---------");
console.log("Merke Tree");
console.log("---------");
console.log(merkleTree.toString());
console.log("---------");
console.log("Merkle Root: " + merkleTree.getHexRoot());

console.log("Proof 1: " + merkleTree.getHexProof(leafNodes[0]));
console.log("Proof 2: " + merkleTree.getHexProof(leafNodes[1]));
