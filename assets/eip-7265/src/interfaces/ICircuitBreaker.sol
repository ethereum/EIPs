// SPDX-License-Identifier: CC0-1.0
pragma solidity 0.8.19;

/// @title Circuit Breaker
/// @dev See https://eips.ethereum.org/EIPS/eip-[EIP NUMBER]
interface ICircuitBreaker {

    /**
     *
     * @custom:section Events
     *
     */

    /// @dev MUST be emitted in `registerAsset` when an asset is registered
    /// @param asset MUST be the address of the asset for which to set rate limit parameters. 
    /// For any EIP-20 token, MUST be an EIP-20 token contract.
    /// For the native asset (ETH on mainnet), MUST be address 0x0000000000000000000000000000000000000001 equivalent to address(1).
    /// @param metricThreshold The threshold metric which defines when a rate limit is triggered
    /// @param minAmountToLimit The minimum amount of nominal asset liquidity at which point rate limits can be triggered
    event AssetRegistered(address indexed asset, uint256 metricThreshold, uint256 minAmountToLimit);

    /// @dev MUST be emitted in `onTokenInflow` and `onNativeAssetInflow` during asset inflow into a protected contract
    /// @param token MUST be the address of the asset flowing in. 
    /// For any EIP-20 token, MUST be an EIP-20 token contract.
    /// For the native asset (ETH on mainnet), MUST be address 0x0000000000000000000000000000000000000001 equivalent to address(1).
    /// @param amount MUST equal the amount of asset transferred into the protected contract
    event AssetInflow(address indexed token, uint256 indexed amount);

    /// @dev MUST be emitted in `onTokenOutflow` and `onNativeAssetOutflow` when a rate limit is triggered
    /// @param asset MUST be the address of the asset triggering the rate limit. 
    /// For any EIP-20 token, MUST be an EIP-20 token contract.
    /// For the native asset (ETH on mainnet), MUST be address 0x0000000000000000000000000000000000000001 equivalent to address(1).
    /// @param timestamp MUST equal the block.timestamp at the time of rate limit breach
    event AssetRateLimitBreached(address indexed asset, uint256 timestamp);

    /// @dev MUST be emitted in `onTokenOutflow` and `onNativeAssetOutflow` when an asset is successfully withdrawn
    /// @param asset MUST be the address of the asset withdrawn. 
    /// For any EIP-20 token, MUST be an EIP-20 token contract.
    /// For the native asset (ETH on mainnet), MUST be address 0x0000000000000000000000000000000000000001 equivalent to address(1).
    /// @param recipient MUST be the address of the recipient withdrawing the assets
    /// @param amount MUST be the amount of assets being withdrawn
    event AssetWithdraw(address indexed asset, address indexed recipient, uint256 amount);

    /// @dev MUST be emitted in `claimLockedFunds` when a recipient claims locked funds
    /// @param asset MUST be the address of the asset claimed. 
    /// For any EIP-20 token, MUST be an EIP-20 token contract.
    /// For the native asset (ETH on mainnet), MUST be address 0x0000000000000000000000000000000000000001 equivalent to address(1).
    /// @param recipient MUST be the address of the recipient claiming the assets
    event LockedFundsClaimed(address indexed asset, address indexed recipient);

    /// @dev MUST be emitted in `setAdmin` when a new admin is set
    /// @param newAdmin MUST be the new admin address
    event AdminSet(address indexed newAdmin);

    /// @dev MUST be emitted in `startGracePeriod` when a new grace period is successfully started
    /// @param gracePeriodEnd MUST be the end timestamp of the new grace period
    event GracePeriodStarted(uint256 gracePeriodEnd);

    /**
     *
     * @custom:section Write functions
     *
     */

    /// @notice Register rate limit parameters for a given asset
    /// @dev Each asset that will be rate limited MUST be registered using this function, including the native asset (ETH on mainnet). 
    /// If an asset is not registered, it will not be subject to rate limiting or circuit breaking and unlimited immediate withdrawals MUST be allowed.
    /// MUST revert if the caller is not the current admin.
    /// MUST revert if the asset has already been registered.
    /// @param _asset The address of the asset for which to set rate limit parameters. 
    /// To set the rate limit parameters for any EIP-20 token, MUST be an EIP-20 token contract.
    /// To set rate limit parameters For the native asset, MUST be address 0x0000000000000000000000000000000000000001 equivalent to address(1).
    /// @param _metricThreshold The threshold metric which defines when a rate limit is triggered. 
    /// This is intentionally left open to allow for various implementations, including percentage-based (see reference implementation), nominal, and more.
    /// MUST be greater than 0.
    /// @param _minAmountToLimit The minimum amount of nominal asset liquidity at which point rate limits can be triggered. 
    /// This limits potential false positives triggered either by minor assets with low liquidity or by low liquidity during early stages of protocol launch.
    /// Below this amount, withdrawals of this asset MUST NOT trigger a rate limit.
    /// However, if a rate limit is triggered, assets below the minimum trigger amount to limit MUST still be locked.
    function registerAsset(
        address _asset,
        uint256 _metricThreshold,
        uint256 _minAmountToLimit
    ) external;

