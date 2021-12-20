//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Offering {

    function startOffering(uint256 price) external ;

    function bid() external payable;

    function endOffering() external;

}