from .dilithium import Dilithium
# from .dilithium_eth import ETHDilithium

DEFAULT_PARAMETERS = {
    "dilithium2": {
        "d": 13,  # number of bits dropped from t
        "tau": 39,  # number of ±1 in c
        "gamma_1": 131072,  # coefficient range of y: 2^17
        "gamma_2": 95232,  # low order rounding range: (q-1)/88
        "k": 4,  # Dimensions of A = (k, l)
        "l": 4,  # Dimensions of A = (k, l)
        "eta": 2,  # Private key range
        "omega": 80,  # Max number of ones in hint
        "c_tilde_bytes": 32,
        "oid": (2, 16, 840, 1, 101, 3, 4, 3, 17),
    },
    "dilithium3": {
        "d": 13,  # number of bits dropped from t
        "tau": 49,  # number of ±1 in c
        "gamma_1": 524288,  # coefficient range of y: 2^19
        "gamma_2": 261888,  # low order rounding range: (q-1)/32
        "k": 6,  # Dimensions of A = (k, l)
        "l": 5,  # Dimensions of A = (k, l)
        "eta": 4,  # Private key range
        "omega": 55,  # Max number of ones in hint
        "c_tilde_bytes": 48,
        "oid": (2, 16, 840, 1, 101, 3, 4, 3, 18),
    },
    "dilithium5": {
        "d": 13,  # number of bits dropped from t
        "tau": 60,  # number of ±1 in c
        "gamma_1": 524288,  # coefficient range of y: 2^19
        "gamma_2": 261888,  # low order rounding range: (q-1)/32
        "k": 8,  # Dimensions of A = (k, l)
        "l": 7,  # Dimensions of A = (k, l)
        "eta": 2,  # Private key range
        "omega": 75,  # Max number of ones in hint
        "c_tilde_bytes": 64,
        "oid": (2, 16, 840, 1, 101, 3, 4, 3, 19),
    },
}

ZK_PARAMETERS = {
    "dilithium2babybear": {
        "d": 13,  # number of bits dropped from t
        "tau": 39,  # number of ±1 in c
        "gamma_1": 131072,  # coefficient range of y: 2^17
        "gamma_2": 983040,  # low order rounding range: (q-1)/2^11
        "k": 4,  # Dimensions of A = (k, l)
        "l": 5,  # Dimensions of A = (k, l)
        "eta": 4,  # Private key range
        "omega": 80,  # Max number of ones in hint
        "c_tilde_bytes": 32,
        "oid": (2, 16, 840, 1, 101, 3, 4, 3, 17),
    },
    "dilithium2koalabear": {
        "d": 13,  # number of bits dropped from t
        "tau": 39,  # number of ±1 in c
        "gamma_1": 131072,  # coefficient range of y: 2^17
        "gamma_2": 1040384,  # low order rounding range: (q-1)/2^11
        "k": 4,  # Dimensions of A = (k, l)
        "l": 5,  # Dimensions of A = (k, l)
        "eta": 4,  # Private key range
        "omega": 80,  # Max number of ones in hint
        "c_tilde_bytes": 32,
        "oid": (2, 16, 840, 1, 101, 3, 4, 3, 17),
    }
}

Dilithium2 = Dilithium(DEFAULT_PARAMETERS["dilithium2"])
Dilithium3 = Dilithium(DEFAULT_PARAMETERS["dilithium3"])
Dilithium5 = Dilithium(DEFAULT_PARAMETERS["dilithium5"])
ZKDilithiumBB = Dilithium(ZK_PARAMETERS["dilithium2babybear"], q=2013265921)
ZKDilithiumKB = Dilithium(ZK_PARAMETERS["dilithium2koalabear"], q=2130706433)
