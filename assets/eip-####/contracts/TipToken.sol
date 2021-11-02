// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./ITipToken.sol";

/// @title Micropayments Standard for NFTs and Multi Tokens
/// @author Jules Lai
/// @notice An implementation for a standard interface for tip tokens that allows tipping to holders of NFTs and multi tokens
/// @dev Allows tipping for ERC-721 and ERC-1155 multi tokens. Their holders receive the rewards of ERC20 compatible deposits
contract TipToken is ITipToken, ERC20, Ownable {
    using SafeERC20 for IERC20;

    // nft => (id => holder)
    mapping(address => mapping(uint256 => address[])) internal _idToAccount;

    // user => deposit balance
    mapping(address => uint256) internal _depositBalances;

    // holder => rewards pending
    mapping(address => uint256) internal _rewardsPending;

    address private _rewardToken;
    uint256 _price;

    constructor(address rewardToken_) ERC20("", "") {
        _rewardToken = rewardToken_;

        emit InitializeTipToken(address(this), _rewardToken, owner());
    }

    function supportsInterface(bytes4 interfaceID) public pure returns (bool) {
        return
            interfaceID == type(IERC165).interfaceId ||
            interfaceID == type(IERC20).interfaceId ||
            interfaceID == type(ITipToken).interfaceId ||
            interfaceID == this.supportsInterface.selector;
    }

    /////////////////////////////////////////// EIP-xxxx //////////////////////////////////////////////

    /// @notice Enable or disable approval for tipping for a single NFT held
    /// by holder
    /// @dev MUST revert if calling nft's supportsInterface does not return
    /// true for either IERC721 or IERC1155.
    /// MUST revert if 'holder' is the zero address.
    /// MUST revert if 'nft' has not approved the tip token contract address.
    /// MUST emit the 'ApprovalForNFT' event to reflect approval or not approval
    /// @param holders The holders of the NFT (NFT controllers)
    /// @param nft The NFT contract address
    /// @param id The NFT token id
    /// @param approved True if the 'holder' is approved, false to revoke approval
    function setApprovalForNFT(
        address[] memory holders,
        address nft,
        uint256 id,
        bool approved
    ) external override onlyOwner {
        require(nft != address(0), "NFT cannot be zero address");

        require(
            IERC165(nft).supportsInterface(type(IERC1155).interfaceId)
                ? _erc1155IsApprovedForAll(nft, holders)
                : IERC165(nft).supportsInterface(type(IERC721).interfaceId)
                ? holders.length == 1 &&
                    IERC721(nft).isApprovedForAll(holders[0], address(this))
                : false,
            "Unable to set approval"
        );

        if (approved) _idToAccount[nft][id] = holders;
        else delete _idToAccount[nft][id];

        emit ApprovalForNFT(holders, nft, id, approved);
    }

    /// @notice Checks if 'holder' and 'nft' with token 'id' have been approved
    /// by setApprovalForNFT
    /// @dev This does not check that the holder of the NFT has changed. That is
    /// left to the implementer to detect events for change of ownership and to
    /// take appropriate action
    /// @param holder The holder of the NFT (NFT controller)
    /// @param nft The NFT contract address
    /// @param id The NFT token id
    /// @return True if 'holder' and 'nft' with token 'id' have previously been
    /// approved by the tip token contract
    function isApprovalForNFT(
        address holder,
        address nft,
        uint256 id
    ) external view override returns (bool) {
        if (_idToAccount[nft][id].length == 0) return false;

        address[] memory holders = _idToAccount[nft][id];
        for (uint256 i = 0; i < holders.length; i++) {
            if (_idToAccount[nft][id][i] == holder) return true;
        }

        return false;
    }

    /// @notice Deposit an ERC20 compatible token in exchange for tip tokens
    /// @dev The price of tip tokens can be different for each deposit as
    /// the amount of reward token sent ultimately is a ratio of the
    /// amount of tip tokens to tip over the user's tip tokens balance available
    /// multiplied by the user's deposit balance.
    /// The deposited tokens can be held in the tip tokens contract account or
    /// in an external eschrow. This will depend on the tip token implementation.
    /// Each tip token contract MUST handle only one type of ERC20 compatible
    /// reward for deposits.
    /// This token address SHOULD be passed in to the tip token constructor or
    /// initialize method. SHOULD revert if ERC20 reward for deposits is
    /// zero address.
    /// MUST emit the 'Deposit' event that shows the user, deposited token details
    /// and amount of tip tokens minted in exchange
    /// @param user The user account
    /// @param amount Amount of ERC20 token to deposit in exchange for tip tokens.
    /// This deposit is to be used later as the reward token
    function deposit(address user, uint256 amount) external payable override {
        require(
            _rewardToken != address(0),
            "Base token cannot be zero address"
        );

        uint256 providerBalanceBefore = IERC20(payable(_rewardToken)).balanceOf(
            address(this)
        );

        IERC20(payable(_rewardToken)).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );

        uint256 valueDeposited = IERC20(_rewardToken).balanceOf(address(this)) -
            providerBalanceBefore;

        _depositBalances[user] += valueDeposited;

        // send subscription tokens to the depositor
        uint256 amountToMint = (amount * (10**18)) / _price;
        _mint(user, amountToMint);

        emit Deposit(user, _rewardToken, amount, amountToMint);
    }

    /// @notice Sends tip from msg.sender to holder of a single NFT
    /// @dev If NFT has not been approved for tipping, MUST revert
    /// MUST revert if 'nft' is zero address.
    /// MUST burn the tip 'amount' to the 'holder' and send the reward to
    /// an account pending for the 'holder'.
    /// MUST emit the 'Tip' event to reflect the amounts that msg.sender tipped
    /// to holder's 'nft'.
    /// @param nft The NFT contract address
    /// @param id The NFT token id
    /// @param amount Amount of tip tokens to send to the holder of the NFT
    function tip(
        address nft,
        uint256 id,
        uint256 amount
    ) external override {
        _tip(msg.sender, nft, id, amount);
    }

    /// @notice Sends a batch of tips to holders of 'nfts' for gas efficiency
    /// @dev If NFT has not been approved for tipping, revert
    /// MUST revert if the input arguments lengths are not all the same
    /// MUST revert if any of the user addresses are zero
    /// MUST revert the whole batch if there are any errors
    /// MUST emit the 'Tip' events so that the state of the amounts sent to
    /// each holder and for which nft and from whom, can be reconstructed.
    /// @param users User accounts to tip from
    /// @param nfts The NFT contract addresses whose holders to tip to
    /// @param ids The NFT token ids that uniquely identifies the nft
    /// @param amounts Amount of tip tokens to send to the holder of the NFT
    function tipBatch(
        address[] memory users,
        address[] memory nfts,
        uint256[] memory ids,
        uint256[] memory amounts
    ) external override onlyOwner {
        require(
            users.length == amounts.length &&
                nfts.length == amounts.length &&
                ids.length == amounts.length,
            "Number of users, nfts, ids and amounts are not equal"
        );

        for (uint256 i = 0; i < ids.length; ++i) {
            _tip(users[i], nfts[i], ids[i], amounts[i]);
        }
    }

    /// @notice MUST have idential behaviour to ERC20 balanceOf and is the amount
    /// of tip tokens held by 'user'
    /// @param user The user account
    /// @return The balance of tip tokens held by user
    function balanceOf(address user)
        public
        view
        override(ERC20, ITipToken)
        returns (uint256)
    {
        return super.balanceOf(user);
    }

    /// @notice The balance of deposit available to become rewards when
    /// user sends the tips
    /// @param user The user account
    /// @return The remaining balance of the ERC20 compatible token deposited
    function balanceDepositOf(address user)
        external
        view
        override
        returns (uint256)
    {
        return _depositBalances[user];
    }

    /// @notice The amount of reward token owed to 'holder'
    /// @dev The pending tokens can come from the tip token contract account
    /// or from an external eschrow, depending on tip token implementation
    /// @param holder The holder of an NFT (NFT controller)
    /// @return The amount of reward tokens owed to the holder from tipping
    function rewardPendingOf(address holder)
        external
        view
        override
        returns (uint256)
    {
        return _rewardsPending[holder];
    }

    /// @notice An NFT holder can withdraw their tips as an ERC20 compatible
    /// reward at a time of their choosing
    /// @dev MUST revert if not enough balance pending available to withdraw.
    /// MUST send 'amount' to msg.sender account (the holder)
    /// MUST reduce the balance of reward tokens pending by the 'amount' withdrawn.
    /// MUST emit the 'Withdraw' event to show the holder who withdrew, the reward
    /// token address and 'amount'
    /// @param amount Amount of ERC20 token to withdraw as a reward
    function withdraw(uint256 amount) external payable override {
        require(_rewardsPending[msg.sender] >= amount, "Not enough balance");

        IERC20(payable(_rewardToken)).safeTransfer(msg.sender, amount);

        emit Withdraw(msg.sender, _rewardToken, amount);
    }

    function price() external view returns (uint256) {
        return _price;
    }

    function setPrice(uint256 price_) external onlyOwner {
        _price = price_;
    }

    /////////////////////////////////////////// Internal //////////////////////////////////////////////

    function _tip(
        address user,
        address nft,
        uint256 id,
        uint256 amount
    ) internal {
        address[] memory holders = _idToAccount[nft][id];

        require(holders.length > 0, "NFT not approved");
        require(
            IERC165(nft).supportsInterface(type(IERC1155).interfaceId)
                ? _erc1155IsApprovedForAll(nft, holders)
                : IERC165(nft).supportsInterface(type(IERC721).interfaceId)
                ? holders.length == 1 &&
                    IERC721(nft).isApprovedForAll(holders[0], address(this))
                : false,
            "NFT to tip not available"
        );

        uint256 rewardTokenBalance = _depositBalances[user];
        uint256 tipTokenBalance = IERC20(address(this)).balanceOf(user);

        uint256 totalRewardTokenAmount = (rewardTokenBalance * amount) /
            tipTokenBalance;

        super._burn(user, amount);

        _depositBalances[user] -= totalRewardTokenAmount;
        uint256[] memory rewardTokenAmountToHolders = new uint256[](
            holders.length
        );

        if (holders.length == 1) {
            _rewardsPending[holders[0]] += totalRewardTokenAmount;
            rewardTokenAmountToHolders[0] = totalRewardTokenAmount;
        } else {
            uint256[] memory ids = new uint256[](holders.length);
            for (uint256 i = 0; i < holders.length; i++) ids[i] = id;

            uint256[] memory erc1155Balances = IERC1155(nft).balanceOfBatch(
                holders,
                ids
            );
            uint256 totalERC1155Balance;

            for (uint256 i = 0; i < holders.length; i++)
                totalERC1155Balance += erc1155Balances[i];

            // pay out in the proportion of balances held
            uint256 actualTotalRewardTokenAmount;
            for (uint256 i = 0; i < holders.length; i++) {
                uint256 holderERC1155Balance = IERC1155(nft).balanceOf(
                    holders[i],
                    id
                );
                uint256 rewardTokenAmountToHolder = (totalRewardTokenAmount *
                    holderERC1155Balance) / totalERC1155Balance;
                actualTotalRewardTokenAmount += rewardTokenAmountToHolder;

                _rewardsPending[holders[i]] += rewardTokenAmountToHolder;
                rewardTokenAmountToHolders[i] = rewardTokenAmountToHolder;
            }

            // adjust for rounding errors
            _rewardsPending[holders[0]] += (totalRewardTokenAmount -
                actualTotalRewardTokenAmount);
            rewardTokenAmountToHolders[0] -= (totalRewardTokenAmount -
                actualTotalRewardTokenAmount);
        }

        emit Tip(
            user,
            _idToAccount[nft][id],
            nft,
            id,
            amount,
            _rewardToken,
            rewardTokenAmountToHolders
        );
    }

    /// @notice Transfer `amount` of funds from `sender` to `recipient`
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        // Transfer the reward and burn the source tips and then recalculate the tips to mint to the recipient
        // to not affect the reward per tip amount

        uint256 senderRewardTokenBalance = _depositBalances[sender];
        uint256 senderTipTokenBalance = IERC20(address(this)).balanceOf(sender);

        uint256 rewardTokenTransferAmount = (senderRewardTokenBalance *
            amount) / senderTipTokenBalance;

        super._burn(sender, amount);

        uint256 recipientTipTokenBalance = IERC20(address(this)).balanceOf(
            recipient
        );
        uint256 recipientRewardTokenBalance = _depositBalances[recipient];

        if (recipientTipTokenBalance == 0) {
            super._mint(recipient, amount);
        } else {
            // Maintain reward per tip ratio for the recipient
            uint256 newAmount = (recipientTipTokenBalance *
                rewardTokenTransferAmount) / recipientRewardTokenBalance;

            super._mint(recipient, newAmount);
        }

        _depositBalances[sender] -= rewardTokenTransferAmount;
        _depositBalances[recipient] += rewardTokenTransferAmount;
    }

    /// @notice Returns true only if all 'holders' of 'nft' have approved TipToken contract as 'nft' operator
    function _erc1155IsApprovedForAll(address nft, address[] memory holders)
        private
        view
        returns (bool)
    {
        for (uint256 i = 0; i < holders.length; i++) {
            if (!IERC1155(nft).isApprovedForAll(holders[i], address(this)))
                return false;
        }

        return true;
    }
}
