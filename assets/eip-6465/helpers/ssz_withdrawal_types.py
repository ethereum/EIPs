from remerkleable.basic import uint64
from remerkleable.byte_arrays import ByteVector
from remerkleable.complex import Container

class ValidatorIndex(uint64):
    pass

class Gwei(uint64):
    pass

class ExecutionAddress(ByteVector[20]):
    pass

class WithdrawalIndex(uint64):
    pass

class Withdrawal(Container):
    index: WithdrawalIndex
    validator_index: ValidatorIndex
    address: ExecutionAddress
    amount: Gwei
