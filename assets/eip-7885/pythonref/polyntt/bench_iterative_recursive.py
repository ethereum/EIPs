from time import time
from polyntt.scripts.generate_test_vectors import deterministic_poly
from polyntt.poly import Poly
from polyntt.params import PARAMS


class BenchIterativeRecursive:
    def bench_ntt(iterations):
        print("Bench NTT")
        print("({} iterations)".format(iterations))

        print("\tq\tn\tRecursive\tIterative")
        for (q, two_adicity) in PARAMS:

            # for two sizes of polynomials
            for n in [1 << (two_adicity-2), 1 << (two_adicity-1)]:
                print("{:10.0f}\t{}".format(q, n), end='\t')
                p1 = Poly(deterministic_poly(q, n), q, 'NTTRecursive')
                T = p1.NTT
                tmp = p1.ntt()
                t1 = time()
                for i in range(iterations):
                    tmp = T.ntt(tmp)
                t2 = time()
                print("{:.0f} μs".format(
                    (t2-t1) * 10**6/iterations), end='\t\t')

                p1 = Poly(deterministic_poly(q, n), q, 'NTTIterative')
                T = p1.NTT
                tmp = p1.ntt()
                t3 = time()
                for i in range(iterations):
                    tmp = T.ntt(tmp)
                t4 = time()
                print("{:.0f} μs".format((t4-t3) * 10**6/iterations))

    def bench_intt(iterations):
        print("Bench INTT")
        print("({} iterations)".format(iterations))

        print("\tq\tn\tRecursive\tIterative")
        for (q, two_adicity) in PARAMS:

            # for two sizes of polynomials
            for n in [1 << (two_adicity-2), 1 << (two_adicity-1)]:
                print("{:10.0f}\t{}".format(q, n), end='\t')
                p1 = Poly(deterministic_poly(q, n), q, 'NTTRecursive')
                T = p1.NTT
                tmp = p1.ntt()
                t1 = time()
                for i in range(iterations):
                    tmp = T.intt(tmp)
                t2 = time()
                print("{:.0f} μs".format(
                    (t2-t1) * 10**6/iterations), end='\t\t')

                p1 = Poly(deterministic_poly(q, n), q, 'NTTIterative')
                T = p1.NTT
                tmp = p1.ntt()
                t3 = time()
                for i in range(iterations):
                    tmp = T.intt(tmp)
                t4 = time()
                print("{:.0f} μs".format((t4-t3) * 10**6/iterations))


BenchIterativeRecursive.bench_ntt(1000)
BenchIterativeRecursive.bench_intt(1000)
