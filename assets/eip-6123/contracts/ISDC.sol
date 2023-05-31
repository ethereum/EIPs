// SPDX-License-Identifier: CC0-1.0
pragma solidity >=0.7.0 <0.9.0;

/*------------------------------------------- DESCRIPTION ---------------------------------------------------------------------------------------*/

/**
 * @title ERC6123 Smart Derivative Contract
 * @dev Interface specification for a Smart Derivative Contract, which specifies the post-trade live cycle of an OTC financial derivative in a completely deterministic way.
 * Counterparty Risk is removed by construction.
 *
 * A Smart Derivative Contract is a deterministic settlement protocol which has economically the same behaviour as a collateralized OTC financial derivative.
 * It aims is to remove many inefficiencies in collateralized OTC transactions and remove counterparty credit risk by construction.
 *
 * In contrast to a collateralized derivative contract based and collateral flows are netted. As result, the smart derivative contract generates a stream of
 * reflecting the settlement of a referenced underlying. The settlement cash flows may be daily (which is the standard frequency in traditional markets)
 * or at higher frequencies.
 * With each settlement flow the change is the (discounting adjusted) net present value of the underlying contract is exchanged and the value of the contract is reset to zero.
 *
 * To automatically process settlement, counterparties need to provide sufficient prefunded margin amounts and termination fees at the
 * beginning of each settlement cycle. Through a settlement cycle the margin amounts are locked. Simplified, the contract reverts the classical scheme of
 * 1) underlying valuation, then 2) funding of a margin call to
 * 1) pre-funding of a margin buffer (a token), then 2) settlement.
 *
 * A SDC automatically terminates the derivatives contract if there is insufficient pre-funding or if the settlement amount exceeds a
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
 *      T_{i,0}, T_{i,1}, T_{i,2}, T_{i,3} with T_{i,1} = pre-funding of the Smart Contract, T_{i,2} = request valuation from oracle, T_{i,3} = perform settlement on given valuation, T_{i+1,0} = T_{i,3}.
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
 *          <dt>AwaitingFunding</dt>
 *          <dd>T_{i,0} < t < T_{i,1}</dd>
 *
 *          <dt>Funding</dt>
 *          <dd>t = T_{i,1}</dd>
 *
 *          <dt>AwaitingSettlement</dt>
 *          <dd>T_{i,1} < t < T_{i,2}</dd>
 *
 *          <dt>ValuationAndSettlement</dt>
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
     * @dev Emitted when funding phase is initiated
     */
    event ProcessAwaitingFunding();

    /**
     * @dev Emitted when margin balance was updated and sufficient funding is provided
     */
    event ProcessFunded();

    /**
     * @dev Emitted when a valuation and settlement is requested
     * @param tradeData holding the stored trade data
     * @param lastSettlementData holding the settlementdata from previous settlement (next settlement will be the increment of next valuation compared to former valuation)
     */
    event ProcessSettlementRequest(string tradeData, string lastSettlementData);

    /**
     * @dev Emitted when a settlement was processed succesfully
     */
    event ProcessSettled();

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

    /*------------------------------------------- FUNCTIONALITY ---------------------------------------------------------------------------------------*/

    /// Trade Inception

    /**
     * @notice Handles trade inception, stores trade data
     * @dev emits a {TradeIncepted} event
     * @param _tradeData a description of the trade specification e.g. in xml format, suggested structure - see assets/eip-6123/doc/sample-tradedata-filestructure.xml
     * @param _initialSettlementData the initial settlement data (e.g. initial market data at which trade was incepted)
     * @param _upfrontPayment provides an initial payment amount upfront
     */
    function inceptTrade(string memory _tradeData, string memory _initialSettlementData, int256 _upfrontPayment) external;

    /**
     * @notice Performs a matching of provided trade data and settlement data
     * @dev emits a {TradeConfirmed} event if trade data match
     * @param _tradeData a description of the trade in sdc.xml, e.g. in xml format, suggested structure - see assets/eip-6123/doc/sample-tradedata-filestructure.xml
     * @param _initialSettlementData the initial settlement data (e.g. initial market data at which trade was incepted)
     */
    function confirmTrade(string memory _tradeData, string memory _initialSettlementData) external;

    /// Settlement Cycle: Prefunding

    /**
     * @notice Called from outside to check and secure pre-funding. Terminate the trade if prefunding fails.
     * @dev emits a {ProcessFunded} event if prefunding check is successful or a {TradeTerminated} event if prefunding check fails
     */
    function initiatePrefunding() external;

    /// Settlement Cycle: Settlement

    /**
     * @notice Called to trigger a (maybe external) valuation of the underlying contract and afterwards the according settlement process
     * @dev emits a {ProcessSettlementRequest}
     */
    function initiateSettlement() external;

    /**
     * @notice Called from outside to trigger according settlement on chain-balances callback for initiateSettlement() event handler
     * @dev emits a {ProcessSettled} if settlement is successful or {TradeTerminated} if settlement fails
     * @param settlementAmount the settlement amount. If settlementAmount > 0 then receivingParty receives this amount from other party. If settlementAmount < 0 then other party receives -settlementAmount from receivingParty.
     * @param settlementData. the tripple (product, previousSettlementData, settlementData) determines the settlementAmount.
     */
    function performSettlement(int256 settlementAmount, string memory settlementData) external;

    /// Trade termination

    /**
     * @notice Called from a counterparty to request a mutual termination
     * @dev emits a {TradeTerminationRequest}
     * @param tradeId the trade identifier which is supposed to be terminated
     */
    function requestTradeTermination(string memory tradeId) external;

    /**
     * @notice Called from a counterparty to confirm a termination, which will triggers a final settlement before trade gets inactive
     * @dev emits a {TradeTerminationConfirmed}
     * @param tradeId the trade identifier of the trade which is supposed to be terminated
     */
    function confirmTradeTermination(string memory tradeId) external;
}

