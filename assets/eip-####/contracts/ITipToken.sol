// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

interface ITipToken {
    /// @dev This emits when the tip token implementation approves the address
    /// of an NFT for tipping.
    /// The holders of the 'nft' are approved to receive rewards.
    /// When an NFT Transfer event emits, this also indicates that the approved
    /// addresses for that NFT (if any) is reset to none.
    event ApprovalForNFT(
        address[] holders,
        address indexed nft,
        uint256 indexed id,
        bool approved
    );

    /// @dev This emits when a user has deposited an ERC20 compatible token to
    /// the tip token's contract address or to an external address.
    /// This also indicates that the deposit has been exchanged for an
    /// amount of tip tokens
    event Deposit(
        address indexed user,
        address indexed rewardToken,
        uint256 amount,
        uint256 tipTokenAmount
    );

    /// @dev This emits when a holder withdraws an amount of ERC20 compatible
    /// reward. This reward comes from the tip token's contract address or from
    /// an external address, depending on the tip token implementation
    event Withdraw(
        address indexed holder,
        address indexed rewardToken,
        uint256 amount
    );

    /// @dev This emits when the tip token constructor or initialize method is
    /// executed. The 'rewardToken_' address is passed to the ERC20 constructor or
    /// initialize method.
    /// Importantly the ERC20 compatible token 'rewardToken_' to use as reward
    /// to NFT holders is set at this time and remains the same throughout the
    /// lifetime of the tip token contract.
    event InitializeTipToken(
        address indexed tipToken_,
        address indexed rewardToken_,
        address owner_
    );

    /// @dev This emits everytime a user tips an NFT holder.
    /// Also includes the reward token address and the reward token amount that
    /// will be held pending until the holder withdraws the reward tokens.
    event Tip(
        address indexed user,
        address[] holder,
        address indexed nft,
        uint256 id,
        uint256 amount,
        address rewardToken,
        uint256[] rewardTokenAmount
    );

    /// @notice Enable or disable approval for tipping for a single NFT held
    /// by a holder or a multi token shared by holders
    /// @dev MUST revert if calling nft's supportsInterface does not return
    /// true for either IERC721 or IERC1155.
    /// MUST revert if any of the 'holders' is the zero address.
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
    ) external;

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
    ) external returns (bool);

    /// @notice Sends tip from msg.sender to holder of a single NFT or
    /// to shared holders of a multi token
    /// @dev If 'nft' has not been approved for tipping, MUST revert
    /// MUST revert if 'nft' is zero address.
    /// MUST burn the tip 'amount' to the 'holder' and send the reward to
    /// an account pending for the holder(s).
    /// If 'nft' is a multi token that has multiple holders then each holder
    /// MUST receive tip amount in proportion of their balance of multi tokens
    /// MUST emit the 'Tip' event to reflect the amounts that msg.sender tipped
    /// to holder(s) of 'nft'.
    /// @param nft The NFT contract address
    /// @param id The NFT token id
    /// @param amount Amount of tip tokens to send to the holder of the NFT
    function tip(
        address nft,
        uint256 id,
        uint256 amount
    ) external;

    /// @notice Sends a batch of tips to holders of 'nfts' for gas efficiency
    /// @dev If NFT has not been approved for tipping, revert
    /// MUST revert if the input arguments lengths are not all the same
    /// MUST revert if any of the user addresses are zero
    /// MUST revert the whole batch if there are any errors
    /// MUST emit the 'Tip' events so that the state of the amounts sent to
    /// each holder and for which nft and from whom, can be reconstructed.
    /// @param users User accounts to tip from
    /// @param nfts The NFT contract addresses whose holders to tip to
    /// @param ids The NFT token ids that uniquely identifies the 'nfts'
    /// @param amounts Amount of tip tokens to send to the holders of the NFTs
    function tipBatch(
        address[] memory users,
        address[] memory nfts,
        uint256[] memory ids,
        uint256[] memory amounts
    ) external;

    /// @notice Deposit an ERC20 compatible token in exchange for tip tokens
    /// @dev The price of tip tokens can be different for each deposit as
    /// the amount of reward token sent ultimately is a ratio of the
    /// amount of tip tokens to tip over the user's tip tokens balance available
    /// multiplied by the user's deposit balance.
    /// The deposited tokens can be held in the tip tokens contract account or
    /// in an external escrow. This will depend on the tip token implementation.
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
    function deposit(address user, uint256 amount) external payable;

    /// @notice An NFT holder can withdraw their tips as an ERC20 compatible
    /// reward at a time of their choosing
    /// @dev MUST revert if not enough balance pending available to withdraw.
    /// MUST send 'amount' to msg.sender account (the holder)
    /// MUST reduce the balance of reward tokens pending by the 'amount' withdrawn.
    /// MUST emit the 'Withdraw' event to show the holder who withdrew, the reward
    /// token address and 'amount'
    /// @param amount Amount of ERC20 token to withdraw as a reward
    function withdraw(uint256 amount) external payable;

    /// @notice MUST have idential behaviour to ERC20 balanceOf and is the amount
    /// of tip tokens held by 'user'
    /// @param user The user account
    /// @return The balance of tip tokens held by user
    function balanceOf(address user) external view returns (uint256);

    /// @notice The balance of deposit available to become rewards when
    /// user sends the tips
    /// @param user The user account
    /// @return The remaining balance of the ERC20 compatible token deposited
    function balanceDepositOf(address user) external view returns (uint256);

    /// @notice The amount of reward token owed to 'holder'
    /// @dev The pending tokens can come from the tip token contract account
    /// or from an external escrow, depending on tip token implementation
    /// @param holder The holder of NFT(s) (NFT controller)
    /// @return The amount of reward tokens owed to the holder from tipping
    function rewardPendingOf(address holder) external view returns (uint256);
}
