// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import "../../support/BigNumbers.sol";

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
