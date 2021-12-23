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

    // offering variables

    // @dev price per Token
    uint256 private pricePerToken;
    
    // @dev price per Token, zero if there are not offering
    uint256 private tokensForSale;

    // @dev the max tokens(in wei) for offering 
    uint256 private maxCap;

    //@dev amount of wei raised, after offering must go to NFT moderator
    uint256 private amountRaised;

    Stage public stage;

    // offering length variables

    uint256 public offeringEnd;

    uint256 private offeringLength;
        
    uint256 private offeringStart;

    struct Bid {
        address sender;
        uint256 amount;
    }
    address[] private bidders; 
    Bid[] public bids;


    constructor(string memory _tokenName, string memory _tokenSymbol, address _tokenContractAddress, address _moderatorNFT, uint256 _tokenId, uint256 _tokenSupply) ERC20(_tokenName,_tokenSymbol) {
       nftAddress = _tokenContractAddress;
       id = _tokenId;
       moderatorNFT = _moderatorNFT;
       _mint(_moderatorNFT,_tokenSupply);
       stage = Stage.NEW;
    }

    function startOffering(uint256 _pricePerToken, uint256 _tokensForSale ) external virtual {
        require(stage == Stage.NEW,"offering: can start single time");
        require(msg.sender == moderatorNFT,"nft moderator can start offering");
        require(_tokensForSale < moderatorTokens(),"offering: moderator tokens > offering token");
        
        offeringEnd = block.timestamp + offeringLength;

        pricePerToken = _pricePerToken;
        tokensForSale = _tokensForSale;
        maxCap = _tokensForSale;
        // transfer this token to the contact itself for security reasons
        transfer(address(this), tokensForSale);

        stage = Stage.ACTIVE;
    }

    function bid() virtual external payable {
        require(stage == Stage.ACTIVE,"offering: allowed only in Active state");
        uint256 amount = msg.value;
        validateSenderAndAmount(msg.sender, amount);
        require(block.timestamp < offeringEnd, "offering: offeringended");
        
        if(amountRaised.add(amount) <= maxCap ){
            uint256 change = maxCap.sub(amountRaised);
            // send back to user change wei
            // finish the auction
            // stage = Stage.FINISH;
        }else {
            // 
        }
        amountRaised = amountRaised.add(amount);
        tokensForSale = tokensForSale.sub(amount);
        // console.log("sender",msg.sender,"tokens",tokensForSale);
        bids.push(Bid(msg.sender, amount));

        //TODO finish the sale if capacity is max
    }

    function endOffering() external virtual {
        require(stage == Stage.ACTIVE,"offering: allowed only in Active state");
        require(block.timestamp >= offeringEnd, "end:auction live");
        stage = Stage.FINISH;

        distributeTokensAndEthers();
    }

    function getPrice() external view returns(uint256) {
        return pricePerToken;
    }

    function getRemainderTokens() external view returns(uint256) {
        return tokensForSale;
    }

    function getAmountRaised() external view returns(uint256) {
        return amountRaised;
    }

    function buyback() external {
        // todo 100 % owner of the tokens
        require(msg.sender == moderatorNFT,"msg.sender must be moderator");
        _burn(msg.sender,totalSupply());
        // transfer back the nft to the owner
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

    function distributeTokensAndEthers() internal {
        
    }
}