    /// @notice Modify rate limit parameters for a given asset 
    /// @dev MAY be used only after registering an asset.
    /// MUST revert if asset is not previously registered with the `registerAsset` method.
    /// MUST revert if the caller is not the current admin.
    /// @param _asset The address of the asset contract for which to set rate limit parameters. 
    /// To update the rate limit parameters for any EIP-20 token, MUST be an EIP-20 token contract.
    /// To update the rate limit parameters For the native asset (ETH on mainnet), MUST be address 0x0000000000000000000000000000000000000001 equivalent to address(1).
    /// @param _metricThreshold The threshold metric which defines when a rate limit is triggered. 
    /// This is left open to allow for various implementations, including percentage-based (see reference implementation), nominal, and more.
    /// MUST be greater than 0.
    /// @param _minAmountToLimit The minimum amount of nominal asset liquidity at which point rate limits can be triggered. 
    /// This limits potential false positives caused both by minor assets with low liquidity and by low liquidity during early stages of protocol launch.
    /// Below this amount, withdrawals of this asset MUST NOT trigger a rate limit.
    /// However, if a rate limit is triggered, assets below the minimum amount to limit MUST still be locked.
    function updateAssetParams(
        address _asset,
        uint256 _metricThreshold,
        uint256 _minAmountToLimit
    ) external;

    /// @notice Record EIP-20 token inflow into a protected contract
    /// @dev This method MUST be called from all protected contract methods where an EIP-20 token is transferred in from a user.
    /// MUST revert if caller is not a protected contract.
    /// MUST revert if circuit breaker is not operational.
    /// @param _token MUST be an EIP-20 token contract
    /// @param _amount MUST equal the amount of token transferred into the protected contract
    function onTokenInflow(address _token, uint256 _amount) external;

    /// @notice Record EIP-20 token outflow from a protected contract and transfer tokens to recipient if rate limit is not triggered
    /// @dev This method MUST be called from all protected contract methods where an EIP-20 token is transferred out to a user.
    /// Before calling this method, the protected contract MUST transfer the EIP-20 tokens to the circuit breaker contract.
    /// For an example, see ProtectedContract.sol in the reference implementation.
    /// MUST revert if caller is not a protected contract.
    /// MUST revert if circuit breaker is not operational.
    /// If the token is not registered, this method MUST NOT revert and MUST transfer the tokens to the recipient.
    /// If a rate limit is not triggered or the circuit breaker is in grace period, this method MUST NOT revert and MUST transfer the tokens to the recipient.
    /// If a rate limit is triggered and the circuit breaker is not in grace period and `_revertOnRateLimit` is TRUE, this method MUST revert.
    /// If a rate limit is triggered and the circuit breaker is not in grace period and `_revertOnRateLimit` is FALSE and caller is a protected contract, this method MUST NOT revert.
    /// If a rate limit is triggered and the circuit breaker is not in grace period, this method MUST record the locked funds in the internal accounting of the circuit breaker implementation.
    /// @param _token MUST be an EIP-20 token contract
    /// @param _amount MUST equal the amount of tokens transferred out of the protected contract
    /// @param _recipient MUST be the address of the recipient of the transferred tokens from the protected contract
    /// @param _revertOnRateLimit MUST be TRUE to revert if a rate limit is triggered or FALSE to return without reverting if a rate limit is triggered (delayed settlement)
    function onTokenOutflow(
        address _token,
        uint256 _amount,
        address _recipient,
        bool _revertOnRateLimit
    ) external;

    /// @notice Record native asset (ETH on mainnet) inflow into a protected contract
    /// @dev This method MUST be called from all protected contract methods where native asset is transferred in from a user.
    /// MUST revert if caller is not a protected contract.
    /// MUST revert if circuit breaker is not operational.
    /// @param _amount MUST equal the amount of native asset transferred into the protected contract
    function onNativeAssetInflow(uint256 _amount) external;

