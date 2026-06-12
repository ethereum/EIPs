// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.13;

import "./Geas.sol";

/// @dev Minimal subset of the Foundry cheatcode interface (avoids a forge-std
/// dependency).
interface Vm {
    struct Log {
        bytes32[] topics;
        bytes data;
        address emitter;
    }

    function etch(address, bytes calldata) external;
    function store(address, bytes32, bytes32) external;
    function load(address, bytes32) external view returns (bytes32);
    function prank(address) external;
    function deal(address, uint256) external;
    function recordLogs() external;
    function getRecordedLogs() external returns (Log[] memory);
}

address constant sysaddr = 0xffffFFFfFFffffffffffffffFfFFFfffFFFfFFfE;

// Storage layout shared by both predeploys (and by the EIP-7002/7251
// contracts they are copied from).
uint256 constant excess_slot = 0;
uint256 constant count_slot = 1;
uint256 constant queue_head_slot = 2;
uint256 constant queue_tail_slot = 3;

uint256 constant target_per_block = 2;
uint256 constant max_per_block = 16;
bytes32 constant inhibitor = bytes32(type(uint256).max);

/// @notice Shared harness: assembles a predeploy from its geas source via FFI,
/// etches it, and mirrors deployment by storing the excess inhibitor (the
/// ctor's only job). Helpers model the activation system call, the fee getter,
/// and the EIP-7002 fee curve.
abstract contract RequestContractTest {
    Vm constant vm = Vm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

    address addr; // contract under test

    // etchInhibited deploys the runtime code at `where` in its pre-fork state:
    // code etched, excess set to the inhibitor (what ctor.eas stores).
    function etchInhibited(address where, string memory path) internal {
        vm.etch(where, Geas.compile(path));
        vm.store(where, bytes32(excess_slot), inhibitor);
        addr = where;
    }

    // getRequests makes a call to the contract as the system address in order
    // to trigger a dequeue action. The first such call after deployment clears
    // the excess inhibitor (the activation block's system call).
    function getRequests() internal returns (bytes memory) {
        vm.prank(sysaddr);
        (bool ok, bytes memory data) = addr.call("");
        require(ok, "system call failed");
        return data;
    }

    // fee calls the fee getter (empty calldata, non-system caller).
    function fee() internal returns (uint256) {
        (bool ok, bytes memory data) = addr.call("");
        require(ok, "fee getter failed");
        return uint256(bytes32(data));
    }

    function load(uint256 slot) internal view returns (uint256) {
        return uint256(vm.load(addr, bytes32(slot)));
    }

    // fakeExponential is the EIP-1559/EIP-7002 fee curve; the contract's fee
    // must equal fakeExponential(1, excess, 17).
    function fakeExponential(uint256 factor, uint256 numerator, uint256 denominator)
        internal
        pure
        returns (uint256)
    {
        uint256 i = 1;
        uint256 output = 0;
        uint256 accum = factor * denominator;
        while (accum > 0) {
            output += accum;
            accum = (accum * numerator) / (denominator * i);
            i += 1;
        }
        return output / denominator;
    }

    // expectLog asserts that exactly one anonymous log carrying `data` was
    // recorded since the last recordLogs().
    function expectLog(bytes memory data) internal {
        Vm.Log[] memory logs = vm.getRecordedLogs();
        assertEq(logs.length, 1, "expected exactly one log");
        assertEq(logs[0].topics.length, 0, "expected an anonymous log");
        assertEq(logs[0].emitter, addr, "unexpected log emitter");
        assertEq(logs[0].data, data, "unexpected log data");
    }

    function pattern(uint8 b, uint256 len) internal pure returns (bytes memory out) {
        out = new bytes(len);
        for (uint256 i = 0; i < len; i++) {
            out[i] = bytes1(b);
        }
    }

    function slice(bytes memory data, uint256 start, uint256 len) internal pure returns (bytes memory out) {
        out = new bytes(len);
        for (uint256 i = 0; i < len; i++) {
            out[i] = data[start + i];
        }
    }

    function assertEq(uint256 a, uint256 b, string memory err) internal pure {
        require(a == b, err);
    }

    function assertEq(address a, address b, string memory err) internal pure {
        require(a == b, err);
    }

    function assertEq(bytes memory a, bytes memory b, string memory err) internal pure {
        require(keccak256(a) == keccak256(b), err);
    }

    function assertStorage(uint256 slot, uint256 value, string memory err) internal view {
        require(load(slot) == value, err);
    }
}

