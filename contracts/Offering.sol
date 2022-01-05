//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";


interface IAuction {

    function start() external ;

    function bid(address recipient) external payable;

    function end() external;

    function getPrice() external returns(uint256);

    function getPricePerWei() external returns(uint256);

    function getRemainderTokens() external view returns(uint256);

    // function getName() external pure returns(string memory);

}

contract BaseAuction {
    using SafeMath for uint256;

    uint256 internal constant WEI = 10**18;

    enum Stage {
        INACTIVE,
        ACTIVE,
        ACTIVE_NO_SUPPLY,
        FINISHED
    }

    Stage public stage;

    // The token being sold
    IERC20 internal token;

    // Address where funds are collected
    address internal wallet;

    // The rate is the conversion between wei and the smallest and indivisible token unit.
    uint256 internal rate;

    //TODO solidity does not support double numbers, so we cannot use weiAmount * 0.1
    // we must use weiAmount / 10 = weiAmount * 0,1
    bool internal ratePositive;

    uint256 internal tokensForSale;

    uint256 internal totalSupply;
    
    // 
    // auction length params 
    //
    uint256 public auctionStart;

    uint256 public auctionEnd;

    uint256 public auctionLength = 1 days;


    event Start(address buyer, uint256 tokensForSale);

    event Bid(address buyer, uint256 purchasedTokens, uint256 weiAmount);

    event End();


    constructor(uint256 _rate, address moderator ,address _token, uint256 _tokensForSale, uint256 _totalSupply) {
        rate = _rate;
        token = IERC20(_token);
        wallet = moderator;

        tokensForSale = _tokensForSale;
        totalSupply = _totalSupply;
        
        stage = Stage.INACTIVE;
    }

    function start() virtual external {
        require(stage == Stage.INACTIVE,"auction: inactive stage");
        
        auctionStart = block.timestamp;
        auctionEnd = block.timestamp + auctionLength;

        stage = Stage.ACTIVE;
    }

    function bid(address recipient) external payable {
        require(stage == Stage.ACTIVE,"auction:active stage only");
        require(block.timestamp < auctionEnd, "auction time ended");

        uint256 amountInWei = msg.value;
        uint256 purchaseTokens = _calcTokenAmount(amountInWei);

        _preValidatePurchase(recipient, purchaseTokens);
        
        _updateState();

        if (purchaseTokens > tokensForSale || block.timestamp > auctionEnd) {
            purchaseTokens = tokensForSale;
            _inAdvanceEnd();
        }
        _updatePurchase(recipient, purchaseTokens,amountInWei);

        _forwardFunds();

        emit Bid(recipient, purchaseTokens, amountInWei);
    }

    function end() virtual external {
        //TODO time is up and moderator must call it to get if tokens exists
        require(stage == Stage.ACTIVE_NO_SUPPLY || block.timestamp > auctionEnd);
        _endAuction();
        stage = Stage.FINISHED;
    }

    function _inAdvanceEnd() internal virtual {
        require(stage == Stage.ACTIVE,"auction:active stage");
        stage = Stage.ACTIVE_NO_SUPPLY;
    }

    function getPrice() virtual external view returns(uint256) {
        return WEI.div(rate);
    }

    function _calcTokenAmount(uint256 weiAmount) virtual internal view returns (uint256) {
        return rate.mul(weiAmount);
    }

    function getRemainderTokens() external view returns(uint256) {
        return tokensForSale;
    }
     
    function _preValidatePurchase(address recipient, uint256 tokens) internal virtual view {
        require(recipient != address(0), "auction: beneficiary is the zero address");
        require(tokens != 0 ,"auction: tokens is not correct amount");
    }

    function _processPurchase(address recipient, uint256 tokens) internal virtual {
        //overrdide         
    }

    function _updatePurchase(address recipient, uint256 tokens,uint256 amountInWei) internal virtual {
        //overrdide
    }

    function _forwardFunds() internal virtual {
        //overrdide
    }
    
    function _updateState() internal virtual {
        // override if needed
    }

    function _endAuction() internal virtual {
        // override if needed
    }
}

