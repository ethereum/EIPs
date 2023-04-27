// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.7.1;
import "./BaseBidOnAddresses.sol";

/// @title Bidding on Ethereum addresses
/// @author Victor Porton
/// @notice Not audited, not enough tested.
/// This allows anyone to claim 1000 conditional tokens in order for him to transfer money from the future.
/// See `docs/future-money.rst` and anyone to donate.
///
/// We have two kinds of ERC-1155 token IDs:
/// - conditional tokens: numbers < 2**64
/// - a combination of a collateral contract address and collateral token ID
///   (a counter of donated amount of collateral tokens, don't confuse with collateral tokens themselves)
///
/// In functions of this contract `condition` is always a customer's original address.
///
/// We receive funds in ERC-1155, see also https://github.com/vporton/wrap-tokens
contract BidOnAddresses is BaseBidOnAddresses {
    uint constant INITIAL_CUSTOMER_BALANCE = 1000 * 10**18; // an arbitrarily chosen value

    /// Customer registered.
    /// @param sender `msg.sender`.
    /// @param customer The customer address.
    /// @param data Additional data.
    event CustomerRegistered(
        address indexed sender,
        address indexed customer,
        uint256 indexed condition,
        bytes data
    );

    /// @param _uri The ERC-1155 token URI.
    constructor(string memory _uri) BaseBidOnAddresses(_uri) {
        _registerInterface(
            BidOnAddresses(0).onERC1155Received.selector ^
            BidOnAddresses(0).onERC1155BatchReceived.selector
        );
    }

    /// Anyone can register anyone.
    ///
    /// This can be called both before or after the oracle finish. However registering after the finish is useless.
    ///
    /// We check that `oracleId` exists (we don't want "spammers" to register themselves for a million oracles).
    ///
    /// We allow anyone to register anyone. This is useful for being registered by robots.
    /// At first it seems to be harmful to make somebody a millionaire unwillingly (he then needs a fortress and bodyguards),
    /// but: Salary tokens will be worth real money, only if the registered person publishes his works together
    /// with his Ethereum address. So, he can be made rich against his will only by impersonating him. But if somebody
    /// impersonates him, then they are able to present him richer than he is anyway, so making him vulnerable to
    /// kidnappers anyway. So having somebody registered against his will seems not to be a problem at all
    /// (except that he will see superfluous worthless tokens in Etherscan data of his account.)
    ///
    /// An alternative way would be to make registration gasless but requiring a registrant signature.
    /// This is not very good, probably:
    /// - It requires to install MetaMask.
    /// - It bothers the person to sign something, when he could just be hesitant to get what he needs.
    /// - It somehow complicates this contract.
    /// @param _customer The address of the customer. // TODO: current or original
    /// @param _oracleId The oracle ID.
    /// @param _data Additional data.
    function registerCustomer(address _customer, uint64 _oracleId, bytes calldata _data) external {
        require(_oracleId <= maxOracleId, "Oracle doesn't exist.");
        uint256 _condition = _createCondition(_customer);
        _mintToCustomer(_customer, _condition, INITIAL_CUSTOMER_BALANCE, _data);
        emit CustomerRegistered(msg.sender, _customer, _condition, _data);
    }
}
