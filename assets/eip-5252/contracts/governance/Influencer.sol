pragma solidity ^0.8.0;

import "../interfaces/IABT.sol";
import "../interfaces/IFactory.sol";
import "../interfaces/IFinance.sol";
import "../interfaces/IERC20Minimal.sol";

contract Influencer {
    
    uint256 totalContributionValue;

    mapping(string => Weight) weights;

    struct Weight {
        uint256 percentage;
        uint256 decimal;
    }

    function getInfluence(address abt_, uint256 id_) public returns (uint multiplier) {
        return _getInfluence(abt_, id_);
    }


    function _getInfluence(address abt_, uint256 id_) internal returns (uint influence) {
        // get Finance address
        address factory = IABT(abt_).factory();
        address finance = IFactory(factory).getFinance(id_);
        address WETH = IFinance(finance).WETH();
        // normalize finance value   
        uint256 norm_alpha = IERC20Minimal(WETH).balanceOf(finance) / totalContributionValue * 100;
        uint256 norm_beta = block.timestamp - IFinance(finance).createdAt() / block.timestamp * 100;

        // Divide with each decimal 
        uint256 influence_dec = weights["alpha"].percentage * norm_alpha + weights["beta"].percentage * norm_beta;
        return influence_dec / weights["alpha"].decimal / weights["beta"].decimal;
    }

    function setWeight(string memory key, uint256 percentage, uint256 decimal) public {
        weights[key] = Weight({
            percentage: percentage,
            decimal: decimal
        });
    }
}