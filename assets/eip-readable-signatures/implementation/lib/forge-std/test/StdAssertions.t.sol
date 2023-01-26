// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "../src/Test.sol";

contract StdAssertionsTest is Test {
    string constant CUSTOM_ERROR = "guh!";

    bool constant EXPECT_PASS = false;
    bool constant EXPECT_FAIL = true;

    TestTest t = new TestTest();

    /*//////////////////////////////////////////////////////////////////////////
                                    FAIL(STRING)
    //////////////////////////////////////////////////////////////////////////*/

    function testShouldFail() external {
        vm.expectEmit(false, false, false, true);
        emit log_named_string("Error", CUSTOM_ERROR);
        t._fail(CUSTOM_ERROR);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    ASSERT_FALSE
    //////////////////////////////////////////////////////////////////////////*/

    function testAssertFalse_Pass() external {
        t._assertFalse(false, EXPECT_PASS);
    }

    function testAssertFalse_Fail() external {
        vm.expectEmit(false, false, false, true);
        emit log("Error: Assertion Failed");
        t._assertFalse(true, EXPECT_FAIL);
    }

    function testAssertFalse_Err_Pass() external {
        t._assertFalse(false, CUSTOM_ERROR, EXPECT_PASS);
    }

    function testAssertFalse_Err_Fail() external {
        vm.expectEmit(false, false, false, true);
        emit log_named_string("Error", CUSTOM_ERROR);
        t._assertFalse(true, CUSTOM_ERROR, EXPECT_FAIL);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    ASSERT_EQ(BOOL)
    //////////////////////////////////////////////////////////////////////////*/

    function testAssertEq_Bool_Pass(bool a) external {
        t._assertEq(a, a, EXPECT_PASS);
    }

    function testAssertEq_Bool_Fail(bool a, bool b) external {
        vm.assume(a != b);

        vm.expectEmit(false, false, false, true);
        emit log("Error: a == b not satisfied [bool]");
        t._assertEq(a, b, EXPECT_FAIL);
    }

    function testAssertEq_BoolErr_Pass(bool a) external {
        t._assertEq(a, a, CUSTOM_ERROR, EXPECT_PASS);
    }

    function testAssertEq_BoolErr_Fail(bool a, bool b) external {
        vm.assume(a != b);

        vm.expectEmit(false, false, false, true);
        emit log_named_string("Error", CUSTOM_ERROR);
        t._assertEq(a, b, CUSTOM_ERROR, EXPECT_FAIL);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    ASSERT_EQ(BYTES)
    //////////////////////////////////////////////////////////////////////////*/

    function testAssertEq_Bytes_Pass(bytes calldata a) external {
        t._assertEq(a, a, EXPECT_PASS);
    }

    function testAssertEq_Bytes_Fail(bytes calldata a, bytes calldata b) external {
        vm.assume(keccak256(a) != keccak256(b));

        vm.expectEmit(false, false, false, true);
        emit log("Error: a == b not satisfied [bytes]");
        t._assertEq(a, b, EXPECT_FAIL);
    }

    function testAssertEq_BytesErr_Pass(bytes calldata a) external {
        t._assertEq(a, a, CUSTOM_ERROR, EXPECT_PASS);
    }

    function testAssertEq_BytesErr_Fail(bytes calldata a, bytes calldata b) external {
        vm.assume(keccak256(a) != keccak256(b));

        vm.expectEmit(false, false, false, true);
        emit log_named_string("Error", CUSTOM_ERROR);
        t._assertEq(a, b, CUSTOM_ERROR, EXPECT_FAIL);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    ASSERT_EQ(ARRAY)
    //////////////////////////////////////////////////////////////////////////*/

    function testAssertEq_UintArr_Pass(uint256 e0, uint256 e1, uint256 e2) public {
        uint256[] memory a = new uint256[](3);
        a[0] = e0;
        a[1] = e1;
        a[2] = e2;
        uint256[] memory b = new uint256[](3);
        b[0] = e0;
        b[1] = e1;
        b[2] = e2;

        t._assertEq(a, b, EXPECT_PASS);
    }

    function testAssertEq_IntArr_Pass(int256 e0, int256 e1, int256 e2) public {
        int256[] memory a = new int256[](3);
        a[0] = e0;
        a[1] = e1;
        a[2] = e2;
        int256[] memory b = new int256[](3);
        b[0] = e0;
        b[1] = e1;
        b[2] = e2;

        t._assertEq(a, b, EXPECT_PASS);
    }

    function testAssertEq_AddressArr_Pass(address e0, address e1, address e2) public {
        address[] memory a = new address[](3);
        a[0] = e0;
        a[1] = e1;
        a[2] = e2;
        address[] memory b = new address[](3);
        b[0] = e0;
        b[1] = e1;
        b[2] = e2;

        t._assertEq(a, b, EXPECT_PASS);
    }

    function testAssertEq_UintArr_FailEl(uint256 e1) public {
        vm.assume(e1 != 0);
        uint256[] memory a = new uint256[](3);
        uint256[] memory b = new uint256[](3);
        b[1] = e1;

        vm.expectEmit(false, false, false, true);
        emit log("Error: a == b not satisfied [uint[]]");
        t._assertEq(a, b, EXPECT_FAIL);
    }

    function testAssertEq_IntArr_FailEl(int256 e1) public {
        vm.assume(e1 != 0);
        int256[] memory a = new int256[](3);
        int256[] memory b = new int256[](3);
        b[1] = e1;

        vm.expectEmit(false, false, false, true);
        emit log("Error: a == b not satisfied [int[]]");
        t._assertEq(a, b, EXPECT_FAIL);
    }

    function testAssertEq_AddressArr_FailEl(address e1) public {
        vm.assume(e1 != address(0));
        address[] memory a = new address[](3);
        address[] memory b = new address[](3);
        b[1] = e1;

        vm.expectEmit(false, false, false, true);
        emit log("Error: a == b not satisfied [address[]]");
        t._assertEq(a, b, EXPECT_FAIL);
    }

    function testAssertEq_UintArrErr_FailEl(uint256 e1) public {
        vm.assume(e1 != 0);
        uint256[] memory a = new uint256[](3);
        uint256[] memory b = new uint256[](3);
        b[1] = e1;

        vm.expectEmit(false, false, false, true);
        emit log_named_string("Error", CUSTOM_ERROR);
        vm.expectEmit(false, false, false, true);
        emit log("Error: a == b not satisfied [uint[]]");
        t._assertEq(a, b, CUSTOM_ERROR, EXPECT_FAIL);
    }

    function testAssertEq_IntArrErr_FailEl(int256 e1) public {
        vm.assume(e1 != 0);
        int256[] memory a = new int256[](3);
        int256[] memory b = new int256[](3);
        b[1] = e1;

        vm.expectEmit(false, false, false, true);
        emit log_named_string("Error", CUSTOM_ERROR);
        vm.expectEmit(false, false, false, true);
        emit log("Error: a == b not satisfied [int[]]");
        t._assertEq(a, b, CUSTOM_ERROR, EXPECT_FAIL);
    }

    function testAssertEq_AddressArrErr_FailEl(address e1) public {
        vm.assume(e1 != address(0));
        address[] memory a = new address[](3);
        address[] memory b = new address[](3);
        b[1] = e1;

        vm.expectEmit(false, false, false, true);
        emit log_named_string("Error", CUSTOM_ERROR);
        vm.expectEmit(false, false, false, true);
        emit log("Error: a == b not satisfied [address[]]");
        t._assertEq(a, b, CUSTOM_ERROR, EXPECT_FAIL);
    }

    function testAssertEq_UintArr_FailLen(uint256 lenA, uint256 lenB) public {
        vm.assume(lenA != lenB);
        vm.assume(lenA <= 10000);
        vm.assume(lenB <= 10000);
        uint256[] memory a = new uint256[](lenA);
        uint256[] memory b = new uint256[](lenB);

        vm.expectEmit(false, false, false, true);
        emit log("Error: a == b not satisfied [uint[]]");
        t._assertEq(a, b, EXPECT_FAIL);
    }

    function testAssertEq_IntArr_FailLen(uint256 lenA, uint256 lenB) public {
        vm.assume(lenA != lenB);
        vm.assume(lenA <= 10000);
        vm.assume(lenB <= 10000);
        int256[] memory a = new int256[](lenA);
        int256[] memory b = new int256[](lenB);

        vm.expectEmit(false, false, false, true);
        emit log("Error: a == b not satisfied [int[]]");
        t._assertEq(a, b, EXPECT_FAIL);
    }

    function testAssertEq_AddressArr_FailLen(uint256 lenA, uint256 lenB) public {
        vm.assume(lenA != lenB);
        vm.assume(lenA <= 10000);
        vm.assume(lenB <= 10000);
        address[] memory a = new address[](lenA);
        address[] memory b = new address[](lenB);

        vm.expectEmit(false, false, false, true);
        emit log("Error: a == b not satisfied [address[]]");
        t._assertEq(a, b, EXPECT_FAIL);
    }

    function testAssertEq_UintArrErr_FailLen(uint256 lenA, uint256 lenB) public {
        vm.assume(lenA != lenB);
        vm.assume(lenA <= 10000);
        vm.assume(lenB <= 10000);
        uint256[] memory a = new uint256[](lenA);
        uint256[] memory b = new uint256[](lenB);

        vm.expectEmit(false, false, false, true);
        emit log_named_string("Error", CUSTOM_ERROR);
        vm.expectEmit(false, false, false, true);
        emit log("Error: a == b not satisfied [uint[]]");
        t._assertEq(a, b, CUSTOM_ERROR, EXPECT_FAIL);
    }

    function testAssertEq_IntArrErr_FailLen(uint256 lenA, uint256 lenB) public {
        vm.assume(lenA != lenB);
        vm.assume(lenA <= 10000);
        vm.assume(lenB <= 10000);
        int256[] memory a = new int256[](lenA);
        int256[] memory b = new int256[](lenB);

        vm.expectEmit(false, false, false, true);
        emit log_named_string("Error", CUSTOM_ERROR);
        vm.expectEmit(false, false, false, true);
        emit log("Error: a == b not satisfied [int[]]");
        t._assertEq(a, b, CUSTOM_ERROR, EXPECT_FAIL);
    }

    function testAssertEq_AddressArrErr_FailLen(uint256 lenA, uint256 lenB) public {
        vm.assume(lenA != lenB);
        vm.assume(lenA <= 10000);
        vm.assume(lenB <= 10000);
        address[] memory a = new address[](lenA);
        address[] memory b = new address[](lenB);

        vm.expectEmit(false, false, false, true);
        emit log_named_string("Error", CUSTOM_ERROR);
        vm.expectEmit(false, false, false, true);
        emit log("Error: a == b not satisfied [address[]]");
        t._assertEq(a, b, CUSTOM_ERROR, EXPECT_FAIL);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    ASSERT_EQ(UINT)
    //////////////////////////////////////////////////////////////////////////*/

    function testAssertEqUint() public {
        assertEqUint(uint8(1), uint128(1));
        assertEqUint(uint64(2), uint64(2));
    }

    function testFailAssertEqUint() public {
        assertEqUint(uint64(1), uint96(2));
        assertEqUint(uint160(3), uint160(4));
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    APPROX_EQ_ABS(UINT)
    //////////////////////////////////////////////////////////////////////////*/

    function testAssertApproxEqAbs_Uint_Pass(uint256 a, uint256 b, uint256 maxDelta) external {
        vm.assume(stdMath.delta(a, b) <= maxDelta);

        t._assertApproxEqAbs(a, b, maxDelta, EXPECT_PASS);
    }

    function testAssertApproxEqAbs_Uint_Fail(uint256 a, uint256 b, uint256 maxDelta) external {
        vm.assume(stdMath.delta(a, b) > maxDelta);

        vm.expectEmit(false, false, false, true);
        emit log("Error: a ~= b not satisfied [uint]");
        t._assertApproxEqAbs(a, b, maxDelta, EXPECT_FAIL);
    }

    function testAssertApproxEqAbs_UintErr_Pass(uint256 a, uint256 b, uint256 maxDelta) external {
        vm.assume(stdMath.delta(a, b) <= maxDelta);

        t._assertApproxEqAbs(a, b, maxDelta, CUSTOM_ERROR, EXPECT_PASS);
    }

    function testAssertApproxEqAbs_UintErr_Fail(uint256 a, uint256 b, uint256 maxDelta) external {
        vm.assume(stdMath.delta(a, b) > maxDelta);

        vm.expectEmit(false, false, false, true);
        emit log_named_string("Error", CUSTOM_ERROR);
        t._assertApproxEqAbs(a, b, maxDelta, CUSTOM_ERROR, EXPECT_FAIL);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    APPROX_EQ_ABS(INT)
    //////////////////////////////////////////////////////////////////////////*/

    function testAssertApproxEqAbs_Int_Pass(int256 a, int256 b, uint256 maxDelta) external {
        vm.assume(stdMath.delta(a, b) <= maxDelta);

        t._assertApproxEqAbs(a, b, maxDelta, EXPECT_PASS);
    }

    function testAssertApproxEqAbs_Int_Fail(int256 a, int256 b, uint256 maxDelta) external {
        vm.assume(stdMath.delta(a, b) > maxDelta);

        vm.expectEmit(false, false, false, true);
        emit log("Error: a ~= b not satisfied [int]");
        t._assertApproxEqAbs(a, b, maxDelta, EXPECT_FAIL);
    }

    function testAssertApproxEqAbs_IntErr_Pass(int256 a, int256 b, uint256 maxDelta) external {
        vm.assume(stdMath.delta(a, b) <= maxDelta);

        t._assertApproxEqAbs(a, b, maxDelta, CUSTOM_ERROR, EXPECT_PASS);
    }

    function testAssertApproxEqAbs_IntErr_Fail(int256 a, int256 b, uint256 maxDelta) external {
        vm.assume(stdMath.delta(a, b) > maxDelta);

        vm.expectEmit(false, false, false, true);
        emit log_named_string("Error", CUSTOM_ERROR);
        t._assertApproxEqAbs(a, b, maxDelta, CUSTOM_ERROR, EXPECT_FAIL);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    APPROX_EQ_REL(UINT)
    //////////////////////////////////////////////////////////////////////////*/

    function testAssertApproxEqRel_Uint_Pass(uint256 a, uint256 b, uint256 maxPercentDelta) external {
        vm.assume(a < type(uint128).max && b < type(uint128).max && b != 0);
        vm.assume(stdMath.percentDelta(a, b) <= maxPercentDelta);

        t._assertApproxEqRel(a, b, maxPercentDelta, EXPECT_PASS);
    }

    function testAssertApproxEqRel_Uint_Fail(uint256 a, uint256 b, uint256 maxPercentDelta) external {
        vm.assume(a < type(uint128).max && b < type(uint128).max && b != 0);
        vm.assume(stdMath.percentDelta(a, b) > maxPercentDelta);

        vm.expectEmit(false, false, false, true);
        emit log("Error: a ~= b not satisfied [uint]");
        t._assertApproxEqRel(a, b, maxPercentDelta, EXPECT_FAIL);
    }

    function testAssertApproxEqRel_UintErr_Pass(uint256 a, uint256 b, uint256 maxPercentDelta) external {
        vm.assume(a < type(uint128).max && b < type(uint128).max && b != 0);
        vm.assume(stdMath.percentDelta(a, b) <= maxPercentDelta);

        t._assertApproxEqRel(a, b, maxPercentDelta, CUSTOM_ERROR, EXPECT_PASS);
    }

    function testAssertApproxEqRel_UintErr_Fail(uint256 a, uint256 b, uint256 maxPercentDelta) external {
        vm.assume(a < type(uint128).max && b < type(uint128).max && b != 0);
        vm.assume(stdMath.percentDelta(a, b) > maxPercentDelta);

        vm.expectEmit(false, false, false, true);
        emit log_named_string("Error", CUSTOM_ERROR);
        t._assertApproxEqRel(a, b, maxPercentDelta, CUSTOM_ERROR, EXPECT_FAIL);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    APPROX_EQ_REL(INT)
    //////////////////////////////////////////////////////////////////////////*/

    function testAssertApproxEqRel_Int_Pass(int128 a, int128 b, uint128 maxPercentDelta) external {
        vm.assume(b != 0);
        vm.assume(stdMath.percentDelta(a, b) <= maxPercentDelta);

        t._assertApproxEqRel(a, b, maxPercentDelta, EXPECT_PASS);
    }

    function testAssertApproxEqRel_Int_Fail(int128 a, int128 b, uint128 maxPercentDelta) external {
        vm.assume(b != 0);
        vm.assume(stdMath.percentDelta(a, b) > maxPercentDelta);

        vm.expectEmit(false, false, false, true);
        emit log("Error: a ~= b not satisfied [int]");
        t._assertApproxEqRel(a, b, maxPercentDelta, EXPECT_FAIL);
    }

    function testAssertApproxEqRel_IntErr_Pass(int128 a, int128 b, uint128 maxPercentDelta) external {
        vm.assume(b != 0);
        vm.assume(stdMath.percentDelta(a, b) <= maxPercentDelta);

        t._assertApproxEqRel(a, b, maxPercentDelta, CUSTOM_ERROR, EXPECT_PASS);
    }

    function testAssertApproxEqRel_IntErr_Fail(int128 a, int128 b, uint128 maxPercentDelta) external {
        vm.assume(b != 0);
        vm.assume(stdMath.percentDelta(a, b) > maxPercentDelta);

        vm.expectEmit(false, false, false, true);
        emit log_named_string("Error", CUSTOM_ERROR);
        t._assertApproxEqRel(a, b, maxPercentDelta, CUSTOM_ERROR, EXPECT_FAIL);
    }
}

contract TestTest is Test {
    modifier expectFailure(bool expectFail) {
        bool preState = vm.load(HEVM_ADDRESS, bytes32("failed")) != bytes32(0x00);
        _;
        bool postState = vm.load(HEVM_ADDRESS, bytes32("failed")) != bytes32(0x00);

        if (preState == true) {
            return;
        }

        if (expectFail) {
            require(postState == true, "expected failure not triggered");

            // unwind the expected failure
            vm.store(HEVM_ADDRESS, bytes32("failed"), bytes32(uint256(0x00)));
        } else {
            require(postState == false, "unexpected failure was triggered");
        }
    }

    function _fail(string memory err) external expectFailure(true) {
        fail(err);
    }

    function _assertFalse(bool data, bool expectFail) external expectFailure(expectFail) {
        assertFalse(data);
    }

    function _assertFalse(bool data, string memory err, bool expectFail) external expectFailure(expectFail) {
        assertFalse(data, err);
    }

    function _assertEq(bool a, bool b, bool expectFail) external expectFailure(expectFail) {
        assertEq(a, b);
    }

    function _assertEq(bool a, bool b, string memory err, bool expectFail) external expectFailure(expectFail) {
        assertEq(a, b, err);
    }

    function _assertEq(bytes memory a, bytes memory b, bool expectFail) external expectFailure(expectFail) {
        assertEq(a, b);
    }

    function _assertEq(bytes memory a, bytes memory b, string memory err, bool expectFail)
        external
        expectFailure(expectFail)
    {
        assertEq(a, b, err);
    }

    function _assertEq(uint256[] memory a, uint256[] memory b, bool expectFail) external expectFailure(expectFail) {
        assertEq(a, b);
    }

    function _assertEq(int256[] memory a, int256[] memory b, bool expectFail) external expectFailure(expectFail) {
        assertEq(a, b);
    }

    function _assertEq(address[] memory a, address[] memory b, bool expectFail) external expectFailure(expectFail) {
        assertEq(a, b);
    }

    function _assertEq(uint256[] memory a, uint256[] memory b, string memory err, bool expectFail)
        external
        expectFailure(expectFail)
    {
        assertEq(a, b, err);
    }

    function _assertEq(int256[] memory a, int256[] memory b, string memory err, bool expectFail)
        external
        expectFailure(expectFail)
    {
        assertEq(a, b, err);
    }

    function _assertEq(address[] memory a, address[] memory b, string memory err, bool expectFail)
        external
        expectFailure(expectFail)
    {
        assertEq(a, b, err);
    }

    function _assertApproxEqAbs(uint256 a, uint256 b, uint256 maxDelta, bool expectFail)
        external
        expectFailure(expectFail)
    {
        assertApproxEqAbs(a, b, maxDelta);
    }

    function _assertApproxEqAbs(uint256 a, uint256 b, uint256 maxDelta, string memory err, bool expectFail)
        external
        expectFailure(expectFail)
    {
        assertApproxEqAbs(a, b, maxDelta, err);
    }

    function _assertApproxEqAbs(int256 a, int256 b, uint256 maxDelta, bool expectFail)
        external
        expectFailure(expectFail)
    {
        assertApproxEqAbs(a, b, maxDelta);
    }

    function _assertApproxEqAbs(int256 a, int256 b, uint256 maxDelta, string memory err, bool expectFail)
        external
        expectFailure(expectFail)
    {
        assertApproxEqAbs(a, b, maxDelta, err);
    }

    function _assertApproxEqRel(uint256 a, uint256 b, uint256 maxPercentDelta, bool expectFail)
        external
        expectFailure(expectFail)
    {
        assertApproxEqRel(a, b, maxPercentDelta);
    }

    function _assertApproxEqRel(uint256 a, uint256 b, uint256 maxPercentDelta, string memory err, bool expectFail)
        external
        expectFailure(expectFail)
    {
        assertApproxEqRel(a, b, maxPercentDelta, err);
    }

    function _assertApproxEqRel(int256 a, int256 b, uint256 maxPercentDelta, bool expectFail)
        external
        expectFailure(expectFail)
    {
        assertApproxEqRel(a, b, maxPercentDelta);
    }

    function _assertApproxEqRel(int256 a, int256 b, uint256 maxPercentDelta, string memory err, bool expectFail)
        external
        expectFailure(expectFail)
    {
        assertApproxEqRel(a, b, maxPercentDelta, err);
    }
}
