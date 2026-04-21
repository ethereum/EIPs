import hashlib
from polyntt.ntt_iterative import NTTIterative
from polyntt.poly import Poly
from polyntt.params import PARAMS


def write_test(f, input, name, expected, gas, final=False):
    f.write("\t{\n")
    f.write("\t\t\"Input\": \"{}\",\n".format(input))
    f.write("\t\t\"Name\": \"{}\",\n".format(name))
    f.write("\t\t\"Expected\": \"{}\",\n".format(expected))
    f.write("\t\t\"Gas\": {}\n".format(gas))
    if final:
        f.write("\t}\n")
    else:
        f.write("\t},\n")


def encode(poly, q):
    # By default, q is a 32-bit integer.
    # NB: this does not apply to q_baby_bear nor q_plonky2.
    assert all([x < q for x in poly])
    size_q = (q.bit_length()+7)//8
    byte_string = b''.join(num.to_bytes(size_q, 'big') for num in poly)
    return byte_string.hex()


def decode(hex_poly, q):
    # By default, q is a 32-bit integer.
    # NB: this does not apply to q_baby_bear nor q_plonky2.
    size_q = (q.bit_length()+7)//8
    bytes_poly = bytes.fromhex(hex_poly)
    return [int.from_bytes(bytes_poly[i:i+size_q], 'big') for i in range(0, len(bytes_poly), size_q)]


def deterministic_poly(q, n, seed="fixed_seed"):
    # This function is used for generating polynomials for the tests.
    # No randomness.
    return [int(hashlib.sha256(f"{seed}{i}".encode()).hexdigest(), 16) % q for i in range(n)]


f = deterministic_poly(8, 3329)
assert decode(encode(f, 3329), 3329) == f
assert decode(encode(f, 3329), 3329) == f

for (q, two_adicity) in PARAMS:

    for n in [1 << (two_adicity-2), 1 << (two_adicity-1)]:  # for two sizes of polynomials
        file = open("../test_vectors/q{}_n{}.json".format(q, n), "w")

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

        file.write("[\n")
        # 1. ntt
        #   Input: f,g
        #   Output: ntt(f), ntt(g).
        input = encode(f, q)+encode(g, q)
        name = "q{}_n{}_{{ntt_of_two_polynomials}}".format(q, n)
        expected = encode(f_ntt, q)+encode(g_ntt, q)
        gas = 600
        write_test(file, input, name, expected, gas)

        # 2. intt
        #   Input: f_ntt,g_ntt
        #   Output: f, g
        input = encode(f_ntt, q)+encode(g_ntt, q)
        name = "q{}_n{}_{{intt_of_two_polynomials}}".format(q, n)
        expected = encode(f_ntt_intt, q)+encode(g_ntt_intt, q)
        gas = 600
        write_test(file, input, name, expected, gas)

        # 3. vec_mul
        #   Input: f_ntt, g_ntt,
        #   Output: f_ntt*g_ntt.
        input = encode(f_ntt, q)+encode(g_ntt, q)
        name = "q{}_n{}_{{vec_mul}}".format(q, n)
        expected = encode(f_ntt_mul_g_ntt, q)
        gas = 300
        write_test(file, input, name, expected, gas)

        # 4. pol_mul
        #   Input: f,g,
        #   Output: f*g.
        input = encode(f, q)+encode(g, q)
        name = "q{}_n{}_{{pol_mul}}".format(q, n)
        expected = encode(f_mul_g, q)
        gas = 600 + 600 + 300 + 600
        write_test(file, input, name, expected, gas)

        # 5. vec_add
        #   Input: f_ntt, g_ntt,
        #   Output: f_ntt + g_ntt.
        input = encode(f_ntt, q)+encode(g_ntt, q)
        name = "q{}_n{}_{{vec_add}}".format(q, n)
        expected = encode(f_ntt_add_g_ntt, q)
        gas = 50  # TODO
        write_test(file, input, name, expected, gas)

        # 6. vec_sub
        #   Input: f_ntt, g_ntt,
        #   Output: f_ntt - g_ntt.
        input = encode(f_ntt, q)+encode(g_ntt, q)
        name = "q{}_n{}_{{vec_sub}}".format(q, n)
        expected = encode(f_ntt_sub_g_ntt, q)
        gas = 100  # TODO
        write_test(file, input, name, expected, gas, final=True)

        file.write("]\n")
    file.close()