/// @notice Tests for the builder deposit request contract (request type 0x03).
/// The input is the raw 184-byte (pubkey ++ withdrawal_credentials ++ amount ++
/// signature) with the amount a big-endian uint64 of gwei; the dequeued record
/// is the same bytes with the amount little-endian. No on-chain BLS: the
/// signature is opaque calldata for the consensus layer to verify on dequeue.
contract BuilderDepositTest is RequestContractTest {
    uint256 constant record_size = 184;
    uint64 constant min_amount = 1_000_000_000; // 1 ETH in gwei
    bytes32 constant wc = 0x0300000000000000000000001111111111111111111111111111111111111111;

    function setUp() public {
        etchInhibited(0x0000000000000000000000000000000000007732, "src/deposits/main.eas");
        getRequests(); // activation system call clears the inhibitor
    }

    function makeDeposit(bytes memory pubkey, uint64 amount) internal pure returns (bytes memory) {
        return abi.encodePacked(pubkey, wc, amount, pattern(0xBB, 96));
    }

    // expectedRecord is the input with the amount (bytes 80..88) reversed into
    // little-endian, as the system call must return it.
    function expectedRecord(bytes memory input) internal pure returns (bytes memory out) {
        out = bytes.concat(input);
        for (uint256 i = 0; i < 8; i++) {
            out[80 + i] = input[87 - i];
        }
    }

    function addDeposit(bytes memory input, uint256 value) internal {
        vm.deal(address(this), value);
        (bool ok,) = addr.call{value: value}(input);
        require(ok, "deposit failed");
    }

    function testDepositEnqueuesAndReads() public {
        bytes memory input = makeDeposit(pattern(0xAA, 48), min_amount);
        uint256 value = uint256(min_amount) * 1 gwei + fee();

        vm.recordLogs();
        addDeposit(input, value);
        expectLog(input); // the log carries the input verbatim (amount big-endian)
        assertStorage(count_slot, 1, "unexpected request count");

        bytes memory req = getRequests();
        assertEq(req.length, record_size, "unexpected request_data length");
        assertEq(req, expectedRecord(input), "unexpected record");
        assertStorage(count_slot, 0, "count not reset");
        assertStorage(queue_head_slot, 0, "head not reset");
        assertStorage(queue_tail_slot, 0, "tail not reset");
        assertEq(fee(), 1, "fee should remain at minimum below target");
    }

    function testDepositAmountConvertedToLittleEndian() public {
        uint64 amount = 0x0102030405060708;
        bytes memory input = makeDeposit(pattern(0xAA, 48), amount);
        addDeposit(input, uint256(amount) * 1 gwei + 1);

        bytes memory req = getRequests();
        assertEq(slice(req, 80, 8), hex"0807060504030201", "amount not little-endian");
        assertEq(slice(req, 0, 80), slice(input, 0, 80), "prefix not verbatim");
        assertEq(slice(req, 88, 96), slice(input, 88, 96), "signature not verbatim");
    }

    function testDepositRejectsAmountBelowMinimum() public {
        bytes memory input = makeDeposit(pattern(0xAA, 48), min_amount - 1);
        vm.deal(address(this), 2 ether);
        (bool ok,) = addr.call{value: 2 ether}(input);
        assertEq(ok ? 1 : 0, 0, "expected below-minimum amount to revert");
        assertStorage(count_slot, 0, "nothing should be enqueued");
    }

    function testDepositRejectsValueBelowStakePlusFee() public {
        bytes memory input = makeDeposit(pattern(0xAA, 48), min_amount);
        vm.deal(address(this), 4 ether);

        // value == stake leaves nothing for the fee (fee is 1 wei here).
        (bool ok,) = addr.call{value: 1 ether}(input);
        assertEq(ok ? 1 : 0, 0, "expected stake-only value to revert");

        // value == 0 fails the fee check itself.
        (ok,) = addr.call{value: 0}(input);
        assertEq(ok ? 1 : 0, 0, "expected zero value to revert");
        assertStorage(count_slot, 0, "nothing should be enqueued");

        // value == stake + fee succeeds.
        (ok,) = addr.call{value: 1 ether + 1}(input);
        assertEq(ok ? 1 : 0, 1, "expected exact stake + fee to succeed");
        assertStorage(count_slot, 1, "expected one request");
    }

    function testDepositRejectsBadInputSize() public {
        bytes memory input = makeDeposit(pattern(0xAA, 48), min_amount);
        vm.deal(address(this), 8 ether);

        // one byte short
        (bool ok,) = addr.call{value: 2 ether}(slice(input, 0, 183));
        assertEq(ok ? 1 : 0, 0, "183 bytes should revert");

        // one byte long
        (ok,) = addr.call{value: 2 ether}(bytes.concat(input, hex"00"));
        assertEq(ok ? 1 : 0, 0, "185 bytes should revert");

        // ABI-style call (4-byte selector prefix)
        (ok,) = addr.call{value: 2 ether}(bytes.concat(hex"deadbeef", input));
        assertEq(ok ? 1 : 0, 0, "selector-prefixed input should revert");

        assertStorage(count_slot, 0, "nothing should be enqueued");
    }

    function testFeeGetterRejectsValue() public {
        vm.deal(address(this), 1 ether);
        (bool ok,) = addr.call{value: 1}("");
        assertEq(ok ? 1 : 0, 0, "fee getter must reject callvalue");
    }

    function testQueueCapFifoAndReset() public {
        bytes[] memory inputs = new bytes[](max_per_block + 1);
        // Enqueue one more deposit than the per-block cap.
        for (uint256 i = 0; i < max_per_block + 1; i++) {
            inputs[i] = makeDeposit(pattern(uint8(i + 1), 48), min_amount);
            addDeposit(inputs[i], 1 ether + 1);
        }
        assertStorage(count_slot, max_per_block + 1, "unexpected request count");

        // First system read drains exactly the cap, FIFO.
        bytes memory req = getRequests();
        assertEq(req.length, max_per_block * record_size, "expected capped read");
        for (uint256 i = 0; i < max_per_block; i++) {
            uint256 offset = i * record_size;
            assertEq(slice(req, offset + 80, 8), hex"00CA9A3B00000000", "amount not little-endian");
            assertEq(slice(req, offset, 80), slice(inputs[i], 0, 80), "prefix not verbatim");
            assertEq(slice(req, offset + 88, 96), slice(inputs[i], 88, 96), "signature not verbatim");
        }
        assertStorage(queue_head_slot, max_per_block, "unexpected head");
        assertStorage(queue_tail_slot, max_per_block + 1, "unexpected tail");
        assertStorage(excess_slot, max_per_block + 1 - target_per_block, "unexpected excess");

        // Second read returns the remainder and resets the queue.
        req = getRequests();
        assertEq(req.length, record_size, "expected single remaining record");
        assertEq(slice(req, 0, 48), pattern(uint8(max_per_block + 1), 48), "wrong remaining record");
        assertStorage(queue_head_slot, 0, "head not reset");
        assertStorage(queue_tail_slot, 0, "tail not reset");

        // The queue is reusable after the reset.
        addDeposit(makeDeposit(pattern(0xEE, 48), min_amount), 1 ether + fee());
        assertStorage(queue_tail_slot, 1, "queue not reusable after reset");
    }

    function testFeeMatchesFakeExponentialAndDecays() public {
        for (uint256 i = 0; i < 18; i++) {
            addDeposit(makeDeposit(pattern(uint8(i + 1), 48), min_amount), 1 ether + 1);
        }
        getRequests();
        // excess = 0 + 18 - 2 = 16
        assertStorage(excess_slot, 16, "unexpected excess");
        assertEq(fee(), fakeExponential(1, 16, 17), "fee does not match curve");

        // With no new requests, each system call decays excess by the target.
        getRequests();
        getRequests(); // drains the 2 remaining records
        assertStorage(excess_slot, 12, "excess should decay by target per block");
        getRequests();
        assertStorage(excess_slot, 10, "excess should keep decaying");
    }

    function testInhibitorBlocksRequestsUntilFirstSystemCall() public {
        // A freshly deployed (not yet activated) instance.
        etchInhibited(0x0000000000000000000000000000000000007734, "src/deposits/main.eas");
        vm.deal(address(this), 2 ether);

        (bool ok,) = addr.call("");
        assertEq(ok ? 1 : 0, 0, "fee getter must revert while inhibited");

        (ok,) = addr.call{value: 1 ether + 1}(makeDeposit(pattern(0xAA, 48), min_amount));
        assertEq(ok ? 1 : 0, 0, "deposit must revert while inhibited");

        // The first system call clears the inhibitor.
        getRequests();
        assertStorage(excess_slot, 0, "inhibitor not cleared");
        assertEq(fee(), 1, "fee should be at minimum after activation");
    }

    function testSystemCallDrainsRegardlessOfCalldata() public {
        addDeposit(makeDeposit(pattern(0xAA, 48), min_amount), 1 ether + 1);

        // The caller check runs before the calldata dispatch.
        vm.prank(sysaddr);
        (bool ok, bytes memory data) = addr.call(hex"01");
        require(ok, "system call failed");
        assertEq(data.length, record_size, "system call should drain the queue");
    }

    receive() external payable {}
}

