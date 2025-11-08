from tx_hashes import compute_auth_hash, compute_sig_hash
from ssz_types import *

def calculate_base_gas_usage(tx: Transaction) -> uint:
    tx_data = tx.payload.data()

    TX_BASE_COST = 21000 # FIXME
    gas_cost = TX_BASE_COST

    if hasattr(tx_data, "authorization_list"):
        for auth in tx_data.authorization_list:
            gas_cost += get_signature_gas_cost(auth.signature)

    gas_cost += get_signature_gas_cost(tx.signature)

    return uint256(gas_cost)

def validate_transaction(tx: Transaction):
    tx_data = tx.payload.data()

    expected_signature_algorithm = None
    assert tx_data.gas >= calculate_base_gas_usage(tx)

    if hasattr(tx_data, "type_"):
        expected_signature_algorithm = SECP256K1_ALGORITHM
        match tx_data.type_:
            case RlpTxType.LEGACY:
                assert isinstance(tx_data, RlpLegacyTransactionPayload)
            case RlpTxType.ACCESS_LIST:
                assert isinstance(tx_data, RlpAccessListTransactionPayload)
            case RlpTxType.FEE_MARKET:
                assert isinstance(tx_data, RlpFeeMarketTransactionPayload)
            case RlpTxType.BLOB:
                assert isinstance(tx_data, RlpBlobTransactionPayload)
            case RlpTxType.SET_CODE:
                assert isinstance(tx_data, RlpSetCodeTransactionPayload)
            case _:
                assert False

    if hasattr(tx_data, "authorization_list"):
        for auth in tx_data.authorization_list:
            auth_data = auth.payload.data()

            if hasattr(auth_data, "magic"):
                assert auth_data.magic == RlpTxType.SET_CODE_MAGIC
            if hasattr(auth_data, "chain_id"):
                assert auth_data.chain_id != 0

            validate_execution_signature(auth.signature, compute_auth_hash(auth), expected_algorithm=expected_signature_algorithm)

    validate_execution_signature(tx.signature, compute_sig_hash(tx), expected_algorithm=expected_signature_algorithm)
