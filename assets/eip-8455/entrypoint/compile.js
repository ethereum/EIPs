const solc = require('solc'); const fs = require('fs'); const path = require('path');
const AA = 'account-abstraction-0.7.0/contracts'  // tag v0.7.0 of eth-infinitism/account-abstraction;
function findImport(p) {
  let f;
  if (p.startsWith('@openzeppelin/')) f = path.join('node_modules', p);
  else if (p.startsWith('@aa/')) f = path.join(AA, p.slice(4));
  else f = p;
  try { return { contents: fs.readFileSync(f, 'utf8') }; } catch (e) { return { error: 'not found ' + p }; }
}
const sources = {
  'core/EntryPoint.sol': { content: fs.readFileSync(AA + '/core/EntryPoint.sol', 'utf8') },
  'core/SenderCreator.sol': { content: fs.readFileSync(AA + '/core/SenderCreator.sol', 'utf8') },
  'extra/MinimalAccount.sol': { content: fs.readFileSync('extra/MinimalAccount.sol', 'utf8') },
};
const input = { language: 'Solidity', sources,
  settings: { optimizer: { enabled: true, runs: 1000000 }, viaIR: true,
    outputSelection: { '*': { '*': ['abi', 'evm.bytecode.object', 'evm.deployedBytecode.object', 'evm.deployedBytecode.immutableReferences', 'storageLayout'] } } } };
// resolve relative imports inside core/*.sol against AA dir
const out = JSON.parse(solc.compile(JSON.stringify(input), { import: (p) => {
  if (p.startsWith('core/') || p.startsWith('interfaces/') || p.startsWith('utils/')) return findImport(path.join(AA, p));
  return findImport(p); } }));
const errs = (out.errors || []).filter(e => e.severity === 'error');
if (errs.length) { console.error(errs.map(e => e.formattedMessage).join('\n')); process.exit(1); }
const res = {};
for (const [file, cs] of Object.entries(out.contracts)) for (const [name, c] of Object.entries(cs))
  res[name] = { abi: c.abi, bytecode: c.evm.bytecode.object, deployed: c.evm.deployedBytecode.object,
    immutables: c.evm.deployedBytecode.immutableReferences, storage: (c.storageLayout || {}).storage };
fs.writeFileSync('compiled.json', JSON.stringify(res));
for (const n of ['EntryPoint', 'SenderCreator', 'MinimalAccount', 'Shared']) console.log(n, res[n].deployed.length / 2, 'bytes; immutables', JSON.stringify(res[n].immutables));
console.log('EntryPoint storage:', res.EntryPoint.storage.map(s => s.label + '@' + s.slot).join(', '));
