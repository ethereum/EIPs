// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "../interfaces/IERC6358.sol";
import "../interfaces/IERC6358Application.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @notice Used to record one omniverse transaction data
 * txData: The original omniverse transaction data committed to the contract
 * timestamp: When the omniverse transaction data is committed
 */
struct OmniverseTx {
    ERC6358TransactionData txData;
    uint256 timestamp;
}

/**
 * @notice An malicious omniverse transaction data
 * oData: The recorded omniverse transaction data
 * hisNonce: The nonce of the historical transaction which it conflicts with
 */
struct EvilTxData {
    OmniverseTx oData;
    uint256 hisNonce;
}

/**
 * @notice Used to record the historical omniverse transactions of a user
 * txList: Successful historical omniverse transaction list
 * evilTxList: Malicious historical omniverse transaction list
 */
struct RecordedCertificate {
    OmniverseTx[] txList;
    EvilTxData[] evilTxList;
}

// Result of verification of an omniverse transaction
enum VerifyResult {
    Success,
    Malicious,
    Duplicated
}

/**
 * @notice The library is mainly responsible for omniverse transaction verification and
 * provides some basic methods.
 * NOTE The verification method is for reference only, and developers can design appropriate
 * verification mechanism based on their bussiness logic.
 */
library OmniverseProtocolHelper {
    /**
     * @notice Get the raw data of a transaction
     */
    function getRawData(ERC6358TransactionData memory _data) internal view returns (bytes memory) {
        bytes memory payloadRawData = IERC6358Application(address(this)).getPayloadRawData(_data.payload);
        bytes memory rawData = abi.encodePacked(_data.nonce, _data.chainId, _data.initiateSC, _data.from, payloadRawData);
        return rawData;
    }

    /**
     * @notice Get the hash of a transaction
     */
    function getTransactionHash(ERC6358TransactionData memory _data) internal view returns (bytes32) {
        bytes memory rawData = getRawData(_data);
        return keccak256(rawData);
    }

    /**
     * @notice Recover the address
     */
    function recoverAddress(bytes32 _hash, bytes memory _signature) public pure returns (address) {
        uint8 v;
        bytes32 r;
        bytes32 s;
        assembly {
            r := mload(add(_signature, 32))
            s := mload(add(_signature, 64))
            v := mload(add(_signature, 65))
        }
        address recovered = ecrecover(_hash, v, r, s);
        return recovered;
    }

    /**
     * @notice Convert the public key to evm address
     */
    function pkToAddress(bytes memory _pk) public pure returns (address) {
        bytes32 hash = keccak256(_pk);
        return address(uint160(uint256(hash)));
    }

    /**
     * @notice Verify if the signature matches the address
     */
    function verifySignature(bytes memory _rawData, bytes memory _signature, address _address) public pure returns (bool) {
        bytes32 hash = keccak256(_rawData);
        address pkAddress = recoverAddress(hash, _signature);
        bytes memory PREFIX = hex"19457468657265756d205369676e6564204d6573736167653a0a";
        
        if (pkAddress == address(0) || pkAddress != _address) {
            hash = keccak256(abi.encodePacked(PREFIX, bytes(Strings.toString(_rawData.length)), _rawData));
            pkAddress = recoverAddress(hash, _signature);
            if (pkAddress == address(0) || pkAddress != _address) {
                return false;
            }
        }

        return true;
    }

    /**
     * @notice Verify an omniverse transaction
     */
    function verifyTransaction(RecordedCertificate storage rc, ERC6358TransactionData memory _data) public returns (VerifyResult) {
        bytes memory rawData = getRawData(_data);
        address senderAddress = pkToAddress(_data.from);
        require(verifySignature(rawData, _data.signature, senderAddress), "Signature error");

        // Check nonce
        uint256 nonce = rc.txList.length;
        if (nonce == _data.nonce) {
            return VerifyResult.Success;
        }
        else if (nonce > _data.nonce) {
            // The message has been received, check conflicts
            OmniverseTx storage hisTx = rc.txList[_data.nonce];
            bytes32 hisTxHash = getTransactionHash(hisTx.txData);
            bytes32 txHash = getTransactionHash(_data);
            if (hisTxHash != txHash) {
                // to be continued, add to evil list, but can not be duplicated
                EvilTxData storage evilTx = rc.evilTxList.push();
                evilTx.hisNonce = nonce;
                evilTx.oData.txData = _data;
                evilTx.oData.timestamp = block.timestamp;
                return VerifyResult.Malicious;
            }
            else {
                return VerifyResult.Duplicated;
            }
        }
        else {
            revert("Nonce error");
        }
    }
}