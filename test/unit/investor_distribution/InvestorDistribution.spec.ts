import { loadFixture, time } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import {
  InvestorDistribution,
  ERC20Token,
  Chest,
} from "../../../typechain-types";
import { BigNumber } from "ethers";
import { deployInvestorDistributionFixture } from "../../fixtures/unit__InvestorDistribution";
import { Investor, investors } from "./investors";

describe("InvestorDistribution", function () {
  const INDEX_SLOT = 1;
  const FIRST_ELEMENT_SLOT = 2;

  const TOTAL_JELLY_AMOUNT = ethers.utils.parseEther("169890391");

  let investorDistribution: InvestorDistribution;
  let jellyToken: ERC20Token;
  let chest: Chest;
  let deployer: SignerWithAddress;
  let otherAccount: SignerWithAddress;

  beforeEach(async function () {
    const fixture = await loadFixture(deployInvestorDistributionFixture);
    investorDistribution = fixture.investorDistribution;
    jellyToken = fixture.jellyToken;
    chest = fixture.chest;
    deployer = fixture.deployer;
    otherAccount = fixture.otherAccount;
  });

  describe("Deployment", function () {
    it("should set the correct owner", async function () {
      expect(await investorDistribution.owner()).to.equal(deployer.address);
    });
    it("should set the correct pending owner", async function () {
      expect(await investorDistribution.getPendingOwner()).to.equal(
        otherAccount.address
      );
    });
    it("should set the correct jellyToken address", async function () {
      expect(await investorDistribution.i_jellyToken()).to.equal(
        jellyToken.address
      );
    });
    it("starting index should be 0", async function () {
      const indexBytes = await ethers.provider.getStorageAt(
        investorDistribution.address,
        INDEX_SLOT
      );
      const index = parseInt(indexBytes.slice(2, 26), 16);
      expect(index).to.equal(0);
    });
    it("investors array elements should be set to correct values", async function () {
      for (let i = 0; i < investors.length; i++) {
        const elementBytes = await ethers.provider.getStorageAt(
          investorDistribution.address,
          FIRST_ELEMENT_SLOT + i
        );
        const amount = parseInt(elementBytes.slice(2, 26), 16);
        const address = ethers.utils.getAddress("0x" + elementBytes.slice(26));
        expect(amount).to.equal(investors[i].amount);
        expect(address).to.equal(investors[i].address);
      }
    });
  });
  describe("#setChest", function () {
    describe("success", function () {
      it("should set the correct chest address and allowance", async function () {
        const allowanceBefore = await jellyToken.allowance(
          investorDistribution.address,
          chest.address
        );
        await investorDistribution.setChest(chest.address);
        const allowanceAfter = await jellyToken.allowance(
          investorDistribution.address,
          chest.address
        );

        expect(await investorDistribution.i_chest()).to.equal(chest.address);
        expect(allowanceAfter).to.equal(
          allowanceBefore.add(TOTAL_JELLY_AMOUNT)
        );
      });
      it("should emit ChestSet event", async function () {
        expect(await investorDistribution.setChest(chest.address))
          .to.emit(investorDistribution, "ChestSet")
          .withArgs(chest.address);
      });
    });
    describe("failure", function () {
      it("should revert if called by non-owner", async function () {
        await expect(
          investorDistribution.connect(otherAccount).setChest(chest.address)
        ).to.be.revertedWithCustomError(
          investorDistribution,
          "Ownable__CallerIsNotOwner"
        );
      });
      it("should revert for address zero", async function () {
        await expect(
          investorDistribution.setChest(ethers.constants.AddressZero)
        ).to.be.revertedWithoutReason();
      });
      it("should revert if chest is already set", async function () {
        await investorDistribution.setChest(chest.address);
        await expect(
          investorDistribution.setChest(chest.address)
        ).to.be.revertedWithCustomError(
          investorDistribution,
          "InvestorDistribution__ChestAlreadySet"
        );
      });
    });
  });
  describe("#distribute", function () {
    describe("success", function () {
      beforeEach(async function () {
        await jellyToken.mint(TOTAL_JELLY_AMOUNT);
        await jellyToken.transfer(
          investorDistribution.address,
          TOTAL_JELLY_AMOUNT
        );
        await investorDistribution.setChest(chest.address);
      });
      it("should distribute jelly to investors in batches of 10", async function () {
        for (let i = 0; i<11; i ++) {
        await investorDistribution.distribute(10);
        }
      await investorDistribution.distribute( investors.length%10)
        expect(await jellyToken.balanceOf(investorDistribution.address)).to.equal(0)

      });
      it("should emit BatchDistributed event", async function () {
        const indexBytes = await ethers.provider.getStorageAt(
          investorDistribution.address,
          INDEX_SLOT
        );
        const indexBefore = indexBytes.slice(2, 26);
        expect(await investorDistribution.distribute(10))
          .to.emit(investorDistribution, "BatchDistributed")
          .withArgs(parseInt(indexBefore, 16), 10);
      });
    });
    describe("failure", function () {
      it("should revert if called by non-owner", async function () {
        const batchLen = 10;
        await expect(
          investorDistribution.connect(otherAccount).distribute(batchLen)
        ).to.be.revertedWithCustomError(
          investorDistribution,
          "Ownable__CallerIsNotOwner"
        );
      });
      it("should revert if chest is not set", async function () {
        const batchLen = 10;
        await expect(
          investorDistribution.distribute(batchLen)
        ).to.be.revertedWithoutReason();
      });
      it("should revert if batch length is 0", async function () {
        await expect(
          investorDistribution.distribute(0)
        ).to.be.revertedWithCustomError(
          investorDistribution,
          "InvestorDistribution__InvalidBatchLength"
        );
      });
      it("should revert if batch length is greater than investors length", async function () {
        const batchLen = investors.length + 1;
        await expect(
          investorDistribution.distribute(batchLen)
        ).to.be.revertedWithCustomError(
          investorDistribution,
          "InvestorDistribution__DistributionIndexOutOfBounds"
        );
      });
    });
  });
});
