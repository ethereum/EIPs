from remerkleable.basic import uint8, uint32
from remerkleable.complex import Vector
from ssz_tx_types import *
from proof_helpers import *
from eip2718_tx_types import BlobTransaction

# Proof 1: Obtain the sequential `tx_index` within an `ExecutionPayload` for a specific `tx_hash`

class TransactionProof(Container):
    tx_root: Root
    tx_selector: uint8
    tx_index: uint32
    tx_branch: Vector[Root, 1 + floorlog2(MAX_TRANSACTIONS_PER_PAYLOAD)]

# Proof 2: Proof that a transaction sends a certain minimum amount to a specific destination

LEGACY_AMOUNT_PROOF_INDICES = [
    get_generalized_index(LegacySSZTransaction, 'startgas'),
    get_generalized_index(LegacySSZTransaction, 'to'),
    get_generalized_index(LegacySSZTransaction, 'value'),
]
LEGACY_AMOUNT_PROOF_HELPER_INDICES = get_helper_indices(LEGACY_AMOUNT_PROOF_INDICES)

class LegacyAmountProof(Container):
    startgas: uint64
    to: Union[None, ExecutionAddress]
    value: uint256
    multi_branch: Vector[Root, len(LEGACY_AMOUNT_PROOF_HELPER_INDICES)]
    signature_root: Root

EIP2930_AMOUNT_PROOF_INDICES = [
    get_generalized_index(EIP2930SSZTransaction, 'to'),
    get_generalized_index(EIP2930SSZTransaction, 'value'),
]
EIP2930_AMOUNT_PROOF_HELPER_INDICES = get_helper_indices(EIP2930_AMOUNT_PROOF_INDICES)

class EIP2930AmountProof(Container):
    to: Union[None, ExecutionAddress]
    value: uint256
    multi_branch: Vector[Root, len(EIP2930_AMOUNT_PROOF_HELPER_INDICES)]
    signature_root: Root

EIP1559_AMOUNT_PROOF_INDICES = [
    get_generalized_index(EIP1559SSZTransaction, 'gas_limit'),
    get_generalized_index(EIP1559SSZTransaction, 'destination'),
    get_generalized_index(EIP1559SSZTransaction, 'amount'),
]
EIP1559_AMOUNT_PROOF_HELPER_INDICES = get_helper_indices(EIP1559_AMOUNT_PROOF_INDICES)

class EIP1559AmountProof(Container):
    gas_limit: uint64
    destination: Union[None, ExecutionAddress]
    amount: uint256
    multi_branch: Vector[Root, len(EIP1559_AMOUNT_PROOF_HELPER_INDICES)]
    signature_root: Root

EIP4844_AMOUNT_PROOF_INDICES = [
    get_generalized_index(BlobTransaction, 'gas'),
    get_generalized_index(BlobTransaction, 'to'),
    get_generalized_index(BlobTransaction, 'value'),
]
EIP4844_AMOUNT_PROOF_HELPER_INDICES = get_helper_indices(EIP4844_AMOUNT_PROOF_INDICES)

class EIP4844AmountProof(Container):
    gas: uint64
    to: Union[None, ExecutionAddress]
    value: uint256
    multi_branch: Vector[Root, len(EIP4844_AMOUNT_PROOF_HELPER_INDICES)]
    signature_root: Root

class UnionAmountProof(Union[
    LegacyAmountProof,
    EIP2930AmountProof,
    EIP1559AmountProof,
    EIP4844AmountProof,
]):
    pass

class AmountProof(Container):
    tx_proof: UnionAmountProof
    tx_index: uint32
    tx_branch: Vector[Root, 1 + floorlog2(MAX_TRANSACTIONS_PER_PAYLOAD)]

# Proof 3: Obtain sender addres who sent a certain minimum amount to a specific destination

LEGACY_SENDER_PROOF_INDICES = [
    get_generalized_index(LegacySSZTransaction, 'startgas'),
    get_generalized_index(LegacySSZTransaction, 'to'),
    get_generalized_index(LegacySSZTransaction, 'value'),
]
LEGACY_SENDER_PROOF_HELPER_INDICES = get_helper_indices(LEGACY_SENDER_PROOF_INDICES)

class LegacySenderProof(Container):
    startgas: uint64
    to: Union[None, ExecutionAddress]
    value: uint256
    multi_branch: Vector[Root, len(LEGACY_SENDER_PROOF_HELPER_INDICES)]
    signature: LegacyECDSASignature

EIP2930_SENDER_PROOF_INDICES = [
    get_generalized_index(EIP2930SSZTransaction, 'to'),
    get_generalized_index(EIP2930SSZTransaction, 'value'),
]
EIP2930_SENDER_PROOF_HELPER_INDICES = get_helper_indices(EIP2930_SENDER_PROOF_INDICES)

class EIP2930SenderProof(Container):
    to: Union[None, ExecutionAddress]
    value: uint256
    multi_branch: Vector[Root, len(EIP2930_SENDER_PROOF_HELPER_INDICES)]
    signature: ECDSASignature

EIP1559_SENDER_PROOF_INDICES = [
    get_generalized_index(EIP1559SSZTransaction, 'gas_limit'),
    get_generalized_index(EIP1559SSZTransaction, 'destination'),
    get_generalized_index(EIP1559SSZTransaction, 'amount'),
]
EIP1559_SENDER_PROOF_HELPER_INDICES = get_helper_indices(EIP1559_SENDER_PROOF_INDICES)

