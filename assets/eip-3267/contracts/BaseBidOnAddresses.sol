// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.7.1;
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { ABDKMath64x64 } from "abdk-libraries-solidity/ABDKMath64x64.sol";
import { BaseLock } from "./BaseLock.sol";

/// @title Bidding on Ethereum addresses
/// @author Victor Porton
/// @notice Not audited, not enough tested.
/// This allows anyone claim conditional tokens in order for him to transfer money from the future.
/// See `docs/future-money.rst`.
abstract contract BaseBidOnAddresses is BaseLock {
    using ABDKMath64x64 for int128;
    using SafeMath for uint256;

    /// A condition score was stored in the chain by an oracle.
    /// @param oracleId The oracle ID.
    /// @param condition The conditional (customer addresses).
    /// @param numerator The relative score provided by the oracle.
    event ReportedNumerator(
        uint64 indexed oracleId,
        uint256 indexed condition,
        uint256 numerator
    );

    /// Some condition scores were stored in the chain by an oracle.
    /// @param oracleId The oracle ID.
    /// @param conditions The conditionals (customer addresses).
    /// @param numerators The relative scores provided by the oracle.
    event ReportedNumeratorsBatch(
        uint64 indexed oracleId,
        uint64[] indexed conditions,
        uint256[] numerators
    );

    // Whether an oracle finished its work.
    mapping(uint64 => bool) private oracleFinishedMap;
    // Mapping (oracleId => (condition => numerator)) for payout numerators.
    mapping(uint64 => mapping(uint256 => uint256)) private payoutNumeratorsMap;
    // Mapping (oracleId => denominator) for payout denominators.
    mapping(uint256 => uint) private payoutDenominatorMap;

    /// Constructor.
    /// @param _uri Our ERC-1155 tokens description URI.
    constructor(string memory _uri) BaseLock(_uri) { }

    /// Retrieve the last stored payout numerator (relative score of a condition).
    /// @param _oracleId The oracle ID.
    /// @param _condition The condition (the original receiver of a conditional token).
    /// The result can't change if the oracle has finished.
    function payoutNumerator(uint64 _oracleId, uint256 _condition) public view returns (uint256) {
        return payoutNumeratorsMap[_oracleId][_condition];
    }

    /// Retrieve the last stored payout denominator (the sum of all numerators of the oracle).
    /// @param _oracleId The oracle ID.
    /// The result can't change if the oracle has finished.
    function payoutDenominator(uint64 _oracleId) public view returns (uint256) {
        return payoutDenominatorMap[_oracleId];
    }

    /// Called by the oracle owner for reporting results of conditions.
    /// @param _oracleId The oracle ID.
    /// @param _condition The condition.
    /// @param _numerator The relative score of the condition.
    /// Note: We could make oracles easily verificable by a hash of all the data, but
    ///       - It may need allowing to set a numerator only once.
    ///       - It may be not necessary because future technology will allow to aggregate blockchains.
    function reportNumerator(uint64 _oracleId, uint256 _condition, uint256 _numerator) external
        _isOracle(_oracleId)
        _oracleNotFinished(_oracleId) // otherwise an oracle can break data consistency
    {
        _updateNumerator(_oracleId, _numerator, _condition);
        emit ReportedNumerator(_oracleId, _condition, _numerator);
    }

    /// Called by the oracle owner for reporting results of several conditions.
    /// @param _oracleId The oracle ID.
    /// @param _conditions The conditions.
    /// @param _numerators The relative scores of the condition.
    function reportNumeratorsBatch(uint64 _oracleId, uint64[] calldata _conditions, uint256[] calldata _numerators) external
        _isOracle(_oracleId)
        _oracleNotFinished(_oracleId) // otherwise an oracle can break data consistency
    {
        require(_conditions.length == _numerators.length, "Length mismatch.");
        for (uint _i = 0; _i < _conditions.length; ++_i) {
            _updateNumerator(_oracleId, _numerators[_i], _conditions[_i]);
        }
        emit ReportedNumeratorsBatch(_oracleId, _conditions, _numerators);
    }

    /// Need to be called after all numerators were reported.
    /// @param _oracleId The oracle ID.
    ///
    /// You should set grace period end time before calling this method.
    ///
    /// TODO: Maybe it makes sense to allow to set finish time in a point of the future?
    function finishOracle(uint64 _oracleId) external
        _isOracle(_oracleId)
    {
        oracleFinishedMap[_oracleId] = true;
        emit OracleFinished(_oracleId);
    }

    /// Check if an oracle has finished.
    /// @param _oracleId The oracle ID.
    /// @return `true` if it has finished.
    function isOracleFinished(uint64 _oracleId) public view override returns (bool) {
        return oracleFinishedMap[_oracleId];
    }

    function _updateNumerator(uint64 _oracleId, uint256 _numerator, uint256 _condition) private {
        payoutDenominatorMap[_oracleId] = payoutDenominatorMap[_oracleId].add(_numerator).sub(payoutNumeratorsMap[_oracleId][_condition]);
        payoutNumeratorsMap[_oracleId][_condition] = _numerator;
    }

    // Virtuals //

    function _calcRewardShare(uint64 _oracleId, uint256 _condition) internal virtual override view returns (int128) {
        uint256 _numerator = payoutNumeratorsMap[_oracleId][_condition];
        uint256 _denominator = payoutDenominatorMap[_oracleId];
        return ABDKMath64x64.divu(_numerator, _denominator);
    }

    // Modifiers //

    modifier _oracleNotFinished(uint64 _oracleId) {
        require(!isOracleFinished(_oracleId), "Oracle is finished.");
        _;
    }
}
