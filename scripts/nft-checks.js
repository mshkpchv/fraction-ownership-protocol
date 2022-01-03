const hre = require('hardhat')
const ethers = hre.ethers;
const abi = [
  // Read-Only Functions
  "function tokenURI(uint256 _tokenId) view returns (string)",
  "function decimals() view returns (uint8)",

];

async function checkTokenUri(contractAddress,wallet,id){
    const contract = new ethers.Contract(contractAddress,abi,wallet);    
    return contract.tokenURI(id);
}
async function main(){
  let wallet = await ethers.getSigner()
  let address = "0x0A37d1406bC29412568c3f86e0cA7f167318573D" // rinkeby contract
  let res = await checkTokenUri(address,wallet,1);
  console.log('uri',res);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});