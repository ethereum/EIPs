import random


class PolynomialRing:
    """
    Initialise the polynomial ring:

        R = GF(q) / (X^n + 1)
    """

    def __init__(self, q, n):
        self.q = q
        self.n = n
        self.element = Polynomial

    def gen(self):
        """
        Return the generator `x` of the polynomial ring
        """
        return self([0, 1])

    def random_element(self):
        """
        Compute a random element of the polynomial ring with coefficients in the
        canonical range: ``[0, q-1]``
        """
        coefficients = [random.randint(0, self.q - 1) for _ in range(self.n)]
        return self(coefficients)

    def __call__(self, coefficients):
        if isinstance(coefficients, int):
            return self.element(self, [coefficients])
        if not isinstance(coefficients, list):
            raise TypeError(
                f"Polynomials should be constructed from a list of integers, of length at most d = {self.n}"
            )
        return self.element(self, coefficients)

    def __repr__(self):
        return f"Univariate Polynomial Ring in x over Finite Field of size {self.q} with modulus x^{self.n} + 1"

    def uncompact_256(self, lst, m):
        # splits the elements of lst (of 256 bits) into lists of m bits
        if not (1 <= m <= 256) or (256 % m != 0):
            raise ValueError(
                "b must be a divisor of 256 and in the range 1-256.")

        chunk_count = 256 // m
        mask = (1 << m) - 1  # Mask to extract b-bit chunks
        result = []
        for num in lst:
            chunk = []
            for i in range(chunk_count):
                chunk.append(num >> (i*m) & mask)
            result.extend(chunk)
        return result


class Polynomial:
    def __init__(self, parent, coefficients):
        self.parent = parent
        self.coeffs = self._parse_coefficients(coefficients)

    def is_zero(self):
        """
        Return if polynomial is zero: f = 0
        """
        return all(c == 0 for c in self.coeffs)

    def is_constant(self):
        """
        Return if polynomial is constant: f = c
        """
        return all(c == 0 for c in self.coeffs[1:])

    def _parse_coefficients(self, coefficients):
        """
        Helper function which right pads with zeros
        to allow polynomial construction as
        f = R([1,1,1])
        """
        l = len(coefficients)
        if l > self.parent.n:
            raise ValueError(
                f"Coefficients describe polynomial of degree greater than maximum degree {self.parent.n}"
            )
        elif l < self.parent.n:
            coefficients = coefficients + [0 for _ in range(self.parent.n - l)]
        return coefficients

    def reduce_coefficients(self):
        """
        Reduce all coefficients modulo q
        """
        self.coeffs = [c % self.parent.q for c in self.coeffs]
        return self

    def _add_mod_q(self, x, y):
        """
        add two coefficients modulo q
        """
        return (x + y) % self.parent.q

    def _sub_mod_q(self, x, y):
        """
        sub two coefficients modulo q
        """
        return (x - y) % self.parent.q

    def _schoolbook_multiplication(self, other):
        """
        Naive implementation of polynomial multiplication
        suitible for all R_q = F_1[X]/(X^n + 1)
        """
        n = self.parent.n
        a = self.coeffs
        b = other.coeffs
        new_coeffs = [0 for _ in range(n)]
        for i in range(n):
            for j in range(0, n - i):
                new_coeffs[i + j] += a[i] * b[j]
        for j in range(1, n):
            for i in range(n - j, n):
                new_coeffs[i + j - n] -= a[i] * b[j]
        return [c % self.parent.q for c in new_coeffs]

    def __neg__(self):
        """
        Returns -f, by negating all coefficients
        """
        neg_coeffs = [(-x % self.parent.q) for x in self.coeffs]
        return self.parent(neg_coeffs)

    def _add_(self, other):
        if isinstance(other, type(self)):
            new_coeffs = [
                self._add_mod_q(x, y) for x, y in zip(self.coeffs, other.coeffs)
            ]
        elif isinstance(other, int):
            new_coeffs = self.coeffs.copy()
            new_coeffs[0] = self._add_mod_q(new_coeffs[0], other)
        else:
            raise NotImplementedError(
                "Polynomials can only be added to each other")
        return new_coeffs

    def __add__(self, other):
        new_coeffs = self._add_(other)
        return self.parent(new_coeffs)

    def __radd__(self, other):
        return self.__add__(other)

    def __iadd__(self, other):
        self = self + other
        return self

    def _sub_(self, other):
        if isinstance(other, type(self)):
            new_coeffs = [
                self._sub_mod_q(x, y) for x, y in zip(self.coeffs, other.coeffs)
            ]
        elif isinstance(other, int):
            new_coeffs = self.coeffs.copy()
            new_coeffs[0] = self._sub_mod_q(new_coeffs[0], other)
        else:
            raise NotImplementedError(
                "Polynomials can only be subtracted from each other"
            )
        return new_coeffs

    def __sub__(self, other):
        new_coeffs = self._sub_(other)
        return self.parent(new_coeffs)

    def __rsub__(self, other):
        return -self.__sub__(other)

    def __isub__(self, other):
        self = self - other
        return self

    def __mul__(self, other):
        if isinstance(other, type(self)):
            new_coeffs = self._schoolbook_multiplication(other)
        elif isinstance(other, int):
            new_coeffs = [(c * other) % self.parent.q for c in self.coeffs]
        else:
            raise NotImplementedError(
                "Polynomials can only be multiplied by each other, or scaled by integers"
            )
        return self.parent(new_coeffs)

    def __rmul__(self, other):
        return self.__mul__(other)

    def __imul__(self, other):
        self = self * other
        return self

    def __pow__(self, n):
        if not isinstance(n, int):
            raise TypeError(
                "Exponentiation of a polynomial must be done using an integer."
            )

        # Deal with negative scalar multiplication
        if n < 0:
            raise ValueError(
                "Negative powers are not supported for elements of a Polynomial Ring"
            )
        f = self
        g = self.parent(1)
        while n > 0:
            if n % 2 == 1:
                g = g * f
            f = f * f
            n = n // 2
        return g

    def __eq__(self, other):
        if isinstance(other, type(self)):
            return self.coeffs == other.coeffs
        elif isinstance(other, int):
            if self.is_constant() and (other % self.parent.q) == self.coeffs[0]:
                return True
        return False

    def __getitem__(self, idx):
        return self.coeffs[idx]

    def __repr__(self):
        if self.is_zero():
            return "0"

        info = []
        for i, c in enumerate(self.coeffs):
            if c != 0:
                if i == 0:
                    info.append(f"{c}")
                elif i == 1:
                    if c == 1:
                        info.append("x")
                    else:
                        info.append(f"{c}*x")
                else:
                    if c == 1:
                        info.append(f"x^{i}")
                    else:
                        info.append(f"{c}*x^{i}")
        return " + ".join(info)

    def __str__(self):
        return self.__repr__()

    def compact_256(self, m):
        # compact a list of n small element of m bits into n*m/256 elements of 256 bits
        # (assuming 2^log_m = m is a divisor of n)
        a = self.coeffs
        assert m < 256
        assert len(a) % m == 0
        for elt in a:
            assert elt < (1 << m)
        b = [0] * (len(a) * m // 256)
        for i in range(len(a)):
            b[(i * m) // 256] |= a[i] << ((i % (256//m)) * m)
        return b
