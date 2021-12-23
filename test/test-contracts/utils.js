const { ethers } = require("hardhat");

const PKS = [
    "0xea6c44ac03bff858b476bba40716402b03e41b8e97e276d1baec7c37d42484a0",
    "0x689af8efa8c651a91ad287602527f3af2fe9f6501a7ac4b061667b5a93e037fd",
    "0xde9be858da4a475276426320d5e9262ecfc3ba460bfac56360bfa6c4c28b4ee0",
    "0xdf57089febbacf7ba0bc227dafbffa9fc08a93fdc68e1e42411a14efcf23656e",
]

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

// function RandomWallet(provider = undefined, addEthers=false){
//     if (provider === undefined){
//         provider = ethers.getDefaultProvider()
//     }
//     rndWallet = ethers.Wallet.createRandom().connect(provider);
//     return rndWallet;
// }

function getProvider(){
    return ethers.providers.getDefaultProvider('http://localhost:8545');
}

function _chooseRandomWallet(index){

}

function RandomWallets(number){
    res = []
    for(let i = 0; i < number; i++){
        res.push(RandomWallet())
    }
    return res
}

function RandomWallet(hasEthers = true) {
    let provider = getProvider()
    let rndWallet;

    if (hasEthers){
        let index = Math.floor(Math.random() * PKS.length);
        rndWallet = new ethers.Wallet(PKS[index],provider);
    }else{
        rndWallet = ethers.Wallet.createRandom().connect(provider);
    }

    return rndWallet;
    
}

module.exports = {
    "deployAndMintNFT":deployNFTAndMintTokens,
    "doFractionNFT":doFractionNFT,
    "createRandomWallet":RandomWallet,
    "createRandomWallets":RandomWallets
};  