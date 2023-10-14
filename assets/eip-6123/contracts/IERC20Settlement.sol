// SPDX-License-Identifier: CC0-1.0
pragma solidity >=0.7.0 <0.9.0;



import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/*------------------------------------------- DESCRIPTION ---------------------------------------------------------------------------------------
 * @title ERC6123 - Settlement Token Interface
 * @dev Settlement Token Interface enhances the ERC20 Token by introducing so called checked transfer functionality which can be used to directly interact with an SDC.
 * Checked transfers can be conducted for single or multiple transactions where SDC will receive a success message whether the transfer was executed successfully or not.
 */


interface IERC20Settlement is IERC20 {

    /*
     * @dev Performs a single transfer from msg.sender balance and checks whether this transfer can be conducted
     * @param to - receiver
     * @param value - transfer amount
     * @param transactionID
     */
    function checkedTransfer(address to, uint256 value, uint256 transactionID) external;

    /*
     * @dev Performs a single transfer to a single addresss and checks whether this transfer can be conducted
     * @param from - payer
     * @param to - receiver
     * @param value - transfer amount
     * @param transactionID
     */
    function checkedTransferFrom(address from, address to, uint256 value, uint256 transactionID) external ;


    /*
     * @dev Performs a multiple transfers from msg.sender balance and checks whether these transfers can be conducted
     * @param to - receivers
     * @param values - transfer amounts
     * @param transactionID
     */
    function checkedBatchTransfer(address[] memory to, uint256[] memory values, uint256 transactionID ) external;

    /*
     * @dev Performs a multiple transfers between multiple addresses and checks whether these transfers can be conducted
     * @param from - payers
     * @param to - receivers
     * @param value - transfer amounts
     * @param transactionID
     */
    function checkedBatchTransferFrom(address[] memory from, address[] memory to, uint256[] memory values, uint256 transactionID ) external;


}
