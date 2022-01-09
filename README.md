# NFT Fractional protocol

## Architecture


![Alt text](docs/architecture.png?raw=true "Architecture")

## Information

Smart Contract protocol where a user can deposit an NFT and fractionalize it into a number of ERC20 tokens called fractions. The user can to create an offering for the fractions. Other users could choose and buy fractions at the specified time.

### Run the tests

1. Test the contracts

```bash
    npm hardhat test
```

```bash
    npm hardhat coverage
```

2. Production

- rinkeby etherscan: https://rinkeby.etherscan.io/address/0x202d263303fA8D37ef770a686e9c806e486AC0Ae

### Smart Contracts
- ERC20FractionTokenFactory
- ERC20FractionToken
- IAuction

ERC20FractionTokenFactory contract has only one function: to create new ERC20FractionToken contracts, that are backed up by single IERC721 NFT.

<b>ERC20FractionTokenFactory.create</b> initializes the ERC20FractionToken smart contract and mints the total supply. After the ERC20FractionToken is initialized, ERC20FractionTokenFactory transfers the NFT to it.
Before that transfer of NFT, the user must call 

<b>(ERC721)NFT.approve(ERC20FractionTokenFactory.address)</b>


```bash

In order to create a fraction, the ERC20FractionTokenFactory.create needs the following parameters:

name — new name use for ERC20
symbol — new ERC20 symbol
token — NFT contract address
id — NFT id
suply — the max supply of ERC20 Contract

```

# Auctions


Auction specifics:

- time based
- supply based
 
Currently, the project provide types of auction:
- First bid, first buy action
- Dutch Auction
! feel free to implement IAuction interface and provide other types of auctions

Every auction must implement this interface:

```{solidity}

interface IAuction {

    function start(uint256 _tokensForSale);

    function bid(address recipient)  payable;

    function end();

    function getPrice()  view returns(uint256);

    function getRemainderTokens() view returns(uint256);

}
```
## Initiating an auction


An auction can be kicked off by creating contract instance of <b>IAuction interface</b> and calling <b>ERC20FractionTokenFactory#startOffering</b>

<b>ERC20FractionToken#startOffering</b> can be called only with the condition:
- the msg.sender must have all the minted ERC20 tokens

## Bidding an auction
Other bidders can submit their bids by calling ERC20FractionToken#bid. Each bid is payable, but if it doesn`t succeed,
the ethers/wei are given back.

## Ending an auction
depending on the specifics of the Auction, <b>ERC20FractionToken.end</b> is very different. See implementaion for more info.
