//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Auction {

    function startAuction() external payable;

    function bid() external payable;

    function endAuction() external;

}