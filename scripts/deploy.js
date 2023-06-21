const hre = require("hardhat");

async function main() {
  
  const usdcAddress = "0xFEca406dA9727A25E71e732F9961F680059eF1F9"; // mumbai
  const crossmintAddress = "0x13253aa4Abe1861124d4c286Ee4374cD054D3eb9"; // staging EVM
  
  // const usdcAddress = "0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174"; // polygon mainnet
  //const crossmintAddress = "0xa8C10eC49dF815e73A881ABbE0Aa7b210f39E2Df"; // production EVM

  const CrossmintTester721NFT = await hre.ethers.getContractFactory("CrossmintTester721");
  const CrossmintTester721 = await CrossmintTester721NFT.deploy(usdcAddress, crossmintAddress);

  await CrossmintTester721.deployed();

  console.log("CrossmintTester721 deployed to:", CrossmintTester721.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
