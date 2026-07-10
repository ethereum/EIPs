
def xgcd(a, b):
    """ Returns gcd(a, b), and x, y such that ax + by = gcd(a, b) """
    x0, x1, y0, y1 = 1, 0, 0, 1
    while b:
        q, a, b = a // b, b, a % b
        x0, x1 = x1, x0 - q * x1
        y0, y1 = y1, y0 - q * y1
    return a, x0, y0


def inv_mod(elt, q):
    """
    Thomas Prest stores the inverses mod q, but in the long term, we will consider a larger q,
    and thus we do not store the inverses mod q (it would require a too large storage).
    """
    _, inv_elt, _ = xgcd(elt, q)
    assert (inv_elt * elt) % q == 1
    return inv_elt


def batch_modular_inversion(elements, q):
    """Compute batch inversion of a list of elements mod q."""
    n = len(elements)
    if n == 0:
        return []
    # Prefix products
    prefix = [None] * n
    prefix[0] = elements[0]
    for i in range(1, n):
        prefix[i] = (prefix[i - 1] * elements[i]) % q
    # Iinverse of the total product
    total_inv = inv_mod(prefix[-1], q)
    # Individual inverses using the prefix products
    inverses = [None] * n
    inverses[-1] = total_inv
    for i in range(n - 2, -1, -1):
        inverses[i] = (inverses[i + 1] * elements[i + 1]) % q
    # Final inverses
    for i in range(1, n):
        inverses[i] = (inverses[i] * prefix[i - 1]) % q
    return inverses


def bit_reverse_order(a):
    '''Reorders the given array in reverse-bit order.'''
    num_bits = len(bin(len(a) - 1)) - 2
    result = [0] * len(a)
    for i in range(len(a)):
        rev_index = int(bin(i)[2:].zfill(num_bits)[::-1], 2)
        result[rev_index] = a[i]
    return result


def legendre_symbol(a, q):
    """ Compute the Legendre symbol a|q using Euler's criterion. """
    return pow(a, (q - 1) // 2, q)


def tonelli_shanks(a, q):
    """ Solve x^2 ≡ a (mod q) using the Tonelli-Shanks algorithm. """
    if legendre_symbol(a, q) != 1:
        raise ValueError(f"No square root exists for {a} modulo {q}")
    s, m = 0, q - 1
    while m % 2 == 0:
        s += 1
        m //= 2
    z = 2
    while legendre_symbol(z, q) != q - 1:
        z += 1
    c = pow(z, m, q)
    t = pow(a, m, q)
    r = pow(a, (m + 1) // 2, q)
    while t != 1:
        # Find the smallest i such that t^(2^i) ≡ 1 (mod q)
        i = 0
        t2i = t
        while t2i != 1:
            t2i = pow(t2i, 2, q)
            i += 1
        b = pow(c, 2**(s-i-1), q)
        r = (r * b) % q
        t = (t * b * b) % q
        c = (b * b) % q
        s = i
    return r


def sqrt_mod(x, q):
    return tonelli_shanks(x, q)
