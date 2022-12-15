
// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;
import "./interfaces/IERC5851.sol";


abstract contract ERC5851Issuer is IERC5851{
    mapping(uint256 => IERC5851.Claim[]) private _claimMetadata;
    mapping(address => mapping(uint256 => bool)) private _SBTVerified;
    address public admin;
    
    constructor() {
        admin = msg.sender;

    }
    
    function ifVerified(address claimmer, uint256 SBTID) public override view returns (bool){
        return(_SBTVerified[claimmer][SBTID]);
    }
    
    function standardClaim(uint256 SBTID) public override view returns (Claim[] memory){
        return(_claimMetadata[SBTID]);
    }

    function changeStandardClaim(uint256 SBTID, Claim[] memory _claims) public override returns (bool){
        require(msg.sender == admin);
        _claimMetadata[SBTID] = _claims;    
        emit StandardChanged(SBTID, _claims);
        return(true);     
    }

    function certify(address claimer, uint256 SBTID) public override returns (bool){
        require(msg.sender == admin);
        _SBTVerified[claimer][SBTID] = true;
        emit Certified(claimer, SBTID);
        return(true);     
    }

    function revoke(address claimer, uint256 SBTID) external override returns (bool){
        require(msg.sender == admin);
        _SBTVerified[claimer][SBTID] = false;
        emit Revoked(claimer, SBTID);
        return(true);     
    }

}
