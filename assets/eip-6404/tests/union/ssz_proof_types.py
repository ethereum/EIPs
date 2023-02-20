from remerkleable.basic import uint8, uint32
from remerkleable.complex import Vector
from ssz_tx_types import *
from proof_helpers import *

# Proof 1: Obtain the sequential `tx_index` within an `ExecutionPayload` for a specific `tx_hash`

class TransactionProof(Container):
    tx_root: Root
    tx_selector: uint8
    tx_index: uint32
    tx_branch: Vector[Root, 1 + floorlog2(MAX_TRANSACTIONS_PER_PAYLOAD)]

# Proof 2: Proof that a transaction sends a certain minimum amount to a specific destination

LEGACY_AMOUNT_PROOF_INDICES = get_helper_indices([
    get_generalized_index(LegacySignedSSZTransaction, 'message', 'startgas'),
    get_generalized_index(LegacySignedSSZTransaction, 'message', 'to'),
    get_generalized_index(LegacySignedSSZTransaction, 'message', 'value'),
])

class LegacyAmountProof(Container):
    startgas: uint64
    to: Union[None, ExecutionAddress]
    value: uint256
    multi_branch: Vector[Root, len(LEGACY_AMOUNT_PROOF_INDICES)]

EIP2930_AMOUNT_PROOF_INDICES = get_helper_indices([
    get_generalized_index(EIP2930SignedSSZTransaction, 'message', 'to'),
    get_generalized_index(EIP2930SignedSSZTransaction, 'message', 'value'),
])

class EIP2930AmountProof(Container):
    to: Union[None, ExecutionAddress]
    value: uint256
    multi_branch: Vector[Root, len(EIP2930_AMOUNT_PROOF_INDICES)]

EIP1559_AMOUNT_PROOF_INDICES = get_helper_indices([
    get_generalized_index(EIP1559SignedSSZTransaction, 'message', 'gas_limit'),
    get_generalized_index(EIP1559SignedSSZTransaction, 'message', 'destination'),
    get_generalized_index(EIP1559SignedSSZTransaction, 'message', 'amount'),
])

class EIP1559AmountProof(Container):
    gas_limit: uint64
    destination: Union[None, ExecutionAddress]
    amount: uint256
    multi_branch: Vector[Root, len(EIP1559_AMOUNT_PROOF_INDICES)]

EIP4844_AMOUNT_PROOF_INDICES = get_helper_indices([
    get_generalized_index(SignedBlobTransaction, 'message', 'gas'),
    get_generalized_index(SignedBlobTransaction, 'message', 'to'),
    get_generalized_index(SignedBlobTransaction, 'message', 'value'),
])

class EIP4844AmountProof(Container):
    gas: uint64
    to: Union[None, ExecutionAddress]
    value: uint256
    multi_branch: Vector[Root, len(EIP4844_AMOUNT_PROOF_INDICES)]

class UnionAmountProof(Union[
    LegacyAmountProof,
    EIP2930AmountProof,
    EIP1559AmountProof,
    EIP4844AmountProof,
]):
    pass

class AmountProof(Container):
    proof: UnionAmountProof
    tx_index: uint32
    tx_branch: Vector[Root, 1 + floorlog2(MAX_TRANSACTIONS_PER_PAYLOAD)]

# Proof 3: Proof that a specific sender sent a certain minimum amount to a specific destination

LEGACY_SENDER_PROOF_INDICES = get_helper_indices([
    get_generalized_index(LegacySignedSSZTransaction, 'message', 'startgas'),
    get_generalized_index(LegacySignedSSZTransaction, 'message', 'to'),
    get_generalized_index(LegacySignedSSZTransaction, 'message', 'value'),
    get_generalized_index(LegacySignedSSZTransaction, 'signature'),
])

class LegacySenderProof(Container):
    startgas: uint64
    to: Union[None, ExecutionAddress]
    value: uint256
    signature: LegacyECDSASignature
    multi_branch: Vector[Root, len(LEGACY_SENDER_PROOF_INDICES)]

EIP2930_SENDER_PROOF_INDICES = get_helper_indices([
    get_generalized_index(EIP2930SignedSSZTransaction, 'message', 'to'),
    get_generalized_index(EIP2930SignedSSZTransaction, 'message', 'value'),
    get_generalized_index(EIP2930SignedSSZTransaction, 'signature'),
])

class EIP2930SenderProof(Container):
    to: Union[None, ExecutionAddress]
    value: uint256
    signature: ECDSASignature
    multi_branch: Vector[Root, len(EIP2930_SENDER_PROOF_INDICES)]

EIP1559_SENDER_PROOF_INDICES = get_helper_indices([
    get_generalized_index(EIP1559SignedSSZTransaction, 'message', 'gas_limit'),
    get_generalized_index(EIP1559SignedSSZTransaction, 'message', 'destination'),
    get_generalized_index(EIP1559SignedSSZTransaction, 'message', 'amount'),
    get_generalized_index(EIP1559SignedSSZTransaction, 'signature'),
])

class EIP1559SenderProof(Container):
    gas_limit: uint64
    destination: Union[None, ExecutionAddress]
    amount: uint256
    signature: ECDSASignature
    multi_branch: Vector[Root, len(EIP1559_SENDER_PROOF_INDICES)]

