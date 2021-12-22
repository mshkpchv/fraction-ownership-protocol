//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./Offering.sol";

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

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
    enum OfferingState {
        NEW,
        ACTIVE,
        FINISH,
        BUYBACK
    }
    
    address immutable private nftAddress;

    uint256 immutable private id;

    address immutable private nftOwner;

    // offering variables
    // @dev rate for which 1 Wei is mapped to 1 FractionWei
    uint256 private immutable rate = 1;

    // @dev price per Token
    uint256 private pricePerToken;
    
    // @dev price per Token, zero if there are not offering
    uint256 private offeringTokens;

    // @dev the max tokens(in wei) for offering 
    uint256 private cap;

    //@dev amount of wei raised, after offering must go to NFT moderator
    uint256 private weiRaised;

    

    OfferingState public offeringState;
    
    constructor(string memory _tokenName, string memory _tokenSymbol, address _tokenContractAddress, address _nftOwner, uint256 _tokenId, uint256 _tokenSupply) ERC20(_tokenName,_tokenSymbol) {
       nftAddress = _tokenContractAddress;
       id = _tokenId;
       nftOwner = _nftOwner;
       _mint(_nftOwner,_tokenSupply);
       offeringState = OfferingState.NEW;
    }

    function startOffering(uint256 _pricePerToken, uint256 _tokenCount ) external virtual {
        require(offeringState == OfferingState.NEW,"offering: can be started just one time");
        require(msg.sender == nftOwner,"only nft moderator can start offering");
        require(_tokenCount < moderatorTokens(),"offering: moderator tokens > offering token");

        pricePerToken = _pricePerToken;
        offeringTokens = _tokenCount;
        cap = _tokenCount;
        
        // transfer this token to the contact itself for security reasons
        transfer(address(this), offeringTokens);

        offeringState = OfferingState.ACTIVE;
    }

    function bid() virtual external payable {
        require(offeringState == OfferingState.ACTIVE,"offering: allowed only in Active state");
        uint256 weiAmount = msg.value;
        preValidatePurchase(msg.sender, weiAmount); 
        // add the weiRaised
        weiRaised = weiRaised.add(weiAmount);
        offeringTokens = offeringTokens - weiRaised;
        uint256 tokens = calcTokenAmount(weiAmount);
       
        transfer(msg.sender,tokens);
    }

    function endOffering() external virtual {

    }

    function getPrice() external view returns(uint256) {
        return pricePerToken;
    }

    function calcTokenAmount(uint256 weiAmount) internal pure returns(uint256) {
        return weiAmount.mul(rate);
    }

    function preValidatePurchase(address participant, uint256 weiAmount ) internal view {
        require(participant != address(0), "participant is the zero address");
        require(weiAmount != 0, "weiAmount is 0");
        require(weiRaised.add(weiAmount) <= offeringTokens, "offeringTokens exceededs");
    }

    function buyback() external {
        // todo 100 % owner of the tokens
        require(msg.sender == nftOwner,"msg.sender must be the nft owner");
        _burn(msg.sender,totalSupply());
        // transfer back the nft to the owner
        IERC721(nftAddress).transferFrom(address(this), msg.sender, id);   
    }

    function moderatorTokens() private view returns(uint256) {
        return balanceOf(nftOwner);
    }

}