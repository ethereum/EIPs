
// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;
import "./interfaces/IERC-5851.sol";


abstract contract ERC5851Issuer is IERC-5851{
    mapping(uint256 => IERC6595.Claim[]) private _requiredClaim;
    mapping(address => mapping(uint256 => bool)) private _SBTVerified;
    address public admin;
    
    constructor() {
        admin = msg.sender;

    }
    
    function ifVerified(address claimmer, uint256 SBTID) public override view returns (bool){
        return(_SBTVerified[claimmer][SBTID]);
    }
    
    function standardclaim(uint256 SBTID) public override view returns (Claim[] memory){
        return(_requiredClaim[SBTID]);
    }

    function changeStandardClaim(uint256 SBTID, Claim[] memory _claims) public override returns (bool){
        require(msg.sender == admin);
        _requiredMetadata[SBTID] = requirements;    
        emit standardChanged(SBTID, requirements);
        return(true);     
    }

    function certify(address claimer, uint256 SBTID) public override returns (bool){
        require(msg.sender == admin);
        _SBTVerified[claimer][SBTID] = true;
        emit certified(claimer, SBTID);
        return(true);     
    }

    function revoke(address claimer, uint256 SBTID) external override returns (bool){
        require(msg.sender == admin);
        _SBTVerified[claimer][SBTID] = false;
        emit revoked(claimer, SBTID);
        return(true);     
    }

}
