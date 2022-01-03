//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "hardhat/console.sol";

interface Offering {

    function start() external ;

    function bid() external payable;

    function end() external;

}

contract Auction is Offering {

    struct Bid {
        address sender;
        uint256 amount;
    }

    enum Stage {
        INACTIVE,
        ACTIVE,
        FINISH,
        BUYBACK
    }

    address[] private bidders;

    Bid[] public bids;

    Stage public stage;

    // The token being sold
    IERC20 private token;

    // Address where funds are collected
    address private wallet;

    // How many token units a buyer gets per wei.
    // The rate is the conversion between wei and the smallest and indivisible token unit.
    // So, if you are using a rate of 1 with a ERC20Detailed token with 3 decimals called TOK
    // 1 wei will give you 1 unit, or 0.001 TOK.
    uint256 private rate;

    // Amount of wei raised
    uint256 private weiRaised;

    uint256 private weiCap;

    uint256 private tokensForSale;

    uint256 private totalSupply;


    constructor(uint256 _rate, address moderator ,address _token, uint256 _tokensForSale, uint256 _totalSupply) {
        // rate = _rate;
        rate = 1;
        token = IERC20(_token);
        wallet = moderator;

        tokensForSale = _tokensForSale;
        totalSupply = _totalSupply;
        
        weiRaised = 0;
        weiCap = _tokensForSale * _rate;
    }

    function start() override external {
        require(stage == Stage.INACTIVE,"auction: can start single time");
        stage = Stage.ACTIVE;
    }

    function bid() external override payable {
        console.log("Offering.sol:offering bid",msg.sender);
        uint256 amountInWei = msg.value;
        address recipient = msg.sender;
        uint256 tokens = _getTokenAmount(amountInWei);
        // _preValidatePurchase(recipient, tokens);

        // _processPurchase(recipient, tokens);
        tokensForSale = tokensForSale - tokens;
        token.transfer(recipient, tokens);
        // token.transferFrom(address(this), msg.sender, tokens);
        // _forwardFunds();
    }

    function end() override external {

    }

    function getPrice() external view returns(uint256) {
        return 0;
    }

    function getRate() external returns(uint256) {
        return rate;
    }

    function _getTokenAmount(uint256 weiAmount) internal view returns (uint256) {
        return weiAmount * rate;
    }

    function getRemainderTokens() external view returns(uint256) {
        return tokensForSale;
    }

    function getAmountRaised() external view returns(uint256) {
        return weiRaised;
    }
     
    function _preValidatePurchase(address beneficiary, uint256 weiAmount) internal view {
        require(beneficiary != address(0), "Crowdsale: beneficiary is the zero address");
        require(weiAmount != 0, "Crowdsale: weiAmount is 0");
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    }
    function _processPurchase() internal view {

    }
    function _forwardFunds() internal view {
        // token.transfer(recipient, tokenCount);
    }
}