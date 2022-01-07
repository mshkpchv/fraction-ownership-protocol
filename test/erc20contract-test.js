const hre  = require("hardhat");
const ethers = hre.ethers;
// const { solidity } = require("ethereum-waffle");
const chai = require("chai");
// chai.use(solidity);
const { expect } = chai;

const init_utils = require("../scripts/utils.js");
const utils = init_utils();
 
describe("ERC20FractionToken", function () {

  // nft vars
  let NFTContract = null;
  let firstNftContractTokenId = null;
  let secondNftContractTokenId = null;
  let thirdNFtContractTokenId = null;
  const MINT_NFT_COUNT = 3;

  let mainWallet = null;
  let FRACTION_CONTRACT_FACTORY = null;
  
  let ERC20FractionTokenObj = null;
  let ERC20FractionTokenObjSecond = null;
  let ERC20FractionTokenObjThird = null;
  

  let erc20abi = null;
  let fractionabi = null;
  let auctionabi = null;

  const TOKEN_NAME = "Misho";
  const TOKEN_SYMBOL = "MSH";
  const TOTAL_SUPPLY = 5000;
  const TOKENS_FOR_SALE = 1000;

  const AUCTION_LENGTH_SECONDS = 24 * 60 * 60;

  before(async function(){
    mainWallet = await ethers.getSigner();
    console.log("mainWallet",await mainWallet.getAddress());
    console.log((await mainWallet.getBalance()).toString());
    console.log("provider",mainWallet.provider);
    
    let ipfs_uri = `${process.env.IPFS_NFT_URI}`
    let nft_uris = Array(MINT_NFT_COUNT).fill(ipfs_uri);

    // mainWallet = utils.createRandomWallet(true) 
    const [contract,ids ] = await utils.deployAndMintNFT(mainWallet,nft_uris);
    NFTContract = contract;
    tokenIds = ids;
    firstNftContractTokenId = tokenIds[0];
    secondNftContractTokenId = tokenIds[1];
    thirdNFtContractTokenId = tokenIds[2];

    
    const fractionFactory = await ethers.getContractFactory("ERC20FractionTokenFactory", mainWallet);
    FRACTION_CONTRACT_FACTORY = await fractionFactory.deploy();
    await FRACTION_CONTRACT_FACTORY.deployed();

    // first erc20fractioncontract
    
    ERC20FractionTokenObj = await utils.doFractionNFT(mainWallet,FRACTION_CONTRACT_FACTORY,
        NFTContract,firstNftContractTokenId,TOKEN_NAME,TOKEN_SYMBOL,TOTAL_SUPPLY);

    // second erc20fractionContract

    ERC20FractionTokenObjSecond = await utils.doFractionNFT(mainWallet,FRACTION_CONTRACT_FACTORY,
      NFTContract,secondNftContractTokenId,TOKEN_NAME,TOKEN_SYMBOL,TOTAL_SUPPLY);

    // third erc20fractionContract
    ERC20FractionTokenObjThird = await utils.doFractionNFT(mainWallet,FRACTION_CONTRACT_FACTORY,
      NFTContract,thirdNFtContractTokenId,TOKEN_NAME,TOKEN_SYMBOL,TOTAL_SUPPLY);

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
        "function stage() view returns (uint256)",
        "function bid() payable",
        "function getRemainderTokens() view returns(uint256)",
        "function getAmountRaised() view returns(uint256)",
        "function auctionAddress() view returns(address)",

        // "function startOffering(uint256 pricePerToken, uint256 tokenCount)",
        "function startOffering(address auction, uint256 tokens)"

    ]);


  })

  it(`should be able to burn ERC20 tokens and redeem the NFT with second`, async function(){
    const contract = new ethers.Contract(ERC20FractionTokenObjSecond.fractionContractAddress, fractionabi, mainWallet);    

    //before the buyback the wallet is not owner of the NFT with id 'nftContractTokenId'
    let walletAddress = await mainWallet.getAddress();
    let owner = await NFTContract.ownerOf(secondNftContractTokenId);
    expect(owner).not.be.equal(walletAddress);
    expect(owner).to.be.equal(contract.address);

    // buyback the nft with mainWallet
    await contract.buyback();
    // // after the success transaction 
    // // the ERC20 tokens must be burn
    expect(await contract.balanceOf(walletAddress)).to.be.equal(0);
    expect(await contract.totalSupply()).to.be.equal(0);
    
    // // the owner should have back the NFT
    expect(await NFTContract.ownerOf(secondNftContractTokenId)).to.be.equal(walletAddress);

  });

  it("should fractionContract be ERC20 compatible", async function(){
    
    const fractionContract = new ethers.Contract(ERC20FractionTokenObj.fractionContractAddress,erc20abi,mainWallet);
    
    expect(await fractionContract.symbol()).to.be.equal(TOKEN_SYMBOL);
    expect(await fractionContract.name()).to.be.equal(TOKEN_NAME);
    expect(await fractionContract.decimals()).to.be.equal(18);

    let walletAddress = await mainWallet.getAddress();
    expect(await fractionContract.balanceOf(walletAddress)).to.be.equal(5000);
    expect(await fractionContract.totalSupply()).to.be.equal(5000);


  });

  it("should random wallet to have 0 ERC20 tokens", async function(){
    // let randomWallet = utils.createRandomWallet();
    let randomWallet = await utils.createRandomWalletFrom(mainWallet);

    const fractionContract = new ethers.Contract(ERC20FractionTokenObj.fractionContractAddress, erc20abi, randomWallet);    

    let walletAddress = await randomWallet.getAddress();
    expect(await fractionContract.balanceOf(walletAddress)).to.be.equal(0);

  });

  it("should random wallet do NOT be able to buyback NFT", async function(){
    // let randomWallet = utils.createRandomWallet(false);
    let randomWallet = await utils.createRandomWalletFrom(mainWallet);

    const fractionContract = new ethers.Contract(ERC20FractionTokenObj.fractionContractAddress, fractionabi, randomWallet);    
    let buybackTx = fractionContract.buyback();
    // after the success call for this one you
    await expect(buybackTx).to.be.revertedWith("msg.sender must have all tokens");
    
  });

  xit("should NOT random auction contract can auction tokens", async function(){
    
    // let randomWallet = utils.createRandomWallet(true);
    let randomWallet = await utils.createRandomWalletFrom(mainWallet);

    let address = await randomWallet.getAddress();

    const auctionFactory = await ethers.getContractFactory("FIFOAuction", randomWallet);

    let auctionContract = await auctionFactory.deploy(1 ,address,ERC20FractionTokenObj.fractionContractAddress,AUCTION_LENGTH_SECONDS);
    await auctionContract.deployed();
    console.log("auction contract address ",auctionContract.address);
    await auctionContract.start(TOKENS_FOR_SALE);

    const options = { value:ethers.utils.parseEther("0.0000000000000001") }
    const params = address
    
    let tx = auctionContract.bid(params,options);
    // await tx.wait();

	  await expect(tx).to.be.revertedWith("ERC20: transfer amount exceeds balance")
    expect(await auctionContract.getRemainderTokens()).to.be.equal(1000);
    
  });

  it("should start offering for the tokens with Simple FIFO Auction", async function(){
    
    let mainWalletAddress = await mainWallet.getAddress();
    const fractionERC20Contract = new ethers.Contract(ERC20FractionTokenObj.fractionContractAddress, fractionabi, mainWallet);
    
    let fractionTokens = await fractionERC20Contract.balanceOf(mainWalletAddress);

    const auctionFactory = await ethers.getContractFactory("FIFOAuction", mainWallet);

    let auctionContract = await auctionFactory.deploy(1, mainWalletAddress, ERC20FractionTokenObj.fractionContractAddress, AUCTION_LENGTH_SECONDS);

    let tx = await fractionERC20Contract.startOffering(
        auctionContract.address,
        TOKENS_FOR_SALE
    );
    
    await tx.wait()

    expect(await fractionERC20Contract.balanceOf(auctionContract.address)).to.be.equal(TOKENS_FOR_SALE);
    // // the moderator must have reduce himself the tokens for the offering
    let mainWalletBalance = await fractionERC20Contract.balanceOf(mainWalletAddress);
    // console.log("mainWalletBalance",mainWalletBalance.toString());
    expect(mainWalletBalance).to.be.equal(fractionTokens - TOKENS_FOR_SALE);

    let howMany = 2;
    let walletArray = await utils.createRandomWalletsFrom(mainWallet,howMany); 


    for(wallet of walletArray){
      expect(await fractionERC20Contract.balanceOf(await wallet.getAddress())).to.be.equal(0);
    }
  });

  it("should be the FIRST bid for tokens", async function(){
    
    // let randomWallet = utils.createRandomWallet(true);
    let randomWallet = await utils.createRandomWalletFrom(mainWallet);
    const fractionERC20Contract = new ethers.Contract(ERC20FractionTokenObj.fractionContractAddress, fractionabi, randomWallet);
    
    let remainderTokens = await fractionERC20Contract.getRemainderTokens();
    expect(remainderTokens).to.be.equal(TOKENS_FOR_SALE);

    const weiValue = ethers.utils.parseEther("0.0000000000000001"); // 100 wei
	  const bidTx = await fractionERC20Contract.bid({value:weiValue});
	  await bidTx.wait()

    remainderTokens = await fractionERC20Contract.getRemainderTokens();
    expect(remainderTokens).to.be.equal(TOKENS_FOR_SALE - weiValue.toNumber());

    expect(await fractionERC20Contract.balanceOf(await randomWallet.getAddress())).to.be.equal(weiValue);

    const provider = randomWallet.provider;
    const fractionContractBalance = await provider.getBalance(fractionERC20Contract.address);
    expect(fractionContractBalance).to.be.equal(0);
  });

  xit("should make concurent bids", async function(){
    let provider = mainWallet.provider;
    let deployerBalanceBegin = await provider.getBalance(await mainWallet.getAddress());

    const fractionERC20Contract = new ethers.Contract(ERC20FractionTokenObj.fractionContractAddress,fractionabi,mainWallet);
    let beforeTokens = await fractionERC20Contract.getRemainderTokens();

    let singleBid = async function (randomWallet, wei) {

      const contract = fractionERC20Contract.connect(randomWallet);
      let tx = await contract.bid({value:wei});
  	  await tx.wait();
    }

    const wei = ethers.utils.parseEther("0.0000000000000001"); // 100 wei
    let howMany = 2;
    // let walletArray = utils.createRandomWallets(howMany);
    let walletArray = await utils.createRandomWalletsFrom(mainWallet,howMany);




    for(wallet of walletArray){
      expect(await fractionERC20Contract.balanceOf(await wallet.getAddress())).to.be.equal(0);
    }

    let promises = walletArray.map((_wlt) => singleBid(_wlt,wei))
    let combinedPromise = Promise.all(promises)
      .catch((error) => console.log("custom error", error));

    await combinedPromise;

    let remainderTokens = await fractionERC20Contract.getRemainderTokens();
    expect(remainderTokens).to.be.equal(beforeTokens - (howMany * wei.toNumber()));

    // check if the wallets have tokens for the ethers send
    for(wallet of walletArray){
      expect(await fractionERC20Contract.balanceOf(await wallet.getAddress())).to.be.equal(wei);
    }

    //  check if you recieve 100 ^ howMany weis after success bid/purchase
    let deployerBalanceAfter = await provider.getBalance(await mainWallet.getAddress());
    expect(howMany * wei).to.be.equal(deployerBalanceAfter.sub(deployerBalanceBegin).toNumber());
  });

  xit("should buy all the left tokens", async function() {
    
    // let randomWallet = utils.createRandomWallet(true);
    let randomWallet = await utils.createRandomWalletFrom(mainWallet);

    let randomWalletAddress = await randomWallet.getAddress();

    const fractionERC20Contract = new ethers.Contract(ERC20FractionTokenObj.fractionContractAddress, fractionabi, randomWallet);
    let remainderTokensBefore = await fractionERC20Contract.getRemainderTokens();

    // this will stop the auction because randomWallet buy all the tokens
	  const bidTx = await fractionERC20Contract.bid({ value:remainderTokensBefore + 100 });
	  await bidTx.wait()

    let remainderTokensAFTER = await fractionERC20Contract.getRemainderTokens();
    expect(remainderTokensAFTER).to.be.equal(0);

    expect(await fractionERC20Contract.balanceOf(randomWalletAddress)).to.be.equal(remainderTokensBefore);

    // should stage to be finish
    await expect(fractionERC20Contract.bid({value:100})).to.be.revertedWith("auction: tokens sold out");

    const provider = randomWallet.provider;
    const fractionContractBalance = await provider.getBalance(fractionERC20Contract.address);
    expect(fractionContractBalance.toNumber()).to.be.equal(0); 
  });

  xit(`should start auction for the third FRACTION contract`, async function() {
    
    let fractionERC20Address = ERC20FractionTokenObjThird.fractionContractAddress;
    const fractionContract = new ethers.Contract(fractionERC20Address, fractionabi, mainWallet);
    let mainWalletAddress = await mainWallet.getAddress();
    
    const dutchAuctionFactory = await ethers.getContractFactory("DutchAuction", mainWallet);
    let auctionContract = await dutchAuctionFactory.deploy(1, 20, mainWalletAddress, fractionERC20Address, AUCTION_LENGTH_SECONDS);

    let auctionAddress = await auctionContract.address;

    let tx = await fractionContract.startOffering(
        auctionAddress,
        TOKENS_FOR_SALE
    );
    
    await tx.wait()

    let auctionRemainderTokens = await auctionContract.getRemainderTokens();
    expect(await fractionContract.balanceOf(auctionAddress)).to.be.equal(auctionRemainderTokens);
    
    // // 2. concurrent bids for tokens
    const wei = ethers.utils.parseEther("0.0000000000000005"); // 500 wei
    let howMany = 2;
    // let walletArray = utils.createRandomWallets(howMany);
    let walletArray = await utils.createRandomWalletsFrom(mainWallet,howMany);

    let promises = walletArray.map((_wlt) => singleBidOver(auctionContract,_wlt,wei));
    
    let combinedPromise = Promise.all(promises)
      .catch((error) => console.log("custom error", error));

    await combinedPromise;

    // // // the tokens are not distrubuted yet
    let remainderTokens = await auctionContract.getRemainderTokens();
    expect(remainderTokens).to.be.equal(0);
    
    // 0 tokens are left for auciton
    let lastBid = singleBidOver(auctionContract,utils.createRandomWallet(true),wei) 
    await expect(lastBid).to.be.revertedWith("auction: tokens sold out");

    // call the end to distribute all the tokens and get the ether
    // await lastBid;
    // await auctionContract.end(
    //   // {
    //   // gasPrice: 816862499,
    //   // gasLimit: 30000000
    // // }
    // );

  });
});

async function singleBidOver(bidContract ,randomWallet, wei){
  const contract = bidContract.connect(randomWallet);
  let addr = await randomWallet.getAddress();
  let tx = await contract.bid(addr,{value:wei});
  await tx.wait();
}
