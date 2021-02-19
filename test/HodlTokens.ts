import hre from "hardhat";
import { Artifact } from "hardhat/types";
import { BasicToken } from "../typechain";
import { HodlTokens } from "../typechain";
import { expect } from "chai";
import { MockProvider } from "ethereum-waffle";

const { deployContract } = hre.waffle;

describe("Smart Contract operations tests", function() {

  const [wallet, walletTo] = new MockProvider({
    ganacheOptions: {
      gasLimit : 10000000
    }
  }).getWallets();
  let token: BasicToken;
  let contract: HodlTokens;

  describe("HodlTokens", function() {
    beforeEach(async function() {
      const hodlTokensArtifact: Artifact = await hre.artifacts.readArtifact("HodlTokens");
      contract = <HodlTokens>await deployContract(wallet, hodlTokensArtifact);
      const tokenArtifact: Artifact = await hre.artifacts.readArtifact("BasicToken");
      token = <BasicToken>await deployContract(wallet, tokenArtifact, [1000]);
    });

    it("should deposit tokens from wallet to the contract", async function() {
      await  token.approve(contract.address,10)
      await contract.connect(wallet).hodlDeposit(token.address, 10, 2020);
      expect(await token.balanceOf(contract.address)).to.equal(10);
      expect(await token.balanceOf(wallet.address)).to.equal(990);
    });

    it("should withdraw tokens from contract to the wallet", async function() {
      await  token.approve(contract.address,10)
      await contract.connect(wallet).hodlDeposit(token.address, 10, 2020);
      await contract.connect(wallet).withdraw(token.address);
      expect(await token.balanceOf(wallet.address)).to.equal(1000);
    });

    it("should apply fee and leave a percent of tokens on the contract on panicWithdraw", async function() {
      await  token.approve(contract.address,100)
      await contract.connect(wallet).hodlDeposit(token.address, 100, 2020);
      await contract.connect(wallet).panicWithdraw(token.address);
      expect(await token.balanceOf(contract.address)).to.equal(15);
    });

  });
});
