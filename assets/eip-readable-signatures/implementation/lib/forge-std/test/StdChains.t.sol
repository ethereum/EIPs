// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "../src/Test.sol";

contract StdChainsTest is Test {
    function testChainRpcInitialization() public {
        // RPCs specified in `foundry.toml` should be updated.
        assertEq(getChain(1).rpcUrl, "https://mainnet.infura.io/v3/7a8769b798b642f6933f2ed52042bd70");
        assertEq(getChain("optimism_goerli").rpcUrl, "https://goerli.optimism.io/");
        assertEq(getChain("arbitrum_one_goerli").rpcUrl, "https://goerli-rollup.arbitrum.io/rpc/");

        // Other RPCs should remain unchanged.
        assertEq(getChain(31337).rpcUrl, "http://127.0.0.1:8545");
        assertEq(getChain("sepolia").rpcUrl, "https://sepolia.infura.io/v3/6770454bc6ea42c58aac12978531b93f");
    }

    function testRpc(string memory rpcAlias) internal {
        string memory rpcUrl = getChain(rpcAlias).rpcUrl;
        vm.createSelectFork(rpcUrl);
    }

    // Ensure we can connect to the default RPC URL for each chain.
    function testRpcs() public {
        testRpc("mainnet");
        testRpc("goerli");
        testRpc("sepolia");
        testRpc("optimism");
        testRpc("optimism_goerli");
        testRpc("arbitrum_one");
        testRpc("arbitrum_one_goerli");
        testRpc("arbitrum_nova");
        testRpc("polygon");
        testRpc("polygon_mumbai");
        testRpc("avalanche");
        testRpc("avalanche_fuji");
        testRpc("bnb_smart_chain");
        testRpc("bnb_smart_chain_testnet");
        testRpc("gnosis_chain");
    }

    function testChainNoDefault() public {
        vm.expectRevert("StdChains getChain(string): Chain with alias \"does_not_exist\" not found.");
        getChain("does_not_exist");
    }

    function testSetChainFirstFails() public {
        vm.expectRevert("StdChains setChain(string,Chain): Chain ID 31337 already used by \"anvil\".");
        setChain("anvil2", Chain("Anvil", 31337, "URL"));
    }

    function testChainBubbleUp() public {
        setChain("needs_undefined_env_var", Chain("", 123456789, ""));
        vm.expectRevert(
            "Failed to resolve env var `UNDEFINED_RPC_URL_PLACEHOLDER` in `${UNDEFINED_RPC_URL_PLACEHOLDER}`: environment variable not found"
        );
        getChain("needs_undefined_env_var");
    }

    function testCannotSetChain_ChainIdExists() public {
        setChain("custom_chain", Chain("Custom Chain", 123456789, "https://custom.chain/"));

        vm.expectRevert('StdChains setChain(string,Chain): Chain ID 123456789 already used by "custom_chain".');

        setChain("another_custom_chain", Chain("", 123456789, ""));
    }

    function testSetChain() public {
        setChain("custom_chain", Chain("Custom Chain", 123456789, "https://custom.chain/"));
        Chain memory customChain = getChain("custom_chain");
        assertEq(customChain.name, "Custom Chain");
        assertEq(customChain.chainId, 123456789);
        assertEq(customChain.rpcUrl, "https://custom.chain/");
        Chain memory chainById = getChain(123456789);
        assertEq(chainById.name, customChain.name);
        assertEq(chainById.chainId, customChain.chainId);
        assertEq(chainById.rpcUrl, customChain.rpcUrl);
    }

    function testSetNoEmptyAlias() public {
        vm.expectRevert("StdChains setChain(string,Chain): Chain alias cannot be the empty string.");
        setChain("", Chain("", 123456789, ""));
    }

    function testSetNoChainId0() public {
        vm.expectRevert("StdChains setChain(string,Chain): Chain ID cannot be 0.");
        setChain("alias", Chain("", 0, ""));
    }

    function testGetNoChainId0() public {
        vm.expectRevert("StdChains getChain(uint256): Chain ID cannot be 0.");
        getChain(0);
    }

    function testGetNoEmptyAlias() public {
        vm.expectRevert("StdChains getChain(string): Chain alias cannot be the empty string.");
        getChain("");
    }

    function testChainIdNotFound() public {
        vm.expectRevert("StdChains getChain(string): Chain with alias \"no_such_alias\" not found.");
        getChain("no_such_alias");
    }

    function testChainAliasNotFound() public {
        vm.expectRevert("StdChains getChain(uint256): Chain with ID 321 not found.");
        getChain(321);
    }

    function testSetChain_ExistingOne() public {
        setChain("custom_chain", Chain("Custom Chain", 123456789, "https://custom.chain/"));
        assertEq(getChain(123456789).chainId, 123456789);

        setChain("custom_chain", Chain("Modified Chain", 999999999, "https://modified.chain/"));
        vm.expectRevert("StdChains getChain(uint256): Chain with ID 123456789 not found.");
        getChain(123456789);

        Chain memory modifiedChain = getChain(999999999);
        assertEq(modifiedChain.name, "Modified Chain");
        assertEq(modifiedChain.chainId, 999999999);
        assertEq(modifiedChain.rpcUrl, "https://modified.chain/");
    }
}
