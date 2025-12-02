from algorithm_registry import helpers, registry


SIGRECOVER_BASE_GAS = 3000


def sigrecover_precompile(input: bytes) -> bytes:
  assert(len(input) >= 34)
  signature = input[:-33]

  # This is a magic number to support
  # potential extensions of hash space
  # if required by a future EIP.
  assert(input[-33] == 0x20)

  hash: Hash32 = input[-32:]

  # Get type
  algorithm_type = signature[0]

  # Ensure the algorithm exists
  if algorithm_type not in registry.algorithm_registry:
    return "0x0000000000000000000000000000000000000000"

  alg = registry.algorithm_registry[algorithm_type]

  # Run verify function
  try:
    pubkey = alg.verify(signature, hash)
    return helpers.pubkey_to_address(pubkey, algorithm_type)
  except Exception as e:
    print(e)
    return "0x0000000000000000000000000000000000000000"



def calculate_sigrecover_gas(input: bytes) -> int:
    try:
        assert(len(input) >= 34)
        signature = input[:-33]

        return SIGRECOVER_BASE_GAS + helpers.calculate_penalty(signature)
    except AssertionError:
        return SIGRECOVER_BASE_GAS

