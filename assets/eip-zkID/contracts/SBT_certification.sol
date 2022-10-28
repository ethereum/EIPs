
// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;
import "./interfaces/IERC6595.sol";


abstract contract KYCABST is IERC6595{
    mapping(uint256 => IERC6595.Requirement[]) private _requiredMetadata;
    mapping(address => mapping(uint256 => bool)) private _SBTVerified;
    address public admin;
    
    constructor() {
        admin = msg.sender;

    }
    
    function ifVerified(address verifying, uint256 SBTID) public override view returns (bool){
        return(_SBTVerified[verifying][SBTID]);
    }
    
    function standardRequirement(uint256 SBTID) public override view returns (Requirement[] memory){
        return(_requiredMetadata[SBTID]);
    }

    function changeStandardRequirement(uint256 SBTID, Requirement[] memory requirements) public override returns (bool){
        require(msg.sender == admin);
        _requiredMetadata[SBTID] = requirements;    
        emit standardChanged(SBTID, requirements);
        return(true);     
    }

    function certify(address certifying, uint256 SBTID) public override returns (bool){
        require(msg.sender == admin);
        _SBTVerified[certifying][SBTID] = true;
        emit certified(certifying, SBTID);
        return(true);     
    }

    function revoke(address certifying, uint256 SBTID) external override returns (bool){
        require(msg.sender == admin);
        _SBTVerified[certifying][SBTID] = false;
        emit revoked(certifying, SBTID);
        return(true);     
    }

}