class Module:
    def __init__(self, ring):
        """
        Initialise a module over the ring ``ring``.
        """
        self.ring = ring
        self.matrix = Matrix

    def random_element(self, m, n):
        """
        Generate a random element of the module of dimension m x n

        :param int m: the number of rows in the matrix
        :param int m: the number of columns in tge matrix
        :return: an element of the module with dimension `m times n`
        """
        elements = [[self.ring.random_element() for _ in range(n)]
                    for _ in range(m)]
        return self(elements)

    def __repr__(self):
        return f"Module over the commutative ring: {self.ring}"

    def __str__(self):
        return f"Module over the commutative ring: {self.ring}"

    def __call__(self, matrix_elements, transpose=False):
        if not isinstance(matrix_elements, list):
            raise TypeError(
                "elements of a module are matrices, built from elements of the base ring"
            )

        if isinstance(matrix_elements[0], list):
            for element_list in matrix_elements:
                if not all(isinstance(aij, self.ring.element) for aij in element_list):
                    raise TypeError(
                        f"All elements of the matrix must be elements of the ring: {self.ring}"
                    )
            return self.matrix(self, matrix_elements, transpose=transpose)

        elif isinstance(matrix_elements[0], self.ring.element):
            if not all(isinstance(aij, self.ring.element) for aij in matrix_elements):
                raise TypeError(
                    f"All elements of the matrix must be elements of the ring: {self.ring}"
                )
            return self.matrix(self, [matrix_elements], transpose=transpose)

        else:
            raise TypeError(
                "elements of a module are matrices, built from elements of the base ring"
            )

    def vector(self, elements):
        """
        Construct a vector given a list of elements of the module's ring

        :param list: a list of elements of the ring
        :return: a vector of the module
        """
        return self.matrix(self, [elements], transpose=True)

    def uncompact_256(self, mat, m):
        result = []
        for row in mat:
            res0 = []
            for elt in row:
                res0.append(self.ring.uncompact_256(elt, m))
            result.append(res0)
        return result


class Matrix:
    def __init__(self, parent, matrix_data, transpose=False):
        self.parent = parent
        self._data = matrix_data
        self._transpose = transpose
        if not self._check_dimensions():
            raise ValueError("Inconsistent row lengths in matrix")

    def dim(self):
        """
        Return the dimensions of the matrix with m rows
        and n columns

        :return: the dimension of the matrix ``(m, n)``
        :rtype: tuple(int, int)
        """
        if not self._transpose:
            return len(self._data), len(self._data[0])
        else:
            return len(self._data[0]), len(self._data)

    def _check_dimensions(self):
        """
        Ensure that the matrix is rectangular
        """
        return len(set(map(len, self._data))) == 1

    def transpose(self):
        """
        Return a matrix with the rows and columns of swapped
        """
        return self.parent(self._data, not self._transpose)

    def transpose_self(self):
        """
        Swap the rows and columns of the matrix in place
        """
        self._transpose = not self._transpose
        return

    T = property(transpose)

    def reduce_coefficients(self):
        """
        Reduce every element in the polynomial
        using the modulus of the PolynomialRing
        """
        for row in self._data:
            for ele in row:
                ele.reduce_coefficients()
        return self

    def __getitem__(self, idx):
        """
        matrix[i, j] returns the element on row i, column j
        """
        assert isinstance(idx, tuple) and len(
            idx) == 2, "Can't access individual rows"
        if not self._transpose:
            return self._data[idx[0]][idx[1]]
        else:
            return self._data[idx[1]][idx[0]]

    def __eq__(self, other):
        if self.dim() != other.dim():
            return False
        m, n = self.dim()
        return all([self[i, j] == other[i, j] for i in range(m) for j in range(n)])

    def __neg__(self):
        """
        Returns -self, by negating all elements
        """
        m, n = self.dim()
        return self.parent(
            [[-self[i, j] for j in range(n)] for i in range(m)],
            self._transpose,
        )

    def __add__(self, other):
        if not isinstance(other, type(self)):
            raise TypeError("Can only add matrices to other matrices")
        if self.parent != other.parent:
            raise TypeError("Matrices must have the same base ring")
        if self.dim() != other.dim():
            raise ValueError("Matrices are not of the same dimensions")

        m, n = self.dim()
        return self.parent(
            [[self[i, j] + other[i, j] for j in range(n)] for i in range(m)],
            False,
        )

    def __iadd__(self, other):
        self = self + other
        return self

    def __sub__(self, other):
        if not isinstance(other, type(self)):
            raise TypeError("Can only add matrices to other matrices")
        if self.parent != other.parent:
            raise TypeError("Matrices must have the same base ring")
        if self.dim() != other.dim():
            raise ValueError("Matrices are not of the same dimensions")

        m, n = self.dim()
        return self.parent(
            [[self[i, j] - other[i, j] for j in range(n)] for i in range(m)],
            False,
        )

    def __isub__(self, other):
        self = self - other
        return self

    def __matmul__(self, other):
        """
        Denoted A @ B
        """
        if not isinstance(other, type(self)):
            raise TypeError("Can only multiply matrcies with other matrices")
        if self.parent != other.parent:
            raise TypeError("Matrices must have the same base ring")

        m, n = self.dim()
        n_, l = other.dim()
        if not n == n_:
            raise ValueError("Matrices are of incompatible dimensions")

        return self.parent(
            [
                [sum(self[i, k] * other[k, j] for k in range(n))
                 for j in range(l)]
                for i in range(m)
            ]
        )

    def scale(self, other):
        """
        Multiply each element of the matrix by a polynomial or integer
        """
        if not (isinstance(other, self.parent.ring.element) or isinstance(other, int)):
            raise TypeError(
                "Can only multiply elements with polynomials or integers")

        matrix = [[other * ele for ele in row] for row in self._data]
        return self.parent(matrix, transpose=self._transpose)

    def dot(self, other):
        """
        Compute the inner product of two vectors
        """
        if not isinstance(other, type(self)):
            raise TypeError("Can only perform dot product with other matrices")
        res = self.T @ other
        assert res.dim() == (1, 1)
        return res[0, 0]

    def __repr__(self):
        m, n = self.dim()

        if m == 1:
            return str(self._data[0])

        max_col_width = [max(len(str(self[i, j]))
                             for i in range(m)) for j in range(n)]
        info = "]\n[".join(
            [
                ", ".join(
                    [f"{str(self[i, j]):>{max_col_width[j]}}" for j in range(n)])
                for i in range(m)
            ]
        )
        return f"[{info}]"

    def compact_256(self, m):
        res = []
        for row in self._data:
            res0 = []
            for p in row:
                res0.append(p.compact_256(m))
            res.append(res0)
        return res
