//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./Offering.sol";

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "hardhat/console.sol";

/**
 * @dev Implementation of the {ERC20} interface.
 *
 * ERC20 contract that holds a single NFT, which is represented
 * as {totalSupply} ERC20 tokens.
 * Must implement ERC721Holder to successfully use IERC721.safeTransferFrom by factory contract
 */
contract ERC20FractionToken is ERC20, ERC721Holder {
    using SafeMath for uint256;
    
    // state for every ERC20FractionToken
    // the state variable is one directional(straightforward),
    enum Stage {
        NEW,
        ACTIVE,
        FINISH,
        BUYBACK
    }
    
    address immutable private nftAddress;

    uint256 immutable private id;

    address immutable private moderatorNFT;

    Auction private auction;

    bool private hasAuction;


    constructor(string memory _tokenName, string memory _tokenSymbol, address _tokenContractAddress, address _moderatorNFT, uint256 _tokenId, uint256 _tokenSupply) ERC20(_tokenName,_tokenSymbol) {
       nftAddress = _tokenContractAddress;
       id = _tokenId;
       moderatorNFT = _moderatorNFT;
       _mint(_moderatorNFT,_tokenSupply);
       hasAuction = false;
    }

    function startOffering(uint256 _pricePerToken, uint256 _tokensForSale ) external virtual {
        require(msg.sender == moderatorNFT," nft moderator can start soffering");
        require(_tokensForSale < moderatorTokens(),"offering: moderator tokens > offering token");
        auction = new Auction(1, moderatorNFT, address(this), _tokensForSale, totalSupply());
        approve(address(auction), _tokensForSale);
        transfer(address(auction), _tokensForSale);
        console.log("ERC20FractionToken auction auction",address(auction));
        hasAuction = true;
    }

    function bid() virtual external payable {
        // validateSenderAndAmount(msg.sender, amount);
        // require(block.timestamp < offeringEnd, "offering: offeringended");
        
        // if(amountRaised.add(amount) <= maxCap ){
            // uint256 change = maxCap.sub(amountRaised);
            // send back to user change wei
            // finish the auction
            // stage = Stage.FINISH;
        // }else {
            // 
        // }
        // amountRaised = amountRaised.add(amount);
        // tokensForSale = tokensForSale.sub(amount);
        // console.log("sender",msg.sender,"tokens",tokensForSale);
        // bids.push(Bid(msg.sender, amount));
        console.log("ERC20FractionToken: msg.sender",msg.sender,"msg.value",msg.value);
        // auction.bid{value:msg.value}();
        Offering(address(auction)).bid();
        console.log("ERC20FractionToken: msg.value",msg.value);
        
    }

    function endOffering() external virtual {
    
    }

    function getPrice() external view returns(uint256) {
        return auction.getPrice();
    }

    function getRemainderTokens() external view returns(uint256) {
        return auction.getRemainderTokens();
    }

    function getAmountRaised() external view returns(uint256) {
        return auction.getAmountRaised();
    }

    function buyback() external {
        // must have 100% of the tokens
        uint256 supply = totalSupply();
        require(balanceOf(msg.sender) == supply,"msg.sender must have all tokens");        
        _burn(msg.sender,totalSupply());
        IERC721(nftAddress).transferFrom(address(this), msg.sender, id);   
    }

    function moderatorTokens() private view returns(uint256) {
        return balanceOf(moderatorNFT);
    }

    function validateSenderAndAmount(address bidder, uint256 amount ) private pure {
        require(bidder != address(0), "bidder is the zero address");
        // TODO bidder has not played
        require(amount != 0, "weiAmount is 0");
        // require(amountRaised.add(amount) <= maxCap, "tokensForSale exceededs");
    }

    function auctionContract() external view returns(Auction) {
        return auction;
    }
}