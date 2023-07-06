from rlp import encode
from ssz_withdrawal_types import *
from eip4895_withdrawal_types import *

def recover_eip4895_withdrawal(withdrawal: Withdrawal) -> EIP4895Withdrawal:
    return EIP4895Withdrawal(
        index=withdrawal.index,
        validator_index=withdrawal.validator_index,
        address=withdrawal.address,
        amount=withdrawal.amount,
    )

def recover_encoded_withdrawal(withdrawal: Withdrawal) -> bytes:
    return encode(recover_eip4895_withdrawal(withdrawal))
