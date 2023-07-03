---
eip: X
title: Quantum Supremacy Puzzle
author: Nicholas Papadopoulos (@nikojpapa)
discussions-to: 
status: Draft
type: Standards Track
category: ERC
created: 2023-06-26
---

# TODO
- Requires singleton
- Specify sanity solution check
- Show example of submitting solution
- Security considerations

## Abstract

[Quantum supremacy](https://en.wikipedia.org/wiki/Quantum_supremacy) indicates the earliest sign where an adversary can bypass current Etherium cryptography standards. To protect one's funds on Etherium, it would be useful to watch a trigger that activates when quantum supremacy has been achieved.
This ERC serves to show proof of quantum supremacy and trigger quantum-secure signature verification schemes on Etherium assets. Previous attempts have been made to demonstrate quantum supremacy, but they have been invalidated because of problem-tailoring, trapdoors, etc. This contract will prevent any notion of cheating by generating a classically impossible problem on chain, to which even the creator does not know the solution. The contract will be funded with ETH, which can only be retrieved by solving the problem.
Etherium accounts can then using custom verification schemes, such as those based on [ERC-4337](./eip-4337.md), can watch this contract and fall back to a quantum secure signature verification scheme if and when it is solved. 

## Motivation

- Proving quantum supremacy using blockchain verifiable methods
- Defining a point in time when quantum-secure protection of assets should be used

## Specification

### [ERC-X] Quantum Supremacy

> This is an exact copy of the code of the [ERCX quantum supremacy contract].

```solidity
// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "solidity-bytes-utils/contracts/BytesLib.sol";

import "../BigNumbers.sol";
import "../PrimeFactoringBounty.sol";
import "./RsaUfoAccumulator.sol";


/* Using methods based on:
 * - Sander, T. (1999). Efficient Accumulators without Trapdoor Extended Abstract. In: Information and Communication Security, V. Varadharajan and Y. Mu (editors), Second International Conference, ICICS’99, pages 252-262.
 * - https://anoncoin.github.io/RSA_UFO/
 *
 * The number of locks should be log(1-p) / log(1 - 0.16), where p is the probability that at least one lock
 * is difficult to factor.
 */
contract PrimeFactoringBountyWithRsaUfo is RsaUfoAccumulator {
  uint256 iteration;

  constructor(uint256 numberOfLocksInit, uint256 bytesPerPrimeInit)
    RsaUfoAccumulator(numberOfLocksInit, bytesPerPrimeInit) {}

  function triggerLockAccumulation() public {
    require(!generationIsDone, 'Locks have already been generated');
    bytes memory randomNumber = abi.encodePacked(keccak256(abi.encodePacked(block.difficulty, iteration++)));
    accumulate(randomNumber);
  }
}
```

```solidity
// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "solidity-bytes-utils/contracts/BytesLib.sol";
import "../PrimeFactoringBounty.sol";


contract RsaUfoAccumulator is PrimeFactoringBounty {
  bool public generationIsDone;

  uint256 private numberOfLocks;
  uint256 private bytesPerPrime;

  bytes private currentLock;
  uint256 private currentLockNumber;
  uint256 private bytesPerLock;

  constructor(uint256 numberOfLocksInit, uint256 bytesPerPrimeInit) {
    numberOfLocks = numberOfLocksInit;
    bytesPerPrime = bytesPerPrimeInit;

    initLocks(numberOfLocks);
    currentLock = "";
    bytesPerLock = 3 * bytesPerPrime;
  }

  function accumulate(bytes memory randomBytes) internal {
    if (generationIsDone) return;

    uint256 numBytesToAccumulate = Math.min(randomBytes.length, bytesPerLock - currentLock.length);
    bytes memory bytesToAccumulate = BytesLib.slice(randomBytes, 0, numBytesToAccumulate);
    currentLock = BytesLib.concat(currentLock, bytesToAccumulate);

    if (currentLock.length >= bytesPerLock) {
      locks[currentLockNumber] = currentLock;
      ++currentLockNumber;
      currentLock = "";
    }

    if (currentLockNumber >= numberOfLocks) generationIsDone = true;
  }
}
```

```solidity
// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "solidity-bytes-utils/contracts/BytesLib.sol";

import "../BountyContract.sol";
import "./BigNumbers.sol";
import "./miller-rabin/MillerRabin.sol";

abstract contract PrimeFactoringBounty is BountyContract {
  using BigNumbers for *;

  function _verifySolution(uint256 lockNumber, bytes[] memory solution) internal view override returns (bool) {
    BigNumber memory product = BigNumbers.one();
    for (uint256 i = 0; i < solution.length; i++) {
      bytes memory primeFactor = solution[i];
      require(MillerRabin.isPrime(primeFactor), 'Given solution is not prime');
      product = product.mul(primeFactor.init(false));
    }

    BigNumber memory lock = locks[lockNumber].init(false);
    return product.eq(lock);
  }
}
```

```solidity
// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/Address.sol";
import "solidity-bytes-utils/contracts/BytesLib.sol";

abstract contract BountyContract {
  bytes[] public locks;
  bool[] public lockSolvedStatus;
  bool public solved;

  struct Commit {
    bytes solutionHash;
    uint256 timestamp;
  }
  mapping(address => mapping(uint256 => Commit)) private commits;
  uint256 ONE_DAY_IN_SECONDS = 86400;

  modifier requireUnsolved() {
    require(!solved, 'Already solved');
    _;
  }

  function initLocks(uint256 numberOfLocks) internal {
    locks = new bytes[](numberOfLocks);
    lockSolvedStatus = new bool[](numberOfLocks);
  }

  function commitSolution(uint256 lockNumber, bytes memory solutionHash) public requireUnsolved {
    Commit storage commit = commits[msg.sender][lockNumber];
    commit.solutionHash = solutionHash;
    commit.timestamp = block.timestamp;
  }

  function getMyCommit(uint256 lockNumber) public view returns (bytes memory, uint256) {
    Commit storage commit = commits[msg.sender][lockNumber];
    _requireCommitExists(commit);
    return (commit.solutionHash, commit.timestamp);
  }

  function solve(uint256 lockNumber, bytes[] memory solution) public requireUnsolved {
    require(_verifyReveal(lockNumber, solution), "Solution hash doesn't match");
    require(_verifySolution(lockNumber, solution), 'Invalid solution');
    lockSolvedStatus[lockNumber] = true;
    if (_allLocksSolved()) {
      solved = true;
      _sendBountyToSolver();
    }
  }

  function _verifyReveal(uint256 lockNumber, bytes[] memory solution) private view returns (bool) {
    Commit storage commit = commits[msg.sender][lockNumber];
    _requireCommitExists(commit);
    require(block.timestamp - commit.timestamp >= ONE_DAY_IN_SECONDS, 'Cannot reveal within a day of the commit');

    bytes memory solutionEncoding = abi.encode(msg.sender, solution);
    bytes32 solutionHash = keccak256(solutionEncoding);
    return BytesLib.equal(abi.encodePacked(solutionHash), commit.solutionHash);
  }

  function _requireCommitExists(Commit memory commit) private pure {
    require(!BytesLib.equal(commit.solutionHash, ""), 'Not committed yet');
  }

  function _verifySolution(uint256 lockNumber, bytes[] memory solution) internal view virtual returns (bool);

  function _allLocksSolved() private view returns (bool) {
    bool allSolved = true;
    for (uint256 lockNumber = 0; lockNumber < lockSolvedStatus.length; lockNumber++) {
      if (!lockSolvedStatus[lockNumber]) {
        allSolved = false;
        break;
      }
    }
    return allSolved;
  }

  function _sendBountyToSolver() private {
    Address.sendValue(payable(msg.sender), bounty());
  }

  function bounty() public view returns (uint256) {
    return address(this).balance;
  }

  receive() external payable {
    addToBounty();
  }

  fallback() external payable {
    addToBounty();
  }

  function addToBounty() public payable requireUnsolved {
  }
}
```

```solidity
//From https://github.com/firoorg/solidity-BigNumber/blob/ca66e95ec3ef32250b0221076f7a10f0d8529bd8/src/BigNumbers.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

// Definition here allows both the lib and inheriting contracts to use BigNumber directly.
  struct BigNumber {
    bytes val;
    bool neg;
    uint bitlen;
  }

/**
 * @notice BigNumbers library for Solidity.
 */
library BigNumbers {

  /// @notice the value for number 0 of a BigNumber instance.
  bytes constant ZERO = hex"0000000000000000000000000000000000000000000000000000000000000000";
  /// @notice the value for number 1 of a BigNumber instance.
  bytes constant  ONE = hex"0000000000000000000000000000000000000000000000000000000000000001";
  /// @notice the value for number 2 of a BigNumber instance.
  bytes constant  TWO = hex"0000000000000000000000000000000000000000000000000000000000000002";

  // ***************** BEGIN EXPOSED MANAGEMENT FUNCTIONS ******************
  /** @notice verify a BN instance
     *  @dev checks if the BN is in the correct format. operations should only be carried out on
     *       verified BNs, so it is necessary to call this if your function takes an arbitrary BN
     *       as input.
     *
     *  @param bn BigNumber instance
     */
  function verify(
    BigNumber memory bn
  ) internal pure {
    uint msword;
    bytes memory val = bn.val;
    assembly {msword := mload(add(val,0x20))} //get msword of result
    if(msword==0) require(isZero(bn));
    else require((bn.val.length % 32 == 0) && (msword>>((bn.bitlen%256)-1)==1));
  }

  /** @notice initialize a BN instance
     *  @dev wrapper function for _init. initializes from bytes value.
     *       Allows passing bitLength of value. This is NOT verified in the internal function. Only use where bitlen is
     *       explicitly known; otherwise use the other init function.
     *
     *  @param val BN value. may be of any size.
     *  @param neg neg whether the BN is +/-
     *  @param bitlen bit length of output.
     *  @return BigNumber instance
     */
  function init(
    bytes memory val,
    bool neg,
    uint bitlen
  ) internal view returns(BigNumber memory){
    return _init(val, neg, bitlen);
  }

  /** @notice initialize a BN instance
     *  @dev wrapper function for _init. initializes from bytes value.
     *
     *  @param val BN value. may be of any size.
     *  @param neg neg whether the BN is +/-
     *  @return BigNumber instance
     */
  function init(
    bytes memory val,
    bool neg
  ) internal view returns(BigNumber memory){
    return _init(val, neg, 0);
  }

  /** @notice initialize a BN instance
     *  @dev wrapper function for _init. initializes from uint value (converts to bytes);
     *       tf. resulting BN is in the range -2^256-1 ... 2^256-1.
     *
     *  @param val uint value.
     *  @param neg neg whether the BN is +/-
     *  @return BigNumber instance
     */
  function init(
    uint val,
    bool neg
  ) internal view returns(BigNumber memory){
    return _init(abi.encodePacked(val), neg, 0);
  }
  // ***************** END EXPOSED MANAGEMENT FUNCTIONS ******************




  // ***************** BEGIN EXPOSED CORE CALCULATION FUNCTIONS ******************
  /** @notice BigNumber addition: a + b.
      * @dev add: Initially prepare BigNumbers for addition operation; internally calls actual addition/subtraction,
      *           depending on inputs.
      *           In order to do correct addition or subtraction we have to handle the sign.
      *           This function discovers the sign of the result based on the inputs, and calls the correct operation.
      *
      * @param a first BN
      * @param b second BN
      * @return r result  - addition of a and b.
      */
  function add(
    BigNumber memory a,
    BigNumber memory b
  ) internal pure returns(BigNumber memory r) {
    if(a.bitlen==0 && b.bitlen==0) return zero();
    if(a.bitlen==0) return b;
    if(b.bitlen==0) return a;
    bytes memory val;
    uint bitlen;
    int compare = cmp(a,b,false);

    if(a.neg || b.neg){
      if(a.neg && b.neg){
        if(compare>=0) (val, bitlen) = _add(a.val,b.val,a.bitlen);
        else (val, bitlen) = _add(b.val,a.val,b.bitlen);
        r.neg = true;
      }
      else {
        if(compare==1){
          (val, bitlen) = _sub(a.val,b.val);
          r.neg = a.neg;
        }
        else if(compare==-1){
          (val, bitlen) = _sub(b.val,a.val);
          r.neg = !a.neg;
        }
        else return zero();//one pos and one neg, and same value.
      }
    }
    else{
      if(compare>=0){ // a>=b
        (val, bitlen) = _add(a.val,b.val,a.bitlen);
      }
      else {
        (val, bitlen) = _add(b.val,a.val,b.bitlen);
      }
      r.neg = false;
    }

    r.val = val;
    r.bitlen = (bitlen);
  }

  /** @notice BigNumber subtraction: a - b.
      * @dev sub: Initially prepare BigNumbers for subtraction operation; internally calls actual addition/subtraction,
                  depending on inputs.
      *           In order to do correct addition or subtraction we have to handle the sign.
      *           This function discovers the sign of the result based on the inputs, and calls the correct operation.
      *
      * @param a first BN
      * @param b second BN
      * @return r result - subtraction of a and b.
      */
  function sub(
    BigNumber memory a,
    BigNumber memory b
  ) internal pure returns(BigNumber memory r) {
    if(a.bitlen==0 && b.bitlen==0) return zero();
    bytes memory val;
    int compare;
    uint bitlen;
    compare = cmp(a,b,false);
    if(a.neg || b.neg) {
      if(a.neg && b.neg){
        if(compare == 1) {
          (val,bitlen) = _sub(a.val,b.val);
          r.neg = true;
        }
        else if(compare == -1) {

          (val,bitlen) = _sub(b.val,a.val);
          r.neg = false;
        }
        else return zero();
      }
      else {
        if(compare >= 0) (val,bitlen) = _add(a.val,b.val,a.bitlen);
        else (val,bitlen) = _add(b.val,a.val,b.bitlen);

        r.neg = (a.neg) ? true : false;
      }
    }
    else {
      if(compare == 1) {
        (val,bitlen) = _sub(a.val,b.val);
        r.neg = false;
      }
      else if(compare == -1) {
        (val,bitlen) = _sub(b.val,a.val);
        r.neg = true;
      }
      else return zero();
    }

    r.val = val;
    r.bitlen = (bitlen);
  }

  /** @notice BigNumber multiplication: a * b.
      * @dev mul: takes two BigNumbers and multiplys them. Order is irrelevant.
      *              multiplication achieved using modexp precompile:
      *                 (a * b) = ((a + b)**2 - (a - b)**2) / 4
      *
      * @param a first BN
      * @param b second BN
      * @return r result - multiplication of a and b.
      */
  function mul(
    BigNumber memory a,
    BigNumber memory b
  ) internal view returns(BigNumber memory r){

    BigNumber memory lhs = add(a,b);
    BigNumber memory fst = modexp(lhs, two(), _powModulus(lhs, 2)); // (a+b)^2

    // no need to do subtraction part of the equation if a == b; if so, it has no effect on final result.
    if(!eq(a,b)) {
      BigNumber memory rhs = sub(a,b);
      BigNumber memory snd = modexp(rhs, two(), _powModulus(rhs, 2)); // (a-b)^2
      r = _shr(sub(fst, snd) , 2); // (a * b) = (((a + b)**2 - (a - b)**2) / 4
    }
    else {
      r = _shr(fst, 2); // a==b ? (((a + b)**2 / 4
    }
  }

  /** @notice BigNumber division verification: a * b.
      * @dev div: takes three BigNumbers (a,b and result), and verifies that a/b == result.
      * Performing BigNumber division on-chain is a significantly expensive operation. As a result,
      * we expose the ability to verify the result of a division operation, which is a constant time operation.
      *              (a/b = result) == (a = b * result)
      *              Integer division only; therefore:
      *                verify ((b*result) + (a % (b*result))) == a.
      *              eg. 17/7 == 2:
      *                verify  (7*2) + (17 % (7*2)) == 17.
      * The function returns a bool on successful verification. The require statements will ensure that false can never
      *  be returned, however inheriting contracts may also want to put this function inside a require statement.
      *
      * @param a first BigNumber
      * @param b second BigNumber
      * @param r result BigNumber
      * @return bool whether or not the operation was verified
      */
  function divVerify(
    BigNumber memory a,
    BigNumber memory b,
    BigNumber memory r
  ) internal view returns(bool) {

    // first do zero check.
    // if a<b (always zero) and r==zero (input check), return true.
    if(cmp(a, b, false) == -1){
      require(cmp(zero(), r, false)==0);
      return true;
    }

    // Following zero check:
    //if both negative: result positive
    //if one negative: result negative
    //if neither negative: result positive
    bool positiveResult = ( a.neg && b.neg ) || (!a.neg && !b.neg);
    require(positiveResult ? !r.neg : r.neg);

    // require denominator to not be zero.
    require(!(cmp(b,zero(),true)==0));

    // division result check assumes inputs are positive.
    // we have already checked for result sign so this is safe.
    bool[3] memory negs = [a.neg, b.neg, r.neg];
    a.neg = false;
    b.neg = false;
    r.neg = false;

    // do multiplication (b * r)
    BigNumber memory fst = mul(b,r);
    // check if we already have 'a' (ie. no remainder after division). if so, no mod necessary, and return true.
    if(cmp(fst,a,true)==0) return true;
    //a mod (b*r)
    BigNumber memory snd = modexp(a,one(),fst);
    // ((b*r) + a % (b*r)) == a
    require(cmp(add(fst,snd),a,true)==0);

    a.neg = negs[0];
    b.neg = negs[1];
    r.neg = negs[2];

    return true;
  }

  /** @notice BigNumber exponentiation: a ^ b.
      * @dev pow: takes a BigNumber and a uint (a,e), and calculates a^e.
      * modexp precompile is used to achieve a^e; for this is work, we need to work out the minimum modulus value
      * such that the modulus passed to modexp is not used. the result of a^e can never be more than size bitlen(a) * e.
      *
      * @param a BigNumber
      * @param e exponent
      * @return r result BigNumber
      */
  function pow(
    BigNumber memory a,
    uint e
  ) internal view returns(BigNumber memory){
    return modexp(a, init(e, false), _powModulus(a, e));
  }

  /** @notice BigNumber modulus: a % n.
      * @dev mod: takes a BigNumber and modulus BigNumber (a,n), and calculates a % n.
      * modexp precompile is used to achieve a % n; an exponent of value '1' is passed.
      * @param a BigNumber
      * @param n modulus BigNumber
      * @return r result BigNumber
      */
  function mod(
    BigNumber memory a,
    BigNumber memory n
  ) internal view returns(BigNumber memory){
    return modexp(a,one(),n);
  }

  /** @notice BigNumber modular exponentiation: a^e mod n.
      * @dev modexp: takes base, exponent, and modulus, internally computes base^exponent % modulus using the precompile at address 0x5, and creates new BigNumber.
      *              this function is overloaded: it assumes the exponent is positive. if not, the other method is used, whereby the inverse of the base is also passed.
      *
      * @param a base BigNumber
      * @param e exponent BigNumber
      * @param n modulus BigNumber
      * @return result BigNumber
      */
  function modexp(
    BigNumber memory a,
    BigNumber memory e,
    BigNumber memory n
  ) internal view returns(BigNumber memory) {
    //if exponent is negative, other method with this same name should be used.
    //if modulus is negative or zero, we cannot perform the operation.
    require(  e.neg==false
    && n.neg==false
    && !isZero(n.val));

    bytes memory _result = _modexp(a.val,e.val,n.val);
    //get bitlen of result (TODO: optimise. we know bitlen is in the same byte as the modulus bitlen byte)
    uint bitlen = bitLength(_result);

    // if result is 0, immediately return.
    if(bitlen == 0) return zero();
    // if base is negative AND exponent is odd, base^exp is negative, and tf. result is negative;
    // in that case we make the result positive by adding the modulus.
    if(a.neg && isOdd(e)) return add(BigNumber(_result, true, bitlen), n);
    // in any other case we return the positive result.
    return BigNumber(_result, false, bitlen);
  }

  /** @notice BigNumber modular exponentiation with negative base: inv(a)==a_inv && a_inv^e mod n.
    /** @dev modexp: takes base, base inverse, exponent, and modulus, asserts inverse(base)==base inverse,
      *              internally computes base_inverse^exponent % modulus and creates new BigNumber.
      *              this function is overloaded: it assumes the exponent is negative.
      *              if not, the other method is used, where the inverse of the base is not passed.
      *
      * @param a base BigNumber
      * @param ai base inverse BigNumber
      * @param e exponent BigNumber
      * @param a modulus
      * @return BigNumber memory result.
      */
  function modexp(
    BigNumber memory a,
    BigNumber memory ai,
    BigNumber memory e,
    BigNumber memory n)
  internal view returns(BigNumber memory) {
    // base^-exp = (base^-1)^exp
    require(!a.neg && e.neg);

    //if modulus is negative or zero, we cannot perform the operation.
    require(!n.neg && !isZero(n.val));

    //base_inverse == inverse(base, modulus)
    require(modinvVerify(a, n, ai));

    bytes memory _result = _modexp(ai.val,e.val,n.val);
    //get bitlen of result (TODO: optimise. we know bitlen is in the same byte as the modulus bitlen byte)
    uint bitlen = bitLength(_result);

    // if result is 0, immediately return.
    if(bitlen == 0) return zero();
    // if base_inverse is negative AND exponent is odd, base_inverse^exp is negative, and tf. result is negative;
    // in that case we make the result positive by adding the modulus.
    if(ai.neg && isOdd(e)) return add(BigNumber(_result, true, bitlen), n);
    // in any other case we return the positive result.
    return BigNumber(_result, false, bitlen);
  }

  /** @notice modular multiplication: (a*b) % n.
      * @dev modmul: Takes BigNumbers for a, b, and modulus, and computes (a*b) % modulus
      *              We call mul for the two input values, before calling modexp, passing exponent as 1.
      *              Sign is taken care of in sub-functions.
      *
      * @param a BigNumber
      * @param b BigNumber
      * @param n Modulus BigNumber
      * @return result BigNumber
      */
  function modmul(
    BigNumber memory a,
    BigNumber memory b,
    BigNumber memory n) internal view returns(BigNumber memory) {
    return mod(mul(a,b), n);
  }

  /** @notice modular inverse verification: Verifies that (a*r) % n == 1.
      * @dev modinvVerify: Takes BigNumbers for base, modulus, and result, verifies (base*result)%modulus==1, and returns result.
      *              Similar to division, it's far cheaper to verify an inverse operation on-chain than it is to calculate it, so we allow the user to pass their own result.
      *
      * @param a base BigNumber
      * @param n modulus BigNumber
      * @param r result BigNumber
      * @return boolean result
      */
  function modinvVerify(
    BigNumber memory a,
    BigNumber memory n,
    BigNumber memory r
  ) internal view returns(bool) {
    require(!a.neg && !n.neg); //assert positivity of inputs.
    /*
     * the following proves:
     * - user result passed is correct for values base and modulus
     * - modular inverse exists for values base and modulus.
     * otherwise it fails.
     */
    require(cmp(modmul(a, r, n),one(),true)==0);

    return true;
  }
  // ***************** END EXPOSED CORE CALCULATION FUNCTIONS ******************




  // ***************** START EXPOSED HELPER FUNCTIONS ******************
  /** @notice BigNumber odd number check
      * @dev isOdd: returns 1 if BigNumber value is an odd number and 0 otherwise.
      *
      * @param a BigNumber
      * @return r Boolean result
      */
  function isOdd(
    BigNumber memory a
  ) internal pure returns(bool r){
    assembly{
      let a_ptr := add(mload(a), mload(mload(a))) // go to least significant word
      r := mod(mload(a_ptr),2)                      // mod it with 2 (returns 0 or 1)
    }
  }

  /** @notice BigNumber comparison
      * @dev cmp: Compares BigNumbers a and b. 'signed' parameter indiciates whether to consider the sign of the inputs.
      *           'trigger' is used to decide this -
      *              if both negative, invert the result;
      *              if both positive (or signed==false), trigger has no effect;
      *              if differing signs, we return immediately based on input.
      *           returns -1 on a<b, 0 on a==b, 1 on a>b.
      *
      * @param a BigNumber
      * @param b BigNumber
      * @param signed whether to consider sign of inputs
      * @return int result
      */
  function cmp(
    BigNumber memory a,
    BigNumber memory b,
    bool signed
  ) internal pure returns(int){
    int trigger = 1;
    if(signed){
      if(a.neg && b.neg) trigger = -1;
      else if(a.neg==false && b.neg==true) return 1;
      else if(a.neg==true && b.neg==false) return -1;
    }

    if(a.bitlen>b.bitlen) return    trigger;   // 1*trigger
    if(b.bitlen>a.bitlen) return -1*trigger;

    uint a_ptr;
    uint b_ptr;
    uint a_word;
    uint b_word;

    uint len = a.val.length; //bitlen is same so no need to check length.

    assembly{
      a_ptr := add(mload(a),0x20)
      b_ptr := add(mload(b),0x20)
    }

    for(uint i=0; i<len;i+=32){
      assembly{
        a_word := mload(add(a_ptr,i))
        b_word := mload(add(b_ptr,i))
      }

      if(a_word>b_word) return    trigger; // 1*trigger
      if(b_word>a_word) return -1*trigger;

    }

    return 0; //same value.
  }

  /** @notice BigNumber equality
      * @dev eq: returns true if a==b. sign always considered.
      *
      * @param a BigNumber
      * @param b BigNumber
      * @return boolean result
      */
  function eq(
    BigNumber memory a,
    BigNumber memory b
  ) internal pure returns(bool){
    int result = cmp(a, b, true);
    return (result==0) ? true : false;
  }

  /** @notice BigNumber greater than
      * @dev eq: returns true if a>b. sign always considered.
      *
      * @param a BigNumber
      * @param b BigNumber
      * @return boolean result
      */
  function gt(
    BigNumber memory a,
    BigNumber memory b
  ) internal pure returns(bool){
    int result = cmp(a, b, true);
    return (result==1) ? true : false;
  }

  /** @notice BigNumber greater than or equal to
      * @dev eq: returns true if a>=b. sign always considered.
      *
      * @param a BigNumber
      * @param b BigNumber
      * @return boolean result
      */
  function gte(
    BigNumber memory a,
    BigNumber memory b
  ) internal pure returns(bool){
    int result = cmp(a, b, true);
    return (result==1 || result==0) ? true : false;
  }

  /** @notice BigNumber less than
      * @dev eq: returns true if a<b. sign always considered.
      *
      * @param a BigNumber
      * @param b BigNumber
      * @return boolean result
      */
  function lt(
    BigNumber memory a,
    BigNumber memory b
  ) internal pure returns(bool){
    int result = cmp(a, b, true);
    return (result==-1) ? true : false;
  }

  /** @notice BigNumber less than or equal o
      * @dev eq: returns true if a<=b. sign always considered.
      *
      * @param a BigNumber
      * @param b BigNumber
      * @return boolean result
      */
  function lte(
    BigNumber memory a,
    BigNumber memory b
  ) internal pure returns(bool){
    int result = cmp(a, b, true);
    return (result==-1 || result==0) ? true : false;
  }

  /** @notice right shift BigNumber value
      * @dev shr: right shift BigNumber a by 'bits' bits.
             copies input value to new memory location before shift and calls _shr function after.
      * @param a BigNumber value to shift
      * @param bits amount of bits to shift by
      * @return result BigNumber
      */
  function shr(
    BigNumber memory a,
    uint bits
  ) internal view returns(BigNumber memory){
    require(!a.neg);
    return _shr(a, bits);
  }

  /** @notice right shift BigNumber memory 'dividend' by 'bits' bits.
      * @dev _shr: Shifts input value in-place, ie. does not create new memory. shr function does this.
      * right shift does not necessarily have to copy into a new memory location. where the user wishes the modify
      * the existing value they have in place, they can use this.
      * @param bn value to shift
      * @param bits amount of bits to shift by
      * @return r result
      */
  function _shr(BigNumber memory bn, uint bits) internal view returns(BigNumber memory){
    uint length;
    assembly { length := mload(mload(bn)) }

    // if bits is >= the bitlength of the value the result is always 0
    if(bits >= bn.bitlen) return BigNumber(ZERO,false,0);

    // set bitlen initially as we will be potentially modifying 'bits'
    bn.bitlen = bn.bitlen-(bits);

    // handle shifts greater than 256:
    // if bits is greater than 256 we can simply remove any trailing words, by altering the BN length.
    // we also update 'bits' so that it is now in the range 0..256.
    assembly {
      if or(gt(bits, 0x100), eq(bits, 0x100)) {
        length := sub(length, mul(div(bits, 0x100), 0x20))
        mstore(mload(bn), length)
        bits := mod(bits, 0x100)
      }

    // if bits is multiple of 8 (byte size), we can simply use identity precompile for cheap memcopy.
    // otherwise we shift each word, starting at the least signifcant word, one-by-one using the mask technique.
    // TODO it is possible to do this without the last two operations, see SHL identity copy.
      let bn_val_ptr := mload(bn)
      switch eq(mod(bits, 8), 0)
      case 1 {
        let bytes_shift := div(bits, 8)
        let in          := mload(bn)
        let inlength    := mload(in)
        let insize      := add(inlength, 0x20)
        let out         := add(in,     bytes_shift)
        let outsize     := sub(insize, bytes_shift)
        let success     := staticcall(450, 0x4, in, insize, out, insize)
        mstore8(add(out, 0x1f), 0) // maintain our BN layout following identity call:
        mstore(in, inlength)         // set current length byte to 0, and reset old length.
      }
      default {
        let mask
        let lsw
        let mask_shift := sub(0x100, bits)
        let lsw_ptr := add(bn_val_ptr, length)
        for { let i := length } eq(eq(i,0),0) { i := sub(i, 0x20) } { // for(int i=max_length; i!=0; i-=32)
          switch eq(i,0x20)                                         // if i==32:
          case 1 { mask := 0 }                                  //    - handles lsword: no mask needed.
          default { mask := mload(sub(lsw_ptr,0x20)) }          //    - else get mask (previous word)
          lsw := shr(bits, mload(lsw_ptr))                          // right shift current by bits
          mask := shl(mask_shift, mask)                             // left shift next significant word by mask_shift
          mstore(lsw_ptr, or(lsw,mask))                             // store OR'd mask and shifted bits in-place
          lsw_ptr := sub(lsw_ptr, 0x20)                             // point to next bits.
        }
      }

    // The following removes the leading word containing all zeroes in the result should it exist,
    // as well as updating lengths and pointers as necessary.
      let msw_ptr := add(bn_val_ptr,0x20)
      switch eq(mload(msw_ptr), 0)
      case 1 {
        mstore(msw_ptr, sub(mload(bn_val_ptr), 0x20)) // store new length in new position
        mstore(bn, msw_ptr)                           // update pointer from bn
      }
      default {}
    }


    return bn;
  }

  /** @notice left shift BigNumber value
      * @dev shr: left shift BigNumber a by 'bits' bits.
                  ensures the value is not negative before calling the private function.
      * @param a BigNumber value to shift
      * @param bits amount of bits to shift by
      * @return result BigNumber
      */
  function shl(
    BigNumber memory a,
    uint bits
  ) internal view returns(BigNumber memory){
    require(!a.neg);
    return _shl(a, bits);
  }

  /** @notice sha3 hash a BigNumber.
      * @dev hash: takes a BigNumber and performs sha3 hash on it.
      *            we hash each BigNumber WITHOUT it's first word - first word is a pointer to the start of the bytes value,
      *            and so is different for each struct.
      *
      * @param a BigNumber
      * @return h bytes32 hash.
      */
  function hash(
    BigNumber memory a
  ) internal pure returns(bytes32 h) {
    //amount of words to hash = all words of the value and three extra words: neg, bitlen & value length.
    assembly {
      h := keccak256( add(a,0x20), add (mload(mload(a)), 0x60 ) )
    }
  }

  /** @notice BigNumber full zero check
      * @dev isZero: checks if the BigNumber is in the default zero format for BNs (ie. the result from zero()).
      *
      * @param a BigNumber
      * @return boolean result.
      */
  function isZero(
    BigNumber memory a
  ) internal pure returns(bool) {
    return isZero(a.val) && a.val.length==0x20 && !a.neg && a.bitlen == 0;
  }


  /** @notice bytes zero check
      * @dev isZero: checks if input bytes value resolves to zero.
      *
      * @param a bytes value
      * @return boolean result.
      */
  function isZero(
    bytes memory a
  ) internal pure returns(bool) {
    uint msword;
    uint msword_ptr;
    assembly {
      msword_ptr := add(a,0x20)
    }
    for(uint i=0; i<a.length; i+=32) {
      assembly { msword := mload(msword_ptr) } // get msword of input
      if(msword > 0) return false;
      assembly { msword_ptr := add(msword_ptr, 0x20) }
    }
    return true;

  }

  /** @notice BigNumber value bit length
      * @dev bitLength: returns BigNumber value bit length- ie. log2 (most significant bit of value)
      *
      * @param a BigNumber
      * @return uint bit length result.
      */
  function bitLength(
    BigNumber memory a
  ) internal pure returns(uint){
    return bitLength(a.val);
  }

  /** @notice bytes bit length
      * @dev bitLength: returns bytes bit length- ie. log2 (most significant bit of value)
      *
      * @param a bytes value
      * @return r uint bit length result.
      */
  function bitLength(
    bytes memory a
  ) internal pure returns(uint r){
    if(isZero(a)) return 0;
    uint msword;
    assembly {
      msword := mload(add(a,0x20))               // get msword of input
    }
    r = bitLength(msword);                         // get bitlen of msword, add to size of remaining words.
    assembly {
      r := add(r, mul(sub(mload(a), 0x20) , 8))  // res += (val.length-32)*8;
    }
  }

  /** @notice uint bit length
        @dev bitLength: get the bit length of a uint input - ie. log2 (most significant bit of 256 bit value (one EVM word))
      *                       credit: Tjaden Hess @ ethereum.stackexchange
      * @param a uint value
      * @return r uint bit length result.
      */
  function bitLength(
    uint a
  ) internal pure returns (uint r){
    assembly {
      switch eq(a, 0)
      case 1 {
        r := 0
      }
      default {
        let arg := a
        a := sub(a,1)
        a := or(a, div(a, 0x02))
        a := or(a, div(a, 0x04))
        a := or(a, div(a, 0x10))
        a := or(a, div(a, 0x100))
        a := or(a, div(a, 0x10000))
        a := or(a, div(a, 0x100000000))
        a := or(a, div(a, 0x10000000000000000))
        a := or(a, div(a, 0x100000000000000000000000000000000))
        a := add(a, 1)
        let m := mload(0x40)
        mstore(m,           0xf8f9cbfae6cc78fbefe7cdc3a1793dfcf4f0e8bbd8cec470b6a28a7a5a3e1efd)
        mstore(add(m,0x20), 0xf5ecf1b3e9debc68e1d9cfabc5997135bfb7a7a3938b7b606b5b4b3f2f1f0ffe)
        mstore(add(m,0x40), 0xf6e4ed9ff2d6b458eadcdf97bd91692de2d4da8fd2d0ac50c6ae9a8272523616)
        mstore(add(m,0x60), 0xc8c0b887b0a8a4489c948c7f847c6125746c645c544c444038302820181008ff)
        mstore(add(m,0x80), 0xf7cae577eec2a03cf3bad76fb589591debb2dd67e0aa9834bea6925f6a4a2e0e)
        mstore(add(m,0xa0), 0xe39ed557db96902cd38ed14fad815115c786af479b7e83247363534337271707)
        mstore(add(m,0xc0), 0xc976c13bb96e881cb166a933a55e490d9d56952b8d4e801485467d2362422606)
        mstore(add(m,0xe0), 0x753a6d1b65325d0c552a4d1345224105391a310b29122104190a110309020100)
        mstore(0x40, add(m, 0x100))
        let magic := 0x818283848586878898a8b8c8d8e8f929395969799a9b9d9e9faaeb6bedeeff
        let shift := 0x100000000000000000000000000000000000000000000000000000000000000
        let _a := div(mul(a, magic), shift)
        r := div(mload(add(m,sub(255,_a))), shift)
        r := add(r, mul(256, gt(arg, 0x8000000000000000000000000000000000000000000000000000000000000000)))
      // where a is a power of two, result needs to be incremented. we use the power of two trick here: if(arg & arg-1 == 0) ++r;
        if eq(and(arg, sub(arg, 1)), 0) {
          r := add(r, 1)
        }
      }
    }
  }

  /** @notice BigNumber zero value
        @dev zero: returns zero encoded as a BigNumber
      * @return zero encoded as BigNumber
      */
  function zero(
  ) internal pure returns(BigNumber memory) {
    return BigNumber(ZERO, false, 0);
  }

  /** @notice BigNumber one value
        @dev one: returns one encoded as a BigNumber
      * @return one encoded as BigNumber
      */
  function one(
  ) internal pure returns(BigNumber memory) {
    return BigNumber(ONE, false, 1);
  }

  /** @notice BigNumber two value
        @dev two: returns two encoded as a BigNumber
      * @return two encoded as BigNumber
      */
  function two(
  ) internal pure returns(BigNumber memory) {
    return BigNumber(TWO, false, 2);
  }
  // ***************** END EXPOSED HELPER FUNCTIONS ******************





  // ***************** START PRIVATE MANAGEMENT FUNCTIONS ******************
  /** @notice Create a new BigNumber.
        @dev init: overloading allows caller to obtionally pass bitlen where it is known - as it is cheaper to do off-chain and verify on-chain.
      *            we assert input is in data structure as defined above, and that bitlen, if passed, is correct.
      *            'copy' parameter indicates whether or not to copy the contents of val to a new location in memory (for example where you pass
      *            the contents of another variable's value in)
      * @param val bytes - bignum value.
      * @param neg bool - sign of value
      * @param bitlen uint - bit length of value
      * @return r BigNumber initialized value.
      */
  function _init(
    bytes memory val,
    bool neg,
    uint bitlen
  ) private view returns(BigNumber memory r){
    // use identity at location 0x4 for cheap memcpy.
    // grab contents of val, load starting from memory end, update memory end pointer.
    assembly {
      let data := add(val, 0x20)
      let length := mload(val)
      let out
      let freemem := msize()
      switch eq(mod(length, 0x20), 0)                       // if(val.length % 32 == 0)
      case 1 {
        out     := add(freemem, 0x20)                 // freememory location + length word
        mstore(freemem, length)                       // set new length
      }
      default {
        let offset  := sub(0x20, mod(length, 0x20))   // offset: 32 - (length % 32)
        out     := add(add(freemem, offset), 0x20)    // freememory location + offset + length word
        mstore(freemem, add(length, offset))          // set new length
      }
      pop(staticcall(450, 0x4, data, length, out, length))  // copy into 'out' memory location
      mstore(0x40, add(freemem, add(mload(freemem), 0x20))) // update the free memory pointer

    // handle leading zero words. assume freemem is pointer to bytes value
      let bn_length := mload(freemem)
      for { } eq ( eq(bn_length, 0x20), 0) { } {            // for(; length!=32; length-=32)
        switch eq(mload(add(freemem, 0x20)),0)               // if(msword==0):
        case 1 { freemem := add(freemem, 0x20) }      //     update length pointer
        default { break }                             // else: loop termination. non-zero word found
        bn_length := sub(bn_length,0x20)
      }
      mstore(freemem, bn_length)

      mstore(r, freemem)                                    // store new bytes value in r
      mstore(add(r, 0x20), neg)                             // store neg value in r
    }

    r.bitlen = bitlen == 0 ? bitLength(r.val) : bitlen;
  }
  // ***************** END PRIVATE MANAGEMENT FUNCTIONS ******************





  // ***************** START PRIVATE CORE CALCULATION FUNCTIONS ******************
  /** @notice takes two BigNumber memory values and the bitlen of the max value, and adds them.
      * @dev _add: This function is private and only callable from add: therefore the values may be of different sizes,
      *            in any order of size, and of different signs (handled in add).
      *            As values may be of different sizes, inputs are considered starting from the least significant
      *            words, working back.
      *            The function calculates the new bitlen (basically if bitlens are the same for max and min,
      *            max_bitlen++) and returns a new BigNumber memory value.
      *
      * @param max bytes -  biggest value  (determined from add)
      * @param min bytes -  smallest value (determined from add)
      * @param max_bitlen uint - bit length of max value.
      * @return bytes result - max + min.
      * @return uint - bit length of result.
      */
  function _add(
    bytes memory max,
    bytes memory min,
    uint max_bitlen
  ) private pure returns (bytes memory, uint) {
    bytes memory result;
    assembly {

      let result_start := msize()                                       // Get the highest available block of memory
      let carry := 0
      let uint_max := sub(0,1)

      let max_ptr := add(max, mload(max))
      let min_ptr := add(min, mload(min))                               // point to last word of each byte array.

      let result_ptr := add(add(result_start,0x20), mload(max))         // set result_ptr end.

      for { let i := mload(max) } eq(eq(i,0),0) { i := sub(i, 0x20) } { // for(int i=max_length; i!=0; i-=32)
        let max_val := mload(max_ptr)                                 // get next word for 'max'
        switch gt(i,sub(mload(max),mload(min)))                       // if(i>(max_length-min_length)). while
        // 'min' words are still available.
        case 1{
          let min_val := mload(min_ptr)                         //      get next word for 'min'
          mstore(result_ptr, add(add(max_val,min_val),carry))   //      result_word = max_word+min_word+carry
          switch gt(max_val, sub(uint_max,sub(min_val,carry)))  //      this switch block finds whether or
          //      not to set the carry bit for the
          //      next iteration.
          case 1  { carry := 1 }
          default {
            switch and(eq(max_val,uint_max),or(gt(carry,0), gt(min_val,0)))
            case 1 { carry := 1 }
            default{ carry := 0 }
          }

          min_ptr := sub(min_ptr,0x20)                       //       point to next 'min' word
        }
        default{                                               // else: remainder after 'min' words are complete.
          mstore(result_ptr, add(max_val,carry))             //       result_word = max_word+carry

          switch and( eq(uint_max,max_val), eq(carry,1) )    //       this switch block finds whether or
          //       not to set the carry bit for the
          //       next iteration.
          case 1  { carry := 1 }
          default { carry := 0 }
        }
        result_ptr := sub(result_ptr,0x20)                         // point to next 'result' word
        max_ptr := sub(max_ptr,0x20)                               // point to next 'max' word
      }

      switch eq(carry,0)
      case 1{ result_start := add(result_start,0x20) }           // if carry is 0, increment result_start, ie.
      // length word for result is now one word
      // position ahead.
      default { mstore(result_ptr, 1) }                          // else if carry is 1, store 1; overflow has
    // occured, so length word remains in the
    // same position.

      result := result_start                                         // point 'result' bytes value to the correct
    // address in memory.
      mstore(result,add(mload(max),mul(0x20,carry)))                 // store length of result. we are finished
    // with the byte array.

      mstore(0x40, add(result,add(mload(result),0x20)))              // Update freemem pointer to point to new
    // end of memory.

    // we now calculate the result's bit length.
    // with addition, if we assume that some a is at least equal to some b, then the resulting bit length will
    // be a's bit length or (a's bit length)+1, depending on carry bit.this is cheaper than calling bitLength.
      let msword := mload(add(result,0x20))                             // get most significant word of result
    // if(msword==1 || msword>>(max_bitlen % 256)==1):
      if or( eq(msword, 1), eq(shr(mod(max_bitlen,256),msword),1) ) {
        max_bitlen := add(max_bitlen, 1)                          // if msword's bit length is 1 greater
      // than max_bitlen, OR overflow occured,
      // new bitlen is max_bitlen+1.
      }
    }


    return (result, max_bitlen);
  }

  /** @notice takes two BigNumber memory values and subtracts them.
      * @dev _sub: This function is private and only callable from add: therefore the values may be of different sizes,
      *            in any order of size, and of different signs (handled in add).
      *            As values may be of different sizes, inputs are considered starting from the least significant words,
      *            working back.
      *            The function calculates the new bitlen (basically if bitlens are the same for max and min,
      *            max_bitlen++) and returns a new BigNumber memory value.
      *
      * @param max bytes -  biggest value  (determined from add)
      * @param min bytes -  smallest value (determined from add)
      * @return bytes result - max + min.
      * @return uint - bit length of result.
      */
  function _sub(
    bytes memory max,
    bytes memory min
  ) internal pure returns (bytes memory, uint) {
    bytes memory result;
    uint carry = 0;
    uint uint_max = type(uint256).max;
    assembly {

      let result_start := msize()                                       // Get the highest available block of memory
      let max_len := mload(max)
      let min_len := mload(min)                                       // load lengths of inputs

      let len_diff := sub(max_len,min_len)                            // get differences in lengths.

      let max_ptr := add(max, max_len)
      let min_ptr := add(min, min_len)                                // go to end of arrays
      let result_ptr := add(result_start, max_len)                    // point to least significant result
    // word.
      let memory_end := add(result_ptr,0x20)                          // save memory_end to update free memory
    // pointer at the end.

      for { let i := max_len } eq(eq(i,0),0) { i := sub(i, 0x20) } {  // for(int i=max_length; i!=0; i-=32)
        let max_val := mload(max_ptr)                               // get next word for 'max'
        switch gt(i,len_diff)                                       // if(i>(max_length-min_length)). while
        // 'min' words are still available.
        case 1{
          let min_val := mload(min_ptr)                       //  get next word for 'min'

          mstore(result_ptr, sub(sub(max_val,min_val),carry)) //  result_word = (max_word-min_word)-carry

          switch or(lt(max_val, add(min_val,carry)),
          and(eq(min_val,uint_max), eq(carry,1)))      //  this switch block finds whether or
          //  not to set the carry bit for the next iteration.
          case 1  { carry := 1 }
          default { carry := 0 }

          min_ptr := sub(min_ptr,0x20)                        //  point to next 'result' word
        }
        default {                                               // else: remainder after 'min' words are complete.

          mstore(result_ptr, sub(max_val,carry))              //      result_word = max_word-carry

          switch and( eq(max_val,0), eq(carry,1) )            //      this switch block finds whether or
          //      not to set the carry bit for the
          //      next iteration.
          case 1  { carry := 1 }
          default { carry := 0 }

        }
        result_ptr := sub(result_ptr,0x20)                          // point to next 'result' word
        max_ptr    := sub(max_ptr,0x20)                             // point to next 'max' word
      }

    //the following code removes any leading words containing all zeroes in the result.
      result_ptr := add(result_ptr,0x20)

    // for(result_ptr+=32;; result==0; result_ptr+=32)
      for { }   eq(mload(result_ptr), 0) { result_ptr := add(result_ptr,0x20) } {
        result_start := add(result_start, 0x20)                      // push up the start pointer for the result
        max_len := sub(max_len,0x20)                                 // subtract a word (32 bytes) from the
      // result length.
      }

      result := result_start                                          // point 'result' bytes value to
    // the correct address in memory

      mstore(result,max_len)                                          // store length of result. we
    // are finished with the byte array.

      mstore(0x40, memory_end)                                        // Update freemem pointer.
    }

    uint new_bitlen = bitLength(result);                                // calculate the result's
    // bit length.

    return (result, new_bitlen);
  }

  /** @notice gets the modulus value necessary for calculating exponetiation.
      * @dev _powModulus: we must pass the minimum modulus value which would return JUST the a^b part of the calculation
      *       in modexp. the rationale here is:
      *       if 'a' has n bits, then a^e has at most n*e bits.
      *       using this modulus in exponetiation will result in simply a^e.
      *       therefore the value may be many words long.
      *       This is done by:
      *         - storing total modulus byte length
      *         - storing first word of modulus with correct bit set
      *         - updating the free memory pointer to come after total length.
      *
      * @param a BigNumber base
      * @param e uint exponent
      * @return BigNumber modulus result
      */
  function _powModulus(
    BigNumber memory a,
    uint e
  ) private pure returns(BigNumber memory){
    bytes memory _modulus = ZERO;
    uint mod_index;

    assembly {
      mod_index := mul(mload(add(a, 0x40)), e)               // a.bitlen * e is the max bitlength of result
      let first_word_modulus := shl(mod(mod_index, 256), 1)  // set bit in first modulus word.
      mstore(_modulus, mul(add(div(mod_index,256),1),0x20))  // store length of modulus
      mstore(add(_modulus,0x20), first_word_modulus)         // set first modulus word
      mstore(0x40, add(_modulus, add(mload(_modulus),0x20))) // update freemem pointer to be modulus index
    // + length
    }

    //create modulus BigNumber memory for modexp function
    return BigNumber(_modulus, false, mod_index);
  }

  /** @notice Modular Exponentiation: Takes bytes values for base, exp, mod and calls precompile for (base^exp)%^mod
      * @dev modexp: Wrapper for built-in modexp (contract 0x5) as described here:
      *              https://github.com/ethereum/EIPs/pull/198
      *
      * @param _b bytes base
      * @param _e bytes base_inverse
      * @param _m bytes exponent
      * @param r bytes result.
      */
  function _modexp(
    bytes memory _b,
    bytes memory _e,
    bytes memory _m
  ) private view returns(bytes memory r) {
    assembly {

      let bl := mload(_b)
      let el := mload(_e)
      let ml := mload(_m)


      let freemem := mload(0x40) // Free memory pointer is always stored at 0x40


      mstore(freemem, bl)         // arg[0] = base.length @ +0

      mstore(add(freemem,32), el) // arg[1] = exp.length @ +32

      mstore(add(freemem,64), ml) // arg[2] = mod.length @ +64

    // arg[3] = base.bits @ + 96
    // Use identity built-in (contract 0x4) as a cheap memcpy
      let success := staticcall(450, 0x4, add(_b,32), bl, add(freemem,96), bl)

    // arg[4] = exp.bits @ +96+base.length
      let size := add(96, bl)
      success := staticcall(450, 0x4, add(_e,32), el, add(freemem,size), el)

    // arg[5] = mod.bits @ +96+base.length+exp.length
      size := add(size,el)
      success := staticcall(450, 0x4, add(_m,32), ml, add(freemem,size), ml)

      switch success case 0 { invalid() } //fail where we haven't enough gas to make the call

    // Total size of input = 96+base.length+exp.length+mod.length
      size := add(size,ml)
    // Invoke contract 0x5, put return value right after mod.length, @ +96
      success := staticcall(sub(gas(), 1350), 0x5, freemem, size, add(freemem, 0x60), ml)

      switch success case 0 { invalid() } //fail where we haven't enough gas to make the call

      let length := ml
      let msword_ptr := add(freemem, 0x60)

    ///the following code removes any leading words containing all zeroes in the result.
      for { } eq ( eq(length, 0x20), 0) { } {                   // for(; length!=32; length-=32)
        switch eq(mload(msword_ptr),0)                        // if(msword==0):
        case 1 { msword_ptr := add(msword_ptr, 0x20) }    //     update length pointer
        default { break }                                 // else: loop termination. non-zero word found
        length := sub(length,0x20)
      }
      r := sub(msword_ptr,0x20)
      mstore(r, length)

    // point to the location of the return value (length, bits)
    //assuming mod length is multiple of 32, return value is already in the right format.
      mstore(0x40, add(add(96, freemem),ml)) //deallocate freemem pointer
    }
  }
  // ***************** END PRIVATE CORE CALCULATION FUNCTIONS ******************





  // ***************** START PRIVATE HELPER FUNCTIONS ******************
  /** @notice left shift BigNumber memory 'dividend' by 'value' bits.
      * @param bn value to shift
      * @param bits amount of bits to shift by
      * @return r result
      */
  function _shl(
    BigNumber memory bn,
    uint bits
  ) private view returns(BigNumber memory r) {
    if(bits==0 || bn.bitlen==0) return bn;

    // we start by creating an empty bytes array of the size of the output, based on 'bits'.
    // for that we must get the amount of extra words needed for the output.
    uint length = bn.val.length;
    // position of bitlen in most significnat word
    uint bit_position = ((bn.bitlen-1) % 256) + 1;
    // total extra words. we check if the bits remainder will add one more word.
    uint extra_words = (bits / 256) + ( (bits % 256) >= (256 - bit_position) ? 1 : 0);
    // length of output
    uint total_length = length + (extra_words * 0x20);

    r.bitlen = bn.bitlen+(bits);
    r.neg = bn.neg;
    bits %= 256;


    bytes memory bn_shift;
    uint bn_shift_ptr;
    // the following efficiently creates an empty byte array of size 'total_length'
    assembly {
      let freemem_ptr := mload(0x40)                // get pointer to free memory
      mstore(freemem_ptr, total_length)             // store bytes length
      let mem_end := add(freemem_ptr, total_length) // end of memory
      mstore(mem_end, 0)                            // store 0 at memory end
      bn_shift := freemem_ptr                       // set pointer to bytes
      bn_shift_ptr := add(bn_shift, 0x20)           // get bn_shift pointer
      mstore(0x40, add(mem_end, 0x20))              // update freemem pointer
    }

    // use identity for cheap copy if bits is multiple of 8.
    if(bits % 8 == 0) {
      // calculate the position of the first byte in the result.
      uint bytes_pos = ((256-(((bn.bitlen-1)+bits) % 256))-1) / 8;
      uint insize = (bn.bitlen / 8) + ((bn.bitlen % 8 != 0) ? 1 : 0);
      assembly {
        let in          := add(add(mload(bn), 0x20), div(sub(256, bit_position), 8))
        let out         := add(bn_shift_ptr, bytes_pos)
        let success     := staticcall(450, 0x4, in, insize, out, length)
      }
      r.val = bn_shift;
      return r;
    }


    uint mask;
    uint mask_shift = 0x100-bits;
    uint msw;
    uint msw_ptr;

    assembly {
      msw_ptr := add(mload(bn), 0x20)
    }

    // handle first word before loop if the shift adds any extra words.
    // the loop would handle it if the bit shift doesn't wrap into the next word,
    // so we check only for that condition.
    if((bit_position+bits) > 256){
      assembly {
        msw := mload(msw_ptr)
        mstore(bn_shift_ptr, shr(mask_shift, msw))
        bn_shift_ptr := add(bn_shift_ptr, 0x20)
      }
    }

    // as a result of creating the empty array we just have to operate on the words in the original bn.
    for(uint i=bn.val.length; i!=0; i-=0x20){                  // for each word:
      assembly {
        msw := mload(msw_ptr)                              // get most significant word
        switch eq(i,0x20)                                  // if i==32:
        case 1 { mask := 0 }                           // handles msword: no mask needed.
        default { mask := mload(add(msw_ptr,0x20)) }   // else get mask (next word)
        msw := shl(bits, msw)                              // left shift current msw by 'bits'
        mask := shr(mask_shift, mask)                      // right shift next significant word by mask_shift
        mstore(bn_shift_ptr, or(msw,mask))                 // store OR'd mask and shifted bits in-place
        msw_ptr := add(msw_ptr, 0x20)
        bn_shift_ptr := add(bn_shift_ptr, 0x20)
      }
    }

    r.val = bn_shift;
  }
  // ***************** END PRIVATE HELPER FUNCTIONS ******************
}
```

```solidity
// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import "../BigNumbers.sol";

//From https://github.com/firoorg/solidity-BigNumber/blob/master/src/utils/Crypto.sol
library MillerRabin {
  using BigNumbers for *;

  function isPrime(bytes memory primeCandidate) internal view returns (bool){
    BigNumber memory a = primeCandidate.init(false);

    BigNumber memory one = BigNumbers.one();
    BigNumber memory two = BigNumbers.two();

    int compare = a.cmp(two,true);
    if (compare < 0){
      // if value is < 2
      return false;
    }
    if(compare == 0){
      // if value is 2
      return true;
    }
    // if a is even and not 2 (checked): return false
    if (!a.isOdd()) {
      return false;
    }

    BigNumber memory a1 = a.sub(one);

    uint k = getK(a1);
    BigNumber memory a1_odd = a1.val.init(a1.neg);
    a1_odd._shr(k);

    int j;
    uint num_checks = primeChecksForSize(a.bitlen);
    BigNumber memory check;
    for (uint i = 0; i < num_checks; i++) {

      BigNumber memory randomness = randMod(a1, i);
      check = randomness.add(one);
      // now 1 <= check < a.

      j = witness(check, a, a1, a1_odd, k);

      if(j==-1 || j==1) return false;
    }

    //if we've got to here, a is likely a prime.
    return true;
  }

  function getK(
    BigNumber memory a1
  ) private pure returns (uint k){
    k = 0;
    uint mask=1;
    uint a1_ptr;
    uint val;
    assembly{
      a1_ptr := add(mload(a1),mload(mload(a1))) // get address of least significant portion of a
      val := mload(a1_ptr)  //load it
    }

    //loop from least signifcant bits until we hit a set bit. increment k until this point.
    for(bool bit_set = ((val & mask) != 0); !bit_set; bit_set = ((val & mask) != 0)){

      if(((k+1) % 256) == 0){ //get next word should k reach 256.
        a1_ptr -= 32;
        assembly {val := mload(a1_ptr)}
        mask = 1;
      }

      mask*=2; // set next bit (left shift)
      k++;     // increment k
    }
  }

  function primeChecksForSize(
    uint bit_size
  ) private pure returns(uint checks){

    checks = bit_size >= 1300 ?  2 :
    bit_size >=  850 ?  3 :
    bit_size >=  650 ?  4 :
    bit_size >=  550 ?  5 :
    bit_size >=  450 ?  6 :
    bit_size >=  400 ?  7 :
    bit_size >=  350 ?  8 :
    bit_size >=  300 ?  9 :
    bit_size >=  250 ? 12 :
    bit_size >=  200 ? 15 :
    bit_size >=  150 ? 18 :
    /* b >= 100 */ 27;
  }

  function randMod(BigNumber memory modulus, uint256 randNonce) private view returns (BigNumber memory) {
    // from https://www.geeksforgeeks.org/random-number-generator-in-solidity-using-keccak256/
    uint256 unmodded = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, randNonce)));
    return unmodded.init(false).mod(modulus);
  }

  function witness(
    BigNumber memory w,
    BigNumber memory a,
    BigNumber memory a1,
    BigNumber memory a1_odd,
    uint k
  ) private view returns (int){
    BigNumber memory one = BigNumbers.one();
    BigNumber memory two = BigNumbers.two();
    // returns -  0: likely prime, 1: composite number (definite non-prime).

    w = w.modexp(a1_odd, a); // w := w^a1_odd mod a

    if (w.cmp(one,true)==0) return 0; // probably prime.

    if (w.cmp(a1,true)==0) return 0; // w == -1 (mod a), 'a' is probably prime

    for (;k != 0; k=k-1) {
      w = w.modexp(two,a); // w := w^2 mod a

      if (w.cmp(one,true)==0) return 1; // // 'a' is composite, otherwise a previous 'w' would have been == -1 (mod 'a')

      if (w.cmp(a1,true)==0) return 0; // w == -1 (mod a), 'a' is probably prime

    }
    /*
     * If we get here, 'w' is the (a-1)/2-th power of the original 'w', and
     * it is neither -1 nor +1 -- so 'a' cannot be prime
     */
    return 1;
  }
}
```

### Requirements

- The paper [
  Efficient Accumulators without Trapdoor Extended Abstract](https://link.springer.com/chapter/10.1007/978-3-540-47942-0_21) by Tomas Sander proves that difficult to factor numbers without a known factorization can be generated. Using logic based on that described by [Anoncoin](https://anoncoin.github.io/RSA_UFO/), this contract shall generate 120 integers of 3,072 bits each to achieve a one in a billion chance of being insecure.
- This contract shall accept funds from any account without restriction.
- This contract shall allow someone to provide a factorization of one of the integers. If it is the correct solution and is the last integer to be solved, then this contract shall send all of its funds to the solver and mark a flag to indicate that this contract has been solved.

### Deployment Method

After deploying the contract with parameters of 120 locks having 3072 random bits each, the contract's `triggerLockAccumulation()` method will be called repeatedly until all bits have been generated.

The following is the code that will be used to deploy the contract.

```javascript
import { HardhatRuntimeEnvironment } from 'hardhat/types'
import { DeployFunction } from 'hardhat-deploy/types'
import { Create2Factory } from '../src/Create2Factory'
import { ethers } from 'hardhat'
import { BigNumber } from 'ethers'

const MAX_GAS_LIMIT_OPTION = { gasLimit: BigNumber.from('0x1c9c380') }

const deployPrimeFactoringBounty: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const provider = ethers.provider
  const from = await provider.getSigner().getAddress()
  await new Create2Factory(ethers.provider).deployFactory()

  const numberOfLocks = 120
  const primeByteLength = 128
  let gasUsed = BigNumber.from(0)

  const deployResult = await hre.deployments.deploy(
    'PrimeFactoringBountyWithRsaUfo', {
      ...MAX_GAS_LIMIT_OPTION,
      from,
      args: [numberOfLocks, primeByteLength],
      gasLimit: 6e6,
      deterministicDeployment: true
    })
  console.log('==PrimeFactoringBounty addr=', deployResult.address)
  gasUsed = gasUsed.add(deployResult.receipt?.gasUsed)

  const bounty = await ethers.getContractAt('PrimeFactoringBountyWithRsaUfo', deployResult.address)
  while (!(await bounty.generationIsDone())) {
    const tx = await bounty.triggerLockAccumulation()
    const receipt = await tx.wait()
    gasUsed = gasUsed.add(receipt.gasUsed)
  }
  console.log('==PrimeFactoringBounty gasUsed=', gasUsed.toHexString())
}

module.exports = deployPrimeFactoringBounty
module.exports.tags = ['PrimeFactoringBounty']
```

After deploying, the deployers should solve all locks that can be readily solved, leaving only the difficult ones to be solved.

### Providing solutions

- The solution for each lock shall be provided separately. Providing solutions will follow a [commit-reveal](https://medium.com/swlh/exploring-commit-reveal-schemes-on-ethereum-c4ff5a777db8) scheme to prevent [front running](https://solidity-by-example.org/hacks/front-running/.)
- This scheme shall require one day between commit and reveal per lock, but allow simultaneous commits and reveals for different locks.

### Providing the bounty funds

Funds covering 6,000,000 gas for each unsolved lock shall be sent to the contract as a bounty. The funds must be updated to cover this amount as the value of gas increases.
The contract shall accept any additional funds from any account as a donation to the bounty.

### Providing the Final Solution

Upon solving the final solution, all funds in the contract shall be sent to the solver, the `solved` flag shall be marked `true`, and no further attempts to commit, reveal, or add funds to the contract shall be allowed.

## Rationale

- The reason to split up the lock generation and solving into many calls is to avoid hitting the gas limit of a transaction in any one call.
- Solving all readily solvable locks at the time of deployment allows for a less expensive transaction to finally solve the contract, since one would only need to pay to solve the difficult locks.
- It is estimated that less than 5,000,000 gas will be required to provide a solution for a single lock. The funds awarded to the solver must cover this cost with a margin of error and provide an additional reward to the solver as an incentive.

## Backwards Compatibility

Does not apply as there are no past versions of a Quantum Supremacy contract being used.

## Test Cases

- https://github.com/nikojpapa/etherium-quantum-bounty/blob/44a1c80eb3bb21c8f5edf6fec26b2d25e7ac8351/test/bounty-contracts/prime-factoring-bounty/prime-factoring-bounty-with-rsa-ufo/prime-factoring-bounty-with-rsa-ufo.test.ts
- https://github.com/nikojpapa/etherium-quantum-bounty/blob/44a1c80eb3bb21c8f5edf6fec26b2d25e7ac8351/test/bounty-contracts/prime-factoring-bounty/prime-factoring-bounty-with-rsa-ufo/rsa-ufo-accumulator.test.ts
- https://github.com/nikojpapa/etherium-quantum-bounty/blob/44a1c80eb3bb21c8f5edf6fec26b2d25e7ac8351/test/bounty-contracts/prime-factoring-bounty/prime-factoring-bounty-with-predetermined-locks/prime-factoring-bounty-with-predetermined-locks.test.ts

## Reference Implementation

### Quantum Supremacy Contract
https://github.com/nikojpapa/etherium-quantum-bounty/blob/44a1c80eb3bb21c8f5edf6fec26b2d25e7ac8351/contracts/bounty-contracts/prime-factoring-bounty/prime-factoring-bounty-with-rsa-ufo/PrimeFactoringBountyWithRsaUfo.sol

### Example Proof-of-concept Account Having a Quantum Secure Verification Scheme After Quantum Supremacy Trigger
https://github.com/nikojpapa/etherium-quantum-bounty/blob/44a1c80eb3bb21c8f5edf6fec26b2d25e7ac8351/contracts/bounty-fallback-account/BountyFallbackAccount.sol

## Security Considerations
- By requiring one day between commit and reveal, it is infeasible to front run because the cost required to keep a reveal transaction in the mempool for a full day is greater than all the Eth in existence.

## Copyright
Copyright and related rights waived via [CC0](../LICENSE.md).
