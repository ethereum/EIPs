// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IERC20charity.sol";

/**
 *@title ERC720 charity Token
 *@author Aubay
 *@dev Extension of ERC720 Token that can be partially donated to a charity project
 *
 *This extensions keeps track of donations to charity addresses. The owner can chose the charity adresses listed.
 *Users can active the donation option or not and specify a different pourcentage than the default one donate.
 * A pourcentage af the amount of token transfered will be added and send to a charity address.
 */

abstract contract ERC20Charity is IERC20charity, ERC20, Ownable {
    mapping(address => uint256) public whitelistedRate; //Keep track of the rate for each charity address
    mapping(address => uint256) internal indexOfAddresses;
    mapping(address => mapping(address => uint256)) private _donation; //Keep track of the desired rate to donate for each user
    mapping(address => address) private _defaultAddress; //keep track of each user's default charity address

    address[] whitelistedAddresses; //Addresses whitelisted

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(IERC165) returns (bool) {
        return
            interfaceId == type(IERC20charity).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }

    /**
     *@dev The default rate of donation can be override
     */
    function _defaultRate() internal pure virtual returns (uint256) {
        return 10; // 0.1%
    }

    /**
     *@dev The denominator to interpret the rate of donation , defaults to 10000 so rate are expressed in basis points, but may be customized by an override.
     * base 10000 , so 10000 =100% , 0 = 0% ,   2000 =20%
     */
    function _feeDenominator() internal pure virtual returns (uint256) {
        return 10000;
    }

    /**
     *@notice Add address to whitelist and set rate to the default rate.
     * @dev Requirements:
     *
     * - `toAdd` cannot be the zero address.
     *
     * @param toAdd The address to whitelist.
     */
    function addToWhitelist(address toAdd) external virtual onlyOwner {
        if (indexOfAddresses[toAdd] == 0) {
            whitelistedRate[toAdd] = _defaultRate();
            whitelistedAddresses.push(toAdd);
            indexOfAddresses[toAdd] = whitelistedAddresses.length;
        }

        emit AddedToWhitelist(toAdd);
    }

    /**
     *@notice Remove the address from the whitelist and set rate to the default rate.
     * @dev Requirements:
     *
     * - `toRemove` cannot be the zero address.
     *
     * @param toRemove The address to remove from whitelist.
     */
    function deleteFromWhitelist(address toRemove) external virtual onlyOwner {
        uint256 index1 = indexOfAddresses[toRemove];
        require(index1 > 0, "Invalid index"); //Indexing starts at 1, 0 is not allowed
        // move the last item into the index being vacated
        address lastValue = whitelistedAddresses[
            whitelistedAddresses.length - 1
        ];
        whitelistedAddresses[index1 - 1] = lastValue; // adjust for 1-based indexing
        indexOfAddresses[lastValue] = index1;
        whitelistedAddresses.pop();
        indexOfAddresses[toRemove] = 0;

        delete whitelistedRate[toRemove]; //whitelistedRate[toRemove] =0;
        emit RemovedFromWhitelist(toRemove);
    }

    /// @notice Get all registered charity addresses
    /// @return List of all registered donations addresses
    function getAllWhitelistedAddresses() external view returns (address[] memory) {
        return whitelistedAddresses;
    }

    /// @notice Display for a user the rate of the default charity address that will receive donation.
    /// @return The default rate of the registered address for the user.
    function getRate() external view returns (uint256) {
        return _donation[msg.sender][_defaultAddress[msg.sender]];
    }

    /**
     *@notice Set for a user a default charity address that will receive donation.
     * The default rate specified in {whitelistedRate} will be applied.
     * @dev Requirements:
     *
     * - `whitelistedAddr` cannot be the zero address.
     *
     * @param whitelistedAddr The address to set as default.
     */
    function setSpecificDefaultAddress(
        address whitelistedAddr
    ) external virtual {
        require(
            whitelistedRate[whitelistedAddr] != 0,
            "ERC20Charity: invalid whitelisted rate"
        );
        _defaultAddress[msg.sender] = whitelistedAddr;
        _donation[msg.sender][whitelistedAddr] = whitelistedRate[
            whitelistedAddr
        ];
        emit DonnationAddressChanged(whitelistedAddr);
    }

    /**
     *@notice Set for a user a default charity address that will receive donation.
     * The rate is specified by the user.
     * @dev Requirements:
     *
     * - `whitelistedAddr` cannot be the zero address.
     * - `rate` cannot be inferior to the default rate
     * or to the rate specified by the owner of this contract in {whitelistedRate}.
     *
     * @param whitelistedAddr The address to set as default.
     * @param rate The personalised rate for donation.
     */
    function setSpecificDefaultAddressAndRate(
        address whitelistedAddr,
        uint256 rate
    ) external virtual {
        require(
            rate <= _feeDenominator(),
            "ERC20Charity: rate must be between 0 and _feeDenominator"
        );
        require(
            rate >= _defaultRate(),
            "ERC20Charity: rate fee must exceed default rate"
        );
        require(
            rate >= whitelistedRate[whitelistedAddr],
            "ERC20Charity: rate fee must exceed the fee set by the owner"
        );
        require(
            whitelistedRate[whitelistedAddr] != 0,
            "ERC20Charity: invalid whitelisted address"
        );
        _defaultAddress[msg.sender] = whitelistedAddr;
        _donation[msg.sender][whitelistedAddr] = rate;
        emit DonnationAddressAndRateChanged(whitelistedAddr, rate);
    }

    /**
     *@notice Set personlised rate for charity address in {whitelistedRate}.
     * @dev Requirements:
     *
     * - `whitelistedAddr` cannot be the zero address.
     * - `rate` cannot be inferior to the default rate.
     *
     * @param whitelistedAddr The address to set as default.
     * @param rate The personalised rate for donation.
     */
    function setSpecificRate(
        address whitelistedAddr,
        uint256 rate
    ) external virtual onlyOwner {
        require(
            rate <= _feeDenominator(),
            "ERC20Charity: rate must be between 0 and _feeDenominator"
        );
        require(
            rate >= _defaultRate(),
            "ERC20Charity: rate fee must exceed default rate"
        );
        require(
            whitelistedRate[whitelistedAddr] != 0,
            "ERC20Charity: invalid whitelisted address"
        );
        whitelistedRate[whitelistedAddr] = rate;
        emit ModifiedCharityRate(whitelistedAddr, rate);
    }

    /**
     *@notice Display for a user the default charity address that will receive donation.
     * The default rate specified in {whitelistedRate} will be applied.
     */
    function specificDefaultAddress() external view virtual returns (address) {
        return _defaultAddress[msg.sender];
    }

    /**
     * inherit IERC20charity
     */
    function charityInfo(
        address charityAddr
    ) external view virtual returns (bool, uint256 rate) {
        rate = whitelistedRate[charityAddr];
        if (rate != 0) {
            return (true, rate);
        } else {
            return (false, rate);
        }
    }

    /**
     *@notice Delete The Default Address and so deactivate donnations .
     */
    function deleteDefaultAddress() external virtual {
        _defaultAddress[msg.sender] = address(0);
        emit DonnationAddressChanged(address(0));
    }

    /**
     *@notice Return the rate to donate.
     * @dev Requirements:
     *
     * - `from` cannot be the zero address
     *
     * @param from The address to get rate of donation.
     */
    function _returnRate(address from) internal virtual returns (uint256 rate) {
        address whitelistedAddr = _defaultAddress[from];
        rate = _donation[from][whitelistedAddr];
        if (
            whitelistedRate[whitelistedAddr] == 0 ||
            _defaultAddress[from] == address(0)
        ) {
            rate = 0;
        }
        return rate;
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address owner = _msgSender();

        if (_defaultAddress[msg.sender] != address(0)) {
            address whitelistedAddr = _defaultAddress[msg.sender];
            uint256 rate = _returnRate(msg.sender);
            uint256 donate = (amount * rate) / _feeDenominator();
            _transfer(owner, whitelistedAddr, donate);
        }
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);

        if (_defaultAddress[from] != address(0)) {
            address whitelistedAddr = _defaultAddress[from];
            uint256 rate = _returnRate(from);
            uint256 donate = (amount * rate) / _feeDenominator();
            _spendAllowance(from, spender, donate);
            _transfer(from, whitelistedAddr, donate);
        }
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(
        address spender,
        uint256 amount
    ) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        if (_defaultAddress[msg.sender] != address(0)) {
            uint256 rate = _returnRate(msg.sender);
            uint256 donate = (amount * rate) / _feeDenominator();
            _approve(owner, spender, (donate + amount));
        }
        return true;
    }
}
