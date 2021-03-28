// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
// When running the script with `hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { ethers } from "hardhat";
import { Contract, ContractFactory } from "ethers";

async function main(): Promise<void> {
  // Hardhat always runs the compile task when running scripts through it.
  // If this runs in a standalone fashion you may want to call compile manually
  // to make sure everything is compiled
  // await run("compile");

  // We get the contract to deploy
  const BasicToken: ContractFactory = await ethers.getContractFactory("BasicToken");
  const basicToken: Contract = await BasicToken.deploy(ethers.utils.parseUnits("50000000000000000000"));
  await basicToken.deployed();

  const TokenLocker: ContractFactory = await ethers.getContractFactory("TokenLocker");
  const tokenLocker: Contract = await TokenLocker.deploy("0x7429c1c1B102296448dfaddf5296709Dc5766c03");
  await tokenLocker.deployed();

  console.log("BasicToken contract deployed to: ", basicToken.address);
  console.log("TokenLocker contract deployed to: ", tokenLocker.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error: Error) => {
    console.error(error);
    process.exit(1);
  });
