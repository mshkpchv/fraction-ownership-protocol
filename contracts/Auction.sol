//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";


interface IAuction {

    function start(uint256 _tokensForSale) external ;

    function bid(address recipient) external payable;

    function end() external;

    function getPrice() external view returns(uint256);

    function getRemainderTokens() external view returns(uint256);

}

/**
 Base Auction contract implemeting the interface and making some abstract methods
 for easy plugin to auction contract
 */
abstract contract BaseAuction is IAuction {
    using SafeMath for uint256;

    uint256 internal constant WEI = 10**18;

    uint256 internal constant MIN_AUCTION_LENGTH = 10 seconds;

    // stages which every auction could move into
    //
    //                    --->ACTIVE_NO_SUPPLY ----> FINISHED 
    // INACTIVE -> ACTIVE |----------------------> FINISHED
    //
    enum Stage {
        INACTIVE,
        ACTIVE,
        ACTIVE_NO_SUPPLY,
        FINISHED
    }

    Stage public stage;

    // The IERC20 token being sold
    IERC20 internal token;

    // Address where funds are collected
    address internal wallet;

    // The rate is the conversion between wei and the smallest and indivisible token unit.
    uint256 internal rate;

    //TODO solidity does not support double numbers, so we cannot use weiAmount * 0.1
    // we must use weiAmount / 10 = weiAmount * 0,1. For this we need indicator to know
    // when to multiply or divide
    bool internal ratePositive;

    // tokens for sale in format n * 10**18
    uint256 internal tokensForSale;

    // 
    // auction length params 
    //
    uint256 public auctionStart;

    uint256 public auctionEnd;

    uint256 public auctionLength;


    event Start(address buyer, uint256 tokensForSale);

    event Bid(address buyer, uint256 purchasedTokens, uint256 weiAmount);

    event End();


    constructor(uint256 _rate, address moderator ,address _token , uint256 _auctionLength) {
        rate = _rate;
        token = IERC20(_token);
        wallet = moderator;

        if (_auctionLength < MIN_AUCTION_LENGTH ){
            _auctionLength = MIN_AUCTION_LENGTH;
        }
        auctionLength = _auctionLength;
        stage = Stage.INACTIVE;
    }

    function start(uint256 _tokensForSale) virtual external override {
        require(stage == Stage.INACTIVE,"auction: inactive stage");
        
        auctionStart = block.timestamp;
        auctionEnd = block.timestamp + auctionLength;
        tokensForSale = _tokensForSale;

        stage = Stage.ACTIVE;

        _startAuction();

    }

    function bid(address recipient) external payable override {
        require(stage == Stage.ACTIVE,"auction:active stage only");
        require(block.timestamp < auctionEnd, "auction: time ended");
        
        bool successUpdateState =  _tryUpdateStateBeforePurchase();
        require(successUpdateState,"auction: tokens sold out");
        // state cannot be changed, beucase of out of supply or something 

        uint256 amountInWei = msg.value;
        uint256 purchaseTokens = _calcTokenAmount(amountInWei);

        _preValidatePurchase(recipient, purchaseTokens);
    
        if (purchaseTokens > tokensForSale) {
            purchaseTokens = tokensForSale;
            // _inAdvanceEnd();
        }
        _updatePurchase(recipient, purchaseTokens, amountInWei);

        _forwardFunds();

        emit Bid(recipient, purchaseTokens, amountInWei);
    }

    function end() virtual external override {
        //TODO time is up and moderator must call it to get if tokens exists
        require(stage == Stage.ACTIVE || stage == Stage.ACTIVE_NO_SUPPLY);
        // require(block.timestamp > auctionEnd,"auction:not finished yet");

        _endAuction();
        stage = Stage.FINISHED;

        emit End();
    }

    function getPrice() virtual external view override returns(uint256) {
        return WEI.div(rate);
    }

    function getRemainderTokens() virtual external view override returns(uint256) {
        return tokensForSale;
    }

    function _inAdvanceEnd() internal virtual {   
        // require(stage == Stage.ACTIVE,"auction:active stage");
        // stage = Stage.ACTIVE_NO_SUPPLY;
    }

    function _calcTokenAmount(uint256 weiAmount) virtual internal view  returns (uint256) {
        return rate.mul(weiAmount);
    }
     
    function _preValidatePurchase(address recipient, uint256 tokens) internal virtual view {
        require(tokensForSale > 0,"auction: tokens sold out");
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
    
    function _tryUpdateStateBeforePurchase() internal virtual returns(bool) {
        return true;
    }

    function _endAuction() internal virtual {
        // override if needed
    }

    function _startAuction() internal virtual {
        // override if needed
    }


}

/**
 Auction contract implemeting the logic for hosting
 Ducth auctions
 */
contract FIFOAuction is BaseAuction {
    using SafeMath for uint256;

    constructor(uint256 _rate, address moderator ,address _token, uint256 _auctionLength)
        BaseAuction(_rate, moderator, _token, _auctionLength) {
    }

    function _calcTokenAmount(uint256 weiAmount) override internal view returns (uint256) {
        return rate.mul(weiAmount);
    }
    
    function _processPurchase(address recipient, uint256 tokens) internal override {
        token.transfer(recipient, tokens);
    }

    function _updatePurchase(address recipient, uint256 tokens, uint256 amountInWei) internal override virtual {
        token.transfer(recipient, tokens);
        tokensForSale = tokensForSale.sub(tokens);
    }

    function _forwardFunds() override internal virtual  {
        payable(wallet).transfer(msg.value);
    }
    
    function _tryUpdateStateBeforePurchase() override internal virtual returns(bool)  {
        // override if needed
        return true;
    }

    function _endAuction() override virtual internal {
        if (tokensForSale != 0 ) {
            _processPurchase(wallet,tokensForSale);
            tokensForSale = 0;
        }
    }
}

/**
 Auction contract implemeting the logic for hosting
 Ducth auctions
 */
contract DutchAuction is BaseAuction {
    using SafeMath for uint256;

    uint256 private maxReserveRate;
    uint256 private finalRateForDistribution;

    uint256 private amountInWeiRaised;
    uint256 private allTokensForSale;

    // bid balances WEI
    mapping(address => uint256) private _balancesWEI;
    
    // two structs to imitate set collection in other languages
    mapping(address => bool) private participants;
    address[] private participantsAddresses;
    

    constructor(uint256 _rate, uint256 _maxRate, address moderator ,address _token,uint256 _auctionLength) BaseAuction(_rate,  moderator , _token, _auctionLength) {
            require(_rate < _maxRate,"the price cannot go up max rate");
            maxReserveRate = _maxRate;
            finalRateForDistribution = _rate;

    }

    function _startAuction() internal virtual override {
        allTokensForSale = tokensForSale;
    }

    // distrbute the tokens to their holder
    function _endAuction() virtual internal override {        
        // distribute the tokens and
        for(uint i = 0; i < participantsAddresses.length; i++) {
            address current = participantsAddresses[i];
            uint256 amountInWei = _balancesWEI[current];

            uint256 purchaseTokens = finalRateForDistribution.mul(amountInWei);

            token.transfer(current, purchaseTokens);
            payable(wallet).transfer(amountInWei);
        }
        
    }

    function getPrice() virtual override external view returns(uint256) {
        return WEI.div(_calcRateAddition());
    }

    function _tryUpdateStateBeforePurchase() override internal returns(bool) {
        uint256 currentRate = _calcRateAddition();
        uint256 remainderTokens = _calcRemainderTokens(currentRate);
        if(remainderTokens < 0) {
            return false;
        }
        rate = currentRate;
        finalRateForDistribution = currentRate;
        tokensForSale = remainderTokens;
        return true;
    }
    
    function _updatePurchase(address recipient, uint256 tokens, uint256 amountInWei) override internal {
        _balancesWEI[recipient] = _balancesWEI[recipient].add(amountInWei);
        participantsAddresses.push(recipient);
        tokensForSale = tokensForSale - tokens;
        amountInWeiRaised = amountInWeiRaised.add(amountInWei);
        participants[recipient] = true;
    }

    // TODO check if rate > from everything
    function _preValidatePurchase(address recipient, uint256 tokens) internal override view {
        require(!participants[recipient], "auction:only one purchase per address");
        super._preValidatePurchase(recipient,tokens);
    }

    function getRemainderTokens() override external view returns(uint256) {
        return _calcRemainderTokens();
    }
    
    function _calcRemainderTokens() internal view returns(uint256) {
        return _calcRemainderTokens(rate);
    }

    function _calcRemainderTokens(uint256 _rate) internal view returns(uint256) {
        uint256 temp = _rate.mul(amountInWeiRaised);
        if (allTokensForSale >= temp){
            return allTokensForSale.sub(temp);
        }
        return 0;
    }

    // translate block.timestamp in [auctionStart;auctionEnd] to [1,10] 
    function _calcRateAddition() view internal returns(uint256) {
        uint256 currentTimestamp = block.timestamp;
        uint256 newRate = _remapRange(currentTimestamp,auctionStart,auctionEnd,rate,maxReserveRate);
        return newRate;
    }
    
    function _remapRange(uint256 x, uint256 a, uint256 b, uint256 c, uint256 d) internal pure returns(uint256) {
        uint256 XdivA = x.div(a);
        uint256 DdivC = d.sub(c);
        uint256 BsubA = b.sub(a);
        uint256 first = XdivA.mul(DdivC);
        first = first.div(BsubA);
        return first.add(c);
    }

}
