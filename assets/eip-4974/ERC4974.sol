// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;
import "./IERC4974.sol";

/**
 * See {IERC4974}
 * Implements the ERC4974 Metadata extension.
 */
contract LoyaltyPoints is IERC4974 {

    // The address of the operator that can assign ratings
    address private _operator;

    // Mapping of customer addresses to their ratings
    mapping (bytes32 => int8) private _ratings;

    // Initializes the contract by setting the operator to msg.sender
    constructor () {
        _operator = msg.sender;
    }

    // Set the operator address
    // Only the current operator or the contract owner can call this function
    function setOperator(address newOperator) public override {
        require(_operator == msg.sender || msg.sender == address(this), "Only the current operator or the contract owner can set the operator.");
        _operator = newOperator;
        emit NewOperator(_operator);
    }

    // Rate a customer
    // Only the operator can call this function
    function rate(address customer, int8 rating) public override {
        require(_operator == msg.sender, "Only the operator can assign ratings.");
        bytes32 hash = keccak256(abi.encodePacked(customer));
        _ratings[hash] = rating;
        emit Rating(customer, rating);
    }

    // Remove a rating from a customer
    // Only the operator can call this function
    function removeRating(address customer) external override {
        require(_operator == msg.sender, "Only the operator can remove ratings.");
        bytes32 hash = keccak256(abi.encodePacked(customer));
        delete _ratings[hash];
        emit Removal(customer);
    }

    // Get the rating for a customer
    function getOperator() public view returns (address) {
        return _operator;
    }

    // Check if a customer has been rated
    function hasBeenRated(address customer) public view returns (bool) {
        // Hash the customer address
        bytes32 hash = keccak256(abi.encodePacked(customer));

        // Check if the hash exists in the mapping
        return _ratings[hash] != 0;
    }

    function ratingOf(address _rated) public view override returns (int8) {
        bytes32 hash = keccak256(abi.encodePacked(_rated));
        // Check if the customer has been rated
        require(hasBeenRated(_rated), "This customer has not been rated yet.");
        // Return the customer's rating
        return _ratings[hash];
    }

    // Award ETH to a customer based on their rating
    function awardEth(address payable customer) public payable {
        // Calculate the amount of ETH to award based on the customer's rating
        int8 rating = ratingOf(customer);
        require(rating > 0, "Sorry, this customer has a rating less than 0 and cannot be awarded.");
        uint256 award = uint256(int256(rating));
        // Transfer the ETH to the customer
        require(address(this).balance >= award, "Contract has insufficient balance to award ETH.");
        customer.transfer(award);
    }

    receive () external payable {}

}