    /// @notice Record native asset (ETH on mainnet) outflow from a protected contract and transfer native asset to recipient if rate limit is not triggered
    /// @dev This method MUST be called from all protected contract methods where native asset is transferred out to a user.
    /// When calling this method, the protected contract MUST send the native asset to the circuit breaker contract in the same call.
    /// For an example, see ProtectedContract.sol in the reference implementation.
    /// MUST revert if caller is not a protected contract.
    /// MUST revert if circuit breaker is not operational.
    /// If native asset is not registered, this method MUST NOT revert and MUST transfer the native asset to the recipient.
    /// If a rate limit is not triggered or the circuit breaker is in grace period, this method MUST NOT revert and MUST transfer the native asset to the recipient.
    /// If a rate limit is triggered and the circuit breaker is not in grace period and `_revertOnRateLimit` is TRUE, this method MUST revert.
    /// If a rate limit is triggered and the circuit breaker is not in grace period and `_revertOnRateLimit` is FALSE and caller is a protected contract, this method MUST NOT revert.
    /// If a rate limit is triggered and the circuit breaker is not in grace period, this method MUST record the locked funds in the internal accounting of the circuit breaker implementation.
    /// @param _recipient MUST be the address of the recipient of the transferred native asset from the protected contract
    /// @param _revertOnRateLimit MUST be TRUE to revert if a rate limit is triggered or FALSE to return without reverting if a rate limit is triggered (delayed settlement)
    function onNativeAssetOutflow(address _recipient, bool _revertOnRateLimit) external payable;

    /// @notice Allow users to claim locked funds when rate limit is resolved
    /// @dev When a asset is transferred out during a rate limit period, the settlement may be delayed and the asset custodied in the circuit breaker.
    /// This method allows users to claim funds that were delayed in settlement after the rate limit is resolved or a grace period is activated.
    /// MUST revert if the recipient does not have locked funds for a given asset.
    /// MUST revert if circuit breaker is rate limited or is not operational.
    /// MUST transfer tokens or native asset (ETH on mainnet) to the recipient on successful call.
    /// MUST update internal accounting of circuit breaker implementation to reflect withdrawn balance on successful call.
    /// @param _asset To claim locked EIP-20 tokens, this MUST be an EIP-20 token contract.
    /// To claim native asset, this MUST be address 0x0000000000000000000000000000000000000001 equivalent to address(1).
    /// @param _recipient MUST be the address of the recipient of the locked funds from the circuit breaker
    function claimLockedFunds(address _asset, address _recipient) external;

    /// @notice Set the admin of the contract to govern the circuit breaker
    /// @dev The admin SHOULD represent the governance contract of the protected protocol.
    /// The admin has authority to: withdraw locked funds, set grace periods, register asset parameters, update asset parameters, 
    /// set new admin, override rate limit, add protected contracts, remove protected contracts.
    /// MUST revert if the caller is not the current admin.
    /// MUST revert if `_newAdmin` is address(0).
    /// MUST update the circuit breaker admin to the new admin in the stored state of the implementation on successful call.
    /// @param _newAdmin MUST be the address of the new admin
    function setAdmin(address _newAdmin) external;

    /// @notice Override a rate limit
    /// @dev This method MAY be called when the protocol admin (typically governance) is certain that a rate limit is the result of a false positive.
    /// MUST revert if caller is not the current admin.
    /// MUST allow the grace period to extend for the full withdrawal period to not trigger the rate limit again if the rate limit is removed just before the withdrawal period ends.
    /// MUST revert if the circuit breaker is not currently rate limited.
    function overrideRateLimit() external;

    /// @notice Override an expired rate limit
    /// @dev This method MAY be called by anyone once the cooldown period is complete. 
    /// MUST revert if the cooldown period is not complete.
    /// MUST revert if the circuit breaker is not currently rate limited.
    function overrideExpiredRateLimit() external;

    /// @notice Add new protected contracts
    /// @dev MUST be used to add protected contracts. Protected contracts MUST be part of your protocol. 
    /// Protected contracts have the authority to trigger rate limits and withdraw assets. 
    /// MUST revert if caller is not the current admin.
    /// MUST store protected contracts in the stored state of the circuit breaker implementation.
    /// @param _ProtectedContracts an array of addresses of protected contracts to add
    function addProtectedContracts(address[] calldata _ProtectedContracts) external;

