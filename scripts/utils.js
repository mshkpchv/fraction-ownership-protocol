const { ethers } = require("hardhat");
const { waffle } = require("hardhat");

const init = function() {

    const PKS = [
        "0x47c99abed3324a2707c28affff1267e45918ec8c3f20b8aa892e8b065d2942dd",
        "0xa267530f49f8280200edf313ee7af6b827f2a8bce2897751d06a843f644967b1",
        "0x701b615bbdfb9de65240bc28bd21bbc0d996645a3dd57e7b12bc2bdf6f192c82",
        "0xf214f2b2cd398c806f84e317254e0f0b801d0643303237d97a22a48e01628897",
        "0x2a871d0798f97d79848a013d4936a73bf4cc922c825d33c1cf7073dff6d409c6",
        "0xdbda1821b80551c9d65939329250298aa3472ba22feea921c0cf5d620ea67b97",
        "0xea6c44ac03bff858b476bba40716402b03e41b8e97e276d1baec7c37d42484a0",
        "0x689af8efa8c651a91ad287602527f3af2fe9f6501a7ac4b061667b5a93e037fd",
        "0xde9be858da4a475276426320d5e9262ecfc3ba460bfac56360bfa6c4c28b4ee0",
        "0xdf57089febbacf7ba0bc227dafbffa9fc08a93fdc68e1e42411a14efcf23656e",
        "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80",
        "0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d",
        "0x8166f546bab6da521a8369cab06c5d2b9e46670292d85c875ee9ec20e84ffb61",
        "0xc526ee95bf44d8fc405a158bb884d9d1238d99f0612e9f33d006bb0789009aaa",
        "0x4bbbf85ce3377467afe5d46f804f221813b2bb87f24d81f60f1fcdbf7cbf4356"
    ]
    
    let _upIndex = -1;
    let maxindex = PKS.length;

    function newIndex(){
        if(_upIndex + 1 < maxindex){
            _upIndex++
            return _upIndex;
        }
        throw Error()
    }

    async function deployNFTAndMintTokens(wallet, nftUris=[]) {
        const LimeNFTFactory = await ethers.getContractFactory("LimeNFT", wallet);
        const contract = await LimeNFTFactory.deploy();
        await contract.deployed();
    
        let walletAddress = await wallet.getAddress();
        let nftCount = nftUris.length;
    
        for(let i = 0; i < nftCount; i++){
            let mintNFTTxRequest = await contract.mintNFT(walletAddress,nftUris[i]);
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

    async function doFractionNFT(wallet, fractionFactoryContract, NFTContract, token, newTokenName, newTokenSymbol,supply=100) {
    
        let nftContractAddress = NFTContract.address;
    
        // approave fraction contract to operate over nft contract
        let approveTx = await NFTContract.approve(fractionFactoryContract.address,token);
        await approveTx.wait();
    
        const fractionContract = fractionFactoryContract.connect(wallet);
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
        let contract = fractionFactoryContract.connect(wallet);        
        let eventFilter = contract.filters.FractionEvent();
        let events = await contract.queryFilter(eventFilter);
    
        events = events.map((ev)=> iface.parseLog(ev));    
        events = events.filter(function(ev){
            let {tokenId} = ev.args;
            return tokenId == token
        })
        let single = events[0];
        
        const {tokenContractAddress,tokenId,fractionContractAddress,fractionIndex} = single.args;
        
        return {
            "tokenContractAddress":tokenContractAddress,
            "tokenId":tokenId,
            "fractionContractAddress":fractionContractAddress,
            "fractionIndex":fractionIndex
        }
        
    }
    
    function getProvider(){
        return ethers.provider;
    }
    
    function RandomWallets(number,hasEthers=true){
        res = []
        for(let i = 0; i < number; i++){
            res.push(RandomWallet(hasEthers))
        }
        return res
    }
    
    function RandomWallet(hasEthers = false) {
        let provider = getProvider()
        let rndWallet;
    
        if (hasEthers){
            // let index = Math.floor(Math.random() * PKS.length);
            let index = newIndex()
            rndWallet = new ethers.Wallet(PKS[index],provider);
        }else{
            rndWallet = ethers.Wallet.createRandom().connect(provider);
        }
    
        return rndWallet;
        
    }

    async function RandomWalletFrom(wallet, money = '10') {
        let rnd = RandomWallet(false);
        // rnd.connect(wallet.provider);
        let rndAddress = rnd.address;
        let amountInEther = money
        let tx = {
            to: rndAddress,
            value: ethers.utils.parseEther(amountInEther)
        }
        
         await wallet.sendTransaction(tx)
         return rnd;
    }

    async function RandomWalletsFrom(wallet,number){
        res = []
        for(let i = 0; i < number; i++){
            res.push(await RandomWalletFrom(wallet))
        }
        return res
    }
    
    return {
        "deployAndMintNFT":deployNFTAndMintTokens,
        "doFractionNFT":doFractionNFT,
        "createRandomWallet":RandomWallet,
        "createRandomWalletFrom":RandomWalletFrom,
        "createRandomWallets":RandomWallets,
        "createRandomWalletsFrom":RandomWalletsFrom
    };

}

module.exports = init;

