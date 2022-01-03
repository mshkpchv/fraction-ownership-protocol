//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface Offering {

    function start() external ;

    function bid() external payable;

    function end() external;

}

contract DutchAuction {

    address[] private bidders;

    // Bid[] public bids;

    // getPrice
    // bid()

}

contract FirstInAuction {

}

contract BaseAuction {
   
}

contract Auction {
    using SafeMath for uint256;

    struct Bid {
        address sender;
        uint256 amount;
    }

    enum Stage {
        INACTIVE,
        ACTIVE,
        ACTIVE_NO_SUPPLY,
        FINISH_TIME
    }


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

    uint256 private tokensForSale;

    uint256 private totalSupply;
    
    // 
    // auction length params 
    //
    uint256 public auctionStart;

    uint256 public auctionEnd;

    uint256 public auctionLength;


    constructor(uint256 _rate, address moderator ,address _token, uint256 _tokensForSale, uint256 _totalSupply) {
        rate = _rate;
        token = IERC20(_token);
        wallet = moderator;

        tokensForSale = _tokensForSale;
        totalSupply = _totalSupply;
        
        stage = Stage.INACTIVE;

        auctionLength = 1 days;

    }

    function start() external {
        require(stage == Stage.INACTIVE,"auction: inactive stage");
        
        auctionStart = block.timestamp;
        auctionEnd = block.timestamp + auctionLength;

        stage = Stage.ACTIVE;
    }

    function bid(address recipient) external payable {
        console.log("Offering.sol:offering bid",msg.sender);
        require(stage == Stage.ACTIVE,"auction:active stage only");
        require(block.timestamp < auctionEnd, "auction time ended");

        uint256 amountInWei = msg.value;
        uint256 purchaseTokens = _getTokenAmount(amountInWei);

        require(recipient != address(0), "auction: beneficiary is the zero address");
        require(purchaseTokens != 0 ,"auction: tokens is not correct amount");

        if (purchaseTokens > tokensForSale) {
            purchaseTokens = tokensForSale;
            _inAdvanceEnd();
        }
        tokensForSale = tokensForSale.sub(purchaseTokens);
        token.transfer(recipient, purchaseTokens);
        payable(wallet).transfer(msg.value);

        //TODO emit
    }

    function end() external {
        //TODO time is up and moderator must call it to get if tokens exists
        require(stage == Stage.ACTIVE_NO_SUPPLY);
        if (tokensForSale != 0 ) {
            _processPurchase(wallet,tokensForSale);
            tokensForSale = 0;
        }
    }

    function _inAdvanceEnd() internal {
        require(stage == Stage.ACTIVE,"auction:active stage");
        stage = Stage.ACTIVE_NO_SUPPLY;
    }

    function getPrice() external view returns(uint256) {
        return 0;
    }

    function _getTokenAmount(uint256 weiAmount) internal view returns (uint256) {
        return weiAmount.mul(rate);
    }

    function getRemainderTokens() external view returns(uint256) {
        return tokensForSale;
    }
     
    function _preValidatePurchase(address beneficiary, uint256 tokens) internal view {
        require(beneficiary != address(0), "auction: beneficiary is the zero address");
        require(tokens != 0 ,"auction: tokens is not correct amount");
    }

    function _processPurchase(address recipient, uint256 tokens) internal {
        token.transfer(recipient, tokens);
    }

    function _forwardFunds() internal {
        payable(wallet).transfer(msg.value);
    }
}