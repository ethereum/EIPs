"""
Python implementation of Falcon:
https://falcon-sign.info/.
"""
from common import q
from numpy import set_printoptions
from math import sqrt
from fft import fft, ifft, sub, neg, add_fft, mul_fft
from ffsampling import gram, ffldl_fft, ffsampling_fft
from ntrugen import ntru_gen
from encoding import compress, decompress
from keccak_prng import KeccakPRNG
from shake import SHAKE
from blake2s_prng import Blake2sPRNG
from hashlib import blake2s
from polyntt.poly import Poly
from polyntt.ntt_iterative import NTTIterative
# Randomness
from os import urandom
from rng import ChaCha20
# For debugging purposes
import sys
if sys.version_info >= (3, 4):
    from importlib import reload  # Python 3.4+ only.


set_printoptions(linewidth=200, precision=5, suppress=True)

logn = {
    2: 1,
    4: 2,
    8: 3,
    16: 4,
    32: 5,
    64: 6,
    128: 7,
    256: 8,
    512: 9,
    1024: 10
}


# Bytelength of the signing salt and header
HEAD_LEN = 1
SALT_LEN = 40
SEED_LEN = 56


# Parameter sets for Falcon:
# - n is the dimension/degree of the cyclotomic ring
# - sigma is the std. dev. of signatures (Gaussians over a lattice)
# - sigmin is a lower bounds on the std. dev. of each Gaussian over Z
# - sigbound is the upper bound on ||s0||^2 + ||s1||^2
# - sig_bytelen is the bytelength of signatures
Params = {
    # FalconParam(2, 2)
    2: {
        "n": 2,
        "sigma": 144.81253976308423,
        "sigmin": 1.1165085072329104,
        "sig_bound": 101498,
        "sig_bytelen": 44,
    },
    # FalconParam(4, 2)
    4: {
        "n": 4,
        "sigma": 146.83798833523608,
        "sigmin": 1.1321247692325274,
        "sig_bound": 208714,
        "sig_bytelen": 47,
    },
    # FalconParam(8, 2)
    8: {
        "n": 8,
        "sigma": 148.83587593064718,
        "sigmin": 1.147528535373367,
        "sig_bound": 428865,
        "sig_bytelen": 52,
    },
    # FalconParam(16, 4)
    16: {
        "n": 16,
        "sigma": 151.78340713845503,
        "sigmin": 1.170254078853483,
        "sig_bound": 892039,
        "sig_bytelen": 63,
    },
    # FalconParam(32, 8)
    32: {
        "n": 32,
        "sigma": 154.6747794602761,
        "sigmin": 1.1925466358390344,
        "sig_bound": 1852696,
        "sig_bytelen": 82,
    },
    # FalconParam(64, 16)
    64: {
        "n": 64,
        "sigma": 157.51308555044122,
        "sigmin": 1.2144300507766141,
        "sig_bound": 3842630,
        "sig_bytelen": 122,
    },
    # FalconParam(128, 32)
    128: {
        "n": 128,
        "sigma": 160.30114421975344,
        "sigmin": 1.235926056771981,
        "sig_bound": 7959734,
        "sig_bytelen": 200,
    },
    # FalconParam(256, 64)
    256: {
        "n": 256,
        "sigma": 163.04153322607107,
        "sigmin": 1.2570545284063217,
        "sig_bound": 16468416,
        "sig_bytelen": 356,
    },
    # FalconParam(512, 128)
    512: {
        "n": 512,
        "sigma": 165.7366171829776,
        "sigmin": 1.2778336969128337,
        "sig_bound": 34034726,
        "sig_bytelen": 666,
    },
    # FalconParam(1024, 256)
    1024: {
        "n": 1024,
        "sigma": 168.38857144654395,
        "sigmin": 1.298280334344292,
        "sig_bound": 70265242,
        "sig_bytelen": 1280,
    },
}


def print_tree(tree, pref=""):
    """
    Display a LDL tree in a readable form.

    Args:
        T: a LDL tree

    Format: coefficient or fft
    """
    leaf = "|_____> "
    top = "|_______"
    son1 = "|       "
    son2 = "        "
    width = len(top)

    a = ""
    if len(tree) == 3:
        if (pref == ""):
            a += pref + str(tree[0]) + "\n"
        else:
            a += pref[:-width] + top + str(tree[0]) + "\n"
        a += print_tree(tree[1], pref + son1)
        a += print_tree(tree[2], pref + son2)
        return a

    else:
        return (pref[:-width] + leaf + str(tree) + "\n")