class EIP1559SenderProof(Container):
    gas_limit: uint64
    destination: Union[None, ExecutionAddress]
    amount: uint256
    multi_branch: Vector[Root, len(EIP1559_SENDER_PROOF_HELPER_INDICES)]
    signature: ECDSASignature

EIP4844_SENDER_PROOF_INDICES = [
    get_generalized_index(BlobTransaction, 'gas'),
    get_generalized_index(BlobTransaction, 'to'),
    get_generalized_index(BlobTransaction, 'value'),
]
EIP4844_SENDER_PROOF_HELPER_INDICES = get_helper_indices(EIP4844_SENDER_PROOF_INDICES)

class EIP4844SenderProof(Container):
    gas: uint64
    to: Union[None, ExecutionAddress]
    value: uint256
    multi_branch: Vector[Root, len(EIP4844_SENDER_PROOF_HELPER_INDICES)]
    signature: ECDSASignature

class UnionSenderProof(Union[
    LegacySenderProof,
    EIP2930SenderProof,
    EIP1559SenderProof,
    EIP4844SenderProof,
]):
    pass

class SenderProof(Container):
    tx_proof: UnionSenderProof
    tx_index: uint32
    tx_branch: Vector[Root, 1 + floorlog2(MAX_TRANSACTIONS_PER_PAYLOAD)]

# Proof 4: Obtain transaction info including fees, but no calldata, access lists, or blobs

LEGACY_INFO_PROOF_INDICES = [
    get_generalized_index(LegacySSZTransaction, 'nonce'),
    get_generalized_index(LegacySSZTransaction, 'gasprice'),
    get_generalized_index(LegacySSZTransaction, 'startgas'),
    get_generalized_index(LegacySSZTransaction, 'to'),
    get_generalized_index(LegacySSZTransaction, 'value'),
]
LEGACY_INFO_PROOF_HELPER_INDICES = get_helper_indices(LEGACY_INFO_PROOF_INDICES)

class LegacyInfoProof(Container):
    nonce: uint64
    gasprice: uint256
    startgas: uint64
    to: Union[None, ExecutionAddress]
    value: uint256
    multi_branch: Vector[Root, len(LEGACY_INFO_PROOF_HELPER_INDICES)]
    signature: LegacyECDSASignature

EIP2930_INFO_PROOF_INDICES = [
    get_generalized_index(EIP2930SSZTransaction, 'nonce'),
    get_generalized_index(EIP2930SSZTransaction, 'gas_price'),
    get_generalized_index(EIP2930SSZTransaction, 'gas_limit'),
    get_generalized_index(EIP2930SSZTransaction, 'to'),
    get_generalized_index(EIP2930SSZTransaction, 'value'),
]
EIP2930_INFO_PROOF_HELPER_INDICES = get_helper_indices(EIP2930_INFO_PROOF_INDICES)

class EIP2930InfoProof(Container):
    nonce: uint64
    gas_price: uint256
    gas_limit: uint64
    to: Union[None, ExecutionAddress]
    value: uint256
    multi_branch: Vector[Root, len(EIP2930_INFO_PROOF_HELPER_INDICES)]
    signature: ECDSASignature

EIP1559_INFO_PROOF_INDICES = [
    get_generalized_index(EIP1559SSZTransaction, 'nonce'),
    get_generalized_index(EIP1559SSZTransaction, 'max_priority_fee_per_gas'),
    get_generalized_index(EIP1559SSZTransaction, 'max_fee_per_gas'),
    get_generalized_index(EIP1559SSZTransaction, 'gas_limit'),
    get_generalized_index(EIP1559SSZTransaction, 'destination'),
    get_generalized_index(EIP1559SSZTransaction, 'amount'),
]
EIP1559_INFO_PROOF_HELPER_INDICES = get_helper_indices(EIP1559_INFO_PROOF_INDICES)

class EIP1559InfoProof(Container):
    nonce: uint256
    max_priority_fee_per_gas: uint256
    max_fee_per_gas: uint256
    gas_limit: uint64
    destination: Union[None, ExecutionAddress]
    amount: uint256
    multi_branch: Vector[Root, len(EIP1559_INFO_PROOF_HELPER_INDICES)]
    signature: ECDSASignature

EIP4844_INFO_PROOF_INDICES = [
    get_generalized_index(BlobTransaction, 'nonce'),
    get_generalized_index(BlobTransaction, 'max_priority_fee_per_gas'),
    get_generalized_index(BlobTransaction, 'max_fee_per_gas'),
    get_generalized_index(BlobTransaction, 'gas'),
    get_generalized_index(BlobTransaction, 'to'),
    get_generalized_index(BlobTransaction, 'value'),
]
EIP4844_INFO_PROOF_HELPER_INDICES = get_helper_indices(EIP4844_INFO_PROOF_INDICES)

class EIP4844InfoProof(Container):
    nonce: uint64
    max_priority_fee_per_gas: uint256
    max_fee_per_gas: uint256
    gas: uint64
    to: Union[None, ExecutionAddress]
    value: uint256
    multi_branch: Vector[Root, len(EIP4844_INFO_PROOF_HELPER_INDICES)]
    signature: ECDSASignature

class UnionInfoProof(Union[
    LegacyInfoProof,
    EIP2930InfoProof,
    EIP1559InfoProof,
    EIP4844InfoProof,
]):
    pass

class InfoProof(Container):
    tx_proof: UnionInfoProof
    tx_index: uint32
    tx_branch: Vector[Root, 1 + floorlog2(MAX_TRANSACTIONS_PER_PAYLOAD)]
