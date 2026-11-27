"""Account-state reference for the EIP-8425 RECOVER frame.

The enclosing client validates ordinary EIP-8141 transaction authorization and
journals access lists and frame receipts. Fork-specific gas prices and warmth
at frame entry are inputs.
"""

import os
import subprocess
import tempfile
from dataclasses import InitVar, dataclass, field, replace
from pathlib import Path
from typing import Callable, FrozenSet, Mapping, MutableMapping, Optional

from eth_hash.auto import keccak


REQUEST_PREFIX_BYTES = 92
PROOF_BYTES = 222_668
SEED_PROOF_GAS = 2_000_000
EMPTY_CODE_HASH = keccak(b"")


class InvalidRecoveryFrame(ValueError):
    """A static frame constraint makes the enclosing transaction invalid."""


class RecoveryRevert(ValueError):
    """An execution check failed after the frame was admitted."""


class OutOfGas(ValueError):
    """The frame halts exceptionally before committing any writes."""


@dataclass
class FrameGas:
    execution: int
    state: int
    warm_access: int
    cold_access: int
    account_write: int
    create_account_state: int
    warm_addresses: FrozenSet[bytes] = frozenset()

    def charge(self, execution: int, state: int = 0) -> None:
        if execution > self.execution or state > self.state:
            self.execution = 0
            raise OutOfGas()
        self.execution -= execution
        self.state -= state

    def access_cost(self, address: bytes) -> int:
        return self.warm_access if address in self.warm_addresses else self.cold_access


@dataclass(frozen=True)
class Account:
    nonce: int = 0
    balance: int = 0
    code: bytes = b""
    storage: Mapping[int, int] = field(default_factory=dict)
    code_hash: bytes = field(init=False)
    code_from: InitVar[Optional["Account"]] = None

    def __post_init__(self, code_from: Optional["Account"]) -> None:
        if code_from is None:
            code_hash = keccak(self.code) if self.code else EMPTY_CODE_HASH
        else:
            object.__setattr__(self, "code", code_from.code)
            code_hash = code_from.code_hash
        object.__setattr__(self, "code_hash", code_hash)


@dataclass(frozen=True)
class Context:
    chain_id: int
    recovery_active: bool  # Both the freeze and the recovery rules are active.
    payer: Optional[bytes]  # Set by an earlier successful payment approval.
    reserved_targets: FrozenSet[bytes] = frozenset()  # Precompiles and system contracts.
    created_in_transaction: FrozenSet[bytes] = frozenset()  # Contract creations.


def verify_seed_proof(request: bytes, proof: bytes) -> bool:
    """Run the pinned native verifier; local errors cannot decide consensus."""
    default = Path(__file__).resolve().parent / "zk/host/target/release/eip8425"
    verifier = os.environ.get("EIP8425_VERIFIER", str(default))
    with tempfile.TemporaryDirectory() as tmp:
        request_file = Path(tmp) / "request"
        proof_file = Path(tmp) / "proof"
        request_file.write_bytes(request)
        proof_file.write_bytes(proof)
        result = subprocess.run([verifier, "verify", str(request_file), str(proof_file)],
                                capture_output=True)
    if result.returncode not in (0, 2):
        raise RuntimeError(f"verifier error ({result.returncode}): {result.stderr.decode(errors='replace')}")
    return result.returncode == 0


def recover(
    accounts: MutableMapping[bytes, Account],
    context: Context,
    target: Optional[bytes],
    frame_data: bytes,
    gas: FrameGas,
    verify_proof: Callable[[bytes, bytes], bool] = verify_seed_proof,
    *,
    is_last: bool = True,
    flags: int = 0,
    value: int = 0,
    previous_frame_flags: int = 0,
) -> None:
    """Validate and apply a RECOVER frame in its enclosing frame sequence."""
    if not is_last or flags != 0 or value != 0 or previous_frame_flags & 0x04:
        raise InvalidRecoveryFrame("RECOVER must be final, unbatched, with zero flags and value")
    if not context.recovery_active or target is None or len(target) != 20:
        raise InvalidRecoveryFrame("inactive recovery or invalid target")
    if len(frame_data) != REQUEST_PREFIX_BYTES + PROOF_BYTES:
        raise InvalidRecoveryFrame("invalid proof length")
    gas.charge(gas.access_cost(target))
    if context.payer is None:
        raise RecoveryRevert("payment has not been approved")

    nonce = int.from_bytes(frame_data[:8], "big")
    source = frame_data[8:28]
    code_hash = frame_data[28:60]
    account = accounts.get(target, Account())
    delegation = len(account.code) == 23 and account.code.startswith(b"\xef\x01\x00")
    if account.code and not delegation:
        raise RecoveryRevert("target already has regular or unsupported code")
    if account.nonce != nonce:
        raise RecoveryRevert("target nonce changed")
    if target in context.reserved_targets or target in context.created_in_transaction:
        raise RecoveryRevert("ineligible target")

    # Target was warmed at frame entry. SETCODEFROM also charges its fixed
    # source validation cost even when the source is invalid.
    source_access = gas.warm_access if source == target else gas.access_cost(source)
    gas.charge(source_access + gas.warm_access)
    source_account = accounts.get(source)
    if (
        source_account is None
        or not source_account.code
        or source_account.code.startswith(b"\xef")
        or source in context.created_in_transaction
    ):
        raise RecoveryRevert("invalid source")
    if source_account.code_hash != code_hash:
        raise RecoveryRevert("source code hash changed")

    gas.charge(SEED_PROOF_GAS)
    request = context.chain_id.to_bytes(32, "big") + target + frame_data[:REQUEST_PREFIX_BYTES]
    if not verify_proof(request, frame_data[REQUEST_PREFIX_BYTES:]):
        raise RecoveryRevert("invalid seed proof")

    target_exists = account.nonce != 0 or account.balance != 0 or bool(account.code)
    gas.charge(gas.warm_access + gas.account_write,
               0 if target_exists else gas.create_account_state)
    accounts[target] = replace(account, code_from=source_account)
    gas.warm_addresses = gas.warm_addresses.union((target, source))
