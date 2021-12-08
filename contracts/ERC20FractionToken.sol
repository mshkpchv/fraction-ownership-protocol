//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

/**
 * @dev Implementation of the {ERC20} interface.
 *
 * ERC20 contract from NFT to N ERC20 tokens.
 * Must implement ERC721Holder to successfully use IERC721.safeTransferFrom by factory contract
 */
contract ERC20FractionToken is ERC20,ERC721Holder {

    address immutable private token;

    uint256 immutable private id;

    address immutable private nftOwner;

    address immutable public fractionToken;

    
    constructor(string memory _tokenName, string memory _tokenSymbol, address _tokenContractAddress, address _nftOwner, uint256 _tokenId, uint256 _tokenSupply) ERC20(_tokenName,_tokenSymbol) {
       token = _tokenContractAddress;
       id = _tokenId;
       nftOwner = _nftOwner;
       fractionToken = address(this);

       _mint(_nftOwner,_tokenSupply);
    }

    function createOfferingAuction() public {

    }


    
}