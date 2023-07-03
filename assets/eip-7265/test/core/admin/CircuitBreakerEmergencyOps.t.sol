// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "forge-std/console.sol";
import {Test} from "forge-std/Test.sol";
import {MockToken} from "../../mocks/MockToken.sol";
import {MockDeFiProtocol} from "../../mocks/MockDeFiProtocol.sol";
import {CircuitBreaker} from "src/core/CircuitBreaker.sol";
import {LimiterLib} from "src/utils/LimiterLib.sol";

contract CircuitBreakerEmergencyOpsTest is Test {
    event FundsReleased(address indexed token);
    event HackerFundsWithdrawn(
        address indexed hacker,
        address indexed token,
        address indexed receiver,
        uint256 amount
    );

    MockToken internal token;
    MockToken internal secondToken;
    MockToken internal unlimitedToken;

    address internal NATIVE_ADDRESS_PROXY = address(1);
    CircuitBreaker internal circuitBreaker;
    MockDeFiProtocol internal deFi;

    address internal alice = vm.addr(0x1);
    address internal bob = vm.addr(0x2);
    address internal admin = vm.addr(0x3);

    function setUp() public {
        token = new MockToken("USDC", "USDC");
        circuitBreaker = new CircuitBreaker(admin, 3 days, 4 hours, 5 minutes);
        deFi = new MockDeFiProtocol(address(circuitBreaker));

        address[] memory addresses = new address[](1);
        addresses[0] = address(deFi);

        vm.prank(admin);
        circuitBreaker.addProtectedContracts(addresses);

        vm.prank(admin);
        // Protect USDC with 70% max drawdown per 4 hours
        circuitBreaker.registerAsset(address(token), 7000, 1000e18);
        vm.prank(admin);
        circuitBreaker.registerAsset(NATIVE_ADDRESS_PROXY, 7000, 1000e18);
        vm.warp(1 hours);
    }

    function test_markAsNotOperational_ifCallerIsNotAdminShouldFail() public {
        vm.expectRevert(CircuitBreaker.NotAdmin.selector);
        circuitBreaker.markAsNotOperational();
    }

    function test_migrateFundsAfterExploit_ifNotExploitedShouldFail() public {
        address[] memory tokens = new address[](1);
        tokens[0] = address(token);
        vm.prank(admin);
        vm.expectRevert(CircuitBreaker.NotExploited.selector);
        circuitBreaker.migrateFundsAfterExploit(tokens, address(admin));
    }

    function test_ifTokenNotRateLimitedShouldFail() public {
        secondToken = new MockToken("DAI", "DAI");
        vm.prank(admin);
        circuitBreaker.registerAsset(address(secondToken), 7000, 1000e18);

        token.mint(alice, 1_000_000e18);

        vm.prank(alice);
        token.approve(address(deFi), 1_000_000e18);

        vm.prank(alice);
        deFi.deposit(address(token), 1_000_000e18);

        int256 withdrawalAmount = 300_001e18;
        vm.warp(5 hours);
        vm.prank(alice);
        deFi.withdrawal(address(token), uint256(withdrawalAmount));
        assertEq(circuitBreaker.isRateLimited(), true);
        assertEq(circuitBreaker.isRateLimitTriggered(address(secondToken)), false);
    }

    function test_claimLockedFunds_ifRecipientHasNoLockedFundsShouldFail() public {
        token.mint(alice, 1_000_000e18);

        vm.prank(alice);
        token.approve(address(deFi), 1_000_000e18);

        vm.prank(alice);
        deFi.deposit(address(token), 1_000_000e18);

        int256 withdrawalAmount = 300_001e18;
        vm.warp(5 hours);
        vm.prank(alice);
        deFi.withdrawal(address(token), uint256(withdrawalAmount));
        assertEq(circuitBreaker.isRateLimited(), true);
        assertEq(circuitBreaker.isRateLimitTriggered(address(token)), true);

        vm.prank(admin);
        vm.expectRevert(CircuitBreaker.NoLockedFunds.selector);
        address[] memory tokens = new address[](1);
        tokens[0] = address(token);
        circuitBreaker.claimLockedFunds(address(token), bob);
    }

    function test_claimLockedFunds_shouldBeSuccessful() public {
        token.mint(alice, 1_000_000e18);
        token.mint(bob, 1_000_000e18);

        vm.prank(alice);
        token.approve(address(deFi), 1_000_000e18);

        vm.prank(bob);
        token.approve(address(deFi), 1_000_000e18);

        vm.prank(alice);
        deFi.deposit(address(token), 1_000_000e18);

        vm.prank(bob);
        deFi.deposit(address(token), 1_000_000e18);

        int256 withdrawalAmount = 700_000e18;

        vm.warp(5 hours);

        vm.prank(alice);
        deFi.withdrawal(address(token), uint256(withdrawalAmount));

        assertEq(circuitBreaker.isRateLimited(), true);
        assertEq(circuitBreaker.isRateLimitTriggered(address(token)), true);

        vm.prank(bob);
        deFi.withdrawal(address(token), 1_000_000e18);

        address[] memory recipients = new address[](1);
        recipients[0] = bob;

        vm.prank(admin);
        circuitBreaker.overrideRateLimit();
        vm.prank(bob);
        circuitBreaker.claimLockedFunds(address(token), bob);
        assertEq(token.balanceOf(bob), 1_000_000e18);
        assertEq(token.balanceOf(alice), 0);
        assertEq(token.balanceOf(address(circuitBreaker)), uint256(withdrawalAmount));
        assertEq(token.balanceOf(address(deFi)), 1_000_000e18 - uint256(withdrawalAmount));
    }

    function test_reverts_ifIsExploitedFlagUp() public {
        token.mint(alice, 1_000_000e18);

        vm.prank(alice);
        token.approve(address(deFi), 1_000_000e18);

        vm.prank(alice);
        deFi.deposit(address(token), 1_000_000e18);

        int256 withdrawalAmount = 300_001e18;
        vm.warp(5 hours);
        vm.prank(alice);
        deFi.withdrawal(address(token), uint256(withdrawalAmount));

        assertEq(circuitBreaker.isRateLimited(), true);

        // Exploit
        vm.prank(admin);
        circuitBreaker.markAsNotOperational();

        token.mint(alice, 1_000_000e18);
        vm.prank(alice);
        token.approve(address(deFi), 1_000_000e18);

        vm.expectRevert(CircuitBreaker.ProtocolWasExploited.selector);
        vm.prank(alice);
        deFi.deposit(address(token), 1_000_000e18);

        vm.expectRevert(CircuitBreaker.ProtocolWasExploited.selector);
        vm.prank(alice);
        deFi.withdrawal(address(token), uint256(withdrawalAmount));

        vm.expectRevert(CircuitBreaker.ProtocolWasExploited.selector);
        vm.prank(alice);
        circuitBreaker.claimLockedFunds(address(token), address(alice));

        vm.deal(alice, 1_000_000e18);
        vm.expectRevert(CircuitBreaker.ProtocolWasExploited.selector);
        vm.prank(alice);
        deFi.depositNative{value: 1_000_000e18}();

        // There are currently 300_001e18 tokens in the contract in the the withdrawable state
        address[] memory tokens = new address[](1);
        tokens[0] = address(token);
        vm.prank(admin);
        circuitBreaker.migrateFundsAfterExploit(tokens, address(bob));
        assertEq(token.balanceOf(address(bob)), uint256(withdrawalAmount));
    }
}
