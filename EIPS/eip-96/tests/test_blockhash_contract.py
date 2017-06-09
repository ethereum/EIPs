import pytest
import os
import random
from ethereum import tester, utils
from ethereum.config import default_config
from rlp.utils import decode_hex

EIP_BLOCKHASH_CODE = decode_hex(
    b'73fffffffffffffffffffffffffffffffffffffffe3314156100935760014303602052600062010000602051071415610051576101006001620100006020510503076040526101005460405161020001555b600061010060205107141561007d57610100600161010060205105030760405260005460405161010001555b6101006020510760405260003560405155610161565b6000356060526060514313156100af57600060605112156100b2565b60005b156101545760605143036080526101006080511315156100dd57610100606051075460a052602060a0f35b60006101006060510714156101535762010100608051131515610113576101006101006060510507610100015460c052602060c0f35b620100006060510715156101305763010101006080511315610133565b60005b1561015257610100620100006060510507610200015460e052602060e0f35b5b5b6000610100526020610100f35b'  # noqa
)

BLOCKHASH_ADDR = decode_hex(b'00000000000000000000000000000000000000f0')
EIP_SYSTEM_ADDR = decode_hex(b'fffffffffffffffffffffffffffffffffffffffe')

SYSTEM_PRIV = os.urandom(32)
SYSTEM_ADDR = utils.privtoaddr(SYSTEM_PRIV)
SYSTEM_GAS_LIMIT = 1000000
SYSTEM_GAS_PRICE = 0
BLOCKHASH_CODE = EIP_BLOCKHASH_CODE.replace(EIP_SYSTEM_ADDR, SYSTEM_ADDR, 1)
NULL_HASH = b'\0' * 32

BLOCKHASH_LEVEL0_COST = 399
BLOCKHASH_LEVEL1_COST = 484
BLOCKHASH_LEVEL2_COST = 564
BLOCKHASH_INVALID_COST = 128
BLOCKHASH_INVALID1_COST = 236
BLOCKHASH_INVALID2_COST = 323

# Configure execution in pre-Metropolis mode.
default_config['HOMESTEAD_FORK_BLKNUM'] = 0
default_config['DAO_FORK_BLKNUM'] = 0
default_config['ANTI_DOS_FORK_BLKNUM'] = 0
default_config['CLEARING_FORK_BLKNUM'] = 0


class State(tester.state):
    def exec_system(self):
        """Execute BLOCKHASH contract from SYSTEM account"""

        prev_block_hash = self.block.get_parent().hash
        assert len(prev_block_hash) == 32

        gas_limit = tester.gas_limit
        tester.gas_limit = SYSTEM_GAS_LIMIT

        gas_price = tester.gas_price
        tester.gas_price = SYSTEM_GAS_PRICE

        output = self.send(sender=SYSTEM_PRIV, to=BLOCKHASH_ADDR, value=0,
                           evmdata=prev_block_hash)
        assert len(output) == 0

        tester.gas_limit = gas_limit
        tester.gas_price = gas_price

    def get_slot(self, index):
        """Get storage entry of BLOCKHASH_ADDR of given index"""
        int_value = self.block.get_storage_data(BLOCKHASH_ADDR, index)
        return utils.zpad(utils.coerce_to_bytes(int_value), 32)


def fake_slot(index):
    value = b'BLOCKHASH slot {:17}'.format(index)
    assert len(value) == 32
    return value


@pytest.fixture(scope='module')
def state():
    state = State()
    state.block._set_acct_item(BLOCKHASH_ADDR, 'code', BLOCKHASH_CODE)

    for i in range(257):
        state.mine()
        state.exec_system()

    return state


@pytest.fixture(scope='module')
def fake_state():
    """Create BLOCKHASH contract state. "Mining" more than 256 blocks is not
       feasible with ethereum.tester."""
    state = State()
    state.block.number = 16777216 + 65536 + 256 + 1
    state.block._set_acct_item(BLOCKHASH_ADDR, 'code', BLOCKHASH_CODE)

    for i in range(3 * 256):
        int_value = utils.big_endian_to_int(fake_slot(i))
        state.block.set_storage_data(BLOCKHASH_ADDR, i, int_value)

    return state


def test_setup(state):
    assert state.block.get_code(BLOCKHASH_ADDR) == BLOCKHASH_CODE
    assert state.block.get_balance(SYSTEM_ADDR) == 0
    assert state.block.get_nonce(SYSTEM_ADDR) > 0

    assert state.get_slot(0) == state.blocks[256].hash
    for i in range(1, 256):
        assert state.get_slot(i) == state.blocks[i].hash

    assert state.get_slot(256) == state.blocks[0].hash
    for i in range(257, 256 + 256):
        assert state.get_slot(i) == NULL_HASH

    for i in range(512, 512 + 256):
        assert state.get_slot(i) == NULL_HASH


def test_get_prev_block_hash(state):
    prev = state.block.number - 1
    expected_hash = state.blocks[prev].hash
    arg = utils.zpad(utils.coerce_to_bytes(prev), 32)
    out = state.profile(sender=tester.k1, to=BLOCKHASH_ADDR, value=0,
                        evmdata=arg)
    assert out['output'] == expected_hash
    assert out['gas'] == BLOCKHASH_LEVEL0_COST


def test_get_current_block_hash(state):
    arg = utils.zpad(utils.coerce_to_bytes(state.block.number), 32)
    out = state.profile(sender=tester.k1, to=BLOCKHASH_ADDR, value=0,
                        evmdata=arg)
    assert out['output'] == b'\0' * 32
    assert out['gas'] == BLOCKHASH_INVALID_COST


