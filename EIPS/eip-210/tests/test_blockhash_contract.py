import pytest
import os
import random
from ethereum import tester, utils
from ethereum.config import default_config
from rlp.utils import decode_hex

from pprint import pprint

EIP_BLOCKHASH_CODE = decode_hex(
    b'73fffffffffffffffffffffffffffffffffffffffe33141561006a5760014303600035610100820755610100810715156100455760003561010061010083050761010001555b6201000081071515610064576000356101006201000083050761020001555b5061013e565b4360003512151561008457600060405260206040f361013d565b61010060003543031315156100a857610100600035075460605260206060f361013c565b6101006000350715156100c55762010000600035430313156100c8565b60005b156100ea576101006101006000350507610100015460805260206080f361013b565b620100006000350715156101095763010000006000354303131561010c565b60005b1561012f57610100620100006000350507610200015460a052602060a0f361013a565b600060c052602060c0f35b5b5b5b5b'  # noqa
)

BLOCKHASH_ADDR = decode_hex(b'00000000000000000000000000000000000000f0')
EIP_SYSTEM_ADDR = decode_hex(b'fffffffffffffffffffffffffffffffffffffffe')

SYSTEM_PRIV = os.urandom(32)
SYSTEM_ADDR = utils.privtoaddr(SYSTEM_PRIV)
SYSTEM_GAS_LIMIT = 1000000
SYSTEM_GAS_PRICE = 0
BLOCKHASH_CODE = EIP_BLOCKHASH_CODE.replace(EIP_SYSTEM_ADDR, SYSTEM_ADDR, 1)
NULL_HASH = b'\0' * 32

BLOCKHASH_LEVEL1_COST = 330
BLOCKHASH_LEVEL2_COST = 429
BLOCKHASH_LEVEL3_COST = 514

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


@pytest.fixture
def fake_state():
    """Create BLOCKHASH contract state. "Mining" more than 256 blocks is not
       feasible with ethereum.tester."""
    state = State()
    state.block.number = 256 * 65536 + 1
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
    assert state.get_slot(257) == state.blocks[256].hash
    for i in range(258, 256 + 256):
        assert state.get_slot(i) == NULL_HASH

    assert state.get_slot(512) == state.blocks[0].hash
    for i in range(513, 512 + 256):
        assert state.get_slot(i) == NULL_HASH


def test_get_prev_block_hash(state):
    prev = state.block.number - 1
    pprint(prev)
    expected_hash = state.blocks[prev].hash
    arg = utils.zpad(utils.coerce_to_bytes(prev), 32)
    out = state.profile(sender=tester.k1, to=BLOCKHASH_ADDR, value=0,
                        evmdata=arg)
    assert out['output'] == expected_hash
    assert out['gas'] == BLOCKHASH_LEVEL1_COST


def test_get_current_block_hash(state):
    arg = utils.zpad(utils.coerce_to_bytes(state.block.number), 32)
    out = state.profile(sender=tester.k1, to=BLOCKHASH_ADDR, value=0,
                        evmdata=arg)
    assert out['output'] == b'\0' * 32
    assert out['gas'] == 79


def test_get_future_block_hash(state):
    arg = utils.zpad(utils.coerce_to_bytes(3**11 + 13), 32)
    out = state.profile(sender=tester.k1, to=BLOCKHASH_ADDR, value=0,
                        evmdata=arg)
    assert out['output'] == b'\0' * 32
    assert out['gas'] == 79


def test_first256th_slot(state):
    n = state.block.number
    state.block.number = 60000  # Allow accessing 256th block hashes

    arg = utils.zpad(utils.coerce_to_bytes(0), 32)
    out = state.profile(sender=tester.k1, to=BLOCKHASH_ADDR, value=0,
                        evmdata=arg)
    assert out['output'] == state.blocks[0].hash
    assert out['gas'] == BLOCKHASH_LEVEL2_COST

    state.block.number = n


