// SPDX-License-Identifier: CC0-1.0
pragma solidity >=0.7.0 <0.9.0;

/*------------------------------------------- DESCRIPTION ---------------------------------------------------------------------------------------*/

/**
 * @title ERC6123 Smart Derivative Contract
 * @dev Interface specification for a Smart Derivative Contract, which specifies the post-trade live cycle of an OTC financial derivative in a completely deterministic way.
 *
 * A Smart Derivative Contract (SDC) is a deterministic settlement protocol which aims is to remove many inefficiencies in (collateralized) financial transactions.
 * Settlement (Delivery versus payment) and Counterparty Credit Risk are removed by construction.
 *
 * Special Case OTC-Derivatives: In case of a collateralized OTC derivative the SDC nets contract-based and collateral flows . As result, the SDC generates a stream of
 * reflecting the settlement of a referenced underlying. The settlement cash flows may be daily (which is the standard frequency in traditional markets)
 * or at higher frequencies.
 * With each settlement flow the change is the (discounting adjusted) net present value of the underlying contract is exchanged and the value of the contract is reset to zero.
 *
 * To automatically process settlement, parties need to provide sufficient initial funding and termination fees at the
 * beginning of each settlement cycle. Through a settlement cycle the margin amounts are locked. Simplified, the contract reverts the classical scheme of
 * 1) underlying valuation, then 2) funding of a margin call to
 * 1) pre-funding of a margin buffer (a token), then 2) settlement.
 *
 * A SDC may automatically terminates the financial contract if there is insufficient pre-funding or if the settlement amount exceeds a
 * prefunded margin balance. Beyond mutual termination is also intended by the function specification.
 *
 * Events and Functionality specify the entire live cycle: TradeInception, TradeConfirmation, TradeTermination, Margin-Account-Mechanics, Valuation and Settlement.
 *
 * The process can be described by time points and time-intervals which are associated with well defined states:
 * <ol>
 *  <li>t < T* (befrore incept).
 *  </li>
 *  <li>
 *      The process runs in cycles. Let i = 0,1,2,... denote the index of the cycle. Within each cycle there are times
 *      T_{i,0}, T_{i,1}, T_{i,2}, T_{i,3} with T_{i,1} = The Activation of the Trade (initial funding provided), T_{i,1} = request valuation from oracle, T_{i,2} = perform settlement on given valuation, T_{i+1,0} = T_{i,3}.
 *  </li>
 *  <li>
 *      Given this time discretization the states are assigned to time points and time intervalls:
 *      <dl>
 *          <dt>Idle</dt>
 *          <dd>Before incept or after terminate</dd>
 *
 *          <dt>Initiation</dt>
 *          <dd>T* < t < T_{0}, where T* is time of incept and T_{0} = T_{0,0}</dd>
 *
 *          <dt>InTransfer (Initiation Phase)</dt>
 *          <dd>T_{i,0} < t < T_{i,1}</dd>
 *
 *          <dt>Settled</dt>
 *          <dd>t = T_{i,1}</dd>
 *
 *          <dt>ValuationAndSettlement</dt>
 *          <dd>T_{i,1} < t < T_{i,2}</dd>
 *
 *          <dt>InTransfer (Settlement Phase)</dt>
 *          <dd>T_{i,2} < t < T_{i,3}</dd>
 *
 *          <dt>Settled</dt>
 *          <dd>t = T_{i,3}</dd>
 *      </dl>
 *  </li>
 * </ol>
 */

interface ISDC {
    /*------------------------------------------- EVENTS ---------------------------------------------------------------------------------------*/
    /**
     * @dev Emitted  when a new trade is incepted from a eligible counterparty
     * @param initiator is the address from which trade was incepted
     * @param tradeId is the trade ID (e.g. generated internally)
     * @param tradeData holding the trade parameters
     */
    event TradeIncepted(address initiator, string tradeId, string tradeData);

    /**
     * @dev Emitted when an incepted trade is confirmed by the opposite counterparty
     * @param confirmer the confirming party
     * @param tradeId the trade identifier
     */
    event TradeConfirmed(address confirmer, string tradeId);

    /**
     * @dev Emitted when a confirmed trade is set to active - e.g. when termination fee amounts are provided
     * @param tradeId the trade identifier of the activated trade
     */
    event TradeActivated(string tradeId);

    /**
     * @dev Emitted when an active trade is terminated
     * @param cause string holding the cause of the termination
     */
    event TradeTerminated(string cause);

