// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.7.1;
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { ABDKMath64x64 } from "abdk-libraries-solidity/ABDKMath64x64.sol";
import { ERC1155WithTotals } from "./ERC1155/ERC1155WithTotals.sol";
import { ERC1155Holder } from "@openzeppelin/contracts/token/ERC1155/ERC1155Holder.sol";
import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import { ERC721Holder } from "@openzeppelin/contracts/token/ERC721/ERC721Holder.sol";

/// @title A base class to lock collaterals and distribute them proportional to an oracle result.
/// @author Victor Porton
/// @notice Not audited, not enough tested.
///
/// One can also donate/bequest a smart wallet (explain how).
///
/// We have two kinds of ERC-1155 token IDs:
/// - conditional tokens: numbers < 2**64
/// - a combination of a collateral contract address and collateral token ID
///   (a counter of donated amount of collateral tokens, don't confuse with collateral tokens themselves)
///
/// Inheriting from here don't forget to create `createOracle()` external method.
abstract contract BaseLock is
    ERC1155WithTotals,
    ERC1155Holder, // You are recommended to use `donate()` function instead.
    ERC721Holder // It can be used through an ERC-1155 wrapper.
{
    using ABDKMath64x64 for int128;
    using SafeMath for uint256;

    /// Emitted when an oracle is created.
    /// @param oracleId The ID of the created oracle.
    event OracleCreated(uint64 oracleId);

    /// Emitted when an oracle owner is set.
    /// @param oracleOwner Who created an oracle
    /// @param oracleId The ID of the oracle.
    event OracleOwnerChanged(address indexed oracleOwner, uint64 indexed oracleId);

    /// Emitted when an oracle owner is set.
    /// @param sender Who created the condition
    /// @param customer The owner of the condition.
    /// @param condition The created condition ID.
    event ConditionCreated(address indexed sender, address indexed customer, uint256 indexed condition);

    /// Emitted when a collateral is donated.
    /// @param collateralContractAddress The ERC-1155 contract of the donated token.
    /// @param collateralTokenId The ERC-1155 ID of the donated token.
    /// @param sender Who donated.
    /// @param amount The amount donated.
    /// @param to Whose account the donation is assigned to.
    /// @param data Additional transaction data.
    event DonateCollateral(
        IERC1155 indexed collateralContractAddress,
        uint256 indexed collateralTokenId,
        address indexed sender,
        uint256 amount,
        address to,
        bytes data
    );

    /// Emitted when an oracle is marked as having finished its work.
    /// @param oracleId The oracle ID.
    event OracleFinished(uint64 indexed oracleId);

    /// Emitted when collateral is withdrawn.
    /// @param contractAddress The ERC-1155 contract of the collateral token.
    /// @param collateralTokenId The ERC-1155 token ID of the collateral.
    /// @param oracleId The oracle ID for which withdrawal is done.
    /// @param user Who has withdrawn.
    /// @param amount The amount withdrawn.
    event CollateralWithdrawn(
        IERC1155 indexed contractAddress,
        uint256 indexed collateralTokenId,
        uint64 indexed oracleId,
        address user,
        uint256 amount
    );

    // Next ID.
    uint64 public maxOracleId; // It doesn't really need to be public.
    uint64 public maxConditionId; // It doesn't really need to be public.

    // Mapping (oracleId => oracle owner).
    mapping(uint64 => address) private oracleOwnersMap;
    // Mapping (oracleId => time) the max time for first withdrawal.
    mapping(uint64 => uint) private gracePeriodEnds;
    // The user lost the right to transfer conditional tokens: (user => (conditionalToken => bool)).
    mapping(address => mapping(uint256 => bool)) private userUsedRedeemMap;
    // Mapping (token => (original user => amount)) used to calculate withdrawal of collateral amounts.
    mapping(uint256 => mapping(address => uint256)) public lastCollateralBalanceFirstRoundMap;
    // Mapping (token => (original user => amount)) used to calculate withdrawal of collateral amounts.
    mapping(uint256 => mapping(address => uint256)) public lastCollateralBalanceSecondRoundMap;
    /// Mapping (oracleId => amount user withdrew in first round) (see `docs/Calculations.md`).
    mapping(uint64 => uint256) public usersWithdrewInFirstRound;

    // Mapping (condition ID => original account)
    mapping(uint256 => address) public conditionOwners;

    /// Constructor.
    /// @param _uri Our ERC-1155 tokens description URI.
    constructor(string memory _uri) ERC1155WithTotals(_uri) {
        _registerInterface(
            BaseLock(0).onERC1155Received.selector ^
            BaseLock(0).onERC1155BatchReceived.selector ^
            BaseLock(0).onERC721Received.selector
        );
    }

    /// This function makes no sense, because it would produce a condition with zero tokens.
    // function createCondition() public returns (uint64) {
    //     return _createCondition();
    // }

    /// Modify the owner of an oracle.
    /// @param _newOracleOwner New owner.
    /// @param _oracleId The oracle whose owner to change.
    function changeOracleOwner(address _newOracleOwner, uint64 _oracleId) public _isOracle(_oracleId) {
        oracleOwnersMap[_oracleId] = _newOracleOwner;
        emit OracleOwnerChanged(_newOracleOwner, _oracleId);
    }

    /// Set the end time of the grace period.
    ///
    /// The first withdrawal can be done *only* during the grace period.
    /// The second withdrawal can be done after the end of the grace period and only if the first withdrawal was done.
    ///
    /// The intention of the grace period is to check which of users are active ("alive").
    function updateGracePeriodEnds(uint64 _oracleId, uint _time) public _isOracle(_oracleId) {
        gracePeriodEnds[_oracleId] = _time;
    }

    /// Donate funds in an ERC-1155 token.
    ///
    /// First, the collateral token need to be approved to be spent by this contract from the address `_from`.
    ///
    /// It also mints a token (with a different ID), that counts donations in that token.
    ///
    /// @param _collateralContractAddress The collateral ERC-1155 contract address.
    /// @param _collateralTokenId The collateral ERC-1155 token ID.
    /// @param _oracleId The oracle ID to whose ecosystem to donate to.
    /// @param _amount The amount to donate.
    /// @param _from From whom to take the donation.
    /// @param _to On whose account the donation amount is assigned.
    /// @param _data Additional transaction data.
    function donate(
        IERC1155 _collateralContractAddress,
        uint256 _collateralTokenId,
        uint64 _oracleId,
        uint256 _amount,
        address _from,
        address _to,
        bytes calldata _data) public
    {
        uint _donatedPerOracleCollateralTokenId = _collateralDonatedPerOracleTokenId(_collateralContractAddress, _collateralTokenId, _oracleId);
        _mint(_to, _donatedPerOracleCollateralTokenId, _amount, _data);
        uint _donatedCollateralTokenId = _collateralDonatedTokenId(_collateralContractAddress, _collateralTokenId);
        _mint(_to, _donatedCollateralTokenId, _amount, _data);
        emit DonateCollateral(_collateralContractAddress, _collateralTokenId, _from, _amount, _to, _data);
        _collateralContractAddress.safeTransferFrom(_from, address(this), _collateralTokenId, _amount, _data); // last against reentrancy attack
    }

    /// Gather a DeFi profit of a token previous donated to this contract.
    /// @param _collateralContractAddress The collateral ERC-1155 contract address.
    /// @param _collateralTokenId The collateral ERC-1155 token ID.
    /// @param _oracleId The oracle ID to whose ecosystem to donate to.
    /// @param _data Additional transaction data.
    /// TODO: Batch calls in several tokens and/or to several oracles for less gas usage?
    function gatherDeFiProfit(
        IERC1155 _collateralContractAddress,
        uint256 _collateralTokenId,
        uint64 _oracleId,
        bytes calldata _data) external
    {
        uint _donatedPerOracleCollateralTokenId = _collateralDonatedPerOracleTokenId(_collateralContractAddress, _collateralTokenId, _oracleId);
        uint _donatedCollateralTokenId = _collateralDonatedTokenId(_collateralContractAddress, _collateralTokenId);

        // We consider an overflow an error and just revert:
        // FIXME: Impossible due to reentrancy vulnerability? (Really? It's a view!)
        uint256 _difference =
            _collateralContractAddress.balanceOf(address(this), _collateralTokenId).sub(
                balanceOf(address(this), _donatedCollateralTokenId));
        uint256 _amount = // rounding down to prevent overflows
            _difference *
            balanceOf(address(this), _donatedPerOracleCollateralTokenId) /
            balanceOf(address(this), _donatedCollateralTokenId);

        // Last to avoid reentrancy vulnerability.
        donate(
            _collateralContractAddress,
            _collateralTokenId,
            _oracleId,
            _amount,
            address(this),
            address(this),
            _data);
    }

    /// Calculate how much collateral is owed to a user.
    /// @param _collateralContractAddress The ERC-1155 collateral token contract.
    /// @param _collateralTokenId The ERC-1155 collateral token ID.
    /// @param _oracleId From which oracle's "account" to withdraw.
    /// @param _condition The condition (the original receiver of a conditional token).
    /// @param _user The user to which we may owe.
    function collateralOwing(
        IERC1155 _collateralContractAddress,
        uint256 _collateralTokenId,
        uint64 _oracleId,
        uint256 _condition,
        address _user
    ) external view returns(uint256) {
        bool _inFirstRound = _isInFirstRound(_oracleId);
        (, uint256 _donated) =
            _collateralOwingBase(_collateralContractAddress, _collateralTokenId, _oracleId, _condition, _user, _inFirstRound);
        return _donated;
    }

    /// Transfer to `msg.sender` the collateral ERC-1155 token.
    ///
    /// The amount transferred is proportional to the score of `_condition` by the oracle.
    /// @param _collateralContractAddress The ERC-1155 collateral token contract.
    /// @param _collateralTokenId The ERC-1155 collateral token ID.
    /// @param _oracleId From which oracle's "account" to withdraw.
    /// @param _condition The condition.
    /// @param _data Additional data.
    ///
    /// Notes:
    /// - It is made impossible to withdraw somebody's other collateral, as otherwise we can't mark non-active
    ///   accounts in grace period.
    /// - We can't transfer to somebody other than `msg.sender` because anybody can transfer
    ///   (needed for multi-level transfers).
    /// - After this function is called, it becomes impossible to transfer the corresponding conditional token
    ///   of `msg.sender` (to prevent its repeated withdrawal).
    function withdrawCollateral(
        IERC1155 _collateralContractAddress,
        uint256 _collateralTokenId,
        uint64 _oracleId,
        uint256 _condition,
        bytes calldata _data) external
    {
        require(isOracleFinished(_oracleId), "too early"); // to prevent the denominator or the numerators change meantime
        bool _inFirstRound = _isInFirstRound(_oracleId);
        userUsedRedeemMap[msg.sender][_condition] = true;
        // _burn(msg.sender, _condition, conditionalBalance); // Burning it would break using the same token for multiple markets.
        (uint _donatedPerOracleCollateralTokenId, uint256 _owingDonated) =
            _collateralOwingBase(_collateralContractAddress, _collateralTokenId, _oracleId, _condition, msg.sender, _inFirstRound);

        // Against rounding errors. Not necessary because of rounding down.
        // if(_owing > balanceOf(address(this), _collateralTokenId)) _owing = balanceOf(address(this), _collateralTokenId);

        if (_owingDonated != 0) {
            uint256 _newTotal = totalSupply(_donatedPerOracleCollateralTokenId);
            if (_inFirstRound) {
                lastCollateralBalanceFirstRoundMap[_donatedPerOracleCollateralTokenId][msg.sender] = _newTotal;
            } else {
                lastCollateralBalanceSecondRoundMap[_donatedPerOracleCollateralTokenId][msg.sender] = _newTotal;
            }
        }
        if (!_inFirstRound) {
            usersWithdrewInFirstRound[_oracleId] = usersWithdrewInFirstRound[_oracleId].add(_owingDonated);
        }
        // Last to prevent reentrancy attack:
        _collateralContractAddress.safeTransferFrom(address(this), msg.sender, _collateralTokenId, _owingDonated, _data);
        emit CollateralWithdrawn(
            _collateralContractAddress,
            _collateralTokenId,
            _oracleId,
            msg.sender,
            _owingDonated
        );
    }

    /// An ERC-1155 function.
    ///
    /// We disallow transfers of conditional tokens after redeem `_to` prevent "gathering" them before redeeming
    /// each oracle.
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _value,
        bytes calldata _data
    )
        public override
    {
        _checkTransferAllowed(_id, _from);
        _baseSafeTransferFrom(_from, _to, _id, _value, _data);
    }

    /// An ERC-1155 function.
    ///
    /// We disallow transfers of conditional tokens after redeem `_to` prevent "gathering" them before redeeming
    /// each oracle.
    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata _data
    )
        public override
    {
        for(uint _i = 0; _i < _ids.length; ++_i) {
            _checkTransferAllowed(_ids[_i], _from);
        }
        _baseSafeBatchTransferFrom(_from, _to, _ids, _values, _data);
    }

    // Getters //

    /// Get the oracle owner.
    /// @param _oracleId The oracle ID.
    function oracleOwner(uint64 _oracleId) public view returns (address) {
        return oracleOwnersMap[_oracleId];
    }

    /// Is the oracle marked as having finished its work?
    ///
    /// `oracleId` is the oracle ID.
    function isOracleFinished(uint64 /*oracleId*/) public virtual view returns (bool) {
        return true;
    }

    /// Are transfers of a conditinal token locked?
    ///
    /// This is used to prevent its repeated withdrawal.
    /// @param _user Querying if locked for this user.
    /// @param _condition The condition (the original receiver of a conditional token).
    function isConditionalLocked(address _user, uint256 _condition) public view returns (bool) {
        return userUsedRedeemMap[_user][_condition];
    }

    /// Retrieve the end of the grace period.
    /// @param _oracleId For which oracle.
    function gracePeriodEnd(uint64 _oracleId) public view returns (uint) {
        return gracePeriodEnds[_oracleId];
    }

    // Virtual functions //

    /// Current address of a user.
    /// @param _originalAddress The original address of the user.
    function originalToCurrentAddress(address _originalAddress) internal virtual returns (address) {
        return _originalAddress;
    }

    /// Mint a conditional to a customer.
    function _mintToCustomer(address _customer, uint256 _condition, uint256 _amount, bytes calldata _data)
        internal virtual
    {
        require(conditionOwners[_condition] == _customer, "Other's salary get attempt.");
        _mint(originalToCurrentAddress(_customer), _condition, _amount, _data);
    }

    /// Calculate the share of a condition in an oracle's market.
    /// @param _oracleId The oracle ID.
    /// @return Uses `ABDKMath64x64` number ID.
    function _calcRewardShare(uint64 _oracleId, uint256 _condition) internal virtual view returns (int128);

    function _calcMultiplier(uint64 _oracleId, uint256 _condition, int128 _oracleShare) internal virtual view returns (int128) {
        int128 _rewardShare = _calcRewardShare(_oracleId, _condition);
        return _oracleShare.mul(_rewardShare);
    }

    function _doTransfer(uint256 _id, address _from, address _to, uint256 _value) internal virtual {
        _balances[_id][_from] = _balances[_id][_from].sub(_value);
        _balances[_id][_to] = _value.add(_balances[_id][_to]);
    }

    // Internal //

    /// Generate the ERC-1155 token ID that counts amount of donations per oracle for a ERC-1155 collateral token.
    /// @param _collateralContractAddress The ERC-1155 contract of the collateral token.
    /// @param _collateralTokenId The ERC-1155 ID of the collateral token.
    /// @param _oracleId The oracle ID.
    /// Note: It does not conflict with other tokens kinds, because the only other one is the uint64 conditional.
    function _collateralDonatedPerOracleTokenId(IERC1155 _collateralContractAddress, uint256 _collateralTokenId, uint64 _oracleId)
        internal pure returns (uint256)
    {
        return uint256(keccak256(abi.encodePacked(_collateralContractAddress, _collateralTokenId, _oracleId)));
    }

    /// Generate the ERC-1155 token ID that counts amount of donations for a ERC-1155 collateral token.
    /// @param _collateralContractAddress The ERC-1155 contract of the collateral token.
    /// @param _collateralTokenId The ERC-1155 ID of the collateral token.
    /// Note: It does not conflict with other tokens kinds, because the only other one is the uint64 conditional.
    function _collateralDonatedTokenId(IERC1155 _collateralContractAddress, uint256 _collateralTokenId)
        internal pure returns (uint256)
    {
        return uint256(keccak256(abi.encodePacked(_collateralContractAddress, _collateralTokenId)));
    }

    function _checkTransferAllowed(uint256 _id, address _from) internal view {
        require(!userUsedRedeemMap[_from][_id], "You can't trade conditional tokens after redeem.");
    }

    function _baseSafeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes memory _data) private {
        require(_to != address(0), "ERC1155: target address must be non-zero");
        require(
            _from == msg.sender || _operatorApprovals[_from][msg.sender] == true,
            "ERC1155: need operator approval for 3rd party transfers."
        );

        _doTransfer(_id, _from, _to, _value);

        emit TransferSingle(msg.sender, _from, _to, _id, _value);

        _doSafeTransferAcceptanceCheck(msg.sender, _from, _to, _id, _value, _data);
    }

    function _baseSafeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] memory _ids,
        uint256[] memory _values,
        bytes memory _data
    )
        private
    {
        require(_ids.length == _values.length, "ERC1155: IDs and _values must have same lengths");
        require(_to != address(0), "ERC1155: target address must be non-zero");
        require(
            _from == msg.sender || _operatorApprovals[_from][msg.sender] == true,
            "ERC1155: need operator approval for 3rd party transfers."
        );

        for (uint256 _i = 0; _i < _ids.length; ++_i) {
            uint256 _id = _ids[_i];
            uint256 _value = _values[_i];

            _doTransfer(_id, _from, _to, _value);
        }

        emit TransferBatch(msg.sender, _from, _to, _ids, _values);

        _doSafeBatchTransferAcceptanceCheck(msg.sender, _from, _to, _ids, _values, _data);
    }

    function _createOracle() internal returns (uint64) {
        uint64 _oracleId = ++maxOracleId;
        oracleOwnersMap[_oracleId] = msg.sender;
        emit OracleCreated(_oracleId);
        emit OracleOwnerChanged(msg.sender, _oracleId);
        return _oracleId;
    }

    /// Start with 1, not 0, to avoid glitch with `conditionalTokens` variable.
    ///
    /// TODO: Use uint64 variables instead?
    function _createCondition(address _customer) internal returns (uint256) {
        return _doCreateCondition(_customer);
    }

    /// Start with 1, not 0, to avoid glitch with `conditionalTokens` variable.
    ///
    /// TODO: Use uint64 variables instead?
    function _doCreateCondition(address _customer) internal virtual returns (uint256) {
        uint64 _condition = ++maxConditionId;

        conditionOwners[_condition] = _customer;

        emit ConditionCreated(msg.sender, _customer, _condition);

        return _condition;
    }

    function _collateralOwingBase(
        IERC1155 _collateralContractAddress,
        uint256 _collateralTokenId,
        uint64 _oracleId,
        uint256 _condition,
        address _user,
        bool _inFirstRound
    )
        private view returns (uint _donatedPerOracleCollateralTokenId, uint256 _donated)
    {
        uint256 _conditionalBalance = balanceOf(_user, _condition);
        uint256 _totalConditionalBalance =
            _inFirstRound ? totalSupply(_condition) : usersWithdrewInFirstRound[_oracleId];
        _donatedPerOracleCollateralTokenId = _collateralDonatedPerOracleTokenId(_collateralContractAddress, _collateralTokenId, _oracleId);
        // Rounded to below for no out-of-funds:
        int128 _oracleShare = ABDKMath64x64.divu(_conditionalBalance, _totalConditionalBalance);
        uint256 _newDividendsDonated =
            totalSupply(_donatedPerOracleCollateralTokenId) -
            (_inFirstRound
                ? lastCollateralBalanceFirstRoundMap[_donatedPerOracleCollateralTokenId][_user] 
                : lastCollateralBalanceSecondRoundMap[_donatedPerOracleCollateralTokenId][_user]);
        int128 _multiplier = _calcMultiplier(_oracleId, _condition, _oracleShare);
        _donated = _multiplier.mulu(_newDividendsDonated);
    }

    function _isInFirstRound(uint64 _oracleId) internal view returns (bool) {
        return block.timestamp <= gracePeriodEnds[_oracleId];
    }

    function _isConditional(uint256 _tokenId) internal pure returns (bool) {
        // Zero 2**-192 probability that tokenId < (1<<64) if it's not a conditional.
        // Note to auditor: It's a hack, check for no errors carefully.
        return _tokenId < (1<<64);
    }

    modifier _isOracle(uint64 _oracleId) {
        require(oracleOwnersMap[_oracleId] == msg.sender, "Not the oracle owner.");
        _;
    }

    modifier checkIsConditional(uint256 _tokenId) {
        require(_isConditional(_tokenId), "It's not your conditional.");
        _;
    }
}
