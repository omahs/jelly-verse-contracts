import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect, assert } from "chai";
import { Signer, constants } from "ethers";
import { ethers } from "hardhat";
import { StandardMerkleTree } from "@openzeppelin/merkle-tree";

describe("StakingRewardDistrubtion", function () {
  async function deployUnitFixture() {
    const [deployer, user, ...otherSigners] = await ethers.getSigners();

    const ERC20Factory = await ethers.getContractFactory("ERC20Token");
    const erc20 = await ERC20Factory.deploy("test", "test");
    erc20.mint("100000");

    const StakingRewardDistrubtionFactory = await ethers.getContractFactory(
      "StakingRewardDistrubtion"
    );
    const StakingRewardDistrubtion =
      await StakingRewardDistrubtionFactory.deploy(
        erc20.address,
        deployer.address,
        constants.AddressZero
      );

    await erc20.approve(StakingRewardDistrubtion.address, "100000");

    return { StakingRewardDistrubtion, deployer, user, otherSigners, erc20 };
  }

  let StakingRewardDistrubtion: any;
  let owner: any;
  let pendingOwner: Signer;
  let otherSigners: any[];
  let erc20: any;

  beforeEach(async function () {
    const fixture = await loadFixture(deployUnitFixture);
    StakingRewardDistrubtion = fixture.StakingRewardDistrubtion;
    owner = fixture.deployer;
    pendingOwner = fixture.user;
    otherSigners = fixture.otherSigners;
    erc20 = fixture.erc20;
  });

  describe("Create Epoch", async function () {
    describe("success", async () => {
      it("should create an epoch", async () => {
        const values = [[owner.address, ethers.utils.parseEther("1")]];
        const tree = StandardMerkleTree.of(values, ["address", "uint256"]);
        await expect(StakingRewardDistrubtion.createEpoch(tree.root, ""))
          .to.emit(StakingRewardDistrubtion, "EpochAdded")
          .withArgs(constants.Zero, tree.root, "");
      });
    });

    describe("failure", async () => {
      it("should not allow other users to create epoch", async () => {
        const values = [[owner.address, ethers.utils.parseEther("1")]];
        const tree = StandardMerkleTree.of(values, ["address", "uint256"]);
        await expect(
          StakingRewardDistrubtion.connect(otherSigners[0]).createEpoch(
            tree.root,
            ""
          )
        ).to.be.revertedWithCustomError(
          StakingRewardDistrubtion,
          "Ownable__CallerIsNotOwner"
        );
      });
    });
  });

  describe("Claim week", async function () {
    beforeEach(async function () {
      await StakingRewardDistrubtion.deposit(erc20.address, "100000");

      const values = [[owner.address, ethers.utils.parseEther("1")]];
      const tree = StandardMerkleTree.of(values, ["address", "uint256"]);
      await StakingRewardDistrubtion.createEpoch(tree.root, "");
    });

    describe("success", async () => {
      it("should claim the amount", async () => {
        const values = [[owner.address, ethers.utils.parseEther("1")]];
        const tree = StandardMerkleTree.of(values, ["address", "uint256"]);
        const proof = tree.getProof(0);

        await expect(
          StakingRewardDistrubtion.claimWeek(
            constants.Zero,
            [erc20.address],
            ethers.utils.parseEther("1"),
            proof,
            false
          )
        )
          .to.emit(StakingRewardDistrubtion, "Claimed")
          .withArgs(owner.address, "100000", erc20.address, constants.Zero);

        expect(await erc20.balanceOf(owner.address)).eq("50000");
      });
    });

    describe("failure", async () => {
      it("should not allow to claim with wrong amount", async () => {
        const values = [[owner.address, ethers.utils.parseEther("1")]];
        const tree = StandardMerkleTree.of(values, ["address", "uint256"]);
        const proof = tree.getProof(0);
        await expect(
          StakingRewardDistrubtion.claimWeek(
            constants.Zero,
            [erc20.address],
            ethers.utils.parseEther("2"),
            proof,
            false
          )
        ).to.be.revertedWithCustomError(
          StakingRewardDistrubtion,
          "Claim_WrongProof"
        );
      });

      it("should not allow to claim with wrong address", async () => {
        const values = [
          [otherSigners[0].address, ethers.utils.parseEther("1")],
        ];
        const tree = StandardMerkleTree.of(values, ["address", "uint256"]);
        const proof = tree.getProof(0);
        await expect(
          StakingRewardDistrubtion.connect(otherSigners[0]).claimWeek(
            constants.Zero,
            [erc20.address],
            ethers.utils.parseEther("1"),
            proof,
            false
          )
        ).to.be.revertedWithCustomError(
          StakingRewardDistrubtion,
          "Claim_WrongProof"
        );
      });

      it("should not allow to claim zero amount", async () => {
        const values = [[owner.address, ethers.utils.parseEther("1")]];
        const tree = StandardMerkleTree.of(values, ["address", "uint256"]);
        const proof = tree.getProof(0);
        await expect(
          StakingRewardDistrubtion.claimWeek(
            constants.Zero,
            [erc20.address],
            ethers.utils.parseEther("0"),
            proof,
            false
          )
        ).to.be.revertedWithCustomError(
          StakingRewardDistrubtion,
          "Claim_ZeroAmount"
        );
      });

      it("should not allow to claim twice", async () => {
        const values = [[owner.address, ethers.utils.parseEther("1")]];
        const tree = StandardMerkleTree.of(values, ["address", "uint256"]);
        const proof = tree.getProof(0);

        await StakingRewardDistrubtion.claimWeek(
          constants.Zero,
          [erc20.address],
          ethers.utils.parseEther("1"),
          proof,
          false
        );

        await expect(
          StakingRewardDistrubtion.claimWeek(
            constants.Zero,
            [erc20.address],
            ethers.utils.parseEther("1"),
            proof,
            false
          )
        ).to.be.revertedWithCustomError(
          StakingRewardDistrubtion,
          "Claim_AlreadyClaimed"
        );
      });

      it("should not allow to claim future epoch", async () => {
        const values = [[owner.address, ethers.utils.parseEther("1")]];
        const tree = StandardMerkleTree.of(values, ["address", "uint256"]);
        const proof = tree.getProof(0);

        await expect(
          StakingRewardDistrubtion.claimWeek(
            constants.One,
            [erc20.address],
            ethers.utils.parseEther("1"),
            proof,
            false
          )
        ).to.be.revertedWithCustomError(
          StakingRewardDistrubtion,
          "Claim_FutureEpoch"
        );
      });
    });
  });

  describe("Claim weeks", async function () {
    beforeEach(async function () {
      const values = [[owner.address, ethers.utils.parseEther("1")]];
      const tree = StandardMerkleTree.of(values, ["address", "uint256"]);
      await StakingRewardDistrubtion.deposit(erc20.address, "50000");
      await StakingRewardDistrubtion.createEpoch(tree.root, "");
      await StakingRewardDistrubtion.deposit(erc20.address, "50000");
      ``;
      await StakingRewardDistrubtion.createEpoch(tree.root, "");
    });

    describe("success", async () => {
      it("should claim the amounts", async () => {
        const values = [[owner.address, ethers.utils.parseEther("1")]];
        const tree = StandardMerkleTree.of(values, ["address", "uint256"]);
        const proof = [tree.getProof(0), tree.getProof(0)];

        await expect(
          StakingRewardDistrubtion.claimWeeks(
            [constants.Zero, constants.One],
            [erc20.address],
            [ethers.utils.parseEther("1"), ethers.utils.parseEther("1")],
            proof,
            false
          )
        )
          .to.emit(StakingRewardDistrubtion, "Claimed")
          .withArgs(owner.address, "50000", erc20.address, constants.Zero);

        expect(await (await erc20).balanceOf(owner.address)).eq("50000");
      });
    });

    describe("failure", async () => {
      it("should not allow to claim with mismatching lengths", async () => {
        const values = [[owner.address, ethers.utils.parseEther("1")]];
        const tree = StandardMerkleTree.of(values, ["address", "uint256"]);
        const proof = [tree.getProof(0)];

        await expect(
          StakingRewardDistrubtion.claimWeeks(
            [constants.Zero, constants.One],
            [erc20.address],
            [ethers.utils.parseEther("1"), ethers.utils.parseEther("1")],
            proof,
            false
          )
        ).to.be.revertedWithCustomError(
          StakingRewardDistrubtion,
          "Claim_LenMissmatch"
        );
      });
    });
  });

  describe("Verify claim", async function () {
    beforeEach(async function () {
      const values = [[owner.address, ethers.utils.parseEther("1")]];
      const tree = StandardMerkleTree.of(values, ["address", "uint256"]);
      await StakingRewardDistrubtion.createEpoch(tree.root, "");
    });

    describe("success", async () => {
      it("should return true", async () => {
        const values = [[owner.address, "1000000"]];
        const tree = StandardMerkleTree.of(values, ["address", "uint256"]);
        const proof = tree.getProof(0);

        expect(
          await StakingRewardDistrubtion.verifyClaim(
            owner.address,
            constants.Zero,
            ethers.utils.parseEther("1"),
            proof
          )
        ).eq(true);
      });
    });

    describe("failure", async () => {
      it("should return false with wrong amount", async () => {
        const values = [[owner.address, ethers.utils.parseEther("1")]];
        const tree = StandardMerkleTree.of(values, ["address", "uint256"]);
        const proof = tree.getProof(0);

        expect(
          await StakingRewardDistrubtion.verifyClaim(
            owner.address,
            constants.Zero,
            ethers.utils.parseEther("0.5"),
            proof
          )
        ).eq(false);
      });

      it("should return false with wrong address", async () => {
        const values = [[owner.address, ethers.utils.parseEther("1")]];
        const tree = StandardMerkleTree.of(values, ["address", "uint256"]);
        const proof = tree.getProof(0);

        expect(
          await StakingRewardDistrubtion.verifyClaim(
            otherSigners[0].address,
            constants.Zero,
            ethers.utils.parseEther("1"),
            proof
          )
        ).eq(false);
      });
    });
  });

  describe("Remove epoch", async function () {
    const values = [[owner.address, ethers.utils.parseEther("1")]];
    const tree = StandardMerkleTree.of(values, ["address", "uint256"]);
    await StakingRewardDistrubtion.createEpoch(tree.root, "");

    it("should emit event", async () => {
      const values = [[owner.address, ethers.utils.parseEther("1")]];
      const tree = StandardMerkleTree.of(values, ["address", "uint256"]);
      await StakingRewardDistrubtion.createEpoch(tree.root, "");

      await expect(StakingRewardDistrubtion.removeEpoch(constants.Zero))
        .to.emit(StakingRewardDistrubtion, "EpochRemoved")
        .withArgs(constants.Zero);
    });
  });
});
