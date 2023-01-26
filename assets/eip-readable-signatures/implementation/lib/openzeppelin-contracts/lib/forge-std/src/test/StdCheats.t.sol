// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "../Test.sol";
import "../StdJson.sol";

contract StdCheatsTest is Test {
    Bar test;

    using stdJson for string;

    function setUp() public {
        test = new Bar();
    }

    function testSkip() public {
        vm.warp(100);
        skip(25);
        assertEq(block.timestamp, 125);
    }

    function testRewind() public {
        vm.warp(100);
        rewind(25);
        assertEq(block.timestamp, 75);
    }

    function testHoax() public {
        hoax(address(1337));
        test.bar{value: 100}(address(1337));
    }

    function testHoaxOrigin() public {
        hoax(address(1337), address(1337));
        test.origin{value: 100}(address(1337));
    }

    function testHoaxDifferentAddresses() public {
        hoax(address(1337), address(7331));
        test.origin{value: 100}(address(1337), address(7331));
    }

    function testStartHoax() public {
        startHoax(address(1337));
        test.bar{value: 100}(address(1337));
        test.bar{value: 100}(address(1337));
        vm.stopPrank();
        test.bar(address(this));
    }

    function testStartHoaxOrigin() public {
        startHoax(address(1337), address(1337));
        test.origin{value: 100}(address(1337));
        test.origin{value: 100}(address(1337));
        vm.stopPrank();
        test.bar(address(this));
    }

    function testChangePrank() public {
        vm.startPrank(address(1337));
        test.bar(address(1337));
        changePrank(address(0xdead));
        test.bar(address(0xdead));
        changePrank(address(1337));
        test.bar(address(1337));
        vm.stopPrank();
    }

    function testMakeAddrEquivalence() public {
        (address addr, ) = makeAddrAndKey("1337");
        assertEq(makeAddr("1337"), addr);
    }

    function testMakeAddrSigning() public {
        (address addr, uint256 key) = makeAddrAndKey("1337");
        bytes32 hash = keccak256("some_message");

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(key, hash);
        assertEq(ecrecover(hash, v, r, s), addr);
    }

    function testDeal() public {
        deal(address(this), 1 ether);
        assertEq(address(this).balance, 1 ether);
    }

    function testDealToken() public {
        Bar barToken = new Bar();
        address bar = address(barToken);
        deal(bar, address(this), 10000e18);
        assertEq(barToken.balanceOf(address(this)), 10000e18);
    }

    function testDealTokenAdjustTS() public {
        Bar barToken = new Bar();
        address bar = address(barToken);
        deal(bar, address(this), 10000e18, true);
        assertEq(barToken.balanceOf(address(this)), 10000e18);
        assertEq(barToken.totalSupply(), 20000e18);
        deal(bar, address(this), 0, true);
        assertEq(barToken.balanceOf(address(this)), 0);
        assertEq(barToken.totalSupply(), 10000e18);
    }

    function testBound() public {
        assertEq(bound(5, 0, 4), 0);
        assertEq(bound(0, 69, 69), 69);
        assertEq(bound(0, 68, 69), 68);
        assertEq(bound(10, 150, 190), 160);
        assertEq(bound(300, 2800, 3200), 3100);
        assertEq(bound(9999, 1337, 6666), 6006);
    }

    function testCannotBoundMaxLessThanMin() public {
        vm.expectRevert(bytes("Test bound(uint256,uint256,uint256): Max is less than min."));
        bound(5, 100, 10);
    }

    function testBound(
        uint256 num,
        uint256 min,
        uint256 max
    ) public {
        if (min > max) (min, max) = (max, min);

        uint256 bounded = bound(num, min, max);

        assertGe(bounded, min);
        assertLe(bounded, max);
    }

    function testBoundUint256Max() public {
        assertEq(bound(0, type(uint256).max - 1, type(uint256).max), type(uint256).max - 1);
        assertEq(bound(1, type(uint256).max - 1, type(uint256).max), type(uint256).max);
    }

    function testCannotBoundMaxLessThanMin(
        uint256 num,
        uint256 min,
        uint256 max
    ) public {
        vm.assume(min > max);
        vm.expectRevert(bytes("Test bound(uint256,uint256,uint256): Max is less than min."));
        bound(num, min, max);
    }

    function testDeployCode() public {
        address deployed = deployCode("StdCheats.t.sol:StdCheatsTest", bytes(""));
        assertEq(string(getCode(deployed)), string(getCode(address(this))));
    }

    function testDeployCodeNoArgs() public {
        address deployed = deployCode("StdCheats.t.sol:StdCheatsTest");
        assertEq(string(getCode(deployed)), string(getCode(address(this))));
    }

    // We need that payable constructor in order to send ETH on construction
    constructor() payable {}

    function testDeployCodeVal() public {
        address deployed = deployCode("StdCheats.t.sol:StdCheatsTest", bytes(""), 1 ether);
        assertEq(string(getCode(deployed)), string(getCode(address(this))));
	assertEq(deployed.balance, 1 ether);
    }

    function testDeployCodeValNoArgs() public {
        address deployed = deployCode("StdCheats.t.sol:StdCheatsTest", 1 ether);
        assertEq(string(getCode(deployed)), string(getCode(address(this))));
	assertEq(deployed.balance, 1 ether);
    }

    // We need this so we can call "this.deployCode" rather than "deployCode" directly
    function deployCodeHelper(string memory what) external {
        deployCode(what);
    }

    function testDeployCodeFail() public {
        vm.expectRevert(bytes("Test deployCode(string): Deployment failed."));
        this.deployCodeHelper("StdCheats.t.sol:RevertingContract");
    }

    function getCode(address who) internal view returns (bytes memory o_code) {
        /// @solidity memory-safe-assembly
        assembly {
            // retrieve the size of the code, this needs assembly
            let size := extcodesize(who)
            // allocate output byte array - this could also be done without assembly
            // by using o_code = new bytes(size)
            o_code := mload(0x40)
            // new "memory end" including padding
            mstore(0x40, add(o_code, and(add(add(size, 0x20), 0x1f), not(0x1f))))
            // store length in memory
            mstore(o_code, size)
            // actually retrieve the code, this needs assembly
            extcodecopy(who, add(o_code, 0x20), 0, size)
        }
    }

    function testBytesToUint() public {
        assertEq(3, bytesToUint(hex'03'));
        assertEq(2, bytesToUint(hex'02'));
        assertEq(255, bytesToUint(hex'ff'));
        assertEq(29625, bytesToUint(hex'73b9'));
    }

    function testParseJsonTxDetail() public {
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/src/test/fixtures/broadcast.log.json");
        string memory json = vm.readFile(path);
        bytes memory transactionDetails = json.parseRaw(".transactions[0].tx");
        RawTx1559Detail memory rawTxDetail = abi.decode(transactionDetails, (RawTx1559Detail));
        Tx1559Detail memory txDetail = rawToConvertedEIP1559Detail(rawTxDetail);
        assertEq(txDetail.from, 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
        assertEq(txDetail.to, 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512);
        assertEq(txDetail.data, hex'23e99187000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000013370000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000030000000000000000000000000000000000000000000000000000000000000004');
        assertEq(txDetail.nonce, 3);
        assertEq(txDetail.txType, 2);
        assertEq(txDetail.gas, 29625);
        assertEq(txDetail.value, 0);
    }

    function testReadEIP1559Transaction() public {
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/src/test/fixtures/broadcast.log.json");
        uint256 index = 0;
        Tx1559 memory transaction = readTx1559(path, index);
    }

    function testReadEIP1559Transactions() public {
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/src/test/fixtures/broadcast.log.json");
        Tx1559[] memory transactions = readTx1559s(path);
    }

    function testReadReceipt() public {
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/src/test/fixtures/broadcast.log.json");
        uint index = 5;
        Receipt memory receipt = readReceipt(path, index);
        assertEq(receipt.logsBloom,
                 hex"00000000000800000000000000000010000000000000000000000000000180000000000000000000000000000000000000000000000008000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100");
    }

    function testReadReceipts() public {
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/src/test/fixtures/broadcast.log.json");
        Receipt[] memory receipts = readReceipts(path);
    }

}

contract Bar {
    constructor() {
        /// `DEAL` STDCHEAT
        totalSupply = 10000e18;
        balanceOf[address(this)] = totalSupply;
    }

    /// `HOAX` STDCHEATS
    function bar(address expectedSender) public payable {
        require(msg.sender == expectedSender, "!prank");
    }
    function origin(address expectedSender) public payable {
        require(msg.sender == expectedSender, "!prank");
        require(tx.origin == expectedSender, "!prank");
    }
    function origin(address expectedSender, address expectedOrigin) public payable {
        require(msg.sender == expectedSender, "!prank");
        require(tx.origin == expectedOrigin, "!prank");
    }

    /// `DEAL` STDCHEAT
    mapping (address => uint256) public balanceOf;
    uint256 public totalSupply;
}

contract RevertingContract {
    constructor() {
        revert();
    }
}

