import { ethers } from 'hardhat'
import { MillerRabinTestHelper, MillerRabinTestHelper__factory } from '../../../typechain'
import { expect } from 'chai'
import { Buffer } from 'buffer'
import { arrayify } from 'ethers/lib/utils'

describe('Miller-Rabin Primality Test', () => {
  const ethersSigner = ethers.provider.getSigner()
  let millerRabin: MillerRabinTestHelper

  before(async () => {
    millerRabin = await new MillerRabinTestHelper__factory(ethersSigner).deploy()
  })

  it('should correctly identify some known prime numbers', async () => {
    const somePrimes = ['0x02', `0x${(6703).toString(16)}`, '0xf699ff9e4915187f931a87e4a4c2b8b0c7df644d1dca77fceaa026c01463327a3ebfbe836bc3535a8e7f9e5d37b638034dbc6c9310b0ee7a691cab4f997120886443452bd889045db3ad0ea130506c705f13abe62a2d9e0af5687d5da8c1f8a893609b2114bd1a03bf20195661172aafc733888bfb3443272e191382f574fcad']
    await checkPrimes(somePrimes, true)
  })

  it('should correctly identify some known composite numbers', async () => {
    const someComposites = ['0x04', `0x${(21).toString(16)}`, '0xf699ff9e4915187f931a87e4a4c2b8b0c7df644d1dca77fceaa026c01463327a3ebfbe836bc3535a8e7f9e5d37b638034dbc6c9310b0ee7a691cab4f997120886443452bd889045db3ad0ea130506c705f13abe62a2d9e0af5687d5da8c1f8a893609b2114bd1a03bf20195661172aafc733888bfb3443272e191382f574fcac']
    await checkPrimes(someComposites, false)
  })

  async function checkPrimes (numbersAsHexStrings: string[], expectedToBePrime: boolean): Promise<void> {
    const resultsPromise = numbersAsHexStrings
      .map(primeCandidate => millerRabin.isPrime(Buffer.from(arrayify(primeCandidate))))
    const results = await Promise.all(resultsPromise)
    expect(results.every(x => x === expectedToBePrime)).to.be.eq(true)
  }
})