EIP4844_SENDER_PROOF_INDICES = get_helper_indices([
    get_generalized_index(SignedBlobTransaction, 'message', 'gas'),
    get_generalized_index(SignedBlobTransaction, 'message', 'to'),
    get_generalized_index(SignedBlobTransaction, 'message', 'value'),
    get_generalized_index(SignedBlobTransaction, 'signature'),
])

class EIP4844SenderProof(Container):
    gas: uint64
    to: Union[None, ExecutionAddress]
    value: uint256
    signature: ECDSASignature
    multi_branch: Vector[Root, len(EIP4844_SENDER_PROOF_INDICES)]

class UnionSenderProof(Union[
    LegacySenderProof,
    EIP2930SenderProof,
    EIP1559SenderProof,
    EIP4844SenderProof,
]):
    pass

class SenderProof(Container):
    proof: UnionSenderProof
    tx_index: uint32
    tx_branch: Vector[Root, 1 + floorlog2(MAX_TRANSACTIONS_PER_PAYLOAD)]

# Proof 4: Obtain transaction info including fees, but no calldata, access lists, or blobs

LEGACY_INFO_PROOF_INDICES = get_helper_indices([
    get_generalized_index(LegacySignedSSZTransaction, 'message', 'nonce'),
    get_generalized_index(LegacySignedSSZTransaction, 'message', 'gasprice'),
    get_generalized_index(LegacySignedSSZTransaction, 'message', 'startgas'),
    get_generalized_index(LegacySignedSSZTransaction, 'message', 'to'),
    get_generalized_index(LegacySignedSSZTransaction, 'message', 'value'),
    get_generalized_index(LegacySignedSSZTransaction, 'signature'),
])

class LegacyInfoProof(Container):
    nonce: uint64
    gasprice: uint256
    startgas: uint64
    to: Union[None, ExecutionAddress]
    value: uint256
    signature: LegacyECDSASignature
    multi_branch: Vector[Root, len(LEGACY_INFO_PROOF_INDICES)]

EIP2930_INFO_PROOF_INDICES = get_helper_indices([
    get_generalized_index(EIP2930SignedSSZTransaction, 'message', 'nonce'),
    get_generalized_index(EIP2930SignedSSZTransaction, 'message', 'gas_price'),
    get_generalized_index(EIP2930SignedSSZTransaction, 'message', 'gas_limit'),
    get_generalized_index(EIP2930SignedSSZTransaction, 'message', 'to'),
    get_generalized_index(EIP2930SignedSSZTransaction, 'message', 'value'),
    get_generalized_index(EIP2930SignedSSZTransaction, 'signature'),
])

class EIP2930InfoProof(Container):
    nonce: uint64
    gas_price: uint256
    gas_limit: uint64
    to: Union[None, ExecutionAddress]
    value: uint256
    signature: ECDSASignature
    multi_branch: Vector[Root, len(EIP2930_INFO_PROOF_INDICES)]

EIP1559_INFO_PROOF_INDICES = get_helper_indices([
    get_generalized_index(EIP1559SignedSSZTransaction, 'message', 'nonce'),
    get_generalized_index(EIP1559SignedSSZTransaction, 'message', 'max_priority_fee_per_gas'),
    get_generalized_index(EIP1559SignedSSZTransaction, 'message', 'max_fee_per_gas'),
    get_generalized_index(EIP1559SignedSSZTransaction, 'message', 'gas_limit'),
    get_generalized_index(EIP1559SignedSSZTransaction, 'message', 'destination'),
    get_generalized_index(EIP1559SignedSSZTransaction, 'message', 'amount'),
    get_generalized_index(EIP1559SignedSSZTransaction, 'signature'),
])

class EIP1559InfoProof(Container):
    nonce: uint256
    max_priority_fee_per_gas: uint256
    max_fee_per_gas: uint256
    gas_limit: uint64
    destination: Union[None, ExecutionAddress]
    amount: uint256
    signature: ECDSASignature
    multi_branch: Vector[Root, len(EIP1559_INFO_PROOF_INDICES)]

EIP4844_INFO_PROOF_INDICES = get_helper_indices([
    get_generalized_index(SignedBlobTransaction, 'message', 'nonce'),
    get_generalized_index(SignedBlobTransaction, 'message', 'max_priority_fee_per_gas'),
    get_generalized_index(SignedBlobTransaction, 'message', 'max_fee_per_gas'),
    get_generalized_index(SignedBlobTransaction, 'message', 'gas'),
    get_generalized_index(SignedBlobTransaction, 'message', 'to'),
    get_generalized_index(SignedBlobTransaction, 'message', 'value'),
    get_generalized_index(SignedBlobTransaction, 'signature'),
])

class EIP4844InfoProof(Container):
    nonce: uint64
    max_priority_fee_per_gas: uint256
    max_fee_per_gas: uint256
    gas: uint64
    to: Union[None, ExecutionAddress]
    value: uint256
    signature: ECDSASignature
    multi_branch: Vector[Root, len(EIP4844_INFO_PROOF_INDICES)]

class UnionInfoProof(Union[
    LegacyInfoProof,
    EIP2930InfoProof,
    EIP1559InfoProof,
    EIP4844InfoProof,
]):
    pass

class InfoProof(Container):
    proof: UnionInfoProof
    tx_index: uint32
    tx_branch: Vector[Root, 1 + floorlog2(MAX_TRANSACTIONS_PER_PAYLOAD)]
