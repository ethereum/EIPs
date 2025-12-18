from algorithm_registry import helpers, registry

INVALID = b"\x00" * 20
SIGRECOVER_BASE_GAS = 3000

# Modified sigrecover precompile to also return gas
def sigrecover_precompile(input: bytes) -> tuple[bytes, int]:
  gas = SIGRECOVER_BASE_GAS
  try:
    assert len(input) >= 1
    assert input[0] in registry.algorithm_registry

    size = registry.algorithm_registry[input[0]].SIZE
  
    assert len(input) > size

    signature = input[:size]
    signing_data = input[size:]

    gas += helpers.calculate_penalty(input[0], signing_data)

    # Run validate/verify function
    helpers.validate_signature(signature)
    pubkey = helpers.verify_signature(signing_data, signature)

    return (helpers.pubkey_to_address(pubkey, input[0]), gas)
  except AssertionError as _:
    return (INVALID, gas)
