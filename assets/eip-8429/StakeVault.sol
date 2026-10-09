// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.26;

interface IDepositContract {
    function deposit(
        bytes calldata pubkey,
        bytes calldata withdrawal_credentials,
        bytes calldata signature,
        bytes32 deposit_data_root
    ) external payable;
}

/// @title StakeVault: ETH in, validator stake out, nothing else.
/// @notice The reference implementation of the stake vault of EIP-8429. Whatever ETH arrives
///         can leave in exactly two ways: 31 ETH at a time into the beacon deposit contract,
///         for a validator that already exists with this vault's withdrawal credentials, and
///         1 ETH at a time back to the operator of a validator that has provably exited
///         without being slashed. There is no owner and no other way out.
///
///         A vault never creates a validator. The operator does, with a deposit of their own
///         of at least 1 ETH and this vault's withdrawal credentials; that deposit is the
///         operator's bond. The vault then proves, against the beacon block root that
///         EIP-4788 exposes, that the validator is in the registry with those credentials,
///         and only then tops it up. The deposit contract does not check signatures and the
///         consensus layer ignores the credentials of a top-up, so a vault that made the
///         first deposit itself could be front-run into funding a validator that pays out to
///         somebody else, or could burn 32 ETH on a signature that does not verify. A top-up
///         of a proven validator can do neither.
///
///         `withdrawalAddress` is held in storage, not as an immutable, so that every vault
///         has the same runtime code and one code hash identifies them all. The sink is the
///         vault whose withdrawal address is itself.
contract StakeVault {
    /// Beacon chain deposit contract
    address public constant DEPOSIT_CONTRACT = 0x00000000219ab540356cBB839Cbe05303d7705Fa;
    /// EIP-4788 beacon roots contract
    address public constant BEACON_ROOTS = 0x000F3df6D732807Ef1319fB7B8bB8522d0Beac02;
    /// EIP-7002 withdrawal request contract
    address public constant WITHDRAWAL_REQUESTS = 0x00000961Ef480Eb55e80D19ad83579A64c007002;

    /// What the operator puts up, inside the validator, and gets back from the vault on exit
    uint256 public constant BOND = 1 ether;
    /// What the vault adds to a proven validator
    uint256 public constant TOP_UP = 31 ether;

    uint64 internal constant FAR_FUTURE_EPOCH = type(uint64).max;
    uint64 internal constant FULL_EFFECTIVE_BALANCE = 32_000_000_000; // gwei
    /// A validator with 0x01 credentials is topped up only while it holds the operator's
    /// bond and nothing more. Anything above 32 ETH on such a validator is swept to the
    /// withdrawal address, so topping up a funded one would turn stake into balance.
    uint64 internal constant BOND_EFFECTIVE_BALANCE = 1_000_000_000; // gwei
    /// A proof older than this is not accepted
    uint256 public constant MAX_PROOF_AGE = 1 hours;
    uint256 internal constant GENESIS_TIME = 1_606_824_023;
    uint256 internal constant SECONDS_PER_SLOT = 12;
    uint256 internal constant SLOTS_PER_EPOCH = 32;

    // Path from a Validator to the beacon block root, leaf first. Electra and Fulu states
    // have between 33 and 64 fields, so the state tree is 6 deep; a fork that takes the
    // state past 64 fields changes STATE_DEPTH and needs a new vault.
    uint256 internal constant VALIDATORS_DEPTH = 40; // List[Validator, 2**40]
    uint256 internal constant STATE_DEPTH = 6;
    uint256 internal constant STATE_VALIDATORS_FIELD = 11;
    uint256 internal constant HEADER_DEPTH = 3;
    uint256 internal constant HEADER_STATE_ROOT_FIELD = 3;
    uint256 internal constant PROOF_LENGTH = VALIDATORS_DEPTH + 1 + STATE_DEPTH + HEADER_DEPTH;

    /// Where consensus-layer withdrawals of this vault's validators go
    address public withdrawalAddress;
    /// 1 ETH per staked validator, kept back so that every bond can be returned
    uint256 public bondsOwed;

    struct Record {
        address operator;
        bool staked;
        bool exited;
    }

    /// keccak256(pubkey) => record
    mapping(bytes32 => Record) public records;

    /// A validator as the beacon state holds it, without the public key
    struct ValidatorFields {
        bytes32 withdrawalCredentials;
        uint64 effectiveBalance;
        bool slashed;
        uint64 activationEligibilityEpoch;
        uint64 activationEpoch;
        uint64 exitEpoch;
        uint64 withdrawableEpoch;
    }

    /// A validator proven against the parent beacon block root of the block at `timestamp`
    struct ValidatorProof {
        uint64 timestamp;
        uint40 validatorIndex;
        ValidatorFields fields;
        bytes32[] branch;
    }

    event Received(address indexed from, uint256 amount);
    event Registered(bytes pubkey, address indexed operator);
    event Staked(bytes pubkey, address indexed operator);
    event Ejected(bytes pubkey, address indexed by);
    event Exited(bytes pubkey, address indexed operator, uint256 bondReturned);

    error BadPubkey();
    error AlreadyRegistered();
    error NotRegistered();
    error AlreadyStaked();
    error NotStaked();
    error AlreadyExited();
    error NothingToStake();
    error NoBeaconRoot();
    error StaleProof();
    error BadProof();
    error NotThisVault();
    error NotStakeable();
    error NotEjectable();
    error NotWithdrawable();
    error CannotRequest();
    error BondNotPaid();

    /// @param withdrawalAddress_ where withdrawals go; zero makes the vault its own, the sink
    constructor(address withdrawalAddress_) {
        withdrawalAddress = withdrawalAddress_ == address(0) ? address(this) : withdrawalAddress_;
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    /// The credentials every validator of this vault carries
    function withdrawalCredentials() public view returns (bytes32) {
        return bytes32(abi.encodePacked(bytes1(0x01), bytes11(0), withdrawalAddress));
    }

    /// Claim a public key before depositing for it. Whoever registers a key is its operator
    /// of record; an operator registers first and makes the deposit afterwards, so nobody
    /// else can have seen the key.
    function register(bytes calldata pubkey) external {
        if (pubkey.length != 48) revert BadPubkey();
        Record storage r = records[keccak256(pubkey)];
        if (r.operator != address(0)) revert AlreadyRegistered();
        r.operator = msg.sender;
        emit Registered(pubkey, msg.sender);
    }

    /// Top up a registered validator with 31 ETH. Anyone may call.
    function stake(bytes calldata pubkey, ValidatorProof calldata proof) external {
        Record storage r = records[keccak256(pubkey)];
        if (r.operator == address(0)) revert NotRegistered();
        if (r.staked) revert AlreadyStaked();
        _verify(pubkey, proof);
        ValidatorFields calldata v = proof.fields;
        if (!_ours(v.withdrawalCredentials)) revert NotThisVault();
        if (v.slashed || v.exitEpoch != FAR_FUTURE_EPOCH) revert NotStakeable();
        if (v.withdrawalCredentials[0] == 0x01 && v.effectiveBalance > BOND_EFFECTIVE_BALANCE) revert NotStakeable();
        if (address(this).balance < bondsOwed + BOND + TOP_UP) revert NothingToStake();

        r.staked = true;
        bondsOwed += BOND;

        bytes memory credentials = abi.encodePacked(withdrawalCredentials());
        // the consensus layer does not read the signature of a top-up
        bytes memory signature = new bytes(96);
        IDepositContract(DEPOSIT_CONTRACT).deposit{value: TOP_UP}(
            pubkey, credentials, signature, _depositDataRoot(pubkey, credentials, signature, TOP_UP)
        );
        emit Staked(pubkey, r.operator);
    }

    /// Ask the consensus layer to exit an active validator of this vault that has fallen
    /// below a full effective balance. Anyone may call and pays the EIP-7002 fee. Only a vault that
    /// is its own withdrawal address can ask.
    function eject(bytes calldata pubkey, ValidatorProof calldata proof) external payable {
        Record storage r = records[keccak256(pubkey)];
        if (!r.staked) revert NotStaked();
        if (withdrawalAddress != address(this)) revert CannotRequest();
        _verify(pubkey, proof);
        ValidatorFields calldata v = proof.fields;
        if (
            v.exitEpoch != FAR_FUTURE_EPOCH || v.effectiveBalance >= FULL_EFFECTIVE_BALANCE
                || v.activationEpoch > _epochBefore(proof.timestamp)
        ) revert NotEjectable();
        // amount 0 is a full exit
        (bool ok,) = WITHDRAWAL_REQUESTS.call{value: msg.value}(abi.encodePacked(pubkey, uint64(0)));
        if (!ok) revert CannotRequest();
        emit Ejected(pubkey, msg.sender);
    }

    /// Close the record of a validator that has exited and return the bond to its operator,
    /// unless it was slashed. Anyone may call.
    function exit(bytes calldata pubkey, ValidatorProof calldata proof) external {
        Record storage r = records[keccak256(pubkey)];
        if (!r.staked) revert NotStaked();
        if (r.exited) revert AlreadyExited();
        _verify(pubkey, proof);
        ValidatorFields calldata v = proof.fields;
        if (v.withdrawableEpoch == FAR_FUTURE_EPOCH || v.withdrawableEpoch > _epochBefore(proof.timestamp)) {
            revert NotWithdrawable();
        }

        r.exited = true;
        bondsOwed -= BOND;
        uint256 returned = v.slashed ? 0 : BOND;
        if (returned != 0) {
            (bool ok,) = r.operator.call{value: returned}("");
            if (!ok) revert BondNotPaid();
        }
        emit Exited(pubkey, r.operator, returned);
    }

    // ------------------------------------------------------------------ proofs

    function _ours(bytes32 credentials) internal view returns (bool) {
        bytes1 prefix = credentials[0];
        return (prefix == 0x01 || prefix == 0x02)
            && credentials == bytes32(abi.encodePacked(prefix, bytes11(0), withdrawalAddress));
    }

    /// The epoch of the slot whose root the block at `timestamp` carries
    function _epochBefore(uint64 timestamp) internal pure returns (uint64) {
        return uint64((timestamp - SECONDS_PER_SLOT - GENESIS_TIME) / (SECONDS_PER_SLOT * SLOTS_PER_EPOCH));
    }

    function _verify(bytes calldata pubkey, ValidatorProof calldata proof) internal view {
        if (pubkey.length != 48) revert BadPubkey();
        if (proof.branch.length != PROOF_LENGTH) revert BadProof();
        if (proof.timestamp + MAX_PROOF_AGE < block.timestamp) revert StaleProof();
        (bool ok, bytes memory ret) = BEACON_ROOTS.staticcall(abi.encode(uint256(proof.timestamp)));
        if (!ok || ret.length != 32) revert NoBeaconRoot();

        bytes32 node = _validatorRoot(pubkey, proof.fields);
        uint256 index = uint256(proof.validatorIndex) | (STATE_VALIDATORS_FIELD << (VALIDATORS_DEPTH + 1))
            | (HEADER_STATE_ROOT_FIELD << (VALIDATORS_DEPTH + 1 + STATE_DEPTH));
        for (uint256 i; i < PROOF_LENGTH; ++i) {
            bytes32 sibling = proof.branch[i];
            node = (index >> i) & 1 == 1 ? _hash(sibling, node) : _hash(node, sibling);
        }
        if (node != abi.decode(ret, (bytes32))) revert BadProof();
    }

    function _validatorRoot(bytes calldata pubkey, ValidatorFields calldata v) internal pure returns (bytes32) {
        bytes32 pubkeyRoot = sha256(abi.encodePacked(pubkey, bytes16(0)));
        return _hash(
            _hash(
                _hash(pubkeyRoot, v.withdrawalCredentials),
                _hash(_le64(v.effectiveBalance), v.slashed ? bytes32(uint256(1) << 248) : bytes32(0))
            ),
            _hash(
                _hash(_le64(v.activationEligibilityEpoch), _le64(v.activationEpoch)),
                _hash(_le64(v.exitEpoch), _le64(v.withdrawableEpoch))
            )
        );
    }

    /// hash_tree_root of `DepositData`, as the deposit contract computes it
    function _depositDataRoot(bytes calldata pubkey, bytes memory credentials, bytes memory signature, uint256 amount)
        internal
        pure
        returns (bytes32)
    {
        bytes32 pubkeyRoot = sha256(abi.encodePacked(pubkey, bytes16(0)));
        bytes32 head;
        bytes32 mid;
        bytes32 tail;
        assembly ("memory-safe") {
            head := mload(add(signature, 0x20))
            mid := mload(add(signature, 0x40))
            tail := mload(add(signature, 0x60))
        }
        bytes32 signatureRoot = _hash(_hash(head, mid), _hash(tail, bytes32(0)));
        return _hash(_hash(pubkeyRoot, bytes32(credentials)), _hash(_le64(uint64(amount / 1 gwei)), signatureRoot));
    }

    function _hash(bytes32 a, bytes32 b) internal pure returns (bytes32) {
        return sha256(abi.encodePacked(a, b));
    }

    /// A uint64 as SSZ stores it: little-endian, in the first eight bytes of the chunk
    function _le64(uint64 v) internal pure returns (bytes32) {
        v = ((v & 0xFF00FF00FF00FF00) >> 8) | ((v & 0x00FF00FF00FF00FF) << 8);
        v = ((v & 0xFFFF0000FFFF0000) >> 16) | ((v & 0x0000FFFF0000FFFF) << 16);
        v = (v >> 32) | (v << 32);
        return bytes32(uint256(v) << 192);
    }
}
