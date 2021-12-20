//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./Offering.sol";

/**
 * @dev Implementation of the {ERC20} interface.
 *
 * ERC20 contract that holds a single NFT, which is represented
 * as {totalSupply} ERC20 tokens.
 * Must implement ERC721Holder to successfully use IERC721.safeTransferFrom by factory contract
 */
contract ERC20FractionToken is ERC20, ERC721Holder, Offering {
    
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

    uint256 private tokenFixedPrice;

    OfferingState public offeringState;
    
    constructor(string memory _tokenName, string memory _tokenSymbol, address _tokenContractAddress, address _nftOwner, uint256 _tokenId, uint256 _tokenSupply) ERC20(_tokenName,_tokenSymbol) {
       nftAddress = _tokenContractAddress;
       id = _tokenId;
       nftOwner = _nftOwner;
       _mint(_nftOwner,_tokenSupply);
       offeringState = OfferingState.NEW;
    }

    function startOffering(uint256 _tokenFixedPrice) external virtual override {
        require(offeringState == OfferingState.NEW,"start Offering occur only one");
        require(msg.sender == nftOwner,"only the nft owner can start the offering");

        offeringState = OfferingState.ACTIVE;
        tokenFixedPrice = _tokenFixedPrice;
    }

    function bid() virtual override external payable {
        require(offeringState == OfferingState.ACTIVE,"bidding allowed only in active offering");
        // require();

    }

    function endOffering() override external virtual {

    }



    function buyback() external {
        require(msg.sender == nftOwner,"msg.sender must be the nft owner");
        _burn(msg.sender,totalSupply());
        // transfer back the nft to the owner
        IERC721(nftAddress).transferFrom(address(this), msg.sender, id);   
    }

}