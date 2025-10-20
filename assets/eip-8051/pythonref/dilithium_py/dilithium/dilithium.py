from hashlib import shake_256
import os
from ..modules.modules import ModuleDilithium

from ..shake.shake_wrapper import Shake, shake128, shake256
from ..keccak_prng.keccak_prng_wrapper import Keccak256PRNG


class Dilithium:
    def __init__(self, parameter_set, q=8380417, n=256):
        self.d = parameter_set["d"]
        self.k = parameter_set["k"]
        self.l = parameter_set["l"]
        self.eta = parameter_set["eta"]
        self.tau = parameter_set["tau"]
        self.omega = parameter_set["omega"]
        self.gamma_1 = parameter_set["gamma_1"]
        self.gamma_2 = parameter_set["gamma_2"]
        self.beta = self.tau * self.eta
        self.c_tilde_bytes = parameter_set["c_tilde_bytes"]

        self.M = ModuleDilithium(q, n)
        self.R = self.M.ring
        self.oid = parameter_set["oid"] if "oid" in parameter_set else None

        # Use system randomness by default, for deterministic randomness
        # use the method `set_drbg_seed()`
        self.random_bytes = os.urandom

    def set_drbg_seed(self, seed):
        """
        Change entropy source to a DRBG and seed it with provided value.

        Setting the seed switches the entropy source from :func:`os.urandom()`
        to an AES256 CTR DRBG.

        Used for both deterministic versions of Kyber as well as testing
        alignment with the KAT vectors

        Note:
          currently requires pycryptodome for AES impl.
        """
        try:
            from ..drbg.aes256_ctr_drbg import AES256_CTR_DRBG

            self._drbg = AES256_CTR_DRBG(seed)
            self.random_bytes = self._drbg.random_bytes
        except ImportError as e:  # pragma: no cover
            print(f"Error importing AES from pycryptodome: {e=}")
            raise Warning(
                "Cannot set DRBG seed due to missing dependencies, try installing requirements: pip -r install requirements"
            )

    """
    H() uses Shake256 to hash data to 32 and 64 bytes in a
    few places in the code
    """

    @staticmethod
    def _h(input_bytes, length, _xof=shake256):
        """
        H: B^*  -> B^*
        """
        if _xof != shake256:  # keccak_prng
            h = _xof()
            h.inject(input_bytes)
        else:
            # fix the bug for now like this
            h = Shake(shake_256, 136)
            h.absorb(input_bytes)
        h.flip()
        return h.read(length)

    def _expand_matrix_from_seed(self, rho, _xof=shake128, zk=False):
        """
        Helper function which generates a element of size
        k x l from a seed `rho`.
        """
        A_data = [[0 for _ in range(self.l)] for _ in range(self.k)]
        for i in range(self.k):
            for j in range(self.l):
                if zk:
                    A_data[i][j] = self.R.rejection_sample_ntt_poly_babybear(
                        rho, i, j, _xof=_xof)
                else:
                    A_data[i][j] = self.R.rejection_sample_ntt_poly(
                        rho, i, j, _xof=_xof)
        return self.M(A_data)

    def _expand_vector_from_seed(self, rho_prime, _xof=shake256):
        s1_elements = [
            self.R.rejection_bounded_poly(rho_prime, i, self.eta, _xof=_xof) for i in range(self.l)
        ]
        s2_elements = [
            self.R.rejection_bounded_poly(
                rho_prime, i, self.eta, _xof=_xof)
            for i in range(self.l, self.l + self.k)
        ]

        s1 = self.M.vector(s1_elements)
        s2 = self.M.vector(s2_elements)
        return s1, s2

    def _expand_mask_vector(self, rho_prime, kappa, _xof=shake256):
        elements = [
            self.R.sample_mask_polynomial(
                rho_prime, i, kappa, self.gamma_1, _xof=_xof)
            for i in range(self.l)
        ]
        return self.M.vector(elements)

    @staticmethod
    def _pack_pk(rho, t1):
        return rho + t1.bit_pack_t1()

    def _pack_sk(self, rho, K, tr, s1, s2, t0):
        s1_bytes = s1.bit_pack_s(self.eta)
        s2_bytes = s2.bit_pack_s(self.eta)
        t0_bytes = t0.bit_pack_t0()
        return rho + K + tr + s1_bytes + s2_bytes + t0_bytes

    def _pack_h(self, h):
        non_zero_positions = [
            [i for i, c in enumerate(poly.coeffs) if c == 1]
            for row in h._data
            for poly in row
        ]
        packed = []
        offsets = []
        for positions in non_zero_positions:
            packed.extend(positions)
            offsets.append(len(packed))

        padding_len = self.omega - offsets[-1]
        packed.extend([0 for _ in range(padding_len)])
        return bytes(packed + offsets)

    def _pack_sig(self, c_tilde, z, h):
        return c_tilde + z.bit_pack_z(self.gamma_1) + self._pack_h(h)

    def _pk_size(self) -> int:
        return 32 + 32 * self.k * 10

    def _unpack_pk(self, pk):
        if len(pk) != self._pk_size():
            raise ValueError("PK packed bytes is of the wrong length")
        rho, t1_bytes = pk[:32], pk[32:]
        t1 = self.M.bit_unpack_t1(t1_bytes, self.k, 1)
        return rho, t1

    def _sk_size(self) -> int:
        if self.eta == 2:
            s_bytes = 96
        else:
            s_bytes = 128
        s1_len = s_bytes * self.l
        s2_len = s_bytes * self.k
        t0_len = 416 * self.k
        return 2 * 32 + 64 + s1_len + s2_len + t0_len

    def _unpack_sk(self, sk: bytes):
        if self.eta == 2:
            s_bytes = 96
        else:
            s_bytes = 128
        s1_len = s_bytes * self.l
        s2_len = s_bytes * self.k
        t0_len = 416 * self.k
        if len(sk) != self._sk_size():
            raise ValueError("sk packed bytes is of the wrong length")

        # Split bytes between seeds and vectors
        sk_seed_bytes, sk_vec_bytes = sk[:128], sk[128:]

        # Unpack seed bytes
        rho, k, tr = (
            sk_seed_bytes[:32],
            sk_seed_bytes[32:64],
            sk_seed_bytes[64:128],
        )

        # Unpack vector bytes
        s1_bytes = sk_vec_bytes[:s1_len]
        s2_bytes = sk_vec_bytes[s1_len: s1_len + s2_len]
        t0_bytes = sk_vec_bytes[-t0_len:]

        # Unpack bytes to vectors
        s1 = self.M.bit_unpack_s(s1_bytes, self.l, 1, self.eta)
        s2 = self.M.bit_unpack_s(s2_bytes, self.k, 1, self.eta)
        t0 = self.M.bit_unpack_t0(t0_bytes, self.k, 1)

        return rho, k, tr, s1, s2, t0

    def _unpack_h(self, h_bytes):
        offsets = [0] + list(h_bytes[-self.k:])

        # ensure offsets are monotonic increasing
        if any(offsets[i] > offsets[i + 1] for i in range(len(offsets) - 1)):
            raise ValueError(
                "offsets in h_bytes are not monotonically increasing")

        # ensure offset[-1] is smaller than the length of h_bytes
        if offsets[-1] > self.omega:
            raise ValueError("accumulate offset of hints exceeds omega")

        # ensure zero fields are all zeros
        if any(b != 0 for b in h_bytes[offsets[-1]: self.omega]):
            raise ValueError("non-zero fields in h_bytes are not all zeros")

        non_zero_positions = [
            list(h_bytes[offsets[i]: offsets[i + 1]]) for i in range(self.k)
        ]

        matrix = []
        for poly_non_zero in non_zero_positions:
            coeffs = [0 for _ in range(256)]
            for i, non_zero in enumerate(poly_non_zero):
                if i > 0 and non_zero < poly_non_zero[i - 1]:
                    raise ValueError(
                        "non-zero positions in h_bytes are not monotonically increasing"
                    )
                coeffs[non_zero] = 1
            matrix.append([self.R(coeffs)])
        return self.M(matrix)

    def _unpack_sig(self, sig: bytes):
        c_tilde = sig[: self.c_tilde_bytes]
        z_bytes = sig[self.c_tilde_bytes: -(self.k + self.omega)]
        h_bytes = sig[-(self.k + self.omega):]

        z = self.M.bit_unpack_z(z_bytes, self.l, 1, self.gamma_1)
        h = self._unpack_h(h_bytes)
        return c_tilde, z, h

    def _keygen_internal(self, zeta: bytes, _xof=shake256, _xof2=shake128, zk=False) -> tuple[bytes, bytes]:
        """
        Generates a public-private key pair from a seed following
        Algorithm 6 (FIPS 204)
        """
        # Expand with an XOF (SHAKE256)
        seed_domain_sep = zeta + bytes([self.k]) + bytes([self.l])
        seed_bytes = self._h(seed_domain_sep, 128, _xof=_xof)

        # Split bytes into suitable chunks
        rho, rho_prime, K = seed_bytes[:32], seed_bytes[32:96], seed_bytes[96:]

        # Generate matrix A ∈ R^(kxl) in the NTT domain
        A_hat = self._expand_matrix_from_seed(rho, _xof=_xof2, zk=zk)

        # Generate the error vectors s1 ∈ R^l, s2 ∈ R^k
        s1, s2 = self._expand_vector_from_seed(rho_prime, _xof=_xof)

        s1_hat = s1.to_ntt()

        # Matrix multiplication
        t = (A_hat @ s1_hat).from_ntt() + s2

        t1, t0 = t.power_2_round(self.d)

        # Pack up the bytes
        pk = self._pack_pk(rho, t1)
        tr = self._h(pk, 64, _xof=_xof)
        sk = self._pack_sk(rho, K, tr, s1, s2, t0)

        return pk, sk

    def _sign_internal(
        self,
        sk: bytes,
        m: bytes,
        rnd: bytes,
        external_mu: bool = False,
        _xof=shake256,
        _xof2=shake128,
        zk=False
    ) -> bytes:
        """
        Deterministic algorithm to generate a signature for a formatted message
        M' following Algorithm 7 (FIPS 204)

        When `external_mu` is `True`, the message `m` is interpreted instead as
        the pre-hashed message `mu = prehash_external_mu()`
        """
        # unpack the secret key
        rho, k, tr, s1, s2, t0 = self._unpack_sk(sk)

        # Precompute NTT representation
        s1_hat = s1.to_ntt()
        s2_hat = s2.to_ntt()
        t0_hat = t0.to_ntt()

        # Generate matrix A ∈ R^(kxl) in the NTT domain
        A_hat = self._expand_matrix_from_seed(rho, _xof=_xof2, zk=zk)

        # Set seeds and nonce (kappa)
        if external_mu:
            mu = m
        else:
            mu = self._h(tr + m, 64, _xof=_xof)

        rho_prime = self._h(k + rnd + mu, 64, _xof=_xof)

        kappa = 0
        alpha = self.gamma_2 << 1
        while True:
            y = self._expand_mask_vector(rho_prime, kappa, _xof=_xof)
            y_hat = y.to_ntt()
            w = (A_hat @ y_hat).from_ntt()

            # increment the nonce
            kappa += self.l

            # NOTE: there is an optimisation possible where both the high and
            # low bits of w are extracted here, which speeds up some checks
            # below and requires the use of make_hint_optimised() -- to see the
            # implementation of this, look at the signing algorithm for
            # dilithium. We include this slower version to mirror the FIPS 204
            # document precisely.
            # Extract out only the high bits
            w1 = w.high_bits(alpha)

            # Create challenge polynomial
            w1_bytes = w1.bit_pack_w(self.gamma_2)
            c_tilde = self._h(mu + w1_bytes, self.c_tilde_bytes, _xof=_xof)
            c = self.R.sample_in_ball(c_tilde, self.tau, _xof=_xof)
            c_hat = c.to_ntt()

            # NOTE: unlike FIPS 204 we start again as soon as a vector
            # fails the norm bound to reduce any unneeded computations.
            c_s1 = s1_hat.scale(c_hat).from_ntt()
            z = y + c_s1
            if z.check_norm_bound(self.gamma_1 - self.beta):
                continue

            c_s2 = s2_hat.scale(c_hat).from_ntt()
            r0 = (w - c_s2).low_bits(alpha)
            if r0.check_norm_bound(self.gamma_2 - self.beta):
                continue

            c_t0 = t0_hat.scale(c_hat).from_ntt()
            if c_t0.check_norm_bound(self.gamma_2):
                continue

            h = (-c_t0).make_hint(w - c_s2 + c_t0, alpha)
            if h.sum_hint() > self.omega:
                continue
            return self._pack_sig(c_tilde, z, h)

    def _verify_internal(
        self,
        pk: bytes,
        m: bytes,
        sig: bytes,
        _xof=shake256,
        _xof2=shake128,
        zk=False
    ) -> bool:
        """
        Internal function to verify a signature sigma for a formatted message M'
        following Algorithm 8 (FIPS 204)
        """
        rho, t1 = self._unpack_pk(pk)
        try:
            c_tilde, z, h = self._unpack_sig(sig)
        except ValueError:
            return False

        if h.sum_hint() > self.omega:
            return False

        if z.check_norm_bound(self.gamma_1 - self.beta):
            return False

        A_hat = self._expand_matrix_from_seed(rho, _xof=_xof2, zk=zk)

        tr = self._h(pk, 64, _xof=_xof)
        mu = self._h(tr + m, 64, _xof=_xof)
        c = self.R.sample_in_ball(c_tilde, self.tau, _xof=_xof)
        # Convert to NTT for computation
        c = c.to_ntt()
        z = z.to_ntt()

        t1 = t1.scale(1 << self.d)
        t1 = t1.to_ntt()

        Az_minus_ct1 = (A_hat @ z) - t1.scale(c)
        Az_minus_ct1 = Az_minus_ct1.from_ntt()

        w_prime = h.use_hint(Az_minus_ct1, 2 * self.gamma_2)
        w_prime_bytes = w_prime.bit_pack_w(self.gamma_2)

        return c_tilde == self._h(mu + w_prime_bytes, self.c_tilde_bytes, _xof=_xof)

    def keygen(self, _xof=shake256, _xof2=shake128, zk=False) -> tuple[bytes, bytes]:
        """
        Generates a public-private key pair following
        Algorithm 1 (FIPS 204)
        """
        zeta = self.random_bytes(32)
        pk, sk = self._keygen_internal(zeta, _xof=_xof, _xof2=_xof2, zk=zk)
        return (pk, sk)

    def key_derive(self, seed: bytes, _xof=shake256, _xof2=shake128, zk=False) -> tuple[bytes, bytes]:
        """
        Derive a verification key and corresponding signing key
        following the approach from Section 6.1 (FIPS 204)
        with storage of the ``seed`` value for later expansion.

        ``seed`` is a byte-encoded concatenation of the ``xi`` value.

        :return: Tuple with verification key and signing key.
        :rtype: tuple(bytes, bytes)
        """
        if len(seed) != 32:
            raise ValueError("The seed must be 32 bytes long")

        pk, sk = self._keygen_internal(seed, _xof=_xof, _xof2=_xof2, zk=zk)
        return (pk, sk)

    def sign(
        self,
        sk: bytes,
        m: bytes,
        ctx: bytes = b"",
        deterministic: bool = False,
        _xof=shake256,
        _xof2=shake128,
        zk=False
    ) -> bytes:
        """
        Generates an ML-DSA signature following
        Algorithm 2 (FIPS 204)
        """
        if len(ctx) > 255:
            raise ValueError(
                f"ctx bytes must have length at most 255, ctx has length {len(ctx)=}"
            )

        if deterministic:
            rnd = bytes([0] * 32)
        else:
            rnd = self.random_bytes(32)

        # Format the message using the context
        m_prime = bytes([0]) + bytes([len(ctx)]) + ctx + m

        # Compute the signature of m_prime
        sig_bytes = self._sign_internal(
            sk, m_prime, rnd, _xof=_xof, _xof2=_xof2, zk=zk)
        return sig_bytes

    def verify(
        self,
        pk: bytes,
        m: bytes,
        sig: bytes,
        ctx: bytes = b"",
        _xof=shake256,
        _xof2=shake128,
        zk=False
    ) -> bool:
        """
        Verifies a signature sigma for a message M following
        Algorithm 3 (FIPS 204)
        """
        if len(ctx) > 255:
            raise ValueError(
                f"ctx bytes must have length at most 255, ctx has length {len(ctx)=}"
            )

        # Format the message using the context
        m_prime = bytes([0]) + bytes([len(ctx)]) + ctx + m

        return self._verify_internal(pk, m_prime, sig, _xof=_xof, _xof2=_xof2, zk=zk)

    """
    The following additional function follows an outline from:
        https://github.com/aws/aws-lc/pull/2142
    which computes pk_bytes when only the sk_bytes are known.
    """

    def pk_from_sk(self, sk: bytes, _xof=shake256, _xof2=shake128, zk=False) -> bytes:
        """
        Given the packed representation of a ML-DSA secret key,
        compute the corresponding packed public key bytes.
        """
        # First unpack the secret key
        rho, _, tr, s1, s2, _ = self._unpack_sk(sk)

        # Compute the matrix A from rho in NTT form
        A_hat = self._expand_matrix_from_seed(rho, _xof=_xof2, zk=zk)

        # Convert s1 to NTT form
        s1_hat = s1.to_ntt()

        # Compute the polynomial t, we have the lower bits t0,
        # but we need the higher bits t1 for the public key
        t = (A_hat @ s1_hat).from_ntt() + s2
        t1, _ = t.power_2_round(self.d)

        # The packed public key is made from rho || t1
        pk = self._pack_pk(rho, t1, _xof=_xof)

        # Ensure the public key matches the hash within the secret key
        if tr != self._h(pk, 64, _xof=_xof):
            raise ValueError("malformed secret key")

        return pk

    """
    The following external mu functions are not in FIPS 204, but are in
    Appendix D of the following IETF draft and are included for experimentation
    for researchers and engineers

    https://datatracker.ietf.org/doc/html/draft-ietf-lamps-dilithium-certificates-07
    """

    def prehash_external_mu(self, pk: bytes, m: bytes, ctx: bytes = b"", _xof=shake256) -> bytes:
        """
        Prehash the message `m` with context `ctx` together with
        the public key. For use with `sign_external_mu()`
        """
        # Ensure the length of the context is as expected
        if len(ctx) > 255:
            raise ValueError(
                f"ctx bytes must have length at most 255, ctx has length {len(ctx)=}"
            )
        if len(pk) != self._pk_size():
            raise ValueError(
                f"Public key size doesn't match this ML-DSA object parameters,"
                f"received {len(pk)=}, expected: {self._pk_size()}"
            )

        # Format the message using the context
        m_prime = bytes([0]) + bytes([len(ctx)]) + ctx + m

        # Compute mu by hashing the public key into the message
        tr = self._h(pk, 64, _xof=_xof)
        mu = self._h(tr + m_prime, 64, _xof=_xof)

        return mu

    def sign_external_mu(
        self, sk: bytes, mu: bytes, deterministic: bool = False,
        _xof=shake256, _xof2=shake128
    ) -> bytes:
        """
        Generates an ML-DSA signature of a message given the prehash
        mu = H(H(pk), M')
        """
        # Ensure the length of the context is as expected
        if len(mu) != 64:
            raise ValueError(
                f"mu bytes must have length 64, mu has length {len(mu)=}"
            )

        if deterministic:
            rnd = bytes([0] * 32)
        else:
            rnd = self.random_bytes(32)

        # Compute the signature given external mu, we set the external_mu
        # to True
        sig = self._sign_internal(
            sk, mu, rnd, external_mu=True, _xof=_xof, _xof2=_xof2)
        return sig

    def pk_for_eth(self, pk, zk=False):
        # a preprocessing for ETHDilithium
        # - tr is computed for saving one hash
        # - t1 is computed in the NTT domain (and shifted by d).
        rho, t1 = self._unpack_pk(pk)
        tr = self._h(pk, 64, _xof=Keccak256PRNG)
        A_hat = self._expand_matrix_from_seed(rho, _xof=Keccak256PRNG, zk=zk)
        t1_new = t1.scale(1 << self.d).to_ntt()
        return A_hat, tr, t1_new
