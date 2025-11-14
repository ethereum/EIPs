"""
This file implements tests for various parts of the Falcon.py library.

Test the code with:
> make test
"""
from keccak_prng import KeccakPRNG
from timeit import default_timer as timer
from scripts.samplerz_KAT1024 import sampler_KAT1024
from scripts.sign_KAT import sign_KAT
from scripts.samplerz_KAT512 import sampler_KAT512
from scripts import saga
from encoding import compress, decompress
from falcon import SALT_LEN, HEAD_LEN
from shake import SHAKE
from keccaxof import KeccaXOF
from falcon import SecretKey, PublicKey, Params
from ntrugen import karamul, ntru_gen, gs_norm
from math import sqrt, ceil
from random import randint, random, gauss, uniform
from ffsampling import gram
from ffsampling import ffldl, ffldl_fft, ffnp, ffnp_fft
from samplerz import samplerz, MAX_SIGMA
from fft import add, sub, mul, div, neg, fft, ifft
from common import q, sqnorm


def vecmatmul(t, B):
    """Compute the product t * B, where t is a vector and B is a square matrix.

    Args:
        B: a matrix

    Format: coefficient
    """
    nrows = len(B)
    ncols = len(B[0])
    deg = len(B[0][0])
    assert (len(t) == nrows)
    v = [[0 for k in range(deg)] for j in range(ncols)]
    for j in range(ncols):
        for i in range(nrows):
            v[j] = add(v[j], mul(t[i], B[i][j]))
    return v


def test_fft(n, iterations=10):
    """Test the FFT."""
    for i in range(iterations):
        f = [randint(-3, 4) for j in range(n)]
        g = [randint(-3, 4) for j in range(n)]
        h = mul(f, g)
        k = div(h, f)
        k = [int(round(elt)) for elt in k]
        if k != g:
            print("(f * g) / f =", k)
            print("g =", g)
            print("mismatch")
            return False
    return True


def check_ntru(f, g, F, G):
    """Check that f * G - g * F = q mod (x ** n + 1)."""
    a = karamul(f, G)
    b = karamul(g, F)
    c = [a[i] - b[i] for i in range(len(f))]
    return ((c[0] == q) and all(coef == 0 for coef in c[1:]))


def test_ntrugen(n, iterations=10):
    """Test ntru_gen."""
    for i in range(iterations):
        f, g, F, G = ntru_gen(n)
        if check_ntru(f, g, F, G) is False:
            return False
    return True


def test_ffnp(n, iterations):
    """Test ffnp.

    This functions check that:
    1. the two versions (coefficient and FFT embeddings) of ffnp are consistent
    2. ffnp output lattice vectors close to the targets.
    """
    f = sign_KAT[n][0]["f"]
    g = sign_KAT[n][0]["g"]
    F = sign_KAT[n][0]["F"]
    G = sign_KAT[n][0]["G"]
    B = [[g, neg(f)], [G, neg(F)]]
    G0 = gram(B)
    G0_fft = [[fft(elt) for elt in row] for row in G0]
    T = ffldl(G0)
    T_fft = ffldl_fft(G0_fft)

    sqgsnorm = gs_norm(f, g, q)
    m = 0
    for i in range(iterations):
        t = [[random() for i in range(n)], [random() for i in range(n)]]
        t_fft = [fft(elt) for elt in t]

        z = ffnp(t, T)
        z_fft = ffnp_fft(t_fft, T_fft)

        zb = [ifft(elt) for elt in z_fft]
        zb = [[round(coef) for coef in elt] for elt in zb]
        if z != zb:
            print("ffnp and ffnp_fft are not consistent")
            return False
        diff = [sub(t[0], z[0]), sub(t[1], z[1])]
        diffB = vecmatmul(diff, B)
        norm_zmc = int(round(sqnorm(diffB)))
        m = max(m, norm_zmc)
    th_bound = (n / 4.) * sqgsnorm
    if m > th_bound:
        print("Warning: ffnp does not output vectors as short as expected")
        return False
    else:
        return True


def test_compress(n, iterations):
    """Test compression and decompression."""
    try:
        sigma = 1.5 * sqrt(q)
        slen = Params[n]["sig_bytelen"] - SALT_LEN - HEAD_LEN
    except KeyError:
        return True
    for i in range(iterations):
        while (1):
            initial = [int(round(gauss(0, sigma))) for coef in range(n)]
            compressed = compress(initial, slen)
            if compressed is not False:
                break
        decompressed = decompress(compressed, slen, n)
        if decompressed != initial:
            return False
    return True


