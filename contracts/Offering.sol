//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Offering {

    function startOffering() external payable;

    function bid() external payable;

    function endOffering() external;

}