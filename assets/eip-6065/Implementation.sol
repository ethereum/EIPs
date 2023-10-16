// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/*
NOTE: WORK IN PROGRESS, NOT READY FOR PRODUCTION

This is a sample interface contract by Klasma Labs Inc. for demonstration purposes for EIP-6065. The technical implementation includes the 
following additional components for reference, this implementation is not required.

Summary of Klasma Inc. ERC-6065 implementation: 
-- NFT burn and mint function
-- Immutable NFT data (unique identifiers and operating agreement hash)
-- Debt tracking by Administrator
-- Blocklist function to freeze asset held by fraudulent addresses (NOTE: to be implemented in the future)
-- Foreclosure logic initiated by Administrator
-- managerOf function implementation 
*/

import "solmate/tokens/ERC721.sol";
import "forge-std/interfaces/IERC20.sol";
import "forge-std/interfaces/IERC165.sol";
import "openzeppelin-contracts/utils/Strings.sol";

contract ERC6065 is ERC721 {
	using Strings for uint256;

	address public ADMINISTRATOR;
	uint256 public COUNTER;
	string public URIBASE;

	struct EIP6065Immutable {
		string legal_description_of_property;
		string street_address;
		string geo_json;
		string parcel_id;
		string legal_owner;
		bytes32 operating_agreement_hash;
	}

	struct EIP6065Mutable {
		address debt_token;
		int256 debt_amt;
		bool foreclosed;
	}

	mapping (uint256 => EIP6065Immutable) EIP6065ImmutableMetadata;
	mapping (uint256 => EIP6065Mutable) EIP6065MutableMetadata;

	event DebtTokenChanged(uint256 id, address newToken);
	event DebtBalanceChanged(uint256 id, int256 changedBy, int256 newAmt);
	event DebtPaid(uint256 id, uint256 paidAmt, int256 remainingAmt);
	event CreditClaimed(uint256 id, uint256 claimedAmt);
	event Foreclosed(uint256 id);

	constructor(string memory _name, string memory _symbol, string memory _uriBase) ERC721(_name, _symbol) {
		ADMINISTRATOR = msg.sender;
		URIBASE = _uriBase;
	}

	modifier onlyAdmin() {
		require(msg.sender == ADMINISTRATOR, "NOT_ADMIN");
		_;
	}

	modifier tokenExists(uint256 _id) {
		require(ownerOf(_id) != address(0), "NOT_MINTED");
		_;
	}

	///// SETTERS /////

	function setAdmin(address _new) external onlyAdmin {
		ADMINISTRATOR = _new;
	}

	function setUriBase(string calldata _new) external onlyAdmin {
		URIBASE = _new;
	}

	///// GETTERS /////

	function tokenURI(uint256 _id) public view override tokenExists(_id) returns (string memory){
		return string(abi.encodePacked(URIBASE, _id.toString()));
	}

	function legalDescriptionOf(uint256 _id) external view tokenExists(_id) returns (string memory){
		return EIP6065ImmutableMetadata[_id].legal_description_of_property;
	}

	function addressOf(uint256 _id) external view tokenExists(_id) returns (string memory){
		return EIP6065ImmutableMetadata[_id].street_address;
	}

	function geoJsonOf(uint256 _id) external view tokenExists(_id) returns (string memory){
		return EIP6065ImmutableMetadata[_id].geo_json;
	}

	function parcelIdOf(uint256 _id) external view tokenExists(_id) returns (string memory){
		return EIP6065ImmutableMetadata[_id].parcel_id;
	}

	function legalOwnerOf(uint256 _id) external view tokenExists(_id) returns (string memory){
		return EIP6065ImmutableMetadata[_id].legal_owner;
	}

	function operatingAgreementHashOf(uint256 _id) external view tokenExists(_id) returns (bytes32){
		return EIP6065ImmutableMetadata[_id].operating_agreement_hash;
	}

	function debtOf(uint256 _id) external view tokenExists(_id) returns (address, int256, bool){
		EIP6065Mutable memory _data = EIP6065MutableMetadata[_id];
		return (_data.debt_token, _data.debt_amt, _data.foreclosed);
	}

	// EIP6065 get manager of the NFT. Smart contracts can optionally implement managerOf() to chain this call to some underlying contract or EOA
	// Otherwise, default to the ownerOf(NFT) being managerOf(NFT)
	function managerOf(uint256 _id) external view returns (address){ // note: modifier removed, implement in code for efficiency tokenExists(_id)
		address _owner = ownerOf(_id);
		require(_owner != address(0), "NOT_MINTED");

		uint256 _codeSize;
        assembly {
            _codeSize := extcodesize(_owner)
        }
        if (_codeSize == 0){
        	return _owner;
        }
        else {
        	try IERC165(_owner).supportsInterface(0x01ffc9a7) returns (bool _check1) { // 0x01ffc9a7 is EIP165 interface
        		if (_check1){
        			try IERC165(_owner).supportsInterface(0xffffffff) returns (bool _check2){ // 0xffffffff is required false check, see: https://eips.ethereum.org/EIPS/eip-165
        				if (!_check2){
        					bool _check3 = IERC165(_owner).supportsInterface(0x9325945c); // 0x9325945c is bytes4(keccak256(bytes("managerOf(address,uint256)"))) ie: IManager interface
			        		if (_check3){
			        			return IManager(_owner).managerOf(address(this), _id); // chain managerOf(nftContract, id) call if smart contract supports this interface
			        		} else {
			        			return _owner;
			        		}
        				} else {
        					return _owner;
        				}
        			} catch {
			        	return _owner;
        			}
        		} else {
        			return _owner;
        		}
        	} catch {
        		return _owner;
        	}	
        }
	}

	///// MANAGEMENT OF NFT STATE / MUTABLE VARS /////

	// change debt token, requires no existing debt or credit on the token
	function changeDebtToken(uint256 _id, address _new) public onlyAdmin tokenExists(_id) {
		require(EIP6065MutableMetadata[_id].debt_amt == 0, "DEBT_AMT_NOT_ZERO");
		EIP6065MutableMetadata[_id].debt_token = _new;
		emit DebtTokenChanged(_id, _new);
	}

	function balanceChange(uint256 _id, int256 _amt) public onlyAdmin tokenExists(_id) {
		require(_amt != 0, "NO_AMT");
		EIP6065Mutable memory _data = EIP6065MutableMetadata[_id];
		int256 _oldAmt = _data.debt_amt;
		_data.debt_amt += _amt;

		if (_amt > 0){ // debt added to token
			if (_oldAmt < 0){
				if (_data.debt_amt < 0){
					IERC20(_data.debt_token).transfer(ADMINISTRATOR, uint256(_amt)); // return entire _amt as it's all prior credit 
				}
				else {
					IERC20(_data.debt_token).transfer(ADMINISTRATOR, uint256(-1 * _oldAmt)); // return _oldAmt, as this credit has been zeroed, and debt added
				}
			}
		}
		else { // (_amt < 0) ie: credit added to token
			if (_data.debt_amt < 0){
				if (_oldAmt < 0){
					IERC20(_data.debt_token).transferFrom(ADMINISTRATOR, address(this), uint256(-1 * _amt)); // admin owes entire amt as credit
				}
				else {
					IERC20(_data.debt_token).transferFrom(ADMINISTRATOR, address(this), uint256(-1 * _data.debt_amt));
				}
			}
		}

		EIP6065MutableMetadata[_id].debt_amt = _data.debt_amt;
		emit DebtBalanceChanged(_id, _amt, _data.debt_amt);
	}

	function payDebt(uint256 _id, uint256 _amt) public tokenExists(_id) {
		EIP6065Mutable memory _data = EIP6065MutableMetadata[_id];
		require(_data.debt_amt > 0, "NO_DEBT");
		require(!_data.foreclosed, "FORECLOSED");
		if (_amt > uint256(_data.debt_amt)) _amt = uint256(_data.debt_amt);

		IERC20(_data.debt_token).transferFrom(msg.sender, ADMINISTRATOR, _amt);

		_data.debt_amt -= int256(_amt);

		EIP6065MutableMetadata[_id].debt_amt = _data.debt_amt;
		emit DebtPaid(_id, _amt, _data.debt_amt);
	}

	function claimCredit(uint256 _id) public {
		require(msg.sender == ownerOf(_id), "NOT_OWNER");

		EIP6065Mutable memory _data = EIP6065MutableMetadata[_id];
		require(_data.debt_amt < 0, "NO_CREDIT");

		EIP6065MutableMetadata[_id].debt_amt = 0;
		uint256 _transferAmt = uint256(-1 * _data.debt_amt);
		IERC20(_data.debt_token).transfer(msg.sender, _transferAmt);
		emit CreditClaimed(_id, _transferAmt);
	}

	function foreclose(uint256 _id) public onlyAdmin tokenExists(_id) {
		require(!EIP6065MutableMetadata[_id].foreclosed, "FORECLOSED");
		EIP6065MutableMetadata[_id].foreclosed = true;
		emit Foreclosed(_id);
	}

	///// MINT & BURN LOGIC /////

	function mint(address _to, EIP6065Immutable calldata _immutableData, EIP6065Mutable calldata _mutableData) public onlyAdmin {
		uint256 _counter = COUNTER;
		_mint(_to, _counter);

		EIP6065ImmutableMetadata[_counter] = _immutableData;
		EIP6065MutableMetadata[_counter] = _mutableData;

		// not reasonable to overflow
		unchecked {
			COUNTER = _counter + 1;
		}
	}

	function burn(uint256 _id) public onlyAdmin {
		require(ownerOf(_id) == ADMINISTRATOR, "ADMIN_NOT_OWNER");

		// recommend to clear data and info about NFT here too
		delete EIP6065ImmutableMetadata[_id];
		delete EIP6065MutableMetadata[_id];

		_burn(_id);
	}
}

// simple manager interface to chain calls of the initial managerOf() function call
interface IManager is IERC165 {
	function managerOf(address _nftContract, uint256 _id) external view returns (address);
}