/// @notice Tests for the builder exit request contract (request type 0x04).
/// The input is the raw 48-byte builder pubkey; the dequeued record is
/// (source_address ++ pubkey), where source_address is the caller.
contract BuilderExitTest is RequestContractTest {
    uint256 constant record_size = 68;

    function setUp() public {
        etchInhibited(0x0000000000000000000000000000000000007733, "src/exits/main.eas");
        getRequests(); // activation system call clears the inhibitor
    }

    function testExitEnqueuesAndReads() public {
        bytes memory pubkey = pattern(0xAB, 48);
        bytes memory record = abi.encodePacked(address(this), pubkey);

        vm.recordLogs();
        vm.deal(address(this), 1 ether);
        (bool ok,) = addr.call{value: fee()}(pubkey);
        require(ok, "exit failed");
        expectLog(record);
        assertStorage(count_slot, 1, "unexpected request count");

        bytes memory req = getRequests();
        assertEq(req.length, record_size, "unexpected request_data length");
        assertEq(req, record, "unexpected record");
        assertStorage(count_slot, 0, "count not reset");
        assertStorage(queue_head_slot, 0, "head not reset");
        assertStorage(queue_tail_slot, 0, "tail not reset");
    }

    function testExitRecordsCaller() public {
        address caller = 0xCAfEcAfeCAfECaFeCaFecaFecaFECafECafeCaFe;
        bytes memory pubkey = pattern(0xCD, 48);

        vm.deal(caller, 1 ether);
        vm.prank(caller);
        (bool ok,) = addr.call{value: 1}(pubkey);
        require(ok, "exit failed");

        bytes memory req = getRequests();
        assertEq(address(bytes20(slice(req, 0, 20))), caller, "source_address must be the caller");
        assertEq(slice(req, 20, 48), pubkey, "unexpected pubkey");
    }

    function testExitRejectsBadInputSize() public {
        vm.deal(address(this), 1 ether);

        (bool ok,) = addr.call{value: 1}(pattern(0xAB, 47));
        assertEq(ok ? 1 : 0, 0, "47 bytes should revert");

        (ok,) = addr.call{value: 1}(pattern(0xAB, 49));
        assertEq(ok ? 1 : 0, 0, "49 bytes should revert");

        (ok,) = addr.call{value: 1}(bytes.concat(hex"deadbeef", pattern(0xAB, 48)));
        assertEq(ok ? 1 : 0, 0, "selector-prefixed input should revert");

        assertStorage(count_slot, 0, "nothing should be enqueued");
    }

    function testExitRejectsInsufficientFee() public {
        (bool ok,) = addr.call{value: 0}(pattern(0xAB, 48));
        assertEq(ok ? 1 : 0, 0, "expected zero-fee exit to revert");
        assertStorage(count_slot, 0, "nothing should be enqueued");
    }

    function testFeeGetterRejectsValue() public {
        vm.deal(address(this), 1 ether);
        (bool ok,) = addr.call{value: 1}("");
        assertEq(ok ? 1 : 0, 0, "fee getter must reject callvalue");
    }

    function testQueueCapAndFifo() public {
        vm.deal(address(this), 1 ether);
        for (uint256 i = 0; i < max_per_block + 1; i++) {
            (bool ok,) = addr.call{value: 1}(pattern(uint8(i + 1), 48));
            require(ok, "exit failed");
        }

        bytes memory req = getRequests();
        assertEq(req.length, max_per_block * record_size, "expected capped read");
        for (uint256 i = 0; i < max_per_block; i++) {
            assertEq(
                slice(req, i * record_size + 20, 48),
                pattern(uint8(i + 1), 48),
                "records not FIFO"
            );
        }

        req = getRequests();
        assertEq(req.length, record_size, "expected single remaining record");
        assertStorage(queue_head_slot, 0, "head not reset");
        assertStorage(queue_tail_slot, 0, "tail not reset");
    }

    function testInhibitorBlocksRequestsUntilFirstSystemCall() public {
        etchInhibited(0x0000000000000000000000000000000000007735, "src/exits/main.eas");
        vm.deal(address(this), 1 ether);

        (bool ok,) = addr.call("");
        assertEq(ok ? 1 : 0, 0, "fee getter must revert while inhibited");

        (ok,) = addr.call{value: 1}(pattern(0xAB, 48));
        assertEq(ok ? 1 : 0, 0, "exit must revert while inhibited");

        getRequests();
        assertStorage(excess_slot, 0, "inhibitor not cleared");
        assertEq(fee(), 1, "fee should be at minimum after activation");
    }

    receive() external payable {}
}