    /// @notice Remove protected contracts
    /// @dev MAY be used to remove protected contracts. Protected contracts MUST be part of your protocol. 
    /// Protected contracts have the authority to trigger rate limits and withdraw assets. 
    /// MUST revert if caller is not the current admin.
    /// MUST remove protected contracts from stored state in the circuit breaker implementation.
    /// @param _ProtectedContracts an array of addresses of protected contracts to remove
    function removeProtectedContracts(address[] calldata _ProtectedContracts) external;

    /// @notice Set a custom grace period
    /// @dev MAY be called by admin to set a custom grace period during which rate limits will not be active.
    /// MUST revert if caller is not the current admin.
    /// MUST start grace period until end timestamp.
    /// @param _gracePeriodEndTimestamp The ending timestamp of the grace period
    /// MUST be greater than the current block.timestamp
    function startGracePeriod(uint256 _gracePeriodEndTimestamp) external;

    /// @notice Lock the circuit breaker
    /// @dev MAY be called by admin to lock the circuit breaker
    /// While the protocol is not operational: inflows, outflows, and claiming locked funds MUST revert
    function markAsNotOperational() external;

    /// @notice Migrates locked funds after exploit for recovery
    /// @dev MUST revert if the protocol is operational.
    /// MUST revert if caller is not the current admin.
    /// MUST transfer assets to recovery recipient on successful call.
    /// @param _assets Array of assets to recover.
    /// For any EIP-20 token, MUST be an EIP-20 token contract.
    /// For the native asset (ETH on mainnet), MUST be address 0x0000000000000000000000000000000000000001 equivalent to address(1).
    /// @param _recoveryRecipient The address of the recipient to receive recovered funds. Often this will be a multisig wallet. 
    function migrateFundsAfterExploit(
        address[] calldata _assets,
        address _recoveryRecipient
    ) external;

    /**
     *
     * @custom:section Read-only functions
     *
     */

    /// @notice View funds locked for a given recipient and asset
    /// @param recipient The address of the recipient
    /// @param asset To view the balance of locked EIP-20 tokens, this MUST be an EIP-20 token contract.
    /// To claim native ETH, this MUST be address 0x0000000000000000000000000000000000000001 equivalent to address(1).
    /// @return amount The locked balance for the given recipient and asset
    function lockedFunds(address recipient, address asset) external view returns (uint256 amount);

    /// @notice Check if a given address is a protected contract
    /// @param account The address of the contract to check
    /// @return protectionActive MUST be TRUE if the contract is protected, FALSE if it is not protected
    function isProtectedContract(address account) external view returns (bool protectionActive);

    /// @notice View the admin of the circuit breaker
    /// @dev This SHOULD be the governance contract for your protocol
    /// @return admin The admin of the circuit breaker
    function admin() external view returns (address);

    /// @notice Check is the circuit breaker is rate limited
    /// @return isRateLimited MUST be TRUE if the circuit breaker is rate limited, FALSE if it is not rate limited
    function isRateLimited() external view returns (bool);

    /// @notice View the rate limit cooldown period
    /// @dev The duration of a rate limit once triggered
    /// @return rateLimitCooldownPeriod The rate limit cooldown period
    function rateLimitCooldownPeriod() external view returns (uint256);

    /// @notice View the last rate limit timestamp
    /// @return lastRateLimitTimestamp MUST return the last rate limit timestamp
    function lastRateLimitTimestamp() external view returns (uint256);

    /// @notice View the grace period end timestamp
    /// @return gracePeriodEndTimestamp MUST return the grace period end timestamp
    function gracePeriodEndTimestamp() external view returns (uint256);

    /// @notice Check if a rate limit is currently triggered for a given asset
    /// @param _asset To check if triggered for EIP-20 tokens, this MUST be an EIP-20 token contract.
    /// To check if triggered For the native asset (ETH on mainnet), this MUST be address 0x0000000000000000000000000000000000000001 equivalent to address(1).
    /// @return isRateLimitTriggered MUST return TRUE if a rate limit is currently triggered for given asset, FALSE if not
    function isRateLimitTriggered(address _asset) external view returns (bool);

    /// @notice Check if the circuit breaker is currently in grace period
    /// @return isInGracePeriod MUST return TRUE if the circuit breaker is currently in grace period, FALSE otherwise
    function isInGracePeriod() external view returns (bool);

    /// @notice Check if the circuit breaker is operational
    /// @return isOperational MUST return TRUE if the circuit breaker is operational (not exploited), FALSE otherwise
    function isOperational() external view returns (bool);
}
