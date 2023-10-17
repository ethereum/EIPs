// SPDX-License-Identifier: CC0.0 OR Apache-2.0
// Author: Zainan Victor Zhou <zzn-ercref@zzn.im>
// See a full runnable hardhat project in https://github.com/ercref/ercref-contracts/tree/main/ERCs/eip-5453
pragma solidity ^0.8.9;

import "./AERC5453.sol";

contract ThresholdMultiSigForwarder is AERC5453Endorsible {
    mapping(address => bool) private owners;
    uint256 private ownerCount;

    constructor() AERC5453Endorsible("ThresholdMultiSigForwarder", "v1") {}

    function initialize(
        address[] calldata _owners,
        uint256 _threshold
    ) external {
        require(_threshold >= 1, "Threshold must be positive");
        require(_owners.length >= _threshold);
        require(_noRepeat(_owners));
        _setThreshold(_threshold);
        for (uint256 i = 0; i < _owners.length; i++) {
            owners[_owners[i]] = true;
        }
        ownerCount = _owners.length;
    }

    function forward(
        address _dest,
        uint256 _value,
        uint256 _gasLimit,
        bytes calldata _calldata,
        bytes calldata _extraData
    )
        external
        onlyEndorsed(
            _computeFunctionParamHash(
                "function forward(address _dest,uint256 _value,uint256 _gasLimit,bytes calldata _calldata)",
                abi.encode(_dest, _value, _gasLimit, keccak256(_calldata))
            ),
            _extraData
        )
    {
        string memory errorMessage = "Fail to call remote contract";
        (bool success, bytes memory returndata) = _dest.call{value: _value}(
            _calldata
        );
        Address.verifyCallResult(success, returndata, errorMessage);
    }

    function _isEligibleEndorser(
        address _endorser
    ) internal view override returns (bool) {
        return owners[_endorser] == true;
    }
}
