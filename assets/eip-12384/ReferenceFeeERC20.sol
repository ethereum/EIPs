// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.26;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title IERC12384: block-scoped reference counting with an escalating in-kind fee.
/// @notice The ERC-20 form of EIP-12384. Where the EIP has the client count calls into
///         an enrolled address per block and charge gas, this token counts its own
///         transfers per block and charges itself, in kind. Same schedule, same
///         destinations, no protocol change needed, deployable on any EVM chain today.
interface IERC12384 {
    /// @notice A counted transfer paid its reference fee.
    /// @param n the reference ordinal in this block (1 = first)
    /// @param fee tokens taken from `value` and split between sink and beneficiary
    event Reference(address indexed from, address indexed to, uint256 n, uint256 fee);

    /// @notice Fast ratchet: references counted in the current block, across every originator.
    function referencesThisBlock() external view returns (uint256);
    /// @notice Slow ratchet: references `origin` has made in the current window.
    function referencesThisWindowBy(address origin) external view returns (uint256);
    /// @notice Fast fee in basis points for the n-th reference in a block (first `FAST_FREE` free).
    function referenceFeeBps(uint256 n) external pure returns (uint256);
    /// @notice Slow fee in basis points for an originator's n-th reference in a window (first `SLOW_FREE` free).
    function slowFeeBps(uint256 n) external pure returns (uint256);
    /// @notice Where fees land, in kind, before settlement. Same as `beneficiary()`.
    function sink() external view returns (address);
    /// @notice The settler that turns fees into native: half burned, half to a stake pool.
    function beneficiary() external view returns (address);
}

