pragma solidity ^0.8.0;

import "../interfaces/IABT.sol";
import "../interfaces/IFactory.sol";
import "../interfaces/IFinance.sol";
import "../interfaces/IERC20Minimal.sol";

contract Influencer {
    
    uint256 totalContributionValue;

    mapping(string => Weight) weights;

    struct Weight {
        uint256 decimal;
        uint256 value;
    }

    function getInfluence(address abt_, uint256 id_) public {
        return _getInfluence(abt_, id_);
    }


    function _getInfluence(address abt_, uint256 id_) internal returns (uint influence) {
        // get Finance address
        address factory = IABT(abt_).factory();
        address finance = IFactory(factory).getFinance(id_);
        address WETH = IFinance(finance).WETH();
        // normalize finance value  
        uint256 norm_finance = IERC20Minimal(WETH).balanceOf(finance) / totalContributionValue * 100;
        uint256 norm_time = block.timestamp - IFinance(finance).createdAt() / block.timestamp * 100;
        uint256 influence = weights["alpha"].value * norm_finance + weights["beta"] * norm_time;
        return influence / weights["alpha"].decimal / weights["beta"].decimal;
    }

    function setWeight(string memory key, uint256 value, uint256 decimal) public {
        weights[key] = Weight({
            value: value,
            decimal: decimal
        });
    }
}