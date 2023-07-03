// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {Test} from "forge-std/Test.sol";
import {MockToken} from "../../mocks/MockToken.sol";
import {MockDeFiProtocol} from "../../mocks/MockDeFiProtocol.sol";
import {CircuitBreaker} from "src/core/CircuitBreaker.sol";
import {LimiterLib} from "src/utils/LimiterLib.sol";

contract CircuitBreakerAdminOpsTest is Test {
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

    function test_initialization_shouldBeSuccessful() public {
        CircuitBreaker newCircuitBreaker = new CircuitBreaker(admin, 3 days, 3 hours, 5 minutes);
        assertEq(newCircuitBreaker.admin(), admin);
        assertEq(newCircuitBreaker.rateLimitCooldownPeriod(), 3 days);
    }

    function test_registerAsset_whenMinimumLiquidityThresholdIsInvalidShouldFail() public {
        secondToken = new MockToken("DAI", "DAI");
        vm.prank(admin);
        vm.expectRevert(LimiterLib.InvalidMinimumLiquidityThreshold.selector);
        circuitBreaker.registerAsset(address(secondToken), 0, 1000e18);

        vm.prank(admin);
        vm.expectRevert(LimiterLib.InvalidMinimumLiquidityThreshold.selector);
        circuitBreaker.registerAsset(address(secondToken), 10_001, 1000e18);

        vm.prank(admin);
        vm.expectRevert(LimiterLib.InvalidMinimumLiquidityThreshold.selector);
        circuitBreaker.updateAssetParams(address(secondToken), 0, 2000e18);

        vm.prank(admin);
        vm.expectRevert(LimiterLib.InvalidMinimumLiquidityThreshold.selector);
        circuitBreaker.updateAssetParams(address(secondToken), 10_001, 2000e18);
    }

    function test_registerAsset_whenAlreadyRegisteredShouldFail() public {
        secondToken = new MockToken("DAI", "DAI");
        vm.prank(admin);
        circuitBreaker.registerAsset(address(secondToken), 7000, 1000e18);
        // Cannot register the same token twice
        vm.expectRevert(LimiterLib.LimiterAlreadyInitialized.selector);
        vm.prank(admin);
        circuitBreaker.registerAsset(address(secondToken), 7000, 1000e18);
    }

    function test_registerAsset_shouldBeSuccessful() public {
        secondToken = new MockToken("DAI", "DAI");
        vm.prank(admin);
        circuitBreaker.registerAsset(address(secondToken), 7000, 1000e18);
        (uint256 minLiquidityThreshold, uint256 minAmount, , , , ) = circuitBreaker.tokenLimiters(
            address(secondToken)
        );
        assertEq(minAmount, 1000e18);
        assertEq(minLiquidityThreshold, 7000);

        vm.prank(admin);
        circuitBreaker.updateAssetParams(address(secondToken), 8000, 2000e18);
        (minLiquidityThreshold, minAmount, , , , ) = circuitBreaker.tokenLimiters(
            address(secondToken)
        );
        assertEq(minAmount, 2000e18);
        assertEq(minLiquidityThreshold, 8000);
    }

    function test_addProtectedContracts_shouldBeSuccessful() public {
        MockDeFiProtocol secondDeFi = new MockDeFiProtocol(address(circuitBreaker));

        address[] memory addresses = new address[](1);
        addresses[0] = address(secondDeFi);
        vm.prank(admin);
        circuitBreaker.addProtectedContracts(addresses);

        assertEq(circuitBreaker.isProtectedContract(address(secondDeFi)), true);
    }

    function test_removeProtectedContracts_shouldBeSuccessful() public {
        MockDeFiProtocol secondDeFi = new MockDeFiProtocol(address(circuitBreaker));

        address[] memory addresses = new address[](1);
        addresses[0] = address(secondDeFi);
        vm.prank(admin);
        circuitBreaker.addProtectedContracts(addresses);

        vm.prank(admin);
        circuitBreaker.removeProtectedContracts(addresses);
        assertEq(circuitBreaker.isProtectedContract(address(secondDeFi)), false);
    }

    function test_setAdmin_WhenCallerIsNotAdminShouldFail() public {
        vm.expectRevert(CircuitBreaker.NotAdmin.selector);
        circuitBreaker.setAdmin(alice);
    }

    function test_setAdmin_shouldBeSuccessful() public {
        assertEq(circuitBreaker.admin(), admin);
        vm.prank(admin);
        circuitBreaker.setAdmin(bob);
        assertEq(circuitBreaker.admin(), bob);

        vm.expectRevert();
        vm.prank(admin);
        circuitBreaker.setAdmin(alice);
    }

    function test_startGracePeriod_whenCallerIsNotAdminShouldFail() public {
        vm.expectRevert(CircuitBreaker.NotAdmin.selector);
        circuitBreaker.startGracePeriod(block.timestamp + 10);
    }

    function test_startGracePeriod_whenGracePeriodEndIsInThePastShouldFail() public {
        vm.expectRevert(CircuitBreaker.InvalidGracePeriodEnd.selector);
        vm.prank(admin);
        circuitBreaker.startGracePeriod(block.timestamp - 10);
    }

    function test_startGracePeriod_shouldBeSuccessfull() public {
        vm.prank(admin);
        circuitBreaker.startGracePeriod(block.timestamp + 10);
    }
}