/// @title ReferenceFeeERC20: reference implementation of IERC12384.
/// @notice Rules, in the EIP's terms:
///
///           1. Every transfer between two non-zero addresses is a reference to this
///              token. Mint and burn are not.
///           2. Two ratchets, and a transfer pays the larger:
///              FAST, global, per block: every reference to this token in the chain's
///                own block counts, whoever made it. The first FAST_FREE are free, then
///                FAST_FLOOR·k² bp, capped at 100%. A sandwich is front, victim, back:
///                the victim is #2 and free, the back-run is #3 and pays, however many
///                wallets the machine uses. Griefing it means dust every 250 ms forever.
///              SLOW, per originator, per window of SLOW_WINDOW blocks: what tx.origin
///                itself has done lately. First SLOW_FREE free, then SLOW_FLOOR·k² bp,
///                capped at SLOW_CAP. Liquidity added and pulled minutes later by the
///                same wallet pays on the pull. Nobody can raise anyone else's count.
///           2b. "Block" is the chain's own block. On Arbitrum-family chains
///              `block.number` is the parent chain's height (a ~12 s window), so the
///              ArbSys precompile is read when it is present.
///           3. The k-th reference in a block pays `FLOOR_BPS * k²` basis points of the
///              transferred amount, capped at `CAP_BPS`, with the first `K_FREE`
///              references free. A wallet transfer or a single swap is almost always
///              the first reference in its block and pays nothing.
///           4. The fee does not reach the party being priced. It is paid in kind to a
///              settler with no owner, which anyone can trigger to sell it for native:
///              half of the native is burned, half goes to the stake pool the deployer
///              fixed, so the people paid are the ones staking, in the chain's own coin.
///
///         The counter is one storage slot: the block it belongs to and the count.
///         The first reference in a new block rewrites it; later references in the
///         same block update a warm slot.
///
///         What this cannot see: a venue with flash accounting nets a sequence of
///         operations into one settlement transfer, so it counts as one reference.
///         That is the reason the Ethereum core EIP counts calls at the client
///         instead. This contract is the version that needs no fork.
abstract contract ReferenceFeeERC20 is ERC20, IERC12384 {
    /// @notice Fast ratchet: 10 bp per k², first two references in a block free, never above 100%.
    uint256 public constant FAST_FLOOR = 10;
    uint256 public constant FAST_FREE = 2;
    uint256 public constant FAST_CAP = 10_000;
    /// @notice Slow ratchet: 2 bp per k² of an originator's references in a ~8.5 minute window, first free, at most 10%.
    uint256 public constant SLOW_FLOOR = 2;
    uint256 public constant SLOW_FREE = 1;
    uint256 public constant SLOW_CAP = 1_000;
    uint256 public constant SLOW_WINDOW = 2048;
    uint256 internal constant BPS = 10_000;

    /// @notice Where every fee goes, in kind: the settler that sells it for native, burns half
    ///         and stakes half. Fixed at deployment. `sink()` and `beneficiary()` both name it,
    ///         so v1 readers keep working.
    address private immutable _beneficiary;

    /// @dev Arbitrum-family chains expose their own block number here; elsewhere there is no code.
    address private constant ARB_SYS = 0x0000000000000000000000000000000000000064;

    /// @dev One word each: block number in the high bits, count in the low 64.
    uint256 private _global;
    mapping(address => uint256) private _byOrigin;

    /// @param beneficiary_ the settler every fee is paid to
    constructor(address beneficiary_) {
        require(beneficiary_ != address(0), "settler");
        _beneficiary = beneficiary_;
    }

    function sink() public view returns (address) {
        return _beneficiary;
    }

    function beneficiary() public view returns (address) {
        return _beneficiary;
    }

    /// @dev The chain's own block: ArbSys.arbBlockNumber() on Arbitrum-family chains, block.number elsewhere.
    function _blockNumber() internal view returns (uint64) {
        if (ARB_SYS.code.length != 0) {
            (bool ok, bytes memory ret) = ARB_SYS.staticcall(hex"a3b1b31d"); // arbBlockNumber()
            if (ok && ret.length == 32) return uint64(abi.decode(ret, (uint256)));
        }
        return uint64(block.number);
    }

    function _count(uint256 packed, uint64 current) private pure returns (uint256) {
        return packed >> 64 == current ? packed & type(uint64).max : 0;
    }

    function referencesThisBlock() public view returns (uint256) {
        return _count(_global, _blockNumber());
    }

    function referencesThisWindowBy(address origin) public view returns (uint256) {
        return _count(_byOrigin[origin], uint64(_blockNumber() / SLOW_WINDOW));
    }

    function referenceFeeBps(uint256 n) public pure returns (uint256) {
        if (n <= FAST_FREE) return 0;
        uint256 r = FAST_FLOOR * n * n;
        return r > FAST_CAP ? FAST_CAP : r;
    }

    function slowFeeBps(uint256 n) public pure returns (uint256) {
        if (n <= SLOW_FREE) return 0;
        uint256 r = SLOW_FLOOR * n * n;
        return r > SLOW_CAP ? SLOW_CAP : r;
    }

    /// @dev Count on both ratchets; return the fast (global) ordinal and the fee rate that applies.
    function _reference() internal returns (uint256 n, uint256 bps) {
        uint64 current = _blockNumber();
        n = _count(_global, current) + 1;
        _global = (uint256(current) << 64) | n;
        uint64 window = uint64(current / SLOW_WINDOW);
        uint256 m = _count(_byOrigin[tx.origin], window) + 1;
        _byOrigin[tx.origin] = (uint256(window) << 64) | m;
        uint256 fast = referenceFeeBps(n);
        uint256 slow = slowFeeBps(m);
        bps = fast > slow ? fast : slow;
    }

    /// @dev Whether a transfer counts. Mint and burn never do; subclasses may exempt
    ///      more (a curve that is the token's own market, for instance).
    function _counted(address from, address to) internal view virtual returns (bool) {
        // settlement is not market activity: what the settler sells is not a reference
        return from != address(0) && to != address(0) && from != _beneficiary;
    }

    function _update(address from, address to, uint256 value) internal virtual override {
        if (!_counted(from, to)) {
            super._update(from, to, value);
            return;
        }
        (uint256 n, uint256 bps) = _reference();
        uint256 fee = (value * bps) / BPS;
        if (fee != 0) super._update(from, _beneficiary, fee);
        super._update(from, to, value - fee);
        emit Reference(from, to, n, fee);
    }
}
