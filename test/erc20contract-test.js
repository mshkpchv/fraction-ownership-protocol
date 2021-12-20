const hre  = require("hardhat");
const ethers = hre.ethers;
const { expect } = require("chai");
const utils = require("./test-contracts/utils.js");

describe("ERC20FractionToken", function () {
  let FRACTION_CONTRACT = null;
  let NFTContract = null;
  let nftContractTokenId = null;
  let wallet = null;
  let mintNFTnumber = 1;
  let ERC20FractionTokenObj = null;
  let erc20abi = null;
  let fractionabi = null;

  let tokenName = "Misho";
  let tokenSymbol = "MSH";

  before(async function(){
    wallet = await ethers.getSigner()
    const [contract,ids ] = await utils.deployAndMintNFT(wallet,mintNFTnumber);
    NFTContract = contract;
    tokenIds = ids;
    nftContractTokenId = tokenIds[0];

    
    const fractionFactory = await ethers.getContractFactory("ERC20FractionTokenFactory", wallet);
    FRACTION_CONTRACT = await fractionFactory.deploy();
    await FRACTION_CONTRACT.deployed();

    
    ERC20FractionTokenObj = await utils.doFractionNFT(wallet,FRACTION_CONTRACT,
        NFTContract,nftContractTokenId,tokenName,tokenSymbol,500);

    erc20abi = [
        // Read-Only Functions
        "function balanceOf(address owner) view returns (uint256)",
        "function decimals() view returns (uint8)",
        "function symbol() view returns (string)",
        "function name() view returns (string)",
        "function totalSupply() view returns (uint256)",
    
        // Authenticated Functions
        "function transfer(address to, uint amount) returns (bool)",
    
        // Events
        "event Transfer(address indexed from, address indexed to, uint amount)"
    ];

    fractionabi = erc20abi.concat([
        "function buyback()"
    ]);


  })

  it("should fractionContract be ERC20 compatible", async function(){
    
    
    const fractionContract = new ethers.Contract(ERC20FractionTokenObj.fractionContractAddress,erc20abi,wallet);
    
    expect(await fractionContract.symbol()).to.be.equal(tokenSymbol);
    expect(await fractionContract.name()).to.be.equal(tokenName);
    expect(await fractionContract.decimals()).to.be.equal(18);

    let walletAddress = await wallet.getAddress();
    expect(await fractionContract.balanceOf(walletAddress)).to.be.equal(500);
    expect(await fractionContract.totalSupply()).to.be.equal(500);


  });

  it("should random wallet to have 0 ERC20 tokens", async function(){
    let randomWallet = utils.createRandomWallet(wallet.provider);

    const fractionContract = new ethers.Contract(ERC20FractionTokenObj.fractionContractAddress, erc20abi, randomWallet);    

    let walletAddress = await randomWallet.getAddress();
    expect(await fractionContract.balanceOf(walletAddress)).to.be.equal(0);
    expect(await fractionContract.totalSupply()).to.be.equal(500);

  });

  it("should random wallet do NOT be able to redeem NFT", async function(){
    let randomWallet = utils.createRandomWallet(wallet.provider);
    
    const fractionContract = new ethers.Contract(ERC20FractionTokenObj.fractionContractAddress, fractionabi, randomWallet);    
    
    let buybackTx = fractionContract.buyback();
    // after the success call for this one you
    expect(buybackTx).to.be.revertedWith("msg.sender must be the nft owner");
    
  });

  it("should be able to burn ERC20 tokens and redeem the NFT", async function(){
    let walletAddress = await wallet.getAddress();
    //before the buyback the wallet is not owner of the NFT with id 'nftContractTokenId'
    let result = await NFTContract.ownerOf(nftContractTokenId);
    expect(result).not.be.equal(walletAddress);

    const fractionContract = new ethers.Contract(ERC20FractionTokenObj.fractionContractAddress, fractionabi, wallet);    
    await fractionContract.buyback();

    // after the success transaction 
    // the ERC20 tokens must be burn
    expect(await fractionContract.balanceOf(walletAddress)).to.be.equal(0);
    expect(await fractionContract.totalSupply()).to.be.equal(0);
    
    // the owner should have back the NFT
    expect(await NFTContract.ownerOf(nftContractTokenId)).to.be.equal(walletAddress);

  });

});
