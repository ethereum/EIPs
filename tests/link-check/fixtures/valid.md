# Fixtures for the link-checker configuration test

`tests/link-check/run.sh` runs lychee over these files using the real
`config/lychee.toml` and asserts the outcome. They are deliberately excluded
from the site build and from the link-check CI job, which only ever inspects
files changed by a pull request.

## Must PASS

These links are expected to resolve.

- [Ethereum EIPs repository](https://github.com/ethereum/EIPs)
- [EIP-1](https://eips.ethereum.org/EIPS/eip-1)

## Must PASS via exclusion

These hosts return 403 to datacenter IPs even though the links are valid, so
`config/lychee.toml` excludes them. If an exclusion is dropped, the test fails.

- [Medium article](https://medium.com/@VitalikButerin/parametrizing-casper-the-decentralization-finality-time-overhead-tradeoff-3f2011672735)
- [Khronos registry](https://registry.khronos.org/SPIR-V/)
- [npm package](https://www.npmjs.com/package/ethereumjs-util)
- [Unreliable host](https://pdaian.com/blog/anti-asic-forks-considered-harmful/)
- [csl-json reference](https://example.com/csl-json)
