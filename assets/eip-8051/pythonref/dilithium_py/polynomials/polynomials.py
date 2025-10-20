from hashlib import shake_256
from .polynomials_generic import PolynomialRing, Polynomial
from ..utilities.utils import (
    reduce_mod_pm,
    high_bits,
    low_bits,
    decompose,
    check_norm_bound,
)
from ..utilities.utils import make_hint, make_hint_optimised, use_hint

from ..shake.shake_wrapper import Shake, shake128, shake256
from polyntt.ntt_iterative import NTTIterative


class PolynomialRingDilithium(PolynomialRing):
    def __init__(self, q, n):
        self.q = q
        self.n = n
        self.element = PolynomialDilithium
        self.element_ntt = PolynomialDilithiumNTT

    def sample_in_ball(self, seed, tau, _xof=shake256):
        """
        Figure 2 (Sample in Ball)
            https://pq-crystals.org/dilithium/data/dilithium-specification-round3-20210208.pdf

        Create a random 256-element array with τ ±1’s and (256 − τ) 0′s using
        the input seed ρ (and an SHAKE256) to generate the randomness needed
        """

        def rejection_sample(i, xof):
            """
            Sample random bytes from `xof_bytes` and
            interpret them as integers in {0, ..., 255}

            Rejects values until a value j <= i is found
            """
            while True:
                j = xof.read(1)[0]
                if j <= i:
                    return j

        # Initialise the XOF
        if _xof == shake256:
            xof = Shake(shake_256, 136)
            xof.absorb(seed)
        else:
            xof = _xof(seed)
        xof.flip()
        # Set the first 8 bytes for the sign, and leave the rest for
        # sampling.
        sign_bytes = xof.read(8)
        sign_int = int.from_bytes(sign_bytes, "little")

        # Set the list of coeffs to be 0
        coeffs = [0 for _ in range(256)]

        # Now set tau values of coeffs to be ±1
        for i in range(256 - tau, 256):
            j = rejection_sample(i, xof)
            coeffs[i] = coeffs[j]
            coeffs[j] = 1 - 2 * (sign_int & 1)
            sign_int >>= 1

        return self(coeffs)

    def rejection_sample_ntt_poly(self, rho, i, j, _xof=shake128):
        """
        Samples an element in the NTT domain of R^q using rejection sampling
        """

        def rejection_sample(xof):
            """
            Sample three random bytes from `xof` and
            interpret them as integers in {0, ..., 2^23 - 1}

            Rejects values until a value j < q is found
            """
            while True:
                j_bytes = xof.read(3)
                j = int.from_bytes(j_bytes, "little")
                j &= 0x7FFFFF
                if j < self.q:
                    return j

        # Initialise the XOF
        seed = rho + bytes([j, i])
        xof = _xof(seed)
        xof.flip()
        coeffs = [rejection_sample(xof) for _ in range(256)]
        return self(coeffs, is_ntt=True)

    def rejection_sample_ntt_poly_babybear(self, rho, i, j, _xof=shake128):
        """
        Samples an element in the NTT domain of R^q using rejection sampling
        """

        def rejection_sample(xof):
            """
            Sample four random bytes from `xof` and
            interpret them as integers in {0, ..., 2^32 - 1}

            Rejects values until a value j < q is found
            """
            while True:
                j_bytes = xof.read(4)
                j = int.from_bytes(j_bytes, "little")
                j &= 0xFFFFFFFF
                if j < self.q:
                    return j

        # Initialise the XOF
        seed = rho + bytes([j, i])
        xof = _xof(seed)
        xof.flip()
        coeffs = [rejection_sample(xof) for _ in range(256)]
        return self(coeffs, is_ntt=True)

    def rejection_bounded_poly(self, rho_prime, i, eta, _xof=shake256):
        """
        Computes an element of the polynomial ring with coefficients between
        -eta and eta using rejection sampling from an XOF
        """

        def coefficient_from_half_byte(j, eta):
            """
            Rejects values until a value j < 2η is found
            """
            if eta == 2 and j < 15:
                return 2 - (j % 5)
            elif j < 9:
                assert eta == 4
                return 4 - j
            return False

        # Initialise the XOF
        seed = rho_prime + int.to_bytes(i, 2, "little")
        xof = _xof(seed)
        if _xof != shake256:
            xof.flip()
        # Sample bytes for all n coeffs
        i = 0
        coeffs = [0 for _ in range(256)]
        while i < 256:
            # Consider two values for each byte (top and bottom four bits)
            j = xof.read(1)[0]
            c0 = coefficient_from_half_byte(j % 16, eta)
            if c0 is not False:
                coeffs[i] = c0
                i += 1

            c1 = coefficient_from_half_byte(j // 16, eta)
            if c1 is not False and i < 256:
                coeffs[i] = c1
                i += 1
        return self(coeffs)

    def sample_mask_polynomial(self, rho_prime, i, kappa, gamma_1, _xof=shake256):
        """
        Samples an element in the polynomial ring with elements bounded
        between -gamma_1 + 1 and gamma_1.
        """
        if gamma_1 == (1 << 17):
            bit_count = 18
            total_bytes = 576  # (256 * 18) / 8
        else:
            bit_count = 20
            total_bytes = 640  # (256 * 20) / 8

        # Initialise the XOF
        seed = rho_prime + int.to_bytes(kappa + i, 2, "little")
        hash = _xof(seed)
        hash.flip()
        xof_bytes = hash.read(total_bytes)
        r = int.from_bytes(xof_bytes, "little")
        mask = (1 << bit_count) - 1
        coeffs = [gamma_1 - ((r >> bit_count * i) & mask)
                  for i in range(self.n)]

        return self(coeffs)

    def __bit_unpack(self, input_bytes, n_bits):
        if (len(input_bytes) * n_bits) % 8 != 0:
            raise ValueError(
                "Input bytes do not have a length compatible with the bit length"
            )

        r = int.from_bytes(input_bytes, "little")
        mask = (1 << n_bits) - 1
        return [(r >> n_bits * i) & mask for i in range(self.n)]

    def bit_unpack_t0(self, input_bytes):
        altered_coeffs = self.__bit_unpack(input_bytes, 13)
        coefficients = [(1 << 12) - c for c in altered_coeffs]
        return self(coefficients)

    def bit_unpack_t1(self, input_bytes):
        coefficients = self.__bit_unpack(input_bytes, 10)
        return self(coefficients)

    def bit_unpack_s(self, input_bytes, eta):
        # Level 2 and 5 parameter set
        if eta == 2:
            altered_coeffs = self.__bit_unpack(input_bytes, 3)
        # Level 3 parameter set
        else:
            assert eta == 4, f"Expected eta to be either 2 or 4, got {eta=}"
            altered_coeffs = self.__bit_unpack(input_bytes, 4)

        coefficients = [eta - c for c in altered_coeffs]
        return self(coefficients)

    def bit_unpack_w(self, input_bytes, gamma_2):
        # Level 2 parameter set
        if gamma_2 == 95232:
            coefficients = self.__bit_unpack(input_bytes, 6)
        # Level 3 and 5 parameter set
        else:
            assert (
                gamma_2 == 261888
            ), f"Expected gamma_2 to be either (q-1)/88 or (q-1)/32, got {gamma_2=}"
            coefficients = self.__bit_unpack(input_bytes, 4)

        return self(coefficients)

    def bit_unpack_32(self, input_bytes, is_ntt=False):
        coefficients = self.__bit_unpack(input_bytes, 32)
        return self(coefficients, is_ntt=is_ntt)

    def bit_unpack_z(self, input_bytes, gamma_1):
        # Level 2 parameter set
        if gamma_1 == (1 << 17):
            altered_coeffs = self.__bit_unpack(input_bytes, 18)
        # Level 3 and 5 parameter set
        else:
            assert gamma_1 == (
                1 << 19
            ), f"Expected gamma_1 to be either 2^17 or 2^19, got {gamma_1=}"
            altered_coeffs = self.__bit_unpack(input_bytes, 20)
        coefficients = [gamma_1 - c for c in altered_coeffs]
        return self(coefficients)

    def __call__(self, coefficients, is_ntt=False):
        if not is_ntt:
            element = self.element
        else:
            element = self.element_ntt

        if isinstance(coefficients, int):
            return element(self, [coefficients])
        if not isinstance(coefficients, list):
            raise TypeError(
                f"Polynomials should be constructed from a list of integers, of length at most d = {256}"
            )
        return element(self, coefficients)


class PolynomialDilithium(Polynomial):
    def __init__(self, parent, coefficients):
        self.parent = parent
        self.coeffs = self._parse_coefficients(coefficients)

    def to_ntt(self):
        """
        Convert a polynomial to number-theoretic transform (NTT)
        ZKNOX implementation
        """
        coeffs_ntt = NTTIterative(self.parent.q).ntt(self.coeffs)
        return self.parent(coeffs_ntt, is_ntt=True)

    def from_ntt(self):
        raise TypeError(f"Polynomial is of type: {type(self)}")

    def power_2_round(self, d):
        power_2 = 1 << d
        r1_coeffs = []
        r0_coeffs = []
        for c in self.coeffs:
            r = c % self.parent.q
            r0 = reduce_mod_pm(r, power_2)
            r1_coeffs.append((r - r0) >> d)
            r0_coeffs.append(r0)

        r1_poly = self.parent(r1_coeffs)
        r0_poly = self.parent(r0_coeffs)

        return r1_poly, r0_poly

    def high_bits(self, alpha, is_ntt=False):
        coeffs = [high_bits(c, alpha, self.parent.q) for c in self.coeffs]
        return self.parent(coeffs, is_ntt=is_ntt)

    def low_bits(self, alpha, is_ntt=False):
        coeffs = [low_bits(c, alpha, self.parent.q) for c in self.coeffs]
        return self.parent(coeffs, is_ntt=is_ntt)

    """
    Compute the high and low bits at the same time
    Not in the pseudocode, but needed for the more
    efficient signing which we implement based on
    section 5.1
    """

    def decompose(self, alpha):
        coeff_high = []
        coeff_low = []
        for c in self.coeffs:
            r1, r0 = decompose(c, alpha, self.parent.q)
            coeff_high.append(r1)
            coeff_low.append(r0)
        return self.parent(coeff_high), self.parent(coeff_low)

    def check_norm_bound(self, bound):
        """
        Returns true if the inf norm of any coeff
        is greater or equal to the bound.
        """
        return any(check_norm_bound(c, bound, self.parent.q) for c in self.coeffs)

    """
    The following bit_pack functions are specific for Dilithium
    but are currently added as methods for the Polynomial class
    as it seemed the most natural way to do this.
    """

    @staticmethod
    def __bit_pack(coeffs, n_bits, n_bytes):
        r = 0
        for c in reversed(coeffs):
            r <<= n_bits
            r |= c
        return r.to_bytes(n_bytes, "little")

    def bit_pack_t0(self):
        # 416 = 256 * 13 // 8
        altered_coeffs = [(1 << 12) - c for c in self.coeffs]
        return self.__bit_pack(altered_coeffs, 13, 416)

    def bit_pack_t1(self):
        # 320 = 256 * 10 // 8
        return self.__bit_pack(self.coeffs, 10, 320)

    def bit_pack_s(self, eta):
        altered_coeffs = [self._sub_mod_q(eta, c) for c in self.coeffs]
        # Level 2 and 5 parameter set
        if eta == 2:
            return self.__bit_pack(altered_coeffs, 3, 96)
        # Level 3 parameter set
        assert eta == 4, f"Expected eta to be either 2 or 4, got {eta=}"
        return self.__bit_pack(altered_coeffs, 4, 128)

    def bit_pack_w(self, gamma_2):
        # Level 2 parameter set
        if gamma_2 == 95232:
            return self.__bit_pack(self.coeffs, 6, 192)
        elif gamma_2 == 983040 or gamma_2 == 1040384:
            # {Baby, Koala}Bear
            # m = max([len(bin(l))-2 for l in self.coeffs])
            # return self.__bit_pack(self.coeffs, m, 256//8 * m)
            return self.__bit_pack(self.coeffs, 10, 320)
        # Level 3 and 5 parameter set
        assert (
            gamma_2 == 261888
        ), f"Expected gamma_2 to be either (q-1)/88 or (q-1)/32, got {gamma_2=}"
        return self.__bit_pack(self.coeffs, 4, 128)

    def bit_pack_z(self, gamma_1):
        altered_coeffs = [self._sub_mod_q(gamma_1, c) for c in self.coeffs]
        # Level 2 parameter set
        if gamma_1 == (1 << 17):
            return self.__bit_pack(altered_coeffs, 18, 576)
        # Level 3 and 5 parameter set
        assert gamma_1 == (
            1 << 19
        ), f"Expected gamma_1 to be either 2^17 or 2^19, got: {gamma_1=}"
        return self.__bit_pack(altered_coeffs, 20, 640)

    def bit_pack_32(self):
        return self.__bit_pack(self.coeffs, 32, 1024)

    def make_hint(self, other, alpha):
        coeffs = [
            make_hint(r, z, alpha, self.parent.q) for r, z in zip(self.coeffs, other.coeffs)
        ]
        return self.parent(coeffs)

    def make_hint_optimised(self, other, alpha):
        coeffs = [
            make_hint_optimised(r, z, alpha, self.parent.q)
            for r, z in zip(self.coeffs, other.coeffs)
        ]
        return self.parent(coeffs)

    def use_hint(self, other, alpha):
        coeffs = [
            use_hint(h, r, alpha, self.parent.q) for h, r in zip(self.coeffs, other.coeffs)
        ]
        return self.parent(coeffs)


class PolynomialDilithiumNTT(PolynomialDilithium):
    def __init__(self, parent, coefficients):
        self.parent = parent
        self.coeffs = self._parse_coefficients(coefficients)

    @staticmethod
    def __bit_pack(coeffs, n_bits, n_bytes):
        r = 0
        for c in reversed(coeffs):
            r <<= n_bits
            r |= c
        return r.to_bytes(n_bytes, "little")

    def bit_pack_32(self):
        return self.__bit_pack(self.coeffs, 32, 1024)

    def to_ntt(self):
        raise TypeError(f"Polynomial is of type: {type(self)}")

    def from_ntt(self):
        """
        Convert a polynomial from number-theoretic transform (NTT) form in place
        The input is in bit-reversed order, the output is in standard order.
        ZKNOX implementation
        """
        coeffs_intt = NTTIterative(self.parent.q).intt(self.coeffs)
        return self.parent(coeffs_intt, is_ntt=False)

    def ntt_coefficient_multiplication(self, f_coeffs, g_coeffs):
        return [(c1 * c2) % self.parent.q for c1, c2 in zip(f_coeffs, g_coeffs)]

    def ntt_multiplication(self, other):
        """
        Number Theoretic Transform multiplication.
        """
        if not isinstance(other, type(self)):
            raise ValueError

        new_coeffs = self.ntt_coefficient_multiplication(
            self.coeffs, other.coeffs)
        return new_coeffs

    def __add__(self, other):
        new_coeffs = self._add_(other)
        return self.parent(new_coeffs, is_ntt=True)

    def __sub__(self, other):
        new_coeffs = self._sub_(other)
        return self.parent(new_coeffs, is_ntt=True)

    def __mul__(self, other):
        if isinstance(other, type(self)):
            new_coeffs = self.ntt_multiplication(other)
        elif isinstance(other, int):
            new_coeffs = [(c * other) % self.parent.q for c in self.coeffs]
        else:
            raise NotImplementedError(
                f"Polynomials can only be multiplied by each other, or scaled by integers, {type(other)=}, {type(self)=}"
            )
        return self.parent(new_coeffs, is_ntt=True)
