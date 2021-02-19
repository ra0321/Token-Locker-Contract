import { expect} from "chai";
import { Contract } from "ethers";
import { MockProvider } from "ethereum-waffle";
import { BasicToken } from "../typechain";
import { Artifact } from "hardhat/types";
import hre from "hardhat";

const { deployContract } = hre.waffle;

describe("BasicToken", () => {
  const [wallet, walletTo] = new MockProvider({
    ganacheOptions: {
      gasLimit : 10000000
    }
  }).getWallets();
  let token: Contract;

  beforeEach(async () => {
    const tokenArtifact: Artifact = await hre.artifacts.readArtifact("BasicToken");
    token = <BasicToken>await deployContract(wallet, tokenArtifact, [1000]);
  });

  it("Assigns initial balance", async () => {
    expect(await token.balanceOf(wallet.address)).to.equal(1000);
  });

  it("Transfer adds amount to destination account", async () => {
    await token.transfer(walletTo.address, 7);
    expect(await token.balanceOf(walletTo.address)).to.equal(7);
  });

  it("Transfer emits event", async () => {
    await expect(token.transfer(walletTo.address, 7))
      .to.emit(token, "Transfer")
      .withArgs(wallet.address, walletTo.address, 7);
  });

  it("Can not transfer above the amount", async () => {
    await expect(token.transfer(walletTo.address, 1007)).to.be.reverted;
  });

  it("Can not transfer from empty account", async () => {
    const tokenFromOtherWallet = token.connect(walletTo);
    await expect(tokenFromOtherWallet.transfer(wallet.address, 1))
      .to.be.reverted;
  });

  //Waffle's calledOnContract is not supported by Hardhat
  // it("Calls totalSupply on BasicToken contract", async () => {
  //   await token.totalSupply();
  //   expect("totalSupply").to.be.calledOnContract(token);
  // });
  //
  // it("Calls balanceOf with sender address on BasicToken contract", async () => {
  //   await token.balanceOf(wallet.address);
  //   expect("balanceOf").to.be.calledOnContractWith(token, [wallet.address]);
  // });
});
