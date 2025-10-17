"""
Compression and decompression routines for signatures.
"""


def compress(v, slen):
    """
    Take as input a list of integers v and a bytelength slen, and
    return a bytestring of length slen that encode/compress v.
    If this is not possible, return False.

    For each coefficient of v:
    - the sign is encoded on 1 bit
    - the 7 lower bits are encoded naively (binary)
    - the high bits are encoded in unary encoding
    """
    u = ""
    for coef in v:
        # Encode the sign
        s = "1" if coef < 0 else "0"
        # Encode the low bits
        s += format((abs(coef) % (1 << 7)), '#09b')[2:]
        # Encode the high bits
        s += "0" * (abs(coef) >> 7) + "1"
        u += s
    # The encoding is too long
    if len(u) > 8 * slen:
        return False
    u += "0" * (8 * slen - len(u))
    w = [int(u[8 * i: 8 * i + 8], 2) for i in range(len(u) // 8)]
    x = bytes(w)
    return x


def decompress(x, slen, n):
    """
    Take as input an encoding x, a bytelength slen and a length n, and
    return a list of integers v of length n such that x encode v.
    If such a list does not exist, the encoding is invalid and we output False.
    """
    if (len(x) > slen):
        print("Too long")
        return False
    w = list(x)
    u = ""
    for elt in w:
        u += bin((1 << 8) ^ elt)[3:]
    v = []

    # Remove the last bits
    while u[-1] == "0":
        u = u[:-1]

    try:
        while (u != "") and (len(v) < n):
            # Recover the sign of coef
            sign = -1 if u[0] == "1" else 1
            # Recover the 7 low bits of abs(coef)
            low = int(u[1:8], 2)
            i, high = 8, 0
            # Recover the high bits of abs(coef)
            while (u[i] == "0"):
                i += 1
                high += 1
            # Compute coef
            coef = sign * (low + (high << 7))
            # Enforce a unique encoding for coef = 0
            if (coef == 0) and (sign == -1):
                return False
            # Store intermediate results
            v += [coef]
            u = u[i + 1:]
        # In this case, the encoding is invalid
        if (len(v) != n):
            return False
        return v
    # IndexError is raised if indices are read outside the table bounds
    except IndexError:
        return False
