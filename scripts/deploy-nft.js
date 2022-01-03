// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const utils = require("./utils.js");
const hre = require('hardhat')
const ethers = hre.ethers;

async function deployNFT(_privateKey = undefined,count=5) {
    await hre.run('compile'); // We are compiling the contracts using subtask
    let wallet;
    if(_privateKey){
        wallet = new ethers.Wallet(_privateKey, hre.ethers.provider) // New wallet with the privateKey passed from CLI as param
    }else{
        wallet = await ethers.getSigner()
    }
    // wallet = await ethers.getSigner()
    let ipfs_uri = `${process.env.IPFS_NFT_URI}` 
    let nft_uris = Array(count).fill(ipfs_uri);

    const [contract,ids ] = await utils.deployAndMintNFT(wallet,nft_uris);
    console.log("NFT address", contract.address);
    console.log("ids", ids);
}

module.exports = deployNFT;