def normalize_tree(tree, sigma):
    """
    Normalize leaves of a LDL tree (from values ||b_i||**2 to sigma/||b_i||).

    Args:
        T: a LDL tree
        sigma: a standard deviation

    Format: coefficient or fft
    """
    if len(tree) == 3:
        normalize_tree(tree[1], sigma)
        normalize_tree(tree[2], sigma)
    else:
        tree[0] = sigma / sqrt(tree[0].real)
        tree[1] = 0


def hash_to_point(n, message, salt, xof=KeccakPRNG):
    """
    Hash a message to a point in Z[x] mod(Phi, q).
    Inspired by the Parse function from NewHope.
    """
    if q > (1 << 16):
        raise ValueError("The modulus is too large")

    k = (1 << 16) // q
    if xof == Blake2sPRNG:
        # /!\ hashing salt to get only 32 bytes (for cairo implementation)
        salt = blake2s(salt).digest()
    if xof != SHAKE:
        # /!\ Reversed compared to NIST
        salt, message = message, salt
    # Create a XOF object and hash the salt and message.
    xof = xof.new()
    xof.update(salt)
    xof.update(message)
    xof.flip()
    # Output pseudorandom bytes and map them to coefficients.
    hashed = [0 for i in range(n)]
    i = 0
    while i < n:
        # Takes 2 bytes, transform them in a 16 bits integer
        twobytes = xof.read(2)
        elt = (twobytes[0] << 8) + twobytes[1]  # This breaks in Python 2.x
        # Implicit rejection sampling
        if elt < k * q:
            hashed[i] = elt % q
            i += 1
    return hashed


class PublicKey:
    """
    This class contains methods for performing public key operations in Falcon.
    """

    def __init__(self, n, h):
        """Initialize a public key."""
        self.n = n
        self.pk = h
        self.hash_to_point = hash_to_point
        self.signature_bound = Params[n]["sig_bound"]
        self.sig_bytelen = Params[n]["sig_bytelen"]

    def __repr__(self):
        """Print the object in readable form."""
        rep = "Public for n = {}:\n\n".format(self.n)
        rep += "pk = {}\n".format(self.pk)
        return rep

    def verify(self, message, signature, ntt=NTTIterative, xof=KeccakPRNG):
        """
        Verify a signature.
        """
        # Unpack the salt and the short polynomial s1
        salt = signature[HEAD_LEN:HEAD_LEN + SALT_LEN]
        enc_s = signature[HEAD_LEN + SALT_LEN:]
        s1 = decompress(enc_s, self.sig_bytelen - HEAD_LEN - SALT_LEN, self.n)
        # Check that the encoding is valid
        if (s1 is False):
            print("Invalid encoding")
            return False

        # Compute s0 and normalize its coefficients in (-q/2, q/2]
        if xof == KeccakPRNG:
            xof = xof.new()
        hashed = Poly(
            self.hash_to_point(self.n, message, salt, xof=xof),
            q, ntt=ntt
        )
        s1 = Poly(s1, q, ntt=ntt)
        pk = Poly(self.pk, q, ntt=ntt)
        s0 = hashed - s1 * pk
        s0 = [(coef + (q >> 1)) % q - (q >> 1) for coef in s0.coeffs]

        # Check that the (s0, s1) is short
        norm_sign = sum(coef ** 2 for coef in s0)
        norm_sign += sum(coef ** 2 for coef in s1.coeffs)
        if norm_sign > self.signature_bound:
            print("Squared norm of signature is too large:", norm_sign)
            return False
        return True


