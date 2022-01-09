require("dotenv").config();

require("@nomiclabs/hardhat-etherscan");
require("@nomiclabs/hardhat-waffle");
require("hardhat-gas-reporter");
require("@nomiclabs/hardhat-ethers");
require("solidity-coverage");

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
    // console.log(account._signer);
    // console.log(Object.keys(account._signer));
  }
});

task("deploy-nft", "Deploys contract on a provided network",
  async (taskArgs, hre) => {
    const deployNFT = require("./scripts/deploy-nft.js");
    await deployNFT();
});

task("deploy-fractionFactory", "Deploys contract on a provided network",
  async (taskArgs, hre) => {
    let wallet= await hre.ethers.getSigner()
    const fractionFactory = await hre.ethers.getContractFactory("ERC20FractionTokenFactory", wallet);
    FRACTION_CONTRACT = await fractionFactory.deploy();
    await FRACTION_CONTRACT.deployed();
    console.log(FRACTION_CONTRACT.address);
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: "0.8.4",
  networks: {
    ropsten: {
      url: process.env.ROPSTEN_URL || "",
      accounts:
        process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
    rinkeby: {
      url: process.env.RINKEBY_URL, //Infura url with projectId
      accounts:
        process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS !== undefined,
    currency: "USD",
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY,
  }
};
