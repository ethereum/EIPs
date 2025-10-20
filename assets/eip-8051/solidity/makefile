CORES := $(shell nproc)

# INSTALL

install:
	foundryup


# TESTS

test: test_fast

test_fast:
	FOUNDRY_PROFILE=lite forge test -j$(CORES) -vv

test_slow:
	forge test -j$(CORES) -vv
