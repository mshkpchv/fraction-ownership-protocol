//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC20FractionToken.sol";

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";


contract ERC20FractionTokenFactory is Ownable {

    ERC20FractionToken[] public tokens;
    mapping(address=>address) public userToTokens;
    
    /**
     * @dev 
     * _tokenName: name of new the ERC-20 token which will represent the fractional ownership of your NFT
     * _tokenSymbol: symbol  of the  fractions, like (ETH,BTC)
     * _tokenContractAddress: contract address of the NFT which you are choosing to fractionalize,you msg.sender must own it
     * _tokenId: identifier used for your ERC-721 NFT in its respective smart contract
     */
    function createERC20FractionToken(string memory _tokenName,string memory _tokenSymbol, address _tokenContractAddress, uint256 _tokenId,uint256 _tokenSuply) public {
        // create a new ERC20Token with the NFT 
        ERC20FractionToken token = new ERC20FractionToken(_tokenName,_tokenSymbol,_tokenContractAddress, msg.sender, _tokenId, _tokenSuply);
        // transfer the nft from owner to new erc20 contract
        // the owner of the nft must be msg.sender and _tokenId must be ownd by msg.sender
        IERC721(_tokenContractAddress).safeTransferFrom(msg.sender,address(token),_tokenId);
        tokens.push(token);
        userToTokens[msg.sender] = address(token);
    }
    
}