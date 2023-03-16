from rlp import decode
from ssz_withdrawal_types import *
from eip4895_withdrawal_types import *

def normalize_withdrawal(encoded_withdrawal: bytes) -> Withdrawal:
    withdrawal = decode(encoded_withdrawal, EIP4895Withdrawal)

    return Withdrawal(
        index=withdrawal.index,
        validator_index=withdrawal.validator_index,
        address=withdrawal.address,
        amount=withdrawal.amount,
    )
