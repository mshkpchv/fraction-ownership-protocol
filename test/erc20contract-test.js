const hre  = require("hardhat");
const ethers = hre.ethers;
const { expect } = require("chai");
const utils = require("../scripts/utils.js");

describe("ERC20FractionToken", function () {
  let FRACTION_CONTRACT_FACTORY = null;
  let NFTContract = null;
  let firstNftContractTokenId = null;
  let secondNftContractTokenId = null;
  let mainWallet = null;
  let mintNFTnumber = 2;

  let ERC20FractionTokenObj = null;
  let ERC20FractionTokenObjSecond = null;

  let erc20abi = null;
  let fractionabi = null;

  let tokenName = "Misho";
  let tokenSymbol = "MSH";
  let totalSupply = 5000;
  let TOKENS_FOR_SALE = null;


  before(async function(){
    // wallet = await ethers.getSigner() 
    let ipfs_uri = `${process.env.IPFS_NFT_URI}`
    let nft_uris = Array(mintNFTnumber).fill(ipfs_uri);

    mainWallet = utils.createRandomWallet() 
    const [contract,ids ] = await utils.deployAndMintNFT(mainWallet,nft_uris);
    NFTContract = contract;
    tokenIds = ids;
    firstNftContractTokenId = tokenIds[0];
    secondNftContractTokenId = tokenIds[1];

    
    const fractionFactory = await ethers.getContractFactory("ERC20FractionTokenFactory", mainWallet);
    FRACTION_CONTRACT_FACTORY = await fractionFactory.deploy();
    await FRACTION_CONTRACT_FACTORY.deployed();

    // first erc20fractioncontract
    
    ERC20FractionTokenObj = await utils.doFractionNFT(mainWallet,FRACTION_CONTRACT_FACTORY,
        NFTContract,firstNftContractTokenId,tokenName,tokenSymbol,totalSupply);

    // second erc20fractioncontract

    ERC20FractionTokenObjSecond = await utils.doFractionNFT(mainWallet,FRACTION_CONTRACT_FACTORY,
      NFTContract,secondNftContractTokenId,tokenName,tokenSymbol,totalSupply);

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
        "function buyback()",
        "function startOffering(uint256 pricePerToken, uint256 tokenCount)",
        "function stage() view returns (uint256)",
        "function bid() payable",
        "function getRemainderTokens() view returns(uint256)",
        "function getAmountRaised() view returns(uint256)",

    ]);


  })

  // it(`should be able to burn ERC20 tokens and redeem the NFT with id ${secondNftContractTokenId}`, async function(){
  //   const contract = new ethers.Contract(ERC20FractionTokenObjSecond.fractionContractAddress, fractionabi, mainWallet);    

  //   //before the buyback the wallet is not owner of the NFT with id 'nftContractTokenId'
  //   let walletAddress = await mainWallet.getAddress();
  //   let result = await NFTContract.ownerOf(secondNftContractTokenId);
  //   expect(result).not.be.equal(walletAddress);
  //   expect(result).to.be.equal(contract.address);

  //   // buyback the nft with mainWallet
  //   await contract.buyback();
  //   // // after the success transaction 
  //   // // the ERC20 tokens must be burn
  //   expect(await contract.balanceOf(walletAddress)).to.be.equal(0);
  //   expect(await contract.totalSupply()).to.be.equal(0);
    
  //   // // the owner should have back the NFT
  //   expect(await NFTContract.ownerOf(secondNftContractTokenId)).to.be.equal(walletAddress);

  // });

  // it("should fractionContract be ERC20 compatible", async function(){
    
  //   const fractionContract = new ethers.Contract(ERC20FractionTokenObj.fractionContractAddress,erc20abi,mainWallet);
    
  //   expect(await fractionContract.symbol()).to.be.equal(tokenSymbol);
  //   expect(await fractionContract.name()).to.be.equal(tokenName);
  //   expect(await fractionContract.decimals()).to.be.equal(18);

  //   let walletAddress = await mainWallet.getAddress();
  //   expect(await fractionContract.balanceOf(walletAddress)).to.be.equal(5000);
  //   expect(await fractionContract.totalSupply()).to.be.equal(5000);


  // });

  // it("should random wallet to have 0 ERC20 tokens", async function(){
  //   let randomWallet = utils.createRandomWallet(false);
  //   const fractionContract = new ethers.Contract(ERC20FractionTokenObj.fractionContractAddress, erc20abi, randomWallet);    

  //   let walletAddress = await randomWallet.getAddress();
  //   expect(await fractionContract.balanceOf(walletAddress)).to.be.equal(0);

  // });

  // it("should random wallet do NOT be able to redeem NFT", async function(){
  //   let randomWallet = utils.createRandomWallet(false);
  //   const fractionContract = new ethers.Contract(ERC20FractionTokenObj.fractionContractAddress, fractionabi, randomWallet);    
  //   let buybackTx = fractionContract.buyback();
  //   // after the success call for this one you
  //   expect(buybackTx).to.be.revertedWith("msg.sender must have all tokens");
    
  // });

  it("should start offering for the tokens", async function(){
    let walletAddress = await mainWallet.getAddress();
    const fractionContract = new ethers.Contract(ERC20FractionTokenObj.fractionContractAddress, fractionabi, mainWallet);
    
    // expect(await fractionContract.stage()).to.be.equal(0);
    
    
    let fractionTokens = await fractionContract.balanceOf(walletAddress);

    let tokensForSale = 1000;
    let price = 10;
    let tx = await fractionContract.startOffering(
        price,
        tokensForSale
    );
    await tx.wait();
    let fractionContractAddress = fractionContract.address;

    // expect(await fractionContract.balanceOf(fractionContractAddress)).to.be.equal(tokensForSale);
    // the moderator must have reduce himself the tokens for the offering
    // expect(await fractionContract.balanceOf(walletAddress)).to.be.equal(fractionTokens - tokensForSale);
    
    // expect(await fractionContract.stage()).to.be.equal(1);

    TOKENS_FOR_SALE = tokensForSale
  });

  // it("should be the FIRST bid for tokens", async function(){

  //   let randomWallet = utils.createRandomWallet();
  //   const fractionContract = new ethers.Contract(ERC20FractionTokenObj.fractionContractAddress, fractionabi, randomWallet);
    
  //   let remainderTokens = await fractionContract.getRemainderTokens();
  //   expect(remainderTokens).to.be.equal(TOKENS_FOR_SALE,"before first bid, equal tokens");

  //   // const wei = ethers.utils.parseEther("0.0000000000000001"); // 100 wei
	//   // const bidTx = await fractionContract.bid({value:wei});
	//   // await bidTx.wait()

  //   // remainderTokens = await fractionContract.getRemainderTokens();
  //   // expect(remainderTokens).to.be.equal(TOKENS_FOR_SALE - wei.toNumber(),"total supply - wei");

  // });

  // it("should make concurent bids", async function(){

  //   const fractionContract = new ethers.Contract(ERC20FractionTokenObj.fractionContractAddress,fractionabi,mainWallet);
  //   let beforeTokens = await fractionContract.getRemainderTokens();

  //   let concurentFunction = async function (randomWallet, wei) {

  //     const contract = fractionContract.connect(randomWallet);
  //     let tx = await contract.bid({value:wei});
  // 	  await tx.wait();
  //   }
  //   const wei = ethers.utils.parseEther("0.0000000000000001"); // 100 wei
  //   let howMany = 2;
  //   let walletArray = utils.createRandomWallets(howMany);
  //   let promises = walletArray.map((_wlt) => concurentFunction(_wlt,wei))
    

  //   let combinedPromise = Promise.all(promises)
  //     .catch((error) => console.log("custom error", error));

  //   await combinedPromise;

  //   let remainderTokens = await fractionContract.getRemainderTokens();
  //   expect(remainderTokens).to.be.equal(beforeTokens - (howMany * wei.toNumber()));
    
  // });

  it("should NOT create random auction contract and get tokens", async function(){
    let address = await mainWallet.getAddress();
    const auctionFactory = await ethers.getContractFactory("Auction", mainWallet);

    let auctionContract = await auctionFactory.deploy(1,address,ERC20FractionTokenObj.fractionContractAddress,TOKENS_FOR_SALE,totalSupply);
    await auctionContract.deployed();
    console.log("auction contract address ",auctionContract.address);

    let randomWallet = utils.createRandomWallet(true);
    auctionContract = auctionContract.connect(randomWallet);

    const wei = ethers.utils.parseEther("0.0000000000000001"); // 100 wei
	  expect(auctionContract.bid({value:wei})).to.be.revertedWith("ERC20: transfer amount exceeds balance")
    // uint256 _rate, address moderator ,address _token, uint256 _tokensForSale, uint256 _totalSupply
    
  });

  it("should retrieve all the ", async function(){
    let address = await mainWallet.getAddress();
    const auctionFactory = await ethers.getContractFactory("Auction", mainWallet);

    let auctionContract = await auctionFactory.deploy(1,address,ERC20FractionTokenObj.fractionContractAddress,TOKENS_FOR_SALE,totalSupply);
    await auctionContract.deployed();
    console.log("auction contract address ",auctionContract.address);

    let randomWallet = utils.createRandomWallet(true);
    auctionContract = auctionContract.connect(randomWallet);

    const wei = ethers.utils.parseEther("0.0000000000000001"); // 100 wei
	  expect(auctionContract.bid({value:wei})).to.be.revertedWith("ERC20: transfer amount exceeds balance")
    // uint256 _rate, address moderator ,address _token, uint256 _tokensForSale, uint256 _totalSupply
    
  });

});
