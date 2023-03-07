from remerkleable.basic import uint32
from remerkleable.complex import Vector
from ssz_tx_types import *
from proof_helpers import *

CHAIN_ID_INDEX = 3

# Proof 1: Obtain the sequential `tx_index` within an `ExecutionPayload` for a specific `tx_hash`

class TransactionProof(Container):
    payload_root: Root
    tx_hash: Hash32
    tx_index: uint32
    tx_branch: Vector[Root, 1 + floorlog2(MAX_TRANSACTIONS_PER_PAYLOAD)]

# Proof 2: Proof that a transaction sends a certain minimum amount to a specific destination

AMOUNT_PROOF_INDICES = [
    get_generalized_index(TransactionPayload, 'tx_from'),  # 16
    get_generalized_index(TransactionPayload, 'nonce'),  # 17
    get_generalized_index(TransactionPayload, 'tx_to'),  # 18
    get_generalized_index(TransactionPayload, 'tx_value'),  # 19
]
AMOUNT_PROOF_HELPER_INDICES = get_helper_indices(AMOUNT_PROOF_INDICES)  # [5, 3]

class AmountProof(Container):
    tx_from: ExecutionAddress
    nonce: uint64
    tx_to: DestinationAddress
    tx_value: uint256
    multi_branch: Vector[Root, len(AMOUNT_PROOF_HELPER_INDICES)]
    tx_hash: Hash32
    tx_index: uint32
    tx_branch: Vector[Root, 1 + floorlog2(MAX_TRANSACTIONS_PER_PAYLOAD)]

# Proof 3: Obtain sender addres who sent a certain minimum amount to a specific destination

SENDER_PROOF_INDICES = [
    get_generalized_index(TransactionPayload, 'tx_from'),  # 16
    get_generalized_index(TransactionPayload, 'nonce'),  # 17
    get_generalized_index(TransactionPayload, 'tx_to'),  # 18
    get_generalized_index(TransactionPayload, 'tx_value'),  # 19
]
SENDER_PROOF_HELPER_INDICES = get_helper_indices(SENDER_PROOF_INDICES)  # [5, 3]

class SenderProof(Container):
    tx_from: ExecutionAddress
    nonce: uint64
    tx_to: DestinationAddress
    tx_value: uint256
    multi_branch: Vector[Root, len(SENDER_PROOF_HELPER_INDICES)]
    tx_hash: Hash32
    tx_index: uint32
    tx_branch: Vector[Root, 1 + floorlog2(MAX_TRANSACTIONS_PER_PAYLOAD)]

# Proof 4: Obtain transaction info including fees, but no calldata, access lists, or blobs

INFO_PROOF_INDICES = [
    get_generalized_index(TransactionPayload, 'tx_from'),  # 16
    get_generalized_index(TransactionPayload, 'nonce'),  # 17
    get_generalized_index(TransactionPayload, 'tx_to'),  # 18
    get_generalized_index(TransactionPayload, 'tx_value'),  # 19
    get_generalized_index(TransactionPayload, 'limits'),  # 21
]
INFO_PROOF_HELPER_INDICES = get_helper_indices(INFO_PROOF_INDICES)  # [20, 11, 3]

class InfoProof(Container):
    tx_from: ExecutionAddress
    nonce: uint64
    tx_to: DestinationAddress
    tx_value: uint256
    limits: TransactionLimits
    multi_branch: Vector[Root, len(INFO_PROOF_HELPER_INDICES)]
    tx_hash: Hash32
    tx_index: uint32
    tx_branch: Vector[Root, 1 + floorlog2(MAX_TRANSACTIONS_PER_PAYLOAD)]
