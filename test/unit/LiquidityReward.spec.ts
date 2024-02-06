import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect, assert } from "chai";
import { Signer, constants } from "ethers";
import { ethers } from "hardhat";
import { StandardMerkleTree } from "@openzeppelin/merkle-tree";

describe("LiquidityRewardDistrubtion", function () {
  async function deployUnitFixture() {
    const [deployer, user, ...otherSigners] = await ethers.getSigners();

    const ERC20Factory = await ethers.getContractFactory("ERC20Token");
    const erc20 = await ERC20Factory.deploy("test", "test");
    erc20.mint("100000");

    const LiquidityRewardDistrubtionFactory = await ethers.getContractFactory(
      "LiquidityRewardDistrubtion"
    );
    const LiquidityRewardDistrubtion =
      await LiquidityRewardDistrubtionFactory.deploy(
        erc20.address,
        deployer.address,
        "0x0000000000000000000000000000000000000000"
      );

    await erc20.transfer(LiquidityRewardDistrubtion.address, "100000");

    return { LiquidityRewardDistrubtion, deployer, user, otherSigners, erc20 };
  }

  let LiquidityRewardDistrubtion: any;
  let owner: any;
  let pendingOwner: Signer;
  let otherSigners: any[];
  let erc20: any;

  beforeEach(async function () {
    const fixture = await loadFixture(deployUnitFixture);
    LiquidityRewardDistrubtion = fixture.LiquidityRewardDistrubtion;
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
        await expect(LiquidityRewardDistrubtion.createEpoch(tree.root, ""))
          .to.emit(LiquidityRewardDistrubtion, "EpochAdded")
          .withArgs(constants.Zero, tree.root, "");

        expect(await LiquidityRewardDistrubtion.epoch()).eq(constants.One);
        expect(await LiquidityRewardDistrubtion.merkleRoots(constants.Zero)).eq(
          tree.root
        );
      });
    });

    describe("failure", async () => {
      it("should not allow other users to create epoch", async () => {
        const values = [[owner.address, "100000"]];
        const tree = StandardMerkleTree.of(values, ["address", "uint256"]);
        await expect(
          LiquidityRewardDistrubtion.connect(otherSigners[0]).createEpoch(
            tree.root,
            ""
          )
        ).to.be.revertedWithCustomError(
          LiquidityRewardDistrubtion,
          "Ownable__CallerIsNotOwner"
        );
      });
    });
  });
  describe("Claim week", async function () {
    beforeEach(async function () {
      const values = [[owner.address, "100000"]];
      const tree = StandardMerkleTree.of(values, ["address", "uint256"]);
      await LiquidityRewardDistrubtion.createEpoch(tree.root, "");
    });
    describe("success", async () => {
      it("should claim the amount", async () => {
        const values = [[otherSigners[0].address, "100000"]];
        const tree = StandardMerkleTree.of(values, ["address", "uint256"]);
        const proof = tree.getProof(0);

        await expect(
          LiquidityRewardDistrubtion.claimWeek(
            constants.Zero,
            "100000",
            proof,
            false
          )
        )
          .to.emit(LiquidityRewardDistrubtion, "Claimed")
          .withArgs(owner.address, constants.Zero, "100000");

        expect(await erc20.balanceOf(owner.address)).eq("50000");
        expect(
          await LiquidityRewardDistrubtion.claimed(
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
          LiquidityRewardDistrubtion.claimWeek(
            constants.Zero,
            "1000000",
            proof,
            false
          )
        ).to.be.revertedWithCustomError(
          LiquidityRewardDistrubtion,
          "Claim_WrongProof"
        );
      });

      it("should not allow to claim with wrong address", async () => {
        const values = [[otherSigners[0].address, "1000000"]];
        const tree = StandardMerkleTree.of(values, ["address", "uint256"]);
        const proof = tree.getProof(0);
        await expect(
          LiquidityRewardDistrubtion.connect(otherSigners[0]).claimWeek(
            constants.Zero,
            "100000",
            proof,
            false
          )
        ).to.be.revertedWithCustomError(
          LiquidityRewardDistrubtion,
          "Claim_WrongProof"
        );
      });

      it("should not allow to claim zero amount", async () => {
        const values = [[owner.address, "100000"]];
        const tree = StandardMerkleTree.of(values, ["address", "uint256"]);
        const proof = tree.getProof(0);
        await expect(
          LiquidityRewardDistrubtion.claimWeek(
            constants.Zero,
            "0",
            proof,
            false
          )
        ).to.be.revertedWithCustomError(
          LiquidityRewardDistrubtion,
          "Claim_ZeroAmount"
        );
      });
      it("should not allow to claim twice", async () => {
        const values = [[owner.address, "100000"]];
        const tree = StandardMerkleTree.of(values, ["address", "uint256"]);
        const proof = tree.getProof(0);

        await LiquidityRewardDistrubtion.claimWeek(
          constants.Zero,
          "100000",
          proof,
          false
        );
        await expect(
          LiquidityRewardDistrubtion.claimWeek(
            constants.Zero,
            "100000",
            proof,
            false
          )
        ).to.be.revertedWithCustomError(
          LiquidityRewardDistrubtion,
          "Claim_AlreadyClaimed"
        );
      });
      it("should not allow to claim future epoch", async () => {
        const values = [[owner.address, "100000"]];
        const tree = StandardMerkleTree.of(values, ["address", "uint256"]);
        const proof = tree.getProof(0);

        await expect(
          LiquidityRewardDistrubtion.claimWeek(
            constants.One,
            "100000",
            proof,
            false
          )
        ).to.be.revertedWithCustomError(
          LiquidityRewardDistrubtion,
          "Claim_FutureEpoch"
        );
      });
    });
  });

  describe("Claim weeks", async function () {
    beforeEach(async function () {
      const values = [[owner.address, "50000"]];
      const tree = StandardMerkleTree.of(values, ["address", "uint256"]);
      await LiquidityRewardDistrubtion.createEpoch(tree.root, "");
      await LiquidityRewardDistrubtion.createEpoch(tree.root, "");
    });
    describe("success", async () => {
      it("should claim the amounts", async () => {
        const values = [[owner.address, "50000"]];
        const tree = StandardMerkleTree.of(values, ["address", "uint256"]);
        const proof = [tree.getProof(0), tree.getProof(0)];

        await expect(
          LiquidityRewardDistrubtion.claimWeeks(
            [constants.Zero, constants.One],
            ["50000", "50000"],
            proof,
            false
          )
        )
          .to.emit(LiquidityRewardDistrubtion, "Claimed")
          .withArgs(owner.address, constants.Zero, "50000");

        expect(await erc20.balanceOf(owner.address)).eq("50000");
        expect(
          await LiquidityRewardDistrubtion.claimed(
            constants.Zero,
            owner.address
          )
        ).eq(true);
        expect(
          await LiquidityRewardDistrubtion.claimed(constants.One, owner.address)
        ).eq(true);
      });
    });

    describe("failure", async () => {
      it("should not allow to claim with mismatching lengths", async () => {
        const values = [[owner.address, "50000"]];
        const tree = StandardMerkleTree.of(values, ["address", "uint256"]);
        const proof = [tree.getProof(0)];

        await expect(
          LiquidityRewardDistrubtion.claimWeeks(
            [constants.Zero, constants.One],
            ["50000", "50000"],
            proof,
            false
          )
        ).to.be.revertedWithCustomError(
          LiquidityRewardDistrubtion,
          "Claim_LenMissmatch"
        );
      });
    });
  });
  describe("Verify claim", async function () {
    beforeEach(async function () {
      const values = [[owner.address, "100000"]];
      const tree = StandardMerkleTree.of(values, ["address", "uint256"]);
      await LiquidityRewardDistrubtion.createEpoch(tree.root, "");
    });
    describe("success", async () => {
      it("should return true", async () => {
        const values = [[owner.address, "1000000"]];
        const tree = StandardMerkleTree.of(values, ["address", "uint256"]);
        const proof = tree.getProof(0);

        expect(
          await LiquidityRewardDistrubtion.verifyClaim(
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
          await LiquidityRewardDistrubtion.verifyClaim(
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
          await LiquidityRewardDistrubtion.verifyClaim(
            otherSigners[0].address,
            constants.Zero,
            "100000",
            proof
          )
        ).eq(false);
      });
    });
  });
  describe("Remove epoch", async function () {
    const values = [[owner.address, "100000"]];
    const tree = StandardMerkleTree.of(values, ["address", "uint256"]);
    await LiquidityRewardDistrubtion.createEpoch(tree.root, "");

    it("should emit event", async () => {
      const values = [[owner.address, "100000"]];
      const tree = StandardMerkleTree.of(values, ["address", "uint256"]);
      await LiquidityRewardDistrubtion.createEpoch(tree.root, "");

      await expect(LiquidityRewardDistrubtion.removeEpoch(constants.Zero))
        .to.emit(LiquidityRewardDistrubtion, "EpochRemoved")
        .withArgs(constants.Zero);
    });

    expect(await LiquidityRewardDistrubtion.epoch(constants.Zero)).eq(
      constants.Zero
    );
  });
});
