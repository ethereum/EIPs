package ntt

// Dilithium NTT implementation
// Constants for ML-DSA (Dilithium) NTT

const (
	// N is the ring size for ML-DSA/Dilithium
	N = 256
	// Q is the modulus: 2^23 - 2^13 + 1
	Q = 8380417
	// QINV is q^(-1) mod 2^32
	QINV = 58728449
	// MONT is 2^32 % Q
	MONT = -4186625
)

// montgomeryReduce performs Montgomery reduction for Dilithium.
// For finite field element a with -2^{31}Q <= a <= Q*2^31,
// compute r ≡ a*2^{-32} (mod Q) such that -Q < r < Q.
//
// Arguments:
//   - a: finite field element
//
// Returns r.
func montgomeryReduce(a int64) int32 {
	t := int32(int64(int32(a)) * QINV)
	t = int32((a - int64(t)*Q) >> 32)
	return t
}

// reduce32 performs modular reduction.
// For finite field element a with a <= 2^{31} - 2^{22} - 1,
// compute r ≡ a (mod Q) such that -6283008 <= r <= 6283008.
//
// Arguments:
//   - a: finite field element
//
// Returns r.
func reduce32(a int32) int32 {
	t := (a + (1 << 22)) >> 23
	t = a - t*Q
	return t
}

// caddq adds Q if input coefficient is negative.
//
// Arguments:
//   - a: finite field element
//
// Returns r.
func caddq(a int32) int32 {
	a += (a >> 31) & Q
	return a
}

// freeze computes standard representative r = a mod^+ Q.
// For finite field element a, compute standard representative r = a mod^+ Q.
//
// Arguments:
//   - a: finite field element
//
// Returns r.
func freeze(a int32) int32 {
	a = reduce32(a)
	a = caddq(a)
	return a
}

// DilithiumNTT computes the forward DilithiumNTT for Dilithium/ML-DSA.
//
// This performs an in-place forward DilithiumNTT transformation.
// No modular reduction is performed after additions or subtractions.
// The output vector is in bitreversed order.
//
// Parameters:
//   - a: input/output coefficient array of length 256 (modified in place)
//
// The input coefficients should be in normal representation and the output
// will be in DilithiumNTT representation.
func DilithiumNTT(a []int32) {
	var (
		length, start, j, k uint
		zeta, t             int32
	)

	k = 0
	for length = 128; length > 0; length >>= 1 {
		for start = 0; start < N; start = j + length {
			k++
			zeta = zetas[k]
			for j = start; j < start+length; j++ {
				t = montgomeryReduce(int64(zeta) * int64(a[j+length]))
				a[j+length] = a[j] - t
				a[j] = a[j] + t
			}
		}
	}
}

// DilithiumInvNTTToMont computes the inverse NTT for Dilithium/ML-DSA.
//
// This performs an in-place inverse NTT and multiplication by Montgomery factor 2^32.
// No modular reductions are performed after additions or subtractions.
// Input coefficients need to be smaller than Q in absolute value.
// Output coefficients are smaller than Q in absolute value.
//
// Parameters:
//   - a: input/output coefficient array of length 256 (modified in place)
//
// The input should be in NTT representation (typically bitreversed from forward NTT)
// and the output will be in normal polynomial representation (Montgomery form).
func DilithiumInvNTTToMont(a []int32) {
	var (
		start, length, j, k uint
		t, zeta             int32
	)
	const f = 41978 // mont^2/256

	k = 256
	for length = 1; length < N; length <<= 1 {
		for start = 0; start < N; start = j + length {
			k--
			zeta = -zetas[k]
			for j = start; j < start+length; j++ {
				t = a[j]
				a[j] = t + a[j+length]
				a[j+length] = t - a[j+length]
				a[j+length] = montgomeryReduce(int64(zeta) * int64(a[j+length]))
			}
		}
	}

	for j = 0; j < N; j++ {
		a[j] = montgomeryReduce(int64(f) * int64(a[j]))
	}
}

// DilithiumInvNTT computes the inverse NTT for Dilithium/ML-DSA and converts to standard form.
//
// This performs an in-place inverse NTT followed by Montgomery reduction and freeze
// to convert from Montgomery form to standard form [0, Q-1].
//
// Parameters:
//   - a: input/output coefficient array of length 256 (modified in place)
//
// The input should be in NTT representation (typically bitreversed from forward NTT)
// and the output will be in normal polynomial representation in range [0, Q-1].
func DilithiumInvNTT(a []int32) {
	DilithiumInvNTTToMont(a)
	// Apply Montgomery reduction and freeze to get standard form [0, Q-1]
	for i := 0; i < N; i++ {
		a[i] = montgomeryReduce(int64(a[i]))
		a[i] = freeze(a[i])
	}
}
