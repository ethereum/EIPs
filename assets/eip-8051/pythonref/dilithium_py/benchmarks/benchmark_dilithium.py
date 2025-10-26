from dilithium_py.dilithium import Dilithium2, Dilithium3, Dilithium5
import cProfile
from time import time
from statistics import mean, median


def profile_dilithium(Dilithium):
    pk, sk = Dilithium.keygen()
    m = b"Signed by dilithium"
    sig = Dilithium.sign(sk, m)
    check = Dilithium.verify(pk, m, sig)
    assert check

    gvars = {}
    lvars = {"Dilithium": Dilithium, "m": m, "pk": pk, "sk": sk, "sig": sig}

    cProfile.runctx(
        "[Dilithium.keygen() for _ in range(100)]", globals=gvars, locals=lvars, sort=1
    )
    cProfile.runctx(
        "[Dilithium.sign(sk, m) for _ in range(100)]",
        globals=gvars,
        locals=lvars,
        sort=1,
    )
    cProfile.runctx(
        "[Dilithium.verify(pk, m, sig) for _ in range(100)]",
        globals=gvars,
        locals=lvars,
        sort=1,
    )


def benchmark_dilithium(Dilithium, name, count):
    # Banner
    print("-" * 27)
    print(f"  {name} | ({count} calls)")
    print("-" * 27)

    fails = 0
    keygen_times = []
    sign_times = []
    verify_times = []
    # 32 byte message
    m = b"Your message signed by Dilithium"

    for _ in range(count):
        t0 = time()
        pk, sk = Dilithium.keygen()
        keygen_times.append(time() - t0)

        t1 = time()
        sig = Dilithium.sign(sk, m)
        sign_times.append(time() - t1)

        t2 = time()
        verify = Dilithium.verify(pk, m, sig)
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
    benchmark_dilithium(Dilithium2, "Dilithium2", count)
    benchmark_dilithium(Dilithium3, "Dilithium3", count)
    benchmark_dilithium(Dilithium5, "Dilithium5", count)
