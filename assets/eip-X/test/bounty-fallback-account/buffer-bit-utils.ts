const BITS_PER_BYTE = 8

export function getReversedBits (buffer: Buffer, numberOfBits: number): number[] {
  const bits = []
  let i = 0
  while (bits.length < numberOfBits) {
    const byteInt = buffer.readUInt8(buffer.byteLength - i - 1)
    for (let j = 0; j < BITS_PER_BYTE; j++) {
      const b = (byteInt >> j) & 1
      bits.push(b)
    }
    ++i
  }
  return bits.slice(0, numberOfBits)
}