def test_samplerz(nb_mu=100, nb_sig=100, nb_samp=1000):
    """
    Test our Gaussian sampler on a bunch of samples.
    This is done by using a light version of the SAGA test suite,
    see ia.cr/2019/1411.
    """
    # Minimal size of a bucket for the chi-squared test (must be >= 5)
    chi2_bucket = 10
    assert (nb_samp >= 10 * chi2_bucket)
    sigmin = 1.3
    nb_rej = 0
    for i in range(nb_mu):
        mu = uniform(0, q)
        for j in range(nb_sig):
            sigma = uniform(sigmin, MAX_SIGMA)
            list_samples = [samplerz(mu, sigma, sigmin)
                            for _ in range(nb_samp)]
            v = saga.UnivariateSamples(mu, sigma, list_samples)
            if (v.is_valid is False):
                nb_rej += 1
    return True
    if (nb_rej > 5 * ceil(saga.pmin * nb_mu * nb_sig)):
        return False
    else:
        return True


def KAT_randbytes(k):
    """
    Use a fixed bytestring 'octets' as a source of random bytes
    """
    global octets
    oc = octets[: (2 * k)]
    if len(oc) != (2 * k):
        raise IndexError("Randomness string out of bounds")
    octets = octets[(2 * k):]
    return bytes.fromhex(oc)[::-1]


def test_samplerz_KAT(unused, unused2):
    # octets is a global variable used as samplerz's randomness.
    # It is set to many fixed values by test_samplerz_KAT,
    # then used as a randomness source via KAT_randbits.
    global octets
    for D in sampler_KAT512 + sampler_KAT1024:
        mu = D["mu"]
        sigma = D["sigma"]
        sigmin = D["sigmin"]
        # Hard copy. octets is the randomness source for samplez
        octets = D["octets"][:]
        exp_z = D["z"]
        try:
            z = samplerz(mu, sigma, sigmin, randombytes=KAT_randbytes)
        except IndexError:
            return False
        if (exp_z != z):
            print("SamplerZ does not match KATs")
            return False
    return True


# def test_sign_KAT(unused, unused2):
#     """
#     Test the signing procedure against test vectors obtained from
#     the Round 3 implementation of Falcon.

#     Starting from the same private key, same message, and same SHAKE256
#     context (for randomness generation), we check that we obtain the
#     same signatures.
#     """
#     message = b"data1"
#     shake = SHAKE.new(b"external")
#     for n in sign_KAT:
#         sign_KAT_n = sign_KAT[n]
#         for D in sign_KAT_n:
#             f = D["f"]
#             g = D["g"]
#             F = D["F"]
#             G = D["G"]
#             sk = SecretKey(n, [f, g, F, G])
#             # The next line is done to synchronize the SHAKE256 context
#             # with the one in the Round 3 C implementation of Falcon.
#             _ = shake.read(8 * D["read_bytes"])
#             sig = sk.sign(message, shake.read, xof=shake)
#             if sig != bytes.fromhex(D["sig"]):
#                 return False
#     return True


def wrapper_test(my_test, name, n, iterations):
    """
    Common wrapper for tests. Run the test, print whether it is successful,
    and if it is, print the running time of each execution.
    """
    d = {True: "OK    ", False: "Not OK"}
    start = timer()
    rep = my_test(n, iterations)
    end = timer()
    message = "Test {name}".format(name=name)
    message = message.ljust(20) + ": " + d[rep]
    if rep is True:
        diff = end - start
        msec = round(diff * 1000 / iterations, 3)
        message += " ({msec} msec / execution)".format(msec=msec).rjust(30)
    print(message)


