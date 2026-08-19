# Fixture containing genuinely broken links

`tests/link-check/run.sh` asserts that lychee reports every link below as an
error. This guards against the exclusion list in `config/lychee.toml` growing
so broad that real breakage stops being detected.

- [Archived wiki page, returns 404](https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_getbalance)
- [Nonexistent path on a live host](https://github.com/ethereum/EIPs/this-path-does-not-exist-9f8e7d6c)
- [Nonexistent host](https://nonexistent-host-8a7b6c5d4e3f.ethereum.org/)
