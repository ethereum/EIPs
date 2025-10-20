from dilithium_py.ml_dsa import ML_DSA_44, ML_DSA_65, ML_DSA_87
import cProfile
from time import time
from statistics import mean, median


def profile_ml_dsa(ML_DSA):
    pk, sk = ML_DSA.keygen()
    m = b"Signed by ml_dsa"
    sig = ML_DSA.sign(sk, m)
    check = ML_DSA.verify(pk, m, sig)
    assert check

    gvars = {}
    lvars = {"ML_DSA": ML_DSA, "m": m, "pk": pk, "sk": sk, "sig": sig}

    cProfile.runctx(
        "[ML_DSA.keygen() for _ in range(500)]", globals=gvars, locals=lvars, sort=1
    )
    # cProfile.runctx(
    #     "[ML_DSA.sign(sk, m) for _ in range(500)]",
    #     globals=gvars,
    #     locals=lvars,
    #     sort=1,
    # )
    # cProfile.runctx(
    #     "[ML_DSA.verify(pk, m, sig) for _ in range(500)]",
    #     globals=gvars,
    #     locals=lvars,
    #     sort=1,
    # )


def benchmark_ml_dsa(ML_DSA, name, count):
    # Banner
    print("-" * 27)
    print(f"  {name} | ({count} calls)")
    print("-" * 27)

    fails = 0
    keygen_times = []
    sign_times = []
    verify_times = []
    # 32 byte message
    m = b"Your message signed by ML_DSA"

    for _ in range(count):
        t0 = time()
        pk, sk = ML_DSA.keygen()
        keygen_times.append(time() - t0)

        t1 = time()
        sig = ML_DSA.sign(sk, m)
        sign_times.append(time() - t1)

        t2 = time()
        verify = ML_DSA.verify(pk, m, sig)
        verify_times.append(time() - t2)
        if not verify:
            fails += 1

    print(f"Keygen median: {round(median(keygen_times), 3)}")
    print(f"Sign median: {round(median(sign_times),3)}")
    print(f"Sign average: {round(mean(sign_times),3)}")
    print(f"Verify median: {round(median(verify_times),3)}")
    print(f"Fails: {fails}")


if __name__ == "__main__":
    # I used 1000 calls for the README, but you might want to
    # shrink this down if you're experimenting
    count = 1000
    benchmark_ml_dsa(ML_DSA_44, "ML_DSA_44", count)
    benchmark_ml_dsa(ML_DSA_65, "ML_DSA_65", count)
    benchmark_ml_dsa(ML_DSA_87, "ML_DSA_87", count)

    # profile_ml_dsa(ML_DSA_44)
