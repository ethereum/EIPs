import os
from Crypto.Cipher import AES
from typing import Optional
from ..utilities.utils import xor_bytes


class AES256_CTR_DRBG:
    def __init__(self, seed: Optional[bytes] = None, personalization: bytes = b""):
        """
        DRBG implementation based on AES-256 CTR following the document NIST SP
        800-90A Section 10.2.1

        https://csrc.nist.gov/pubs/sp/800/90/a/r1/final

        Used for deterministic randomness, particularly used for comparing the
        output of Kyber/ML-KEM against known answer tests.

        :param bytes seed: 48 byte seed, if none is supplied a seed is generated
            using ``os.urandom(48)``.
        :param bytes personalization: optional bytes, of length at most 48 used
            during instantiation of the DRBG
        """
        self.seed_length = 48
        self.reseed_interval = 2**48
        self.key = bytes([0]) * 32
        self.V = bytes([0]) * 16
        self.entropy_input = self.__check_entropy_input(seed)

        seed_material = self.__instantiate(personalization=personalization)
        self.__ctr_drbg_update(seed_material)
        self.reseed_ctr = 1

    def __check_entropy_input(self, entropy_input: bytes) -> bytes:
        """
        If no entropy given, us os.urandom, else
        check that the input is of the right length.
        """
        if entropy_input is None:
            return os.urandom(self.seed_length)
        elif len(entropy_input) != self.seed_length:
            raise ValueError(
                f"The entropy input must be of length: {self.seed_length}. "
                f"Input has length {len(entropy_input)}"
            )
        return entropy_input

    def __instantiate(self, personalization: bytes = b"") -> bytes:
        """
        Combine the input seed and optional personalisation
        string into the seed material for the DRBG

        Section 10.2.1.3.1, Page 52 (CTR_DRBG_Instantiate_algorithm)
        """
        if len(personalization) > self.seed_length:
            raise ValueError(
                f"The Personalization String must be at most length: "
                f"{self.seed_length}. Input has length {len(personalization)}"
            )
        # Ensure personalization has exactly seed_length bytes
        personalization += bytes([0]) * (self.seed_length - len(personalization))
        # debugging
        assert len(personalization) == self.seed_length
        return xor_bytes(self.entropy_input, personalization)

    def __increment_counter(self) -> None:
        """
        Increment the internal counter of the DRBG
        """
        int_V = int.from_bytes(self.V, "big")
        new_V = (int_V + 1) % 2**128
        self.V = new_V.to_bytes(16, byteorder="big")

    def __ctr_drbg_update(self, provided_data: bytes) -> None:
        """
        Updates the internal state of the CTR_DRBG using the
        provided_data

        Section 10.2.1.2, Page 51 (CTR_DRBG_Update)
        """
        tmp = b""
        cipher = AES.new(self.key, AES.MODE_ECB)

        # Collect bytes from AES ECB
        while len(tmp) != self.seed_length:
            self.__increment_counter()
            tmp += cipher.encrypt(self.V)

        # Take the first 48 bytes
        tmp = tmp[: self.seed_length]
        tmp = xor_bytes(tmp, provided_data)

        # Set the new values of key and V
        self.key = tmp[:32]
        self.V = tmp[32:]

    def random_bytes(self, num_bytes: int, additional: Optional[bytes] = None) -> bytes:
        """
        Generate pseudorandom bytes without a generating function

        Section 10.2.1.5.1, Page 56 (CTR_DRBG_Generate_algorithm)

        :param int num_bytes: the number of random bytes requested
        :param bytes additional: optional bytes to be mixed into the generation
        :return: pseudorandom bytes extracted from the DRBG of length ``num_bytes``.
        :rtype: bytes
        """
        # We don't cover this in coverage as we would need to run the counter 2^48 times
        if self.reseed_ctr >= self.reseed_interval:  # pragma: no cover
            raise Warning("The DRBG has been exhausted! Reseed!")

        # Set the optional additional information
        if additional is None:
            additional = bytes([0]) * self.seed_length
        else:
            if len(additional) > self.seed_length:
                raise ValueError(
                    f"The additional input must be of length at most: "
                    f"{self.seed_length}. Input has length {len(additional)}"
                )
            additional += bytes([0]) * (self.seed_length - len(additional))
            self.__ctr_drbg_update(additional)

        # Collect bytes!
        tmp = b""
        cipher = AES.new(self.key, AES.MODE_ECB)
        while len(tmp) < num_bytes:
            self.__increment_counter()
            tmp += cipher.encrypt(self.V)

        # Collect only the requested number of bits
        output_bytes = tmp[:num_bytes]
        self.__ctr_drbg_update(additional)
        self.reseed_ctr += 1
        return output_bytes
