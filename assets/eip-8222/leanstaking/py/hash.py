from snark_lib import *
from utils.hash import *


def main():
    a = NONRESERVED_PROGRAM_INPUT_START
    b = a + 8
    res = Array(8)
    poseidon16_compress(a, b, res)
    for i in range(0, 8):
        print(res[i])
    return
