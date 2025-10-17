PYTHON=python-ref/myenv/bin/python
CORES := $(shell grep -c ^processor /proc/cpuinfo)

# INSTALL

install:
	foundryup
	forge install OpenZeppelin/openzeppelin-contracts-upgradeable
	forge install OpenZeppelin/openzeppelin-contracts

# TESTS

test: test_fast 

test_fast:
	FOUNDRY_PROFILE=lite forge test -vv

test_slow:
	forge test -j$(CORES) -vv
	
# BENCH

bench:
	forge test -j$(CORES) test/ZKNOXBenchmarks.t.sol -vv | grep -A1 "Logs" | grep -v "Logs" | grep -v "\-\-"