# Dirty trick to fit test_samplerz into our test wrapper
def test_samplerz_simple(n, iterations):
    return test_samplerz(10, 10, iterations // 100)


def test_hash_to_point(n):
    f = sign_KAT[n][0]["f"]
    g = sign_KAT[n][0]["g"]
    F = sign_KAT[n][0]["F"]
    G = sign_KAT[n][0]["G"]
    sk = SecretKey(n, [f, g, F, G])
    message = b"abc"
    salt = b"def"
    xof = KeccaXOF
    hash = sk.hash_to_point(message, salt, xof=xof)
    assert hash == [7373, 883, 5550, 2322, 8580, 11319, 1037, 9708, 7159, 4158, 683, 1120, 9948, 11269, 790, 6252, 2698, 12217, 3596, 1819, 10441, 8257, 3040, 5573, 5213, 5150, 6123, 4363, 10505, 3359, 363, 10882, 4000, 3996, 2150, 6823, 8209, 10781, 11953, 397, 10576, 5527, 239, 7733, 8493, 3126, 3301, 10385, 7235, 8080, 1175, 6491, 11269, 3618, 3479, 1771, 406, 5245, 9874, 10195, 6777, 5908, 10147, 2321, 71, 5157, 6106, 9459, 7587, 7005, 10808, 9396, 6657, 10692, 11888, 10688, 9776, 6123, 11708, 6919, 1184, 3832, 4832, 6274, 5330, 7664, 9929, 4401, 8412, 7710, 1733, 8158, 8469, 10972, 8546, 10418, 1032, 5926, 6686, 1606, 2094, 6147, 4268, 2856, 9724, 8827, 2276, 327, 364, 3546, 5060, 38, 6461, 7825, 11703, 10229, 586, 6232, 5538, 8703, 9068, 1751, 1261, 10886, 8971, 10072, 4803, 12269, 11905, 1677, 168, 2793, 2446, 5598, 8609, 4471, 10206, 1457, 3344, 2115, 6331, 11897, 1509, 8496, 12033, 3422, 10769, 11981, 6746, 7141, 94, 5401, 5412, 7172, 4080, 1804, 5720, 7593, 8985, 1068, 866, 2872, 1144, 8687, 1395, 3877, 6666, 380, 1886, 8886, 3537, 6025, 4523, 11893, 2189, 9675, 9704, 2827, 4970, 1684, 6198, 9349, 2356, 9487, 9011, 6136, 2937, 7772, 8917, 5851, 5574, 4245, 1868, 3395, 11345, 9115, 6179, 8240, 170, 11821, 11009, 10257, 2003, 2154, 4612, 1906, 7653, 203, 6384, 437, 6531, 145, 10917, 2606, 6845, 8790, 700, 6949, 12030, 3271, 8790, 8978, 856, 963, 7089, 7632, 4568, 1919, 981, 8380, 3234, 8620, 9570, 6974, 3323, 9642, 11463, 7488, 12036, 9285, 2705, 10601, 10934, 6299, 2429, 5872, 2395, 8623, 10114, 2620, 2630, 590, 3967, 4556, 9924,
                    879, 2707, 4040, 6396, 3889, 4566, 8314, 6265, 9124, 11261, 5979, 11982, 1516, 1839, 8051, 2727, 11180, 7284, 8952, 6320, 2185, 12130, 2611, 7147, 8642, 333, 9797, 3864, 3853, 2205, 537, 2776, 6938, 10117, 3333, 5040, 4924, 7216, 862, 5323, 5855, 7323, 11256, 7123, 5614, 10247, 6583, 1246, 2875, 9923, 271, 2680, 4780, 3484, 907, 542, 9323, 6595, 12025, 7084, 3173, 10515, 7797, 9340, 4198, 877, 7058, 10517, 10104, 2880, 8175, 9685, 7269, 11157, 3314, 3034, 11799, 2551, 11904, 7429, 5751, 3132, 3452, 4780, 7713, 6464, 4353, 8079, 10272, 9572, 3381, 2148, 4100, 4467, 8107, 60, 609, 67, 11037, 478, 3026, 9156, 4803, 7480, 5859, 8840, 3731, 3487, 5738, 9166, 2234, 292, 5043, 6837, 7510, 7688, 2131, 11644, 12285, 4427, 6851, 5184, 5932, 242, 4802, 8613, 11136, 1682, 11256, 6734, 6703, 7082, 9114, 9563, 9119, 8417, 10026, 12245, 2885, 1798, 8815, 4490, 4079, 9728, 2595, 4923, 9698, 9093, 3926, 670, 4016, 10825, 1518, 8949, 909, 8707, 9346, 8743, 2106, 3059, 11835, 11278, 10934, 10177, 7263, 10275, 5048, 6952, 6250, 2353, 3920, 2781, 7631, 8632, 1223, 5428, 7385, 10594, 12115, 5957, 10539, 6384, 2624, 3349, 718, 8849, 228, 10276, 6353, 10616, 1686, 10242, 9974, 8008, 3376, 8098, 4266, 1021, 10080, 8667, 8964, 3002, 7628, 6421, 1920, 3720, 9781, 4655, 8790, 10767, 10205, 7210, 1727, 9543, 11341, 3906, 6320, 11588, 4259, 11000, 12284, 2957, 9151, 1844, 2047, 7067, 7948, 4312, 10967, 1997, 3450, 7, 9290, 10288, 5251, 2092, 3033, 10705, 9763, 12187, 4430, 6390, 3185, 12255, 287, 11098, 5316, 9010, 6996, 4205, 991, 2719, 6812, 8947, 7238, 4094, 2293]


def test(n, iterations=500):
    """A battery of tests."""
    wrapper_test(test_fft, "FFT", n, iterations)
    # test_ntrugen is super slow, hence performed over a single iteration
    wrapper_test(test_ntrugen, "NTRUGen", n, 1)
    wrapper_test(test_ffnp, "ffNP", n, iterations)
    # test_compress and test_signature are only performed
    # for parameter sets that are defined.
    if (n in Params):
        wrapper_test(test_compress, "Compress", n, iterations)
        # wrapper_test(test_sign_KAT, "Signature KATs", n, iterations)
    print("")

    # Run all the tests
if (__name__ == "__main__"):
    # print("Test Sig KATs       : ", end="")
    # print("OK" if (test_sign_KAT() is True) else "Not OK")

    # # wrapper_test(test_samplerz_simple, "SamplerZ", None, 100000)
    # wrapper_test(test_samplerz_KAT, "SamplerZ KATs", None, 1)
    # print("")

    for i in range(9, 10):
        n = (1 << i)
        it = 100
        print("Test battery for n = {n}".format(n=n))
        test(n, it)