def test_get_future_block_hash(state):
    arg = utils.zpad(utils.coerce_to_bytes(3**11 + 13), 32)
    out = state.profile(sender=tester.k1, to=BLOCKHASH_ADDR, value=0,
                        evmdata=arg)
    assert out['output'] == b'\0' * 32
    assert out['gas'] == BLOCKHASH_INVALID_COST


def test_first256th_slot(state):
    n = state.block.number
    state.block.number = 60000  # Allow accessing 256th block hashes

    arg = utils.zpad(utils.coerce_to_bytes(0), 32)
    out = state.profile(sender=tester.k1, to=BLOCKHASH_ADDR, value=0,
                        evmdata=arg)
    assert out['output'] == state.blocks[0].hash
    assert out['gas'] == BLOCKHASH_LEVEL1_COST

    state.block.number = n


def test_overflow(state):
    n = state.block.number
    state.block.number = 1

    arg = utils.zpad(utils.coerce_to_bytes(2**256 - 256), 32)
    out = state.profile(sender=tester.k1, to=BLOCKHASH_ADDR, value=0,
                        evmdata=arg)
    assert out['output'] == NULL_HASH
    assert out['gas'] == 150

    state.block.number = n


def test_fake_state_setup(fake_state):
    for i in range(3 * 256):
        assert fake_state.get_slot(i) == fake_slot(i)
    assert fake_state.get_slot(3 * 256) == NULL_HASH


def test_overflow2(fake_state):
    n = fake_state.block.number
    fake_state.block.number = 255

    arg = '\xff' * 31
    out = fake_state.profile(sender=tester.k1, to=BLOCKHASH_ADDR, value=0,
                             evmdata=arg)
    assert out['output'] == NULL_HASH
    assert out['gas'] == 150

    fake_state.block.number = n


def test_blockhash_last256(fake_state):
    start_block = fake_state.block.number - 256
    for n in range(start_block, fake_state.block.number):
        arg = utils.zpad(utils.coerce_to_bytes(n), 32)
        out = fake_state.profile(sender=tester.k1, to=BLOCKHASH_ADDR, value=0,
                                 evmdata=arg)
        assert out['gas'] == BLOCKHASH_LEVEL0_COST
        assert out['output'] == fake_slot(n % 256)


def test_blockhash_level1(fake_state):
    n = fake_state.block.number
    last_block = n - (n % 256) - 256
    first_block = last_block - 255 * 256

    for n in range(first_block, last_block + 1, 256):
        arg = utils.zpad(utils.coerce_to_bytes(n), 32)
        out = fake_state.profile(sender=tester.k1, to=BLOCKHASH_ADDR, value=0,
                                 evmdata=arg)
        assert out['gas'] == BLOCKHASH_LEVEL1_COST
        level1_offset = (n / 256) % 256
        assert out['output'] == fake_slot(256 + level1_offset)


def test_blockhash_level2(fake_state):
    n = fake_state.block.number
    last_block = n - (n % 65536) - 65536
    first_block = last_block - 255 * 65536

    for n in range(first_block, last_block + 1, 65536):
        arg = utils.zpad(utils.coerce_to_bytes(n), 32)
        out = fake_state.profile(sender=tester.k1, to=BLOCKHASH_ADDR, value=0,
                                 evmdata=arg)
        assert out['gas'] == BLOCKHASH_LEVEL2_COST
        level2_offset = (n / 65536) % 256
        assert out['output'] == fake_slot(512 + level2_offset)


def test_blockhash_future_blocks(fake_state):
    for n in range(fake_state.block.number, fake_state.block.number + 10):
        arg = utils.zpad(utils.coerce_to_bytes(n), 32)
        out = fake_state.profile(sender=tester.k1, to=BLOCKHASH_ADDR, value=0,
                                 evmdata=arg)
        assert out['gas'] == BLOCKHASH_INVALID_COST
        assert out['output'] == NULL_HASH


def test_blockhash_not_covered_blocks_level1(fake_state):
    start_block = fake_state.block.number - 256 - 2
    assert start_block % 256 != 0
    for n in range(start_block, start_block - 255, -1):
        arg = utils.zpad(utils.coerce_to_bytes(n), 32)
        out = fake_state.profile(sender=tester.k1, to=BLOCKHASH_ADDR, value=0,
                                 evmdata=arg)
        assert out['gas'] == BLOCKHASH_INVALID1_COST
        assert out['output'] == NULL_HASH


def test_blockhash_not_covered_blocks_level2(fake_state):
    start_block = fake_state.block.number - 65536 - 256 - 2
    assert start_block % 256 != 0
    for n in range(start_block, start_block - 1000, -1):
        arg = utils.zpad(utils.coerce_to_bytes(n), 32)
        out = fake_state.profile(sender=tester.k1, to=BLOCKHASH_ADDR, value=0,
                                 evmdata=arg)
        if n % 256 == 0:
            assert out['gas'] == BLOCKHASH_INVALID2_COST
        else:
            assert out['gas'] == BLOCKHASH_INVALID1_COST
        assert out['output'] == NULL_HASH


def test_blockhash_not_covered_blocks_random_access(fake_state):
    current_n = fake_state.block.number
    for _ in range(1000):
        n = random.randint(0, current_n - 256)
        arg = utils.zpad(utils.coerce_to_bytes(n), 32)
        output = fake_state.send(sender=tester.k1, to=BLOCKHASH_ADDR, value=0,
                                 evmdata=arg)
        if current_n - n < 65536 + 256:
            if n % 256 == 0:
                assert output != NULL_HASH
            else:
                assert output == NULL_HASH
        else:
            if n % 65536 == 0:
                assert output != NULL_HASH
            else:
                assert output == NULL_HASH