class SecretKey:
    """
    This class contains methods for performing
    secret key operations (and also public key operations) in Falcon.

    One can:
    - initialize a secret key for:
        - n = 128, 256, 512, 1024,
        - phi = x ** n + 1,
        - q = 12 * 1024 + 1
    - find a preimage t of a point c (both in ( Z[x] mod (Phi,q) )**2 ) such that t*B0 = c
    - hash a message to a point of Z[x] mod (Phi,q)
    - sign a message
    - verify the signature of a message
    """

    def __init__(self, n, polys=None, ntt=NTTIterative, randombytes=urandom):
        """Initialize a secret key."""
        # Public parameters
        self.n = n
        self.sigma = Params[n]["sigma"]
        self.sigmin = Params[n]["sigmin"]
        self.signature_bound = Params[n]["sig_bound"]
        self.sig_bytelen = Params[n]["sig_bytelen"]

        # Compute NTRU polynomials f, g, F, G verifying fG - gF = q mod Phi
        if polys is None:
            self.f, self.g, self.F, self.G = ntru_gen(
                n, randombytes=randombytes)
        else:
            [f, g, F, G] = polys
            assert all((len(poly) == n) for poly in [f, g, F, G])
            self.f = f[:]
            self.g = g[:]
            self.F = F[:]
            self.G = G[:]

        # From f, g, F, G, compute the basis B0 of a NTRU lattice
        # as well as its Gram matrix and their fft's.
        B0 = [[self.g, neg(self.f)], [self.G, neg(self.F)]]
        G0 = gram(B0)
        self.B0_fft = [[fft(elt) for elt in row] for row in B0]
        G0_fft = [[fft(elt) for elt in row] for row in G0]

        self.T_fft = ffldl_fft(G0_fft)

        # Normalize Falcon tree
        normalize_tree(self.T_fft, self.sigma)

        # The public key is a polynomial such that h*f = g mod (Phi,q)
        # self.pk = div_zq(self.g, self.f)
        poly_f = Poly(self.f, q, ntt=ntt)
        poly_g = Poly(self.g, q, ntt=ntt)
        poly_h = poly_g/poly_f
        self.h = poly_h.coeffs
        self.hash_to_point = hash_to_point

    def __repr__(self, verbose=False):
        """Print the object in readable form."""
        rep = "Private key for n = {n}:\n\n".format(n=self.n)
        rep += "f = {f}\n".format(f=self.f)
        rep += "g = {g}\n".format(g=self.g)
        rep += "F = {F}\n".format(F=self.F)
        rep += "G = {G}\n".format(G=self.G)
        if verbose:
            rep += "\nFFT tree\n"
            rep += print_tree(self.T_fft, pref="")
        return rep

    def sample_preimage(self, point, seed=None):
        """
        Sample a short vector s such that s[0] + s[1] * h = point.
        """
        [[a, b], [c, d]] = self.B0_fft

        # We compute a vector t_fft such that:
        #     (fft(point), fft(0)) * B0_fft = t_fft
        # Because fft(0) = 0 and the inverse of B has a very specific form,
        # we can do several optimizations.
        point_fft = fft(point)
        t0_fft = [(point_fft[i] * d[i]) / q for i in range(self.n)]
        t1_fft = [(-point_fft[i] * b[i]) / q for i in range(self.n)]
        t_fft = [t0_fft, t1_fft]

        # We now compute v such that:
        #     v = z * B0 for an integral vector z
        #     v is close to (point, 0)
        if seed is None:
            # If no seed is defined, use urandom as the pseudo-random source.
            z_fft = ffsampling_fft(t_fft, self.T_fft, self.sigmin, urandom)
        else:
            # If a seed is defined, initialize a ChaCha20 PRG
            # that is used to generate pseudo-randomness.
            chacha_prng = ChaCha20(seed)
            z_fft = ffsampling_fft(t_fft, self.T_fft, self.sigmin,
                                   chacha_prng.randombytes)

        v0_fft = add_fft(mul_fft(z_fft[0], a), mul_fft(z_fft[1], c))
        v1_fft = add_fft(mul_fft(z_fft[0], b), mul_fft(z_fft[1], d))
        v0 = [int(round(elt)) for elt in ifft(v0_fft)]
        v1 = [int(round(elt)) for elt in ifft(v1_fft)]

        # The difference s = (point, 0) - v is such that:
        #     s is short
        #     s[0] + s[1] * h = point
        s = [sub(point, v0), neg(v1)]
        return s

    def sign(self, message, randombytes=urandom, xof=KeccakPRNG):
        """
        Sign a message. The message MUST be a byte string or byte array.
        Optionally, one can select the source of (pseudo-)randomness used
        (default: urandom).
        """
        int_header = 0x30 + logn[self.n]
        header = int_header.to_bytes(1, "little")

        salt = randombytes(SALT_LEN)
        hashed = self.hash_to_point(self.n, message, salt, xof=xof)
        # We repeat the signing procedure until we find a signature that is
        # short enough (both the Euclidean norm and the bytelength)
        while (1):
            if (randombytes == urandom):
                s = self.sample_preimage(hashed)
            else:
                seed = randombytes(SEED_LEN)
                s = self.sample_preimage(hashed, seed=seed)
            norm_sign = sum(coef ** 2 for coef in s[0])
            norm_sign += sum(coef ** 2 for coef in s[1])
            # Check the Euclidean norm
            if norm_sign <= self.signature_bound:
                enc_s = compress(
                    s[1], self.sig_bytelen - HEAD_LEN - SALT_LEN)
                # Check that the encoding is valid (sometimes it fails)
                if (enc_s is not False):
                    return header + salt + enc_s