def test_overflow(state):
    n = state.block.number
    state.block.number = 1

    arg = utils.zpad(utils.coerce_to_bytes(2**256 - 256), 32)
    out = state.profile(sender=tester.k1, to=BLOCKHASH_ADDR, value=0,
                        evmdata=arg)
    assert out['output'] == NULL_HASH
    assert out['gas'] == 79

    state.block.number = n


def test_fake_state_setup(fake_state):
    for i in range(3 * 256):
        assert fake_state.get_slot(i) == fake_slot(i)
    assert fake_state.get_slot(3 * 256) == NULL_HASH


def test_overflow2(fake_state):
    fake_state.block.number = 255

    arg = '\xff' * 31
    out = fake_state.profile(sender=tester.k1, to=BLOCKHASH_ADDR, value=0,
                             evmdata=arg)
    assert out['output'] == NULL_HASH
    assert out['gas'] == 79


def test_blockhash_last256(fake_state):
    start_block = fake_state.block.number - 256
    for n in range(start_block, fake_state.block.number):
        arg = utils.zpad(utils.coerce_to_bytes(n), 32)
        out = fake_state.profile(sender=tester.k1, to=BLOCKHASH_ADDR, value=0,
                                 evmdata=arg)
        assert out['gas'] == BLOCKHASH_LEVEL1_COST
        assert out['output'] == fake_slot(n % 256)


def test_blockhash_level2(fake_state):
    last256th = fake_state.block.number - (fake_state.block.number % 256)

    # TODO: We can only access 255 block hashes on level 2.
    start_block = last256th - (255 - 1) * 256

    arg = utils.zpad(utils.coerce_to_bytes(last256th), 32)
    output = fake_state.send(sender=tester.k1, to=BLOCKHASH_ADDR, value=0,
                             evmdata=arg)
    assert output == fake_slot(0)

    for n in range(start_block, last256th, 256):
        arg = utils.zpad(utils.coerce_to_bytes(n), 32)
        out = fake_state.profile(sender=tester.k1, to=BLOCKHASH_ADDR, value=0,
                                 evmdata=arg)
        assert out['gas'] == BLOCKHASH_LEVEL2_COST
        level2_offset = (n / 256) % 256
        assert out['output'] == fake_slot(256 + level2_offset)


def test_blockhash_level3(fake_state):
    last65kth = fake_state.block.number - (fake_state.block.number % 65536)

    # TODO: We can only access 255 block hashes on level 3.
    start_block = last65kth - (255 - 1) * 65536

    arg = utils.zpad(utils.coerce_to_bytes(last65kth), 32)
    output = fake_state.send(sender=tester.k1, to=BLOCKHASH_ADDR, value=0,
                             evmdata=arg)
    assert output == fake_slot(0)

    for n in range(start_block, last65kth, 65536):
        arg = utils.zpad(utils.coerce_to_bytes(n), 32)
        out = fake_state.profile(sender=tester.k1, to=BLOCKHASH_ADDR, value=0,
                                 evmdata=arg)
        assert out['gas'] == BLOCKHASH_LEVEL3_COST
        level3_offset = (n / 65536) % 256
        assert out['output'] == fake_slot(512 + level3_offset)


def test_blockhash_future_blocks(fake_state):
    for n in range(fake_state.block.number, fake_state.block.number + 10):
        arg = utils.zpad(utils.coerce_to_bytes(n), 32)
        out = fake_state.profile(sender=tester.k1, to=BLOCKHASH_ADDR, value=0,
                                 evmdata=arg)
        assert out['gas'] == 79
        assert out['output'] == NULL_HASH


def test_blockhash_not_covered_blocks(fake_state):
    current_n = fake_state.block.number
    for _ in range(1000):
        n = random.randint(0, current_n - 256)
        arg = utils.zpad(utils.coerce_to_bytes(n), 32)
        output = fake_state.send(sender=tester.k1, to=BLOCKHASH_ADDR, value=0,
                                 evmdata=arg)
        if current_n - n < 65536:
            if n % 256 == 0:
                assert output != NULL_HASH
            else:
                assert output == NULL_HASH
        else:
            if n % 65536 == 0:
                assert output != NULL_HASH
            else:
                assert output == NULL_HASH
