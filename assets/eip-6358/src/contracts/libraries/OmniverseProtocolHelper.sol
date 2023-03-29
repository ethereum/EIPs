// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "../interfaces/IERC6358.sol";
import "../interfaces/IERC6358Application.sol";

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
     * @notice Get the hash of a transaction
     */
    function getTransactionHash(ERC6358TransactionData memory _data) internal view returns (bytes32) {
        bytes memory payloadRawData = IERC6358Application(address(this)).getPayloadRawData(_data.payload);
        bytes memory rawData = abi.encodePacked(_data.nonce, _data.chainId, _data.initiateSC, _data.from, payloadRawData);
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
        require(recovered != address(0), "Verify failed");
        return recovered;
    }

    /**
     * @notice Check if the public key matches the recovered address
     */
    function checkPkMatched(bytes memory _pk, address _address) public pure {
        bytes32 hash = keccak256(_pk);
        address pkAddress = address(uint160(uint256(hash)));
        require(_address == pkAddress, "Signer not sender");
    }

    /**
     * @notice Verify an omniverse transaction
     */
    function verifyTransaction(RecordedCertificate storage rc, ERC6358TransactionData memory _data) public returns (VerifyResult) {
        uint256 nonce = rc.txList.length;
        
        bytes32 txHash = getTransactionHash(_data);
        address recoveredAddress = recoverAddress(txHash, _data.signature);
        // Signature verified failed
        checkPkMatched(_data.from, recoveredAddress);

        // Check nonce
        if (nonce == _data.nonce) {
            return VerifyResult.Success;
        }
        else if (nonce > _data.nonce) {
            // The message has been received, check conflicts
            OmniverseTx storage hisTx = rc.txList[_data.nonce];
            bytes32 hisTxHash = getTransactionHash(hisTx.txData);
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