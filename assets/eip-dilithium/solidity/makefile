CORES := $(shell nproc)

# INSTALL

install:
	foundryup


# TESTS

test:
	FOUNDRY_PROFILE=lite forge test -j$(CORES) -vv

test_slow:
	forge test -j$(CORES) -vv
