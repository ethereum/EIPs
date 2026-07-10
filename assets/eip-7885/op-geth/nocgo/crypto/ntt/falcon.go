package ntt

// Falcon NTT implementation
// Constants for Falcon NTT with modulus q = 12289

const (
	falconQ   = 12289 // Modulus
	falconQ0I = 12287 // -1/q mod 2^16
	falconR   = 4091  // 2^16 mod q
	falconR2  = 10952 // 2^32 mod q
)

// mqAdd performs addition modulo q for Falcon.
// Operands must be in the 0..q-1 range.
func mqAdd(x, y uint32) uint32 {
	// Compute x + y - q. If the result is negative, the high bit will be set.
	// This implements a conditional addition of q.
	d := x + y - falconQ
	d += falconQ & -(d >> 31)
	return d
}

// mqSub performs subtraction modulo q for Falcon.
// Operands must be in the 0..q-1 range.
func mqSub(x, y uint32) uint32 {
	// Use conditional addition to ensure result is in 0..q-1 range.
	d := x - y
	d += falconQ & -(d >> 31)
	return d
}

// mqRshift1 performs division by 2 modulo q for Falcon.
// Operand must be in the 0..q-1 range.
func mqRshift1(x uint32) uint32 {
	x += falconQ & -(x & 1)
	return x >> 1
}

// mqMontyMul performs Montgomery multiplication modulo q for Falcon.
// This computes: x * y / R mod q where R = 2^16 mod q.
// Operands must be in the 0..q-1 range.
func mqMontyMul(x, y uint32) uint32 {
	// Compute x*y + k*q with k chosen so that the 16 low bits are 0.
	z := x * y
	w := ((z * falconQ0I) & 0xFFFF) * falconQ

	// When adding z and w, the result will have its low 16 bits equal to 0.
	// The sum will fit on 29 bits.
	z = (z + w) >> 16

	// After the shift, the value will be less than 2q.
	// Do subtraction then conditional subtraction to ensure result is in range.
	z -= falconQ
	z += falconQ & -(z >> 31)
	return z
}

// FalconNTT computes the forward NTT on a ring element for Falcon (binary case).
//
// Parameters:
//   - a: input/output coefficient array (modified in place)
//   - logn: log2 of the ring size (n = 2^logn, typically 9 or 10 for Falcon)
//
// The output is in NTT representation with twiddle factors from the gmb table.
func FalconNTT(a []uint16, logn uint) {
	n := 1 << logn
	t := n

	for m := 1; m < n; m <<= 1 {
		ht := t >> 1
		for i, j1 := 0, 0; i < m; i, j1 = i+1, j1+t {
			s := gmb[m+i]
			j2 := j1 + ht
			for j := j1; j < j2; j++ {
				u := uint32(a[j])
				v := mqMontyMul(uint32(a[j+ht]), uint32(s))
				a[j] = uint16(mqAdd(u, v))
				a[j+ht] = uint16(mqSub(u, v))
			}
		}
		t = ht
	}
}

// FalconINTT computes the inverse NTT on a ring element for Falcon (binary case).
//
// Parameters:
//   - a: input/output coefficient array (modified in place)
//   - logn: log2 of the ring size (n = 2^logn, typically 9 or 10 for Falcon)
//
// The input should be in NTT representation and the output will be in
// standard polynomial representation.
func FalconINTT(a []uint16, logn uint) {
	n := 1 << logn
	t := 1
	m := n

	for m > 1 {
		hm := m >> 1
		dt := t << 1
		for i, j1 := 0, 0; i < hm; i, j1 = i+1, j1+dt {
			j2 := j1 + t
			s := igmb[hm+i]
			for j := j1; j < j2; j++ {
				u := uint32(a[j])
				v := uint32(a[j+t])
				a[j] = uint16(mqAdd(u, v))
				w := mqSub(u, v)
				a[j+t] = uint16(mqMontyMul(w, uint32(s)))
			}
		}
		t = dt
		m = hm
	}

	// Complete the inverse NTT by dividing all values by n.
	// We need the inverse of n in Montgomery representation,
	// i.e., we divide 1 by 2 logn times and multiply by R = 2^16.
	ni := uint32(falconR)
	for m := n; m > 1; m >>= 1 {
		ni = mqRshift1(ni)
	}
	for i := 0; i < n; i++ {
		a[i] = uint16(mqMontyMul(uint32(a[i]), ni))
	}
}
