// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {PriceConverter} from "./PriceConverter.sol";

/**
 * @title This contract allows to gether funds, keep a record of funders and withdraw the funds.
 * @author Aleksandr Rybin
 * @notice Testet, but not audited.
 * @dev Implements Chainlink Data Feeds
 */

contract FundMe {
    /**
     * @dev Library used to get the current ETH/USD conversion rate
     */
    using PriceConverter for uint256;

    /* Errors */
    error FundMe__NotOwner();
    error FundMe__NotEnoughEth();
    error FundMe__CallFailed();

    /* Interfaces */
    AggregatorV3Interface private s_priceFeed;

    /* State variables */
    uint256 public constant MINIMUM_USD = 5 * 10 ** 18;
    address private immutable i_owner;

    mapping(address => uint256) private s_addressToAmountFunded;
    address[] private s_funders;

    /* Events */
    event NewFunder(address indexed funder);
    event MoneyWithdrawn();

    constructor(address priceFeed) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeed);
    }

    /* Modifiers */
    modifier onlyOwner() {
        if (msg.sender != i_owner) revert FundMe__NotOwner();
        _;
    }

    modifier checkFunds() {
        if (msg.value.getConversionRate(s_priceFeed) < MINIMUM_USD) {
            revert FundMe__NotEnoughEth();
        }
        _;
    }

    /**
     * @dev Function that is used by funders to fund the contract.
     */

    function fund() public payable checkFunds {
        s_addressToAmountFunded[msg.sender] += msg.value;
        s_funders.push(msg.sender);
        emit NewFunder(msg.sender);
    }

    /**
     * @dev Get the price feed version.
     */

    function getVersion() public view returns (uint256) {
        return s_priceFeed.version();
    }

    /**
     * @dev Withdraw funds
     */

    function withdraw() public onlyOwner {
        uint256 fundersLength = s_funders.length;
        for (
            uint256 funderIndex = 0;
            funderIndex < fundersLength;
            funderIndex++
        ) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        if (!callSuccess) revert FundMe__CallFailed();
        emit MoneyWithdrawn();
    }

    fallback() external payable {
        fund();
    }

    receive() external payable {
        fund();
    }

    /* Getters */

    function getAddressToAmountFunded(
        address fundingAddress
    ) external view returns (uint256) {
        return s_addressToAmountFunded[fundingAddress];
    }

    function getFunder(uint256 index) external view returns (address) {
        return s_funders[index];
    }

    function getOwner() external view returns (address) {
        return i_owner;
    }
}