    /**
     * @dev Emitted when Settlement phase is initiated
     */
    event TradeSettlementPhase();

    /**
     * @dev Emitted when settlement process has been finished
     */
    event TradeSettled();

    /**
     * @dev Emitted when a settlement gets requested
     * @param tradeData holding the stored trade data
     * @param lastSettlementData holding the settlementdata from previous settlement (next settlement will be the increment of next valuation compared to former valuation)
     */
    event TradeSettlementRequest(string tradeData, string lastSettlementData);

    /**
     * @dev Emitted when a counterparty proactively requests an early termination of the underlying trade
     * @param cpAddress the address of the requesting party
     * @param tradeId the trade identifier which is supposed to be terminated
     */
    event TradeTerminationRequest(address cpAddress, string tradeId);

    /**
     * @dev Emitted when early termination request is confirmed by the opposite party
     * @param cpAddress the party which confirms the trade termination
     * @param tradeId the trade identifier which is supposed to be terminated
     */
    event TradeTerminationConfirmed(address cpAddress, string tradeId);

    /**
     * @dev Emitted when trade processing is halted
     * @param message of what has happened
     */
    event ProcessHalted(string message);

    /*------------------------------------------- FUNCTIONALITY ---------------------------------------------------------------------------------------*/

    /// Trade Inception

    /**
     * @notice Incepts a trade, stores trade data
     * @dev emits a {TradeIncepted} event
     * @param _withParty is the party the inceptor wants to trade with
     * @param _tradeData a description of the trade specification e.g. in xml format, suggested structure - see assets/eip-6123/doc/sample-tradedata-filestructure.xml
     * @param _position is the position the inceptor has in that trade
     * @param _paymentAmount is the paymentamount which can be positive or negative
     * @param _initialSettlementData the initial settlement data (e.g. initial market data at which trade was incepted)
     */
    function inceptTrade(address _withParty, string memory _tradeData, int _position, int256 _paymentAmount, string memory _initialSettlementData) external;

    /**
     * @notice Performs a matching of provided trade data and settlement data of a previous trade inception
     * @dev emits a {TradeConfirmed} event if trade data match
     * @param _withParty is the party the confirmer wants to trade with
     * @param _tradeData a description of the trade specification e.g. in xml format, suggested structure - see assets/eip-6123/doc/sample-tradedata-filestructure.xml
     * @param _position is the position the inceptor has in that trade
     * @param _paymentAmount is the paymentamount which can be positive or negative
     * @param _initialSettlementData the initial settlement data (e.g. initial market data at which trade was incepted)
     */
     function confirmTrade(address _withParty, string memory _tradeData, int _position, int256 _paymentAmount, string memory _initialSettlementData) external;


    /// Settlement Cycle: Settlement

    /**
     * @notice Called to trigger a (maybe external) valuation of the underlying contract and afterwards the according settlement process
     * @dev emits a {TradeSettlementRequest}
     */
    function initiateSettlement() external;

    /**
     * @notice Called to trigger according settlement on chain-balances callback for initiateSettlement() event handler
     * @dev perform settlement checks, may initiate transfers and emits {TradeSettlementPhase}
     * @param settlementAmount the settlement amount. If settlementAmount > 0 then receivingParty receives this amount from other party. If settlementAmount < 0 then other party receives -settlementAmount from receivingParty.
     * @param settlementData. the tripple (product, previousSettlementData, settlementData) determines the settlementAmount.
     */
    function performSettlement(int256 settlementAmount, string memory settlementData) external;


    /**
     * @notice May get called from outside to to finish a transfer (callback). The trade decides on how to proceed based on success flag
     * @param success tells the protocol whether transfer was successful
     * @dev may emit a {TradeSettled} event  or a {TradeTerminated} event
     */
    function afterTransfer(uint256 transactionHash, bool success) external;


    /// Trade termination

    /**
     * @notice Called from a counterparty to request a mutual termination
     * @dev emits a {TradeTerminationRequest}
     * @param tradeId the trade identifier which is supposed to be terminated
     */
    function requestTradeTermination(string memory tradeId, int256 _terminationPayment) external;

    /**
     * @notice Called from a party to confirm an incepted termination, which might trigger a final settlement before trade gets closed
     * @dev emits a {TradeTerminationConfirmed}
     * @param tradeId the trade identifier of the trade which is supposed to be terminated
     */
    function confirmTradeTermination(string memory tradeId, int256 _terminationPayment) external;
}
