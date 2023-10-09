// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

import "../IERC7092.sol";

library CouponMath {
    /**
    * @notice Returns the annual interest earned by an account in bips
    * @param _investor the investor account address
    * @param _bondContract the bond contract address
    */
    function annualInterest(
        address _investor,
        address _bondContract
    ) external view returns(uint256) {
        uint256 couponRate = IERC7092(_bondContract).couponRate();
        uint256 denomination = IERC7092(_bondContract).denomination();
        uint256 principal = IERC7092(_bondContract).principalOf(_investor);

        return principal * denomination * couponRate;
    }

    /**
    * @notice Returns the interest earned by an account in period `_duration` in bips
    * @param _investor the investor account address
    * @param _duration time ellapsed since the last coupon payment
    * @param _bondContract the bond contract address
    */
    function interest(
        address _investor,
        uint256 _duration,
        address _bondContract
    ) external view returns(uint256) {
        uint256 couponRate = IERC7092(_bondContract).couponRate();
        uint256 denomination = IERC7092(_bondContract).denomination();
        uint256 principal = IERC7092(_bondContract).principalOf(_investor);
        uint256 frequency = IERC7092(_bondContract).couponFrequency();
        uint256 numberOfDays = _numberOfDays(_bondContract);

        return principal * denomination * couponRate * _duration / (frequency * numberOfDays);
    }

    /**
    * @notice Returns the number of days in a year based on the base count basis used.
    *         Here we just check for two values.
    */
    function _numberOfDays(address _bondContract) private view returns(uint256) {
        uint256 dayCountBasis = IERC7092(_bondContract).dayCountBasis();

        if(dayCountBasis == 0) {
            return 365;
        } else if(dayCountBasis == 1) {
            return 360;
        } else {
            revert("invalid day count basis value");
        }
    }
}
