import hre from "hardhat";
import { Artifact } from "hardhat/types";
import { BasicToken } from "../typechain";
import { TokenLocker } from "../typechain";
import { expect } from "chai";
import { MockProvider } from "ethereum-waffle";

const { deployContract } = hre.waffle;

describe("Smart Contract operations tests", function() {
  const [wallet, otherWallet] = new MockProvider({
    ganacheOptions: {
      gasLimit: 10000000,
      time: new Date(),
    },
  }).getWallets();
  let token: BasicToken;
  let contract: TokenLocker;

  describe("TokenLocker", function() {

    beforeEach(async function() {
      const hodlTokensArtifact: Artifact = await hre.artifacts.readArtifact("TokenLocker");
      contract = <TokenLocker>await deployContract(wallet, hodlTokensArtifact, [wallet.address]);
      const tokenArtifact: Artifact = await hre.artifacts.readArtifact("BasicToken");
      token = <BasicToken>await deployContract(wallet, tokenArtifact, [1000]);
    });

    it("should deposit tokens from wallet to the contract", async function() {
      await token.approve(contract.address, 10);
      await contract.connect(wallet).hodlDeposit(token.address, 10, 2020, 20);
      expect(await token.balanceOf(contract.address)).to.equal(10);
      expect(await token.balanceOf(wallet.address)).to.equal(990);
    });

    it("should withdraw tokens from contract to the wallet", async function() {
      await token.approve(contract.address, 10);
      await contract.connect(wallet).hodlDeposit(token.address, 10, 2020, 20);
      await contract.connect(wallet).withdraw(token.address);
      expect(await token.balanceOf(wallet.address)).to.equal(1000);
    });

    it("should apply fee and leave a percent of tokens on the contract on panicWithdraw", async function() {
      await token.approve(contract.address, 100);
      const fee = 20
      await contract.connect(wallet).hodlDeposit(token.address, 100, 2020, fee);
      await contract.connect(wallet).panicWithdraw(token.address);
      expect(await token.balanceOf(contract.address)).to.equal(fee);
    });

    it("should fail withdrawing tokens because of the time limit", async function() {
      const dateNow = Math.floor(Date.now() / 1000);
      const dateInFuture = dateNow + 6000;
      await token.approve(contract.address, 10);
      await contract.connect(wallet).hodlDeposit(token.address, 10, dateInFuture, 20);
      await expect(contract.connect(wallet).withdraw(token.address)).to.be.reverted;
    });

    it("should fail because it's not the owner", async function() {
      await expect(contract.connect(otherWallet).claimFees([])).to.be.reverted;
    });

    it("should transfer leftover token fees to the original wallet", async function() {
      await token.approve(contract.address, 200);
      await contract.connect(wallet).hodlDeposit(token.address, 200, 2020, 20);
      await contract.connect(wallet).panicWithdraw(token.address);
      await contract.connect(wallet).claimFees([token.address]);
      expect(await token.balanceOf(wallet.address)).to.equal(1000);
    });

  });
});
