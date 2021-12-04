//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC20FractionToken.sol";


contract ERC20FractionTokenFactory is Ownable {

    ERC20FractionToken[] public tokens;
    
    function createERC20FractionToken() public {

    }
    
}