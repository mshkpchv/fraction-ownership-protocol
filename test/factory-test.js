const hre  = require("hardhat");
const ethers = hre.ethers;
const { expect } = require("chai");
const init_utils = require("../scripts/utils.js");
const utils =init_utils();

describe("ERC20FractionTokenFactory", function () {
  let FRACTION_CONTRACT = null;
  let NFTContract = null;
  let mainWallet = null;
  let mintNFTnumber = 1;
  let tokenIds = null;

  let ERC20FractionTokenObj = null;

  before(async function(){
    // mainWallet = await ethers.getSigner()
    mainWallet = utils.createRandomWallet(true);

    let ipfs_uri = `${process.env.IPFS_NFT_URI}` 
    let nft_uris = Array(mintNFTnumber).fill(ipfs_uri);
    const [contract,ids ] = await utils.deployAndMintNFT(mainWallet,nft_uris);
    NFTContract = contract;
    tokenIds = ids;
    const fractionFactory = await ethers.getContractFactory("ERC20FractionTokenFactory", mainWallet);
    FRACTION_CONTRACT = await fractionFactory.deploy();
    await FRACTION_CONTRACT.deployed();

  })

  it("deployment should be finished and correct",async function(){
    expect(NFTContract).not.be.equal(null)
    expect(mainWallet).not.be.equal(null)
    expect(FRACTION_CONTRACT).not.be.equal(null)
    expect(tokenIds).not.be.equal(null) 
  })

  it("should NFTs minted succcessfully for main wallet", async function(){
    let address = await mainWallet.getAddress()
    let tokens = await NFTContract.balanceOf(address);
    expect(tokens).to.be.equal(mintNFTnumber);

    // check for random address
    let randomAddr = "0x1cbd3b2770909d4e10f157cabc84c7264073c9ec";
    let zeroTokens = await NFTContract.balanceOf(randomAddr);
    expect(zeroTokens).to.be.equal(0);

  })
  
  it("should revert,because the address is not owner/approve for specific nft",async function(){
    let nftContractAddress = NFTContract.address;  
    let tx = FRACTION_CONTRACT.create(
      "Mishondera",
      "MSH",
      nftContractAddress,
      1,
      100
    );
    expect(tx).to.be.revertedWith("reverted with reason string 'ERC721: transfer caller is not owner nor approved")
  })

  it("show the owner of the tokens", async function() {
    let token = tokenIds[0]
    let result = await NFTContract.ownerOf(token);
    let addr = await mainWallet.getAddress();
    expect(result).to.be.equal(addr)
  });

  it("should transfer NFT to Fraction ERC20 contract", async function(){
    let token = tokenIds[0];
    let name = "MishoToken";
    let symbol = "MSH";
    let contractInfo = await utils.doFractionNFT(
      mainWallet,
      FRACTION_CONTRACT,
      NFTContract,
      token,
      name,
      symbol
    );
    ERC20FractionTokenObj = contractInfo;

    let address = await mainWallet.getAddress();
    let tokens = await NFTContract.balanceOf(address);
    expect(tokens).to.be.equal(mintNFTnumber - 1);
  })

  it("should get the event from ERC20FractionTokenFactory ", async function(){
    
    let tokenId = ERC20FractionTokenObj.tokenId;
    let fractionContractAddress = ERC20FractionTokenObj.fractionContractAddress;
    // check if fractionAddress is the owner of tokenIndex
    let owner = await NFTContract.ownerOf(tokenId.toNumber());
    expect(owner).to.be.equal(fractionContractAddress);
  })
});
