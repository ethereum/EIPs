// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {SafeERC20} from "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";
import {ICircuitBreaker} from "../interfaces/ICircuitBreaker.sol";
import {Limiter, LiqChangeNode} from "../static/Structs.sol";
import {LimiterLib, LimitStatus} from "../utils/LimiterLib.sol";

contract CircuitBreaker is ICircuitBreaker {
    using SafeERC20 for IERC20;
    using LimiterLib for Limiter;

    ////////////////////////////////////////////////////////////////
    //                      STATE VARIABLES                       //
    ////////////////////////////////////////////////////////////////

    mapping(address => Limiter limiter) public tokenLimiters;

    /**
     * @notice Funds locked if rate limited reached
     */
    mapping(address recipient => mapping(address asset => uint256 amount)) public lockedFunds;

    mapping(address account => bool protectionActive) public isProtectedContract;

    address public admin;

    bool public isRateLimited;

    uint256 public rateLimitCooldownPeriod;

    uint256 public lastRateLimitTimestamp;

    uint256 public gracePeriodEndTimestamp;

    // Using address(1) as a proxy for native token (ETH, BNB, etc), address(0) could be problematic
    address public immutable NATIVE_ADDRESS_PROXY = address(1);

    uint256 public immutable WITHDRAWAL_PERIOD;

    uint256 public immutable TICK_LENGTH;

    bool public isOperational = true;

    ////////////////////////////////////////////////////////////////
    //                           EVENTS                           //
    ////////////////////////////////////////////////////////////////

    /**
     * @notice Non-EIP standard events
     */

    event TokenBacklogCleaned(address indexed token, uint256 timestamp);

    ////////////////////////////////////////////////////////////////
    //                           ERRORS                           //
    ////////////////////////////////////////////////////////////////

    error NotAProtectedContract();
    error NotAdmin();
    error InvalidAdminAddress();
    error NoLockedFunds();
    error RateLimited();
    error NotRateLimited();
    error TokenNotRateLimited();
    error CooldownPeriodNotReached();
    error NativeTransferFailed();
    error InvalidRecipientAddress();
    error InvalidGracePeriodEnd();
    error ProtocolWasExploited();
    error NotExploited();

    ////////////////////////////////////////////////////////////////
    //                         MODIFIERS                          //
    ////////////////////////////////////////////////////////////////

    modifier onlyProtected() {
        if (!isProtectedContract[msg.sender]) revert NotAProtectedContract();
        _;
    }

    modifier onlyAdmin() {
        if (msg.sender != admin) revert NotAdmin();
        _;
    }

    /**
     * @notice When the isOperational flag is set to false, the protocol is considered locked and will
     * revert all future deposits, withdrawals, and claims to locked funds.
     * The admin should migrate the funds from the underlying protocol and what is remaining
     * in the CircuitBreaker contract to a multisig. This multisig should then be used to refund users pro-rata.
     * (Social Consensus)
     */
    modifier onlyOperational() {
        if (!isOperational) revert ProtocolWasExploited();
        _;
    }

    /**
     * @notice gracePeriod refers to the time after a rate limit trigger and then overriden where withdrawals are
     * still allowed.
     * @dev For example a false positive rate limit trigger, then it is overriden, so withdrawals are still
     * allowed for a period of time.
     * Before the rate limit is enforced again, it should be set to be at least your largest
     * withdrawalPeriod length
     */
    constructor(
        address _admin,
        uint256 _rateLimitCooldownPeriod,
        uint256 _withdrawlPeriod,
        uint256 _liquidityTickLength
    ) {
        admin = _admin;
        rateLimitCooldownPeriod = _rateLimitCooldownPeriod;
        WITHDRAWAL_PERIOD = _withdrawlPeriod;
        TICK_LENGTH = _liquidityTickLength;
    }

    ////////////////////////////////////////////////////////////////
    //                         FUNCTIONS                          //
    ////////////////////////////////////////////////////////////////

    /**
     * @dev Give protected contracts one function to call for convenience
     */
    function onTokenInflow(address _token, uint256 _amount) external onlyProtected onlyOperational {
        _onTokenInflow(_token, _amount);
    }

    function onTokenOutflow(
        address _token,
        uint256 _amount,
        address _recipient,
        bool _revertOnRateLimit
    ) external onlyProtected onlyOperational {
        _onTokenOutflow(_token, _amount, _recipient, _revertOnRateLimit);
    }

    function onNativeAssetInflow(uint256 _amount) external onlyProtected onlyOperational {
        _onTokenInflow(NATIVE_ADDRESS_PROXY, _amount);
    }

    function onNativeAssetOutflow(
        address _recipient,
        bool _revertOnRateLimit
    ) external payable onlyProtected onlyOperational {
        _onTokenOutflow(NATIVE_ADDRESS_PROXY, msg.value, _recipient, _revertOnRateLimit);
    }

    /**
     * @notice Allow users to claim locked funds when rate limit is resolved
     * use address(1) for native token claims
     */

    function claimLockedFunds(address _asset, address _recipient) external onlyOperational {
        if (lockedFunds[_recipient][_asset] == 0) revert NoLockedFunds();
        if (isRateLimited) revert RateLimited();

        uint256 amount = lockedFunds[_recipient][_asset];
        lockedFunds[_recipient][_asset] = 0;

        emit LockedFundsClaimed(_asset, _recipient);

        _safeTransferIncludingNative(_asset, _recipient, amount);
    }

    /**
     * @dev Due to potential inactivity, the linked list may grow to where
     * it is better to clear the backlog in advance to save gas for the users
     * this is a public function so that anyone can call it as it is not user sensitive
     */
    function clearBackLog(address _token, uint256 _maxIterations) external {
        tokenLimiters[_token].sync(WITHDRAWAL_PERIOD, _maxIterations);
        emit TokenBacklogCleaned(_token, block.timestamp);
    }

    function overrideExpiredRateLimit() external {
        if (!isRateLimited) revert NotRateLimited();
        if (block.timestamp - lastRateLimitTimestamp < rateLimitCooldownPeriod) {
            revert CooldownPeriodNotReached();
        }

        isRateLimited = false;
    }

    function registerAsset(
        address _asset,
        uint256 _minLiqRetainedBps,
        uint256 _limitBeginThreshold
    ) external onlyAdmin {
        tokenLimiters[_asset].init(_minLiqRetainedBps, _limitBeginThreshold);
        emit AssetRegistered(_asset, _minLiqRetainedBps, _limitBeginThreshold);
    }

    function updateAssetParams(
        address _asset,
        uint256 _minLiqRetainedBps,
        uint256 _limitBeginThreshold
    ) external onlyAdmin {
        Limiter storage limiter = tokenLimiters[_asset];
        limiter.updateParams(_minLiqRetainedBps, _limitBeginThreshold);
        limiter.sync(WITHDRAWAL_PERIOD);
    }

    function overrideRateLimit() external onlyAdmin {
        if (!isRateLimited) revert NotRateLimited();
        isRateLimited = false;
        // Allow the grace period to extend for the full withdrawal period to not trigger rate limit again
        // if the rate limit is removed just before the withdrawal period ends
        gracePeriodEndTimestamp = lastRateLimitTimestamp + WITHDRAWAL_PERIOD;
    }

    function addProtectedContracts(address[] calldata _ProtectedContracts) external onlyAdmin {
        for (uint256 i = 0; i < _ProtectedContracts.length; i++) {
            isProtectedContract[_ProtectedContracts[i]] = true;
        }
    }

    function removeProtectedContracts(address[] calldata _ProtectedContracts) external onlyAdmin {
        for (uint256 i = 0; i < _ProtectedContracts.length; i++) {
            isProtectedContract[_ProtectedContracts[i]] = false;
        }
    }

    function startGracePeriod(uint256 _gracePeriodEndTimestamp) external onlyAdmin {
        if (_gracePeriodEndTimestamp <= block.timestamp) revert InvalidGracePeriodEnd();
        gracePeriodEndTimestamp = _gracePeriodEndTimestamp;
        emit GracePeriodStarted(_gracePeriodEndTimestamp);
    }

    function setAdmin(address _newAdmin) external onlyAdmin {
        if (_newAdmin == address(0)) revert InvalidAdminAddress();
        admin = _newAdmin;
        emit AdminSet(_newAdmin);
    }

    function tokenLiquidityChanges(
        address _token,
        uint256 _tickTimestamp
    ) external view returns (uint256 nextTimestamp, int256 amount) {
        LiqChangeNode storage node = tokenLimiters[_token].listNodes[_tickTimestamp];
        nextTimestamp = node.nextTimestamp;
        amount = node.amount;
    }

    function isRateLimitTriggered(address _asset) public view returns (bool) {
        return tokenLimiters[_asset].status() == LimitStatus.Triggered;
    }

    function isInGracePeriod() public view returns (bool) {
        return block.timestamp <= gracePeriodEndTimestamp;
    }

    function markAsNotOperational() external onlyAdmin {
        isOperational = false;
    }

    function migrateFundsAfterExploit(
        address[] calldata _assets,
        address _recoveryRecipient
    ) external onlyAdmin {
        if (isOperational) revert NotExploited();
        for (uint256 i = 0; i < _assets.length; i++) {
            if (_assets[i] == NATIVE_ADDRESS_PROXY) {
                uint256 amount = address(this).balance;
                if (amount > 0) {
                    _safeTransferIncludingNative(_assets[i], _recoveryRecipient, amount);
                }
            } else {
                uint256 amount = IERC20(_assets[i]).balanceOf(address(this));
                if (amount > 0) {
                    _safeTransferIncludingNative(_assets[i], _recoveryRecipient, amount);
                }
            }
        }
    }

    ////////////////////////////////////////////////////////////////
    //                       INTERNAL  FUNCTIONS                  //
    ////////////////////////////////////////////////////////////////

    function _onTokenInflow(address _token, uint256 _amount) internal {
        /// @dev uint256 could overflow into negative
        Limiter storage limiter = tokenLimiters[_token];

        limiter.recordChange(int256(_amount), WITHDRAWAL_PERIOD, TICK_LENGTH);
        emit AssetInflow(_token, _amount);
    }

    function _onTokenOutflow(
        address _token,
        uint256 _amount,
        address _recipient,
        bool _revertOnRateLimit
    ) internal {
        Limiter storage limiter = tokenLimiters[_token];
        // Check if the token has enforced rate limited
        if (!limiter.initialized()) {
            // if it is not rate limited, just transfer the tokens
            _safeTransferIncludingNative(_token, _recipient, _amount);
            return;
        }
        limiter.recordChange(-int256(_amount), WITHDRAWAL_PERIOD, TICK_LENGTH);
        // Check if currently rate limited, if so, add to locked funds claimable when resolved
        if (isRateLimited) {
            if (_revertOnRateLimit) {
                revert RateLimited();
            }
            lockedFunds[_recipient][_token] += _amount;
            return;
        }

        // Check if rate limit is triggered after withdrawal and not in grace period
        // (grace period allows for withdrawals to be made if rate limit is triggered but overriden)
        if (limiter.status() == LimitStatus.Triggered && !isInGracePeriod()) {
            if (_revertOnRateLimit) {
                revert RateLimited();
            }
            // if it is, set rate limited to true
            isRateLimited = true;
            lastRateLimitTimestamp = block.timestamp;
            // add to locked funds claimable when resolved
            lockedFunds[_recipient][_token] += _amount;

            emit AssetRateLimitBreached(_token, block.timestamp);

            return;
        }

        // if everything is good, transfer the tokens
        _safeTransferIncludingNative(_token, _recipient, _amount);

        emit AssetWithdraw(_token, _recipient, _amount);
    }

    function _safeTransferIncludingNative(
        address _token,
        address _recipient,
        uint256 _amount
    ) internal {
        if (_token == NATIVE_ADDRESS_PROXY) {
            (bool success, ) = _recipient.call{value: _amount}("");
            if (!success) revert NativeTransferFailed();
        } else {
            IERC20(_token).safeTransfer(_recipient, _amount);
        }
    }
}
