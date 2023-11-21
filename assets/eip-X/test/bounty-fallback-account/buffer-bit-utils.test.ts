import { getReversedBits } from './buffer-bit-utils'
import { expect } from 'chai'

describe('BufferBitUtils', () => {
  describe('Reversed Bits', () => {
    it('should return 1 when given a buffer of 5 wanting 2 bits', () => {
      const bits = getReversedBits(Buffer.from([5]), 2)
      expect(bits).to.eql([1, 0])
    })
  })
})
