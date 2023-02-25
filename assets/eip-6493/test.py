from remerkleable.basic import uint8, uint64, uint256
from remerkleable.byte_arrays import ByteVector, Bytes4, Bytes32
from remerkleable.complex import Container
from remerkleable.core import View
from secp256k1 import PrivateKey

class Root(Bytes32):
    pass

class Domain(Bytes32):
    pass

class SigningData(Container):
    object_root: Root
    domain: Domain

def compute_signing_root(ssz_object: View, domain: Domain) -> Root:
    return SigningData(
        object_root=ssz_object.hash_tree_root(),
        domain=domain,
    ).hash_tree_root()

class TransactionType(uint8):
    pass

class DomainType(Bytes4):
    pass

class Version(Bytes4):
    pass

class Hash32(Bytes32):
    pass

DOMAIN_EXECUTION_TRANSACTION_BASE = DomainType('0x01000002')

def domain_type_for_transaction_type(tx_type: TransactionType) -> DomainType:
    return DomainType(
        DOMAIN_EXECUTION_TRANSACTION_BASE[0],
        tx_type,
        DOMAIN_EXECUTION_TRANSACTION_BASE[2],
        DOMAIN_EXECUTION_TRANSACTION_BASE[3],
    )

class ExecutionForkData(Container):
    fork_version: Version
    genesis_hash: Hash32
    chain_id: uint256

def compute_execution_fork_data_root(
    fork_version: Version,
    genesis_hash: Hash32,
    chain_id: uint256,
) -> Root:
    return ExecutionForkData(
        fork_version=fork_version,
        genesis_hash=genesis_hash,
        chain_id=chain_id,
    ).hash_tree_root()

def compute_execution_domain(
    domain_type: DomainType,
    fork_version: Version,
    genesis_hash: Hash32,
    chain_id: uint256,
) -> Domain:
    fork_data_root = compute_execution_fork_data_root(fork_version, genesis_hash, chain_id)
    return Domain(domain_type + fork_data_root[:28])

def compute_transaction_domain(
    tx_type: TransactionType,
    tx_type_fork_version: Version,
    genesis_hash: Hash32,
    chain_id: uint256,
) -> Domain:
    domain_type = domain_type_for_transaction_type(tx_type)
    return compute_execution_domain(domain_type, tx_type_fork_version, genesis_hash, chain_id)

class ExecutionAddress(ByteVector[20]):
    pass

# Network configuration
GENESIS_HASH = Hash32('0x000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f')
CHAIN_ID = uint256(424242)

# Example SSZ transaction
EXAMPLE_TX_TYPE = TransactionType(0xab)
EXAMPLE_TX_TYPE_FORK_VERSION = Version('0x12345678')

class ExampleTransaction(Container):
    chain_id: uint256
    nonce: uint64
    max_fee_per_gas: uint256
    gas: uint64
    tx_to: ExecutionAddress
    tx_value: uint256

class ExampleSignature(ByteVector[65]):
    pass

class ExampleSignedTransaction(Container):
    message: ExampleTransaction
    signature: ExampleSignature

def compute_example_sig_hash(message: ExampleTransaction) -> Hash32:
    return compute_signing_root(
        message,
        compute_transaction_domain(
            EXAMPLE_TX_TYPE,
            EXAMPLE_TX_TYPE_FORK_VERSION,
            GENESIS_HASH,
            CHAIN_ID,
        )
    )

def compute_example_tx_hash(signed_tx: ExampleSignedTransaction) -> Hash32:
    return signed_tx.hash_tree_root()

# Example transaction
message = ExampleTransaction(
    chain_id=CHAIN_ID,
    nonce=42,
    max_fee_per_gas=69123456789,
    gas=21000,
    tx_to=ExecutionAddress(bytes.fromhex('d8da6bf26964af9d7eed9e03e53415d37aa96045')),
    tx_value=3_141_592_653,
)
sig_hash = compute_example_sig_hash(message)

privkey = PrivateKey()
raw_sig = privkey.ecdsa_sign_recoverable(sig_hash, raw=True)
sig, y_parity = privkey.ecdsa_recoverable_serialize(raw_sig)
assert y_parity in (0, 1)

signed_tx = ExampleSignedTransaction(
    message=message,
    signature=ExampleSignature(sig + bytes([y_parity])),
)
tx_hash = compute_example_tx_hash(signed_tx)



print(f'0x{tx_hash.hex()}')
