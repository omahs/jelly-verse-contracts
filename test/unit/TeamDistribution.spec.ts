import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect, assert } from "chai";
import { Signer, constants } from "ethers";
import { ethers } from "hardhat";
import { StandardMerkleTree } from "@openzeppelin/merkle-tree";

describe("TeamDistribution", function () {
  async function deployUnitFixture() {
    const [deployer, user, ...otherSigners] = await ethers.getSigners();

    const totalAmount = ethers.utils.parseEther("110000000");
    const ERC20Factory = await ethers.getContractFactory("ERC20Token");
    const erc20 = await ERC20Factory.deploy("test", "test");
    erc20.mint(totalAmount);

    const ChestFactory = await ethers.getContractFactory("Chest");

  
    const TeamDistributionFactory = await ethers.getContractFactory(
      "TeamDistribution"
    );
    const TeamDistribution = await TeamDistributionFactory.deploy(
      erc20.address,
      deployer.address,
      constants.AddressZero
    );


    const chest = await ChestFactory.deploy(
      erc20.address,
      0,
      0,
      deployer.address,
      constants.AddressZero
    );

    await erc20.transfer(TeamDistribution.address, totalAmount);

    return {
      TeamDistribution,
      deployer,
      user,
      otherSigners,
      erc20,
      chest,
      totalAmount,
    };
  }

  let TeamDistribution: any;
  let owner: any;
  let pendingOwner: Signer;
  let otherSigners: any[];
  let erc20: any;
  let chest: any;
  let totalAmount: any;

  beforeEach(async function () {
    const fixture = await loadFixture(deployUnitFixture);
    TeamDistribution = fixture.TeamDistribution;
    owner = fixture.deployer;
    pendingOwner = fixture.user;
    otherSigners = fixture.otherSigners;
    erc20 = fixture.erc20;
    chest = fixture.chest;
    totalAmount = fixture.totalAmount;
  });

  describe("Set Chest", async function () {
    describe("success", async () => {
      it("should set a chest", async () => {
        await expect(TeamDistribution.setChest(chest.address))
          .to.emit(TeamDistribution, "ChestSet")
          .withArgs(chest.address);

        expect(await TeamDistribution.chestContract()).eq(chest.address);
        expect(
          await erc20.allowance(TeamDistribution.address, chest.address)
        ).eq(totalAmount);
      });
    });

    describe("failure", async () => {
      it("should not allow to set chest twice", async () => {
        await TeamDistribution.setChest(chest.address);
        await expect(
          TeamDistribution.setChest(chest.address)
        ).to.be.revertedWithCustomError(
          TeamDistribution,
          "TeamDistribution__ChestAlreadySet"
        );
      });
    });
  });

  describe("Distribute", async function () {
    beforeEach(async function () {
      await TeamDistribution.setChest(chest.address);
    });
    describe("success", async () => {
      it("should distribute all at once", async () => {
        await expect(TeamDistribution.distribute(15))
          .to.emit(TeamDistribution, "BatchDistributed")
          .withArgs(constants.Zero, 15);

        expect(
          await chest.balanceOf("0x76e43d3E07c204F25e3a46Ead7Ccc1b07611061D")
        ).eq(13); //this will change
        expect(await erc20.balanceOf(TeamDistribution.address)).eq(
          constants.Zero
        );
      });

      it("should distribute in batches", async () => {
        await expect(TeamDistribution.distribute(10))
          .to.emit(TeamDistribution, "BatchDistributed")
          .withArgs(constants.Zero, 10);

        expect(
          await chest.balanceOf("0x76e43d3E07c204F25e3a46Ead7Ccc1b07611061D")
        ).eq(9); //this will change
     

        await expect(TeamDistribution.distribute(5))
        .to.emit(TeamDistribution, "BatchDistributed")
        .withArgs(10, 5);

      expect(
        await chest.balanceOf("0x76e43d3E07c204F25e3a46Ead7Ccc1b07611061D")
      ).eq(13); //this will change
      });
    });

    describe("failure", async () => {
      it("should not allow batch len to be zero", async () => {
        await expect(
          TeamDistribution.distribute(constants.Zero)
        ).to.be.revertedWithCustomError(
          TeamDistribution,
          "TeamDistribution__InvalidBatchLength"
        );
      });

      it("should not allow batch len to exceed max", async () => {
        await expect(
          TeamDistribution.distribute(16)
        ).to.be.revertedWithCustomError(
          TeamDistribution,
          "TeamDistribution__DistributionIndexOutOfBounds"
        );
      });
    });
  });
});
