const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();

  const tokenAddress = "0xYourERC20TokenAddressHere"; // Replace with your ERC20 token address
  const TokenVesting = await ethers.getContractFactory("TokenVesting");
  const vesting = await TokenVesting.deploy(tokenAddress, deployer.address);

  await vesting.deployed();
  console.log("TokenVesting deployed to:", vesting.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