contract Auction is BaseAuction {
    using SafeMath for uint256;

    constructor(uint256 _rate, address moderator ,address _token, uint256 _tokensForSale, uint256 _totalSupply)
        BaseAuction(_rate,moderator,_token,_tokensForSale,_totalSupply) {
    }

    function _inAdvanceEnd() internal override {
        require(stage == Stage.ACTIVE,"auction:active stage");
        stage = Stage.ACTIVE_NO_SUPPLY;
    }

    
    function _calcTokenAmount(uint256 weiAmount) override internal view returns (uint256) {
        return rate.mul(weiAmount);
    }
     

    function _processPurchase(address recipient, uint256 tokens) internal override {
        token.transfer(recipient, tokens);
    }

    function _updatePurchase(address recipient, uint256 tokens,uint256 amountInWei) internal override virtual {
        tokensForSale = tokensForSale.sub(tokens);
        token.transfer(recipient, tokens);
    }

    function _forwardFunds() override internal virtual  {
        payable(wallet).transfer(msg.value);
    }
    
    function _updateState() override internal virtual  {
        // override if needed
    }

    function _endAuction() override virtual internal {
        if (tokensForSale != 0 ) {
            _processPurchase(wallet,tokensForSale);
            tokensForSale = 0;
        }
    }
}

contract DutchAuction is Auction {
    using SafeMath for uint256;

    uint256 private maxReserveRate;

    // bid balances WEI
    mapping(address => uint256) private _balancesWEI;
    
    // two structs to imitate set collection in other languages
    mapping(address => bool) private participants;
    address[] private participantsAddresses;
    

    constructor(uint256 _rate, uint256 _maxRate, address moderator ,address _token, uint256 _tokensForSale) Auction(_rate,  moderator , _token,  _tokensForSale,0) {
            require(_rate < _maxRate,"the price cannot go up max rate");
            maxReserveRate = _maxRate;
    }

    // distrbute the tokens to their holder
    function _endAuction() virtual internal override {
        
        uint256 finalRate = 0;
        // distribute the tokens and

        for(uint i = 0; i < participantsAddresses.length; i++) {
            address current = participantsAddresses[i];
            uint256 amountInWei = _balancesWEI[current];
            uint256 purchaseTokens = finalRate.mul(amountInWei);
            token.transfer(current, purchaseTokens);
            payable(wallet).transfer(amountInWei);
        }
        
    }

    function getPrice() virtual override external view returns(uint256) {
        return _calcRateAddition();
    }

    // translate block.timestamp in [auctionStart;auctionEnd] to [1,10] 
    function _calcRateAddition() view internal returns(uint256) {
        uint256 current = block.timestamp;
        return _remapRange(current,auctionStart,auctionEnd,rate,maxReserveRate);
    }
    
    function _remapRange(uint256 x, uint256 a, uint256 b,uint256 c,uint256 d) internal pure returns(uint256) {
        uint256 XdivA = x.div(a);
        uint256 DdivC = d.sub(c);
        uint256 BsubA = b.sub(a);
        uint256 first = XdivA.mul(DdivC);
        first = first.div(BsubA);
        return first.add(c);
    }

    function _updateState() override internal {
        rate = _calcRateAddition();
    }
    
    function _updatePurchase(address recipient, uint256 tokens, uint256 amountInWei) override internal {
        _balancesWEI[recipient] = _balancesWEI[recipient].add(amountInWei);
        participantsAddresses.push(recipient);
        participants[recipient] = true;
    }

    function _preValidatePurchase(address recipient, uint256 tokens) internal override view {
        require(!participants[recipient], "auction:only one purchase per address");
        super._preValidatePurchase(recipient,tokens);
    }

    function _forwardFunds() override internal {
        // we do not forward tokens before token sale ends
    }


}
