import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { Signer, constants } from "ethers";
import { ethers } from "hardhat";
import { StandardMerkleTree } from "@openzeppelin/merkle-tree";

describe("LiquidityRewardDistribution", function () {
  async function deployUnitFixture() {
    const [deployer, user, ...otherSigners] = await ethers.getSigners();

    const ERC20Factory = await ethers.getContractFactory("JellyToken");
    const erc20 = await ERC20Factory.deploy(deployer.address);
    erc20.mint(deployer.address,"100000");

    const LiquidityRewardDistributionFactory = await ethers.getContractFactory(
      "LiquidityRewardDistribution"
    );
    const LiquidityRewardDistribution =
      await LiquidityRewardDistributionFactory.deploy(
        erc20.address,
        deployer.address,
        "0x0000000000000000000000000000000000000000"
      );

    await erc20.transfer(LiquidityRewardDistribution.address, "100000");

    return { LiquidityRewardDistribution, deployer, user, otherSigners, erc20 };
  }

  let LiquidityRewardDistribution: any;
  let owner: any;
  let pendingOwner: Signer;
  let otherSigners: any[];
  let erc20: any;

  beforeEach(async function () {
    const fixture = await loadFixture(deployUnitFixture);
    LiquidityRewardDistribution = fixture.LiquidityRewardDistribution;
    owner = fixture.deployer;
    pendingOwner = fixture.user;
    otherSigners = fixture.otherSigners;
    erc20 = fixture.erc20;
  });

  describe("Create Epoch", async function () {
    describe("success", async () => {
      it("should create an epoch", async () => {
        const values = [[owner.address, "100000"]];
        const tree = StandardMerkleTree.of(values, ["address", "uint256"]);
        await expect(LiquidityRewardDistribution.createEpoch(tree.root, ""))
          .to.emit(LiquidityRewardDistribution, "EpochAdded")
          .withArgs(constants.Zero, tree.root, "");

        expect(await LiquidityRewardDistribution.epoch()).eq(constants.One);
        expect(await LiquidityRewardDistribution.merkleRoots(constants.Zero)).eq(
          tree.root
        );
      });
    });

    describe("failure", async () => {
      it("should not allow other users to create epoch", async () => {
        const values = [[owner.address, "100000"]];
        const tree = StandardMerkleTree.of(values, ["address", "uint256"]);
        await expect(
          LiquidityRewardDistribution.connect(otherSigners[0]).createEpoch(
            tree.root,
            ""
          )
        ).to.be.revertedWithCustomError(
          LiquidityRewardDistribution,
          "Ownable__CallerIsNotOwner"
        );
      });
    });
  });
  describe("Claim week", async function () {
    beforeEach(async function () {
      const values = [[owner.address, "100000"]];
      const tree = StandardMerkleTree.of(values, ["address", "uint256"]);
      await LiquidityRewardDistribution.createEpoch(tree.root, "");
    });
    describe("success", async () => {
      it("should claim the amount", async () => {
        const values = [[otherSigners[0].address, "100000"]];
        const tree = StandardMerkleTree.of(values, ["address", "uint256"]);
        const proof = tree.getProof(0);

        await expect(
          LiquidityRewardDistribution.claimWeek(
            constants.Zero,
            "100000",
            proof,
            false
          )
        )
          .to.emit(LiquidityRewardDistribution, "Claimed")
          .withArgs(owner.address, constants.Zero, "100000");

        expect(await erc20.balanceOf(owner.address)).eq("50000");
        expect(
          await LiquidityRewardDistribution.claimed(
            constants.Zero,
            owner.address
          )
        ).eq(true);
      });
    });

    describe("failure", async () => {
      it("should not allow to claim with wrong amount", async () => {
        const values = [[owner.address, "100000"]];
        const tree = StandardMerkleTree.of(values, ["address", "uint256"]);
        const proof = tree.getProof(0);
        await expect(
          LiquidityRewardDistribution.claimWeek(
            constants.Zero,
            "1000000",
            proof,
            false
          )
        ).to.be.revertedWithCustomError(
          LiquidityRewardDistribution,
          "Claim_WrongProof"
        );
      });

      it("should not allow to claim with wrong address", async () => {
        const values = [[otherSigners[0].address, "1000000"]];
        const tree = StandardMerkleTree.of(values, ["address", "uint256"]);
        const proof = tree.getProof(0);
        await expect(
          LiquidityRewardDistribution.connect(otherSigners[0]).claimWeek(
            constants.Zero,
            "100000",
            proof,
            false
          )
        ).to.be.revertedWithCustomError(
          LiquidityRewardDistribution,
          "Claim_WrongProof"
        );
      });

      it("should not allow to claim zero amount", async () => {
        const values = [[owner.address, "100000"]];
        const tree = StandardMerkleTree.of(values, ["address", "uint256"]);
        const proof = tree.getProof(0);
        await expect(
          LiquidityRewardDistribution.claimWeek(
            constants.Zero,
            "0",
            proof,
            false
          )
        ).to.be.revertedWithCustomError(
          LiquidityRewardDistribution,
          "Claim_ZeroAmount"
        );
      });
      it("should not allow to claim twice", async () => {
        const values = [[owner.address, "100000"]];
        const tree = StandardMerkleTree.of(values, ["address", "uint256"]);
        const proof = tree.getProof(0);

        await LiquidityRewardDistribution.claimWeek(
          constants.Zero,
          "100000",
          proof,
          false
        );
        await expect(
          LiquidityRewardDistribution.claimWeek(
            constants.Zero,
            "100000",
            proof,
            false
          )
        ).to.be.revertedWithCustomError(
          LiquidityRewardDistribution,
          "Claim_AlreadyClaimed"
        );
      });
      it("should not allow to claim future epoch", async () => {
        const values = [[owner.address, "100000"]];
        const tree = StandardMerkleTree.of(values, ["address", "uint256"]);
        const proof = tree.getProof(0);

        await expect(
          LiquidityRewardDistribution.claimWeek(
            constants.One,
            "100000",
            proof,
            false
          )
        ).to.be.revertedWithCustomError(
          LiquidityRewardDistribution,
          "Claim_FutureEpoch"
        );
      });
    });
  });

  describe("Claim weeks", async function () {
    beforeEach(async function () {
      const values = [[owner.address, "50000"]];
      const tree = StandardMerkleTree.of(values, ["address", "uint256"]);
      await LiquidityRewardDistribution.createEpoch(tree.root, "");
      await LiquidityRewardDistribution.createEpoch(tree.root, "");
    });
    describe("success", async () => {
      it("should claim the amounts", async () => {
        const values = [[owner.address, "50000"]];
        const tree = StandardMerkleTree.of(values, ["address", "uint256"]);
        const proof = [tree.getProof(0), tree.getProof(0)];

        await expect(
          LiquidityRewardDistribution.claimWeeks(
            [constants.Zero, constants.One],
            ["50000", "50000"],
            proof,
            false
          )
        )
          .to.emit(LiquidityRewardDistribution, "Claimed")
          .withArgs(owner.address, constants.Zero, "50000");

        expect(await erc20.balanceOf(owner.address)).eq("50000");
        expect(
          await LiquidityRewardDistribution.claimed(
            constants.Zero,
            owner.address
          )
        ).eq(true);
        expect(
          await LiquidityRewardDistribution.claimed(constants.One, owner.address)
        ).eq(true);
      });
    });

    describe("failure", async () => {
      it("should not allow to claim with mismatching lengths", async () => {
        const values = [[owner.address, "50000"]];
        const tree = StandardMerkleTree.of(values, ["address", "uint256"]);
        const proof = [tree.getProof(0)];

        await expect(
          LiquidityRewardDistribution.claimWeeks(
            [constants.Zero, constants.One],
            ["50000", "50000"],
            proof,
            false
          )
        ).to.be.revertedWithCustomError(
          LiquidityRewardDistribution,
          "Claim_LenMissmatch"
        );
      });
    });
  });
  describe("Verify claim", async function () {
    beforeEach(async function () {
      const values = [[owner.address, "100000"]];
      const tree = StandardMerkleTree.of(values, ["address", "uint256"]);
      await LiquidityRewardDistribution.createEpoch(tree.root, "");
    });
    describe("success", async () => {
      it("should return true", async () => {
        const values = [[owner.address, "1000000"]];
        const tree = StandardMerkleTree.of(values, ["address", "uint256"]);
        const proof = tree.getProof(0);

        expect(
          await LiquidityRewardDistribution.verifyClaim(
            owner.address,
            constants.Zero,
            "100000",
            proof
          )
        ).eq(true);
      });
    });
    describe("failure", async () => {
      it("should return false with wrong amount", async () => {
        const values = [[owner.address, "100000"]];
        const tree = StandardMerkleTree.of(values, ["address", "uint256"]);
        const proof = tree.getProof(0);

        expect(
          await LiquidityRewardDistribution.verifyClaim(
            owner.address,
            constants.Zero,
            "1000",
            proof
          )
        ).eq(false);
      });
      it("should return false with wrong address", async () => {
        const values = [[owner.address, "100000"]];
        const tree = StandardMerkleTree.of(values, ["address", "uint256"]);
        const proof = tree.getProof(0);

        expect(
          await LiquidityRewardDistribution.verifyClaim(
            otherSigners[0].address,
            constants.Zero,
            "100000",
            proof
          )
        ).eq(false);
      });
    });
  });

});
