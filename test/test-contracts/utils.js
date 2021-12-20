const { ethers } = require("hardhat");



async function deployNFTAndMintTokens(wallet, autonumber=2) {

    const LimeNFTFactory = await ethers.getContractFactory("LimeNFT", wallet);
    const contract = await LimeNFTFactory.deploy();
    await contract.deployed();
    let addr = await wallet.getAddress();

    addresses = Array(autonumber).fill(addr);

    for (let address of addresses){
        let mintNFTTxRequest = await contract.mintNFT(address,"localhost");
        await mintNFTTxRequest.wait()
    }
    let abi = ['event Transfer(address indexed from, address indexed to, uint256 indexed tokenId)']
    let iface = new ethers.utils.Interface(abi);       
    let eventFilter = contract.filters.Transfer();
    let transfers = await contract.queryFilter(eventFilter);
    transfers = transfers.map((single)=> iface.parseLog(single));

    tokenIds = transfers.map((single)=>{
        let { tokenId } = single.args
        return tokenId.toNumber();
    })

    return [contract , tokenIds]
}

async function doFractionNFT(wallet, FRACTION_CONTRACT, NFTContract, token, newTokenName, newTokenSymbol,supply=100) {
    
    let nftContractAddress = NFTContract.address;

    // approave fraction contract to operate over nft contract
    let approveTx = await NFTContract.approve(FRACTION_CONTRACT.address,token);
    await approveTx.wait();

    const fractionContract = FRACTION_CONTRACT.connect(wallet);
    let tx = await fractionContract.create(
        newTokenName,
        newTokenSymbol,
        nftContractAddress,
        token,
        supply,
      {
        gasPrice: 816862499,
        gasLimit: 30000000
      }
    );
    await tx.wait();

    let abi = ['event FractionEvent(address tokenContractAddress, uint256 tokenId,address fractionContractAddress, uint256 fractionIndex)']
    let iface = new ethers.utils.Interface(abi);
    let contract = FRACTION_CONTRACT.connect(wallet);        
    let eventFilter = contract.filters.FractionEvent();
    let events = await contract.queryFilter(eventFilter);

    events = events.map((ev)=> iface.parseLog(ev));    
    single = events[0];
    const {tokenContractAddress,tokenId,fractionContractAddress,fractionIndex} = single.args;
    
    return {
        "tokenContractAddress":tokenContractAddress,
        "tokenId":tokenId,
        "fractionContractAddress":fractionContractAddress,
        "fractionIndex":fractionIndex
    }
    
}

function createRandomWallet(provider = undefined){
    if (provider === undefined){
        provider = ethers.getDefaultProvider()
    }
    rndWallet = ethers.Wallet.createRandom().connect(provider);
    return rndWallet;

}

module.exports = {
    "deployAndMintNFT":deployNFTAndMintTokens,
    "doFractionNFT":doFractionNFT,
    "createRandomWallet":createRandomWallet   
};  