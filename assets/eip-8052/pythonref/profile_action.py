"""
Profile the code with:
> make profile
"""
from test import *

if __name__ == "__main__":
    test_signature(1024, 100)
    # test_ntrugen(1024, 10)
    # test_samplerz(10, 10, 10000)
    # test_compress(1024, 10000)
