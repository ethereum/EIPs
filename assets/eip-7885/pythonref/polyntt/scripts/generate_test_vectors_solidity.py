import hashlib
from polyntt.ntt_iterative import NTTIterative
from polyntt.poly import Poly
from polyntt.params import PARAMS


def encode(poly, q):
    # By default, q is a 32-bit integer.
    # NB: this does not apply to q_baby_bear nor q_plonky2.
    assert all([x < q for x in poly])
    size_q = (q.bit_length()+7)//8
    byte_string = b''.join(num.to_bytes(size_q, 'big') for num in poly)
    return byte_string.hex()


def deterministic_poly(q, n, seed="fixed_seed"):
    # This function is used for generating polynomials for the tests.
    # No randomness.
    return [int(hashlib.sha256(f"{seed}{i}".encode()).hexdigest(), 16) % q for i in range(n)]


for (q, two_adicity) in PARAMS:

    for n in [1 << (two_adicity-2), 1 << (two_adicity-1)]:  # for two sizes of polynomials
        file = open("../test_vectors/q{}_n{}.sol".format(q, n), "w")

        file.write(
            "// File generated using ../pythonref/scripts/generate_test_vectors_solidity.py\n\n")
        f = deterministic_poly(q, n, seed="seed_f")
        g = deterministic_poly(q, n, seed="seed_g")

        T = NTTIterative(q)
        f_ntt = T.ntt(f)
        g_ntt = T.ntt(g)
        f_ntt_intt = T.intt(f_ntt)
        g_ntt_intt = T.intt(g_ntt)
        assert f_ntt_intt == f
        assert g_ntt_intt == g

        f_ntt_mul_g_ntt = T.vec_mul(f_ntt, g_ntt)
        f_mul_g = T.intt(f_ntt_mul_g_ntt)
        assert f_mul_g == (Poly(f, q) * Poly(g, q)).coeffs

        f_ntt_add_g_ntt = T.vec_add(f_ntt, g_ntt)
        f_ntt_sub_g_ntt = T.vec_sub(f_ntt, g_ntt)

        # 1. ntt
        #   Input: f,g
        #   Output: ntt(f), ntt(g).
        file.write("// ntt of f and g;\n")
        file.write("uint{}[] f = {};\n".format(len(f), f))
        file.write("uint{}[] g = {};\n".format(len(g), g))
        file.write("uint{}[] f_ntt = {};\n".format(len(f_ntt), f_ntt))
        file.write("uint{}[] g_ntt = {};\n".format(len(g_ntt), g_ntt))
        file.write("\n")

        # 2. intt
        #   Input: f_ntt,g_ntt
        #   Output: f, g
        file.write("// intt of f_ntt and g_ntt;\n")
        file.write("uint{}[] f_ntt = {};\n".format(len(f_ntt), f_ntt))
        file.write("uint{}[] g_ntt = {};\n".format(len(g_ntt), g_ntt))
        file.write("uint{}[] f = {};\n".format(len(f), f))
        file.write("uint{}[] g = {};\n".format(len(g), g))
        file.write("\n")

        # 3. vec_mul
        #   Input: f_ntt, g_ntt,
        #   Output: f_ntt*g_ntt.
        file.write("// vec_mul of f_ntt and g_ntt;\n")
        file.write("uint{}[] f_ntt = {};\n".format(len(f_ntt), f_ntt))
        file.write("uint{}[] g_ntt = {};\n".format(len(g_ntt), g_ntt))
        file.write("uint{}[] f_ntt_mul_g_ntt = {};\n".format(
            len(f_ntt_mul_g_ntt), f_ntt_mul_g_ntt))
        file.write("\n")

        # 4. pol_mul
        #   Input: f,g,
        #   Output: f*g.
        file.write("// pol_mul of f and g;\n")
        file.write("uint{}[] f = {};\n".format(len(f), f))
        file.write("uint{}[] g = {};\n".format(len(g), g))
        file.write("uint{}[] f_mul_g = {};\n".format(len(f_mul_g), f_mul_g))
        file.write("\n")

        # 5. vec_add
        #   Input: f_ntt, g_ntt,
        #   Output: f_ntt + g_ntt.
        file.write("// vec_add of f_ntt and g_ntt;\n")
        file.write("uint{}[] f_ntt = {};\n".format(len(f_ntt), f_ntt))
        file.write("uint{}[] g_ntt = {};\n".format(len(g_ntt), g_ntt))
        file.write("uint{}[] f_ntt_add_g_ntt = {};\n".format(
            len(f_ntt_add_g_ntt), f_ntt_add_g_ntt))
        file.write("\n")

        # 6. vec_sub
        #   Input: f_ntt, g_ntt,
        #   Output: f_ntt - g_ntt.
        file.write("// vec_sub of f_ntt and g_ntt;\n")
        file.write("uint{}[] f_ntt = {};\n".format(len(f_ntt), f_ntt))
        file.write("uint{}[] g_ntt = {};\n".format(len(g_ntt), g_ntt))
        file.write("uint{}[] f_ntt_sub_g_ntt = {};\n".format(
            len(f_ntt_sub_g_ntt), f_ntt_sub_g_ntt))
        file.write("\n")
    file.close()
