// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC20.sol";
import "./libraries/OmniverseProtocolHelper.sol";
import "./interfaces/IERC6358Fungible.sol";

/**
* @notice Fungible token data structure, from which the field `payload` in `ERC6358TransactionData` will be encoded
*
* @member op: The operation type
* NOTE op: 0-31 are reserved values, 32-255 are custom values
*           op: 0 - omniverse account `from` transfers `amount` tokens to omniverse account `exData`, `from` have at least `amount` tokens
*           op: 1 - omniverse account `from` mints `amount` tokens to omniverse account `exData`
*           op: 2 - omniverse account `from` burns `amount` tokens from his own, `from` have at least `amount` tokens
* @member exData: The operation data. This sector could be empty and is determined by `op`. For example: 
            when `op` is 0 and 1, `exData` stores the omniverse account that receives.
            when `op` is 2, `exData` is empty.
* @member amount: The amount of tokens being operated
 */
struct Fungible {
    uint8 op;
    bytes exData;
    uint256 amount;
}

/**
 * @notice Implementation of the {IERC6358Fungible} interface
 */
contract ERC6358FungibleExample is ERC20, Ownable, IERC6358Fungible {
    uint8 constant TRANSFER = 0;
    uint8 constant MINT = 1;
    uint8 constant BURN = 2;

    /** @notice Used to index a delayed transaction
     * sender: The account which sent the transaction
     * nonce: The nonce of the delayed transaction
     */
    struct DelayedTx {
        bytes sender;
        uint256 nonce;
    }

    /**
     * @notice The member information
     * chainId: The chain which the member belongs to
     * contractAddr: The contract address on the member chain
     */
    struct Member {
        uint32 chainId;
        bytes contractAddr;
    }

    // Chain id used to distinguish different chains
    uint32 chainId;
    // O-transaction cooling down time
    uint256 public cdTime;
    // Omniverse accounts record
    mapping(bytes => RecordedCertificate) transactionRecorder;
    // Transactions to be executed
    mapping(bytes => OmniverseTx) public transactionCache;

    // All information of chains on which the token is deployed
    Member[] members;
    // Omniverse balances
    mapping(bytes => uint256) omniverseBalances;
    // Delay-executing transactions
    DelayedTx[] delayedTxs;
    // Account map from evm address to public key
    mapping(address => bytes) accountsMap;

    event OmniverseTokenTransfer(bytes from, bytes to, uint256 value);

    /**
     * @notice Initiates the contract
     * @param _chainId The chain which the contract is deployed on
     * @param _name The name of the token
     * @param _symbol The symbol of the token
     */
    constructor(uint32 _chainId, string memory _name, string memory _symbol) ERC20(_name, _symbol) {
        chainId = _chainId;
    }

    /**
     * @notice See {IERC6358Fungible-sendOmniverseTransaction}
     * Send an omniverse transaction
     */
    function sendOmniverseTransaction(ERC6358TransactionData calldata _data) external override {
        _omniverseTransaction(_data);
    }

    /**
     * @notice See {IERC6358Fungible-triggerExecution}
     */
    function triggerExecution() external {
        require(delayedTxs.length > 0, "No delayed tx");

        OmniverseTx storage cache = transactionCache[delayedTxs[0].sender];
        require(cache.timestamp != 0, "Not cached");
        require(cache.txData.nonce == delayedTxs[0].nonce, "Nonce error");
        (ERC6358TransactionData storage txData, uint256 timestamp) = (cache.txData, cache.timestamp);
        require(block.timestamp >= timestamp + cdTime, "Not executable");
        delayedTxs[0] = delayedTxs[delayedTxs.length - 1];
        delayedTxs.pop();
        cache.timestamp = 0;
        // Add to transaction recorder
        RecordedCertificate storage rc = transactionRecorder[txData.from];
        rc.txList.push(cache);

        Fungible memory fungible = decodeData(txData.payload);
        if (fungible.op == TRANSFER) {
            _omniverseTransfer(txData.from, fungible.exData, fungible.amount);
        }
        else if (fungible.op == MINT) {
            _checkOwner(txData.from);
            _omniverseMint(fungible.exData, fungible.amount);
        }
        else if (fungible.op == BURN) {
            _checkOwner(txData.from);
            _checkOmniverseBurn(fungible.exData, fungible.amount);
            _omniverseBurn(fungible.exData, fungible.amount);
        }
        emit TransactionExecuted(txData.from, txData.nonce);
    }
    
    /**
     * @notice Check if the transaction can be executed successfully
     */
    function _checkExecution(ERC6358TransactionData memory txData) internal view {
        Fungible memory fungible = decodeData(txData.payload);
        if (fungible.op == TRANSFER) {
            _checkOmniverseTransfer(txData.from, fungible.amount);
        }
        else if (fungible.op == MINT) {
            _checkOwner(txData.from);
        }
        else if (fungible.op == BURN) {
            _checkOwner(txData.from);
            _checkOmniverseBurn(fungible.exData, fungible.amount);
        }
        else {
            revert("OP code error");
        }
    }

    /**
     * @notice Returns the nearest exexutable delayed transaction info
     * or returns default if not found
     */
    function getExecutableDelayedTx() external view returns (DelayedTx memory ret) {
        if (delayedTxs.length > 0) {
            OmniverseTx storage cache = transactionCache[delayedTxs[0].sender];
            if (block.timestamp >= cache.timestamp + cdTime) {
                ret = delayedTxs[0];
            }
        }
    }

    /**
     * @notice Returns the count of delayed transactions
     */
    function getDelayedTxCount() external view returns (uint256) {
        return delayedTxs.length;
    }

    /**
     * @notice See {IERC6358Fungible-omniverseBalanceOf}
     * Returns the omniverse balance of a user
     */
    function omniverseBalanceOf(bytes calldata _pk) external view override returns (uint256) {
        return omniverseBalances[_pk];
    }

    /**
     * @notice See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        bytes storage pk = accountsMap[account];
        if (pk.length == 0) {
            return 0;
        }
        else {
            return omniverseBalances[pk];
        }
    }

    /**
     * @notice Receive and check an omniverse transaction
     */
    function _omniverseTransaction(ERC6358TransactionData memory _data) internal {
        // Check if the tx initiateSC is correct
        bool found = false;
        for (uint256 i = 0; i < members.length; i++) {
            if (members[i].chainId == _data.chainId) {
                require(keccak256(members[i].contractAddr) == keccak256(_data.initiateSC), "Wrong initiateSC");
                found = true;
            }
        }
        require(found, "Wrong initiateSC");

        // Check if the sender is honest
        // to be continued, we can use block list instead of `isMalicious`
        require(!isMalicious(_data.from), "User malicious");

        // Verify the signature
        VerifyResult verifyRet = OmniverseProtocolHelper.verifyTransaction(transactionRecorder[_data.from], _data);

        if (verifyRet == VerifyResult.Success) {
            // Check cache
            OmniverseTx storage cache = transactionCache[_data.from];
            require(cache.timestamp == 0, "Transaction cached");
            // Logic verification
            _checkExecution(_data);
            // Delays in executing
            cache.txData = _data;
            cache.timestamp = block.timestamp;
            delayedTxs.push(DelayedTx(_data.from, _data.nonce));
            if (_data.chainId == chainId) {
                emit TransactionSent(_data.from, _data.nonce);
            }
        }
        else if (verifyRet == VerifyResult.Duplicated) {
            emit TransactionExecuted(_data.from, _data.nonce);
        }
        else if (verifyRet == VerifyResult.Malicious) {
            // Slash
        }
    }

    /**
     * @notice Check if an omniverse transfer operation can be executed successfully
     */
    function _checkOmniverseTransfer(bytes memory _from, uint256 _amount) internal view {
        uint256 fromBalance = omniverseBalances[_from];
        require(fromBalance >= _amount, "Exceed balance");
    }

    /**
     * @notice Exucute an omniverse transfer operation
     */
    function _omniverseTransfer(bytes memory _from, bytes memory _to, uint256 _amount) internal {
        _checkOmniverseTransfer(_from, _amount);
        
        uint256 fromBalance = omniverseBalances[_from];
        
        unchecked {
            omniverseBalances[_from] = fromBalance - _amount;
        }
        omniverseBalances[_to] += _amount;

        emit OmniverseTokenTransfer(_from, _to, _amount);

        address toAddr = OmniverseProtocolHelper.pkToAddress(_to);
        accountsMap[toAddr] = _to;
    }
    
    /**
     * @notice Check if the public key is the owner
     */
    function _checkOwner(bytes memory _pk) internal view {
        address fromAddr = OmniverseProtocolHelper.pkToAddress(_pk);
        require(fromAddr == owner(), "Not owner");
    }

    /**
     * @notice Execute an omniverse mint operation
     */
    function _omniverseMint(bytes memory _to, uint256 _amount) internal {
        omniverseBalances[_to] += _amount;
        emit OmniverseTokenTransfer("", _to, _amount);

        address toAddr = OmniverseProtocolHelper.pkToAddress(_to);
        accountsMap[toAddr] = _to;
    }

    /**
     * @notice Check if an omniverse burn operation can be executed successfully
     */
    function _checkOmniverseBurn(bytes memory _from, uint256 _amount) internal view {
        uint256 fromBalance = omniverseBalances[_from];
        require(fromBalance >= _amount, "Exceed balance");
    }

    /**
     * @notice Execute an omniverse burn operation
     */
    function _omniverseBurn(bytes memory _from, uint256 _amount) internal {
        omniverseBalances[_from] -= _amount;
        emit OmniverseTokenTransfer(_from, "", _amount);
    }

    /**
     * @notice Add new chain members to the token
     */
    function setMembers(Member[] calldata _members) external onlyOwner {
        for (uint256 i = 0; i < _members.length; i++) {
            if (i < members.length) {
                members[i] = _members[i];
            }
            else {
                members.push(_members[i]);
            }
        }

        for (uint256 i = _members.length; i < members.length; i++) {
            delete members[i];
        }
    }

    /**
     * @notice Returns chain members of the token
     */
    function getMembers() external view returns (Member[] memory) {
        return members;
    }
    
    /**
     @notice See {IERC20-decimals}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 12;
    }

    /**
     * @notice See IERC6358Fungible
     */
    function getTransactionCount(bytes memory _pk) external override view returns (uint256) {
        return transactionRecorder[_pk].txList.length;
    }

    /**
     * @notice See IERC6358Fungible
     */
    function getTransactionData(bytes calldata _user, uint256 _nonce) external override view returns (ERC6358TransactionData memory txData, uint256 timestamp) {
        RecordedCertificate storage rc = transactionRecorder[_user];
        OmniverseTx storage omniTx = rc.txList[_nonce];
        txData = omniTx.txData;
        timestamp = omniTx.timestamp;
    }

    /**
     * @notice Set the cooling down time of an omniverse transaction
     */
    function setCoolingDownTime(uint256 _time) external {
        cdTime = _time;
    }

    /**
     * @notice Index the user is malicious or not
     */
    function isMalicious(bytes memory _pk) public view returns (bool) {
        RecordedCertificate storage rc = transactionRecorder[_pk];
        return (rc.evilTxList.length > 0);
    }

    /**
     * @notice See IERC6358Fungible
     */
    function getChainId() external view returns (uint32) {
        return chainId;
    }

    /**
     * @notice Decode `_data` from bytes to Fungible
     */
    function decodeData(bytes memory _data) internal pure returns (Fungible memory) {
        (uint8 op, bytes memory exData, uint256 amount) = abi.decode(_data, (uint8, bytes, uint256));
        return Fungible(op, exData, amount);
    }

    /**
     * @notice See IERC6358Application
     */
    function getPayloadRawData(bytes memory _payload) external pure returns (bytes memory) {
        Fungible memory fungible = decodeData(_payload);
        return abi.encodePacked(fungible.op, fungible.exData, uint128(fungible.amount));
    }
}