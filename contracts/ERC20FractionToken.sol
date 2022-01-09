//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./Auction.sol";

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

    IAuction private auction;

    event Buyback(address buyer);

    modifier activeAuction {
        require(
            address(auction) != address(0),
            "auction:not started"
        );
        _;
    }

    constructor(string memory _tokenName, string memory _tokenSymbol, address _tokenContractAddress, address _moderatorNFT, uint256 _tokenId, uint256 _tokenSupply) ERC20(_tokenName,_tokenSymbol) {
       nftAddress = _tokenContractAddress;
       id = _tokenId;
       moderatorNFT = _moderatorNFT;
       _mint(_moderatorNFT,_tokenSupply);
    }

    /**
     * @dev start auction for  tokens 
     * @param _auction: auction address which is IAuction compatible
     * @param _tokensForSale: number of tokens to be transfer to the auction contract
     */
    function startOffering(address _auction, uint256 _tokensForSale) external virtual {
        require(msg.sender == moderatorNFT,"nft moderator can start soffering");
        require(_tokensForSale <= balanceOf(moderatorNFT),"offering: moderator tokens > offering token");
        require(address(_auction) != address(0),"auction: need valid auction");
        // TODO check if _auction is subtype of Auction

        auction = IAuction(_auction);
        // // approve(address(auction), _tokensForSale);
        transfer(address(auction), _tokensForSale);
        auction.start(_tokensForSale);
    }

        /**
     * @dev buyback the NFT if you have the all the tokens
     */
    function buyback() external {
        // must have 100% of the tokens
        uint256 supply = totalSupply();
        address sender = msg.sender;
        require(balanceOf(sender) == supply,"msg.sender must have all tokens");        
        _burn(sender,totalSupply());
        IERC721(nftAddress).transferFrom(address(this), sender, id);
        emit Buyback(sender);   
    }


    function bid() virtual external payable activeAuction {      
        auction.bid{value:msg.value}(msg.sender);
    }

    function endOffering() external virtual activeAuction {
        auction.end();
    }

    function getPrice() external view  activeAuction returns(uint256) {
        return auction.getPrice();
    }

    function getRemainderTokens() external view activeAuction returns(uint256) {
        return auction.getRemainderTokens();
    }

    function auctionAddress() external view  activeAuction returns(IAuction)  {
        return auction;
    }
}