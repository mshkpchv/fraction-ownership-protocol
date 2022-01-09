//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./ERC20FractionToken.sol";

contract ERC20FractionTokenFactory {

    ERC20FractionToken[] public tokens;
    uint256 public tokenCount;
    
    event FractionEvent(address tokenContractAddress, uint256 tokenId,address fractionContractAddress, uint256 tokenIndex);
    
    /**
     * @dev create new ERC20 contract which is holder for the NFT
     * @param _tokenName: name of new the ERC-20 token which will represent the fractional ownership of your NFT
     * @param _tokenSymbol: symbol  of the  fractions, like (ETH,BTC)
     * @param _tokenContractAddress: contract address of the NFT which you are choosing to fractionalize,you msg.sender must own it
     * @param _tokenId: identifier used for your ERC-721 NFT in its respective smart contract
     * @param _tokenId: identifier used for your ERC-721 NFT in its respective smart contract
     */
    function create(string memory _tokenName,string memory _tokenSymbol, address _tokenContractAddress, uint256 _tokenId, uint256 _tokenSuply) public {
        ERC20FractionToken token = new ERC20FractionToken(_tokenName,_tokenSymbol,_tokenContractAddress, msg.sender, _tokenId, _tokenSuply);
        // transfer the nft from owner to new erc20 contract
        // the owner of the nft must be msg.sender and _tokenId must be ownd by msg.sender
        // also the owner must call IERC721.approve with address(this) before call safeTransferFrom
        IERC721(_tokenContractAddress).transferFrom(msg.sender,address(token),_tokenId);
        tokens.push(token);
        tokenCount++;        
        emit FractionEvent(_tokenContractAddress, _tokenId, address(token), tokenCount - 1);
    }
}