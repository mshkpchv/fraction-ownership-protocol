//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

contract ERC20FractionToken is ERC20,ERC721Holder {

    constructor(string memory _name,string memory _symbol) ERC20(_name,_symbol) {
        
    }
    
}