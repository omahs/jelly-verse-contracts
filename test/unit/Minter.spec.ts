import { expect } from "chai";
import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { loadFixture } from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { time } from "@nomicfoundation/hardhat-toolbox/network-helpers";

import { JellyToken, Minter } from "../../typechain-types";
import { deployMinter } from "../fixtures/minter";

describe("Minter", () => {
  let minter: Minter;
  let jellyToken: JellyToken;

  let inflationRate: number;
  let inflationPeriod: number;

  let owner: SignerWithAddress;
  let governance: SignerWithAddress;
  let otherAccount: SignerWithAddress;
  let beneficiaries: SignerWithAddress[];

  beforeEach(async () => {
    ({
      minter,
      inflationRate,
      inflationPeriod,
      jellyToken,
      owner,
      governance,
      otherAccount,
      beneficiaries
    } = await loadFixture(deployMinter));
  });

  describe("Deployment", () => {
    it("Sets the contract params", async () => {
      const jellyAddress = await minter.jellyToken();
      const inflRate = await minter.inflationRate();
      const inflPeriod = await minter.inflationPeriod();
      const governanceAddress = await minter.governance();
      const beneficiary1 = await minter.beneficiaries(0);
      const beneficiary2 = await minter.beneficiaries(1);

      expect(jellyAddress).to.eq(jellyToken.target);
      expect(inflRate).to.eq(inflationRate);
      expect(inflPeriod).to.eq(inflationPeriod);
      expect(governanceAddress).to.eq(governance.address);
      expect(beneficiary1).to.eq(beneficiaries[0].address);
      expect(beneficiary2).to.eq(beneficiaries[1].address);
    });
  });

  describe("mint", () => {
    it("Reverts when non governance address tries to mint", async () => {
      await expect(
        minter.connect(otherAccount).mint()
      ).to.be.revertedWith("Only governance can call.")
    });

    it("Increases the supply of tokens following fixed inflation curve", async () => {
      const jellySupply = await jellyToken.totalSupply();

      const lastTime = await time.latest();
      await time.increaseTo(lastTime + 1000);

      await minter.connect(governance).mint();

      const jellySupplyAfterMint = await jellyToken.totalSupply();

      expect(jellySupply).to.be.lt(jellySupplyAfterMint);
    });

    it("Mints tokens to the beneficiaries", async () => {
      const lastTime = await time.latest();
      await time.increaseTo(lastTime + 1000);

      await minter.connect(governance).mint();

      const balance1 = await jellyToken.balanceOf(beneficiaries[0]);
      const balance2 = await jellyToken.balanceOf(beneficiaries[1]);

      expect(balance1).to.eq(10);
      expect(balance2).to.eq(10);
    });
  });

  describe("addBeneficiary", () => {
    it("Reverts when non governance address tries to add beneficiary", async () => {
      await expect(
        minter.connect(otherAccount).addBeneficiary(otherAccount)
      ).to.be.revertedWith("Only governance can call.")
    });

    it("Adds beneficiary", async () => {
      await minter.connect(governance).addBeneficiary(otherAccount.address)
      const newBeneficiary = await minter.beneficiaries(2);
      expect(otherAccount.address).to.eq(newBeneficiary);
    });
  });

  describe("removeBeneficiary", () => {
    it("Reverts when non governance address tries to remove beneficiary", async () => {
      await expect(
        minter.connect(otherAccount).removeBeneficiary(beneficiaries[0])
      ).to.be.revertedWith("Only governance can call.")
    });

    it("Reverts when beneficiary doesn't exist", async () => {
      await expect(
        minter.connect(governance).removeBeneficiary(otherAccount)
      ).to.be.revertedWith("Address not in beneficiary list.");
    });

    it("Removes beneficiary", async () => {
      await minter.connect(governance).removeBeneficiary(beneficiaries[0].address)
      const firstBeneficiarry = await minter.beneficiaries(0);

      expect(beneficiaries[1].address).to.eq(firstBeneficiarry);
    });
  });
});
