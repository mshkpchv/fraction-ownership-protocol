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
    
    address immutable private nftAddress;

    uint256 immutable private id;

    address immutable private moderatorNFT;

    Auction private auction;

    event Buyback(address buyer);

    modifier hasAuction {
        require(
            address(auction) != address(0),
            "There must be auction!"
        );
        _;
    }

    constructor(string memory _tokenName, string memory _tokenSymbol, address _tokenContractAddress, address _moderatorNFT, uint256 _tokenId, uint256 _tokenSupply) ERC20(_tokenName,_tokenSymbol) {
       nftAddress = _tokenContractAddress;
       id = _tokenId;
       moderatorNFT = _moderatorNFT;
       _mint(_moderatorNFT,_tokenSupply);
    }

    //TODO auction type
    function startOffering(uint256 _rate, uint256 _tokensForSale) external virtual returns(address) {
        require(msg.sender == moderatorNFT," nft moderator can start soffering");
        require(_tokensForSale < balanceOf(moderatorNFT),"offering: moderator tokens > offering token");
        require(address(auction) == address(0),"auction:started only one time");
        require(_rate > 0,"auction:rate >= 0");

        auction = new Auction(_rate, moderatorNFT, address(this), _tokensForSale, totalSupply());
        // approve(address(auction), _tokensForSale);
        transfer(address(auction), _tokensForSale);
        auction.start();

        console.log("ERC20FractionToken auction auction", address(auction));
        return address(auction);
    }

    function bid() hasAuction virtual external payable hasAuction {      
        console.log("ERC20FractionToken: msg.sender", msg.sender,"msg.value",msg.value);    
        auction.bid{value:msg.value}(msg.sender);
    }

    function buyback() external {
        // must have 100% of the tokens
        uint256 supply = totalSupply();
        address sender = msg.sender;
        require(balanceOf(sender) == supply,"msg.sender must have all tokens");        
        _burn(sender,totalSupply());
        IERC721(nftAddress).transferFrom(address(this), sender, id);
        emit Buyback(sender);   
    }

    function endOffering() external virtual hasAuction {
        auction.end();
    }

    function getPrice() external view hasAuction returns(uint256) {
        return auction.getPrice();
    }

    function getRemainderTokens() external view hasAuction returns(uint256) {
        return auction.getRemainderTokens();
    }

    function auctionAddress() external view  hasAuction returns(Auction)  {
        return auction;
    }
}