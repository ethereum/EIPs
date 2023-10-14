// SPDX-License-Identifier: CC0-1.0
pragma solidity >=0.8.0 <0.9.0;

import "./SDC.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./ERC20Settlement.sol";


/**
 * @title Reference Implementation of ERC6123 - Smart Derivative Contract
 * @notice This reference implementation is based on a finite state machine with predefined trade and process states (see enums below)
 * Some comments on the implementation:
 * - trade and process states are used in modifiers to check which function is able to be called at which state
 * - trade data are stored in the contract
 * - trade data matching is done in incept and confirm routine (comparing the hash of the provided data)
 * - ERC-20 token is used for three participants: counterparty1 and counterparty2 and sdc
 * - when prefunding is done sdc contract will hold agreed amounts and perform settlement on those
 * - sdc also keeps track on internal balances for each counterparty
 * - during prefunding sdc will transfer required amounts to its own balance - therefore sufficient approval is needed
 * - upon termination all remaining 'locked' amounts will be transferred back to the counterparties
 *------------------------------------*
     * Setup with Pledge Account
     *
     *  Settlement:
     *  _bookSettlement
     *      Update internal balances
     *      Message
     *  Rebalance:
     *      Book Party2 -> Party1:   X
     *      Rebalance Check
     *          Failed
     *              Book SDC -> Party1:   X
     *              Terminate
 *-------------------------------------*
*/

contract SDCPledgedBalance is SDC {

    struct MarginRequirement {
        uint256 buffer;
        uint256 terminationFee;
    }


    mapping(address => MarginRequirement) private marginRequirements; // Storage of M and P per counterparty address

    constructor(
        address _party1,
        address _party2,
        address _settlementToken,
        uint256 _initialBuffer, // m
        uint256 _initalTerminationFee // p
    ) SDC(_party1,_party2,_settlementToken) {
        marginRequirements[party1] = MarginRequirement(_initialBuffer, _initalTerminationFee);
        marginRequirements[party2] = MarginRequirement(_initialBuffer, _initalTerminationFee);
    }


    function processTradeAfterConfirmation(address upfrontPayer, uint256 upfrontPayment) override internal{
        uint256 marginRequirementParty1 = uint(marginRequirements[party1].buffer + marginRequirements[party1].terminationFee );
        uint256 marginRequirementParty2 = uint(marginRequirements[party2].buffer + marginRequirements[party2].terminationFee );
        uint256 requiredBalanceParty1 = marginRequirementParty1 + (upfrontPayer==party1 ? upfrontPayment : 0);
        uint256 requiredBalanceParty2 = marginRequirementParty2 + (upfrontPayer==party2 ? upfrontPayment : 0);
        bool isAvailableParty1 = (settlementToken.balanceOf(party1) >= requiredBalanceParty1) && (settlementToken.allowance(party1, address(this)) >= requiredBalanceParty1);
        bool isAvailableParty2 = (settlementToken.balanceOf(party2) >= requiredBalanceParty2) && (settlementToken.allowance(party2, address(this)) >= requiredBalanceParty2);
        if (isAvailableParty1 && isAvailableParty2){       // Pre-Conditions: M + P needs to be locked (i.e. pledged)
            address[] memory from = new address[](3);
            address[] memory to = new address[](3);
            uint256[] memory amounts = new uint256[](3);
            from[0] = party1;       to[0] = address(this);              amounts[0] = marginRequirementParty1;
            from[1] = party2;       to[1] = address(this);              amounts[1] = marginRequirementParty2;
            from[2] = upfrontPayer; to[2] = otherParty(upfrontPayer);   amounts[2] = upfrontPayment;
            uint256 transactionID = uint256(keccak256(abi.encodePacked(from,to,amounts)));
            tradeState = TradeState.InTransfer;
            settlementToken.checkedBatchTransferFrom(from,to,amounts,transactionID);             // Atomic Transfer
        }
        else {
            tradeState = TradeState.Inactive;
            emit TradeTerminated("Insufficient Balance or Allowance");
            }
        }

    /*
     * Settlement can be initiated when margin accounts are locked, a valuation request event is emitted containing tradeData and valuationViewParty
     * Changes Process State to Valuation&Settlement
     * can be called only when ProcessState = Rebalanced and TradeState = Active
     */
    function initiateSettlement() external override onlyCounterparty onlyWhenSettled {
        tradeState = TradeState.Valuation;
        emit TradeSettlementRequest(tradeData, settlementData[settlementData.length - 1]);
    }

    /*
     * Performs a settelement only when processState is ValuationAndSettlement
     * Puts process state to "inTransfer"
     * Checks Settlement amount according to valuationViewParty: If SettlementAmount is > 0, valuationViewParty receives
     * can be called only when ProcessState = ValuationAndSettlement
     */

    function performSettlement(int256 settlementAmount, string memory _settlementData) onlyWhenValuation external override {

        if (mutuallyTerminated){
            settlementAmount = settlementAmount + terminationPayment;
        }

        settlementData.push(_settlementData);
        settlementAmounts.push(settlementAmount);

        uint256 transferAmount;
        address settlementPayer;
        (settlementPayer, transferAmount) = determineTransferAmountAndPayerAddress(settlementAmount);

        if (settlementToken.balanceOf(settlementPayer) >= transferAmount &&
            settlementToken.allowance(settlementPayer,address(this)) >= transferAmount) { /* Good case: Balances are sufficient and token has enough approval */
            uint256 transactionID = uint256(keccak256(abi.encodePacked(settlementPayer,otherParty(settlementPayer), transferAmount)));
            emit TradeSettlementPhase();
            tradeState = TradeState.InTransfer;
            address[] memory from = new address[](1);
            address[] memory to = new address[](1);
            uint256[] memory amounts = new uint256[](1);
            from[0] = settlementPayer; to[0] = otherParty(settlementPayer); amounts[0] = transferAmount;
            tradeState = TradeState.InTransfer;
            settlementToken.checkedBatchTransferFrom(from,to,amounts,transactionID);
        }
        else { /* Bad Case: Process termination by booking from own balance */
            tradeState = TradeState.InTransfer;
            _processAfterTransfer(false);
        }
    }

    function determineTransferAmountAndPayerAddress(int256 settlementAmount) internal returns(address, uint256)  {
        address settlementReceiver = settlementAmount > 0 ? receivingParty : otherParty(receivingParty);
        address settlementPayer = otherParty(settlementReceiver);

        uint256 transferAmount;
        if (settlementAmount > 0)
            transferAmount = uint256(abs(min( settlementAmount, int(marginRequirements[settlementPayer].buffer))));
        else
            transferAmount = uint256(abs(max( settlementAmount, -int(marginRequirements[settlementReceiver].buffer))));

        return (settlementPayer,transferAmount);
    }


    function afterTransfer(uint256 transactionHash, bool success) external override onlyWhenInTransfer  {
        emit TradeSettled();
        _processAfterTransfer(success);
    }

    function _processAfterTransfer(bool success) internal{
        if(success){
            tradeState = TradeState.Settled;
            emit TradeSettled();
            if (tradeState == TradeState.Terminated){
                tradeState = TradeState.Inactive;
            }
            if (mutuallyTerminated){
                tradeState = TradeState.Inactive;
            }
        }
        else{ // TRANSFER HAS FAILED
            if (settlementData.length == 1){ // Case after confirmTrade where Transfer of upfront has failed
                tradeState = TradeState.Inactive;
                emit TradeTerminated("Initial Upfront Transfer fail - Trade Inactive");
            }
            else{
                // Settlement & Pledge Case: transferAmount is transferred from SDC balance (i.e. pledged balance).
                int256 settlementAmount = settlementAmounts[settlementAmounts.length-1];
                uint256 transferAmount;
                address settlementPayer;
                (settlementPayer, transferAmount)  = determineTransferAmountAndPayerAddress(settlementAmounts[settlementAmounts.length-1]);
                address settlementReceiver = otherParty(settlementPayer);
                settlementToken.approve(settlementPayer,uint256(marginRequirements[settlementPayer].buffer - transferAmount)); // Release Buffers
                settlementToken.approve(settlementReceiver,uint256(marginRequirements[settlementReceiver].buffer)); // Release Buffers

                // Do Pledge Transfer from own balances including termination fee
                tradeState = TradeState.Terminated;
                emit TradeTerminated("Trade terminated due to regular settlement failure");
                address[] memory to = new address[](2);
                uint256[] memory amounts = new uint256[](2);
                to[0] = settlementReceiver; amounts[0] = uint256(transferAmount);
                to[1] = settlementReceiver; amounts[1] = uint256(marginRequirements[settlementPayer].terminationFee);
                uint256 transactionID = uint256(keccak256(abi.encodePacked(to,amounts)));
                settlementToken.checkedBatchTransfer(to,amounts,transactionID);
            }
        }
    }


}
