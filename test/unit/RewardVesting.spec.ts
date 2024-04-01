import { loadFixture, time } from "@nomicfoundation/hardhat-network-helpers";
import { expect, assert } from "chai";
import { Signer, constants } from "ethers";
import { ethers } from "hardhat";
import { StandardMerkleTree } from "@openzeppelin/merkle-tree";

describe("RewardVesting", function () {
  async function deployUnitFixture() {
    const [deployer, user, ...otherSigners] = await ethers.getSigners();

    const ERC20Factory = await ethers.getContractFactory("JellyToken");
    const erc20 = await ERC20Factory.deploy(deployer.address);
    const amount = "100000";
    erc20.mint(deployer.address,amount);

    const RewardVestingFactory = await ethers.getContractFactory(
      "RewardVesting"
    );
    const RewardVesting = await RewardVestingFactory.deploy(
      deployer.address,
      constants.AddressZero,
      deployer.address,
      deployer.address,
      erc20.address
    );

    await erc20.approve(RewardVesting.address, amount);

    return { RewardVesting, deployer, user, otherSigners, erc20, amount };
  }

  let RewardVesting: any;
  let owner: any;
  let pendingOwner: Signer;
  let otherSigners: any[];
  let erc20: any;
  let liquidityContract: any;
  let stakingContract: any;
  let amount: any;

  beforeEach(async function () {
    const fixture = await loadFixture(deployUnitFixture);
    RewardVesting = fixture.RewardVesting;
    owner = fixture.deployer;
    pendingOwner = fixture.user;
    otherSigners = fixture.otherSigners;
    erc20 = fixture.erc20;
    liquidityContract = fixture.deployer;
    stakingContract = fixture.deployer;
    amount = fixture.amount;
  });

  describe("Vest Liquidity", async function () {
    describe("success", async () => {
      it("should vest an amount", async () => {
        await expect(RewardVesting.vestLiquidity(amount, owner.address))
          .to.emit(RewardVesting, "VestedLiqidty")
          .withArgs(amount, owner.address);

        const position = await RewardVesting.liquidityVestedPositions(
          owner.address
        );
        const timestamp = await time.latest();
        expect(position[0]).eq(amount);
        expect(position[1]).eq(timestamp);
      });
    });

    describe("failure", async () => {
      it("should not allow other addresses to vest", async () => {
        await expect(
          RewardVesting.connect(otherSigners[0]).vestLiquidity(
            amount,
            owner.address
          )
        ).to.be.revertedWithCustomError(RewardVesting, "Vest__InvalidCaller");
      });

      it("should not allow benificary to ve zero address", async () => {
        await expect(
          RewardVesting.vestLiquidity(amount, constants.AddressZero)
        ).to.be.revertedWithCustomError(RewardVesting, "Vest__ZeroAddress");
      });

      it("should not allow zero amount to vest", async () => {
        await expect(
          RewardVesting.vestLiquidity(constants.Zero, owner.address)
        ).to.be.revertedWithCustomError(
          RewardVesting,
          "Vest__InvalidVestingAmount"
        );
      });

      it("should not allow to vest if vested", async () => {
        await RewardVesting.vestLiquidity(amount, owner.address);

        await expect(
          RewardVesting.vestLiquidity(amount, owner.address)
        ).to.be.revertedWithCustomError(RewardVesting, "Vest__AlreadyVested");
      });
    });
  });

  describe("Claim Liquidity", async function () {
    beforeEach(async function () {
      await RewardVesting.vestLiquidity(amount, owner.address);
    });

    describe("success", async () => {
      it("should claim full amount", async () => {
        ethers.provider.send("evm_increaseTime", [30 * 24 * 60 * 60]);

        await expect(RewardVesting.claimLiquidity())
          .to.emit(RewardVesting, "VestingLiquidityClaimed")
          .withArgs(amount, owner.address);

        expect(await erc20.balanceOf(owner.address)).eq(amount);
        const position = await RewardVesting.liquidityVestedPositions(
          owner.address
        );
        expect(position[0]).eq(constants.Zero);
      });

      it("should claim half amount", async () => {
        ethers.provider.send("evm_increaseTime", [15 * 24 * 60 * 60]);

        await expect(RewardVesting.claimLiquidity())
          .to.emit(RewardVesting, "VestingLiquidityClaimed")
          .withArgs(amount * 0.75, owner.address);

        expect(await erc20.balanceOf(owner.address)).eq(amount * 0.75);
        const position = await RewardVesting.liquidityVestedPositions(
          owner.address
        );
        expect(position[0]).eq(constants.Zero);
      });
    });

    describe("failure", async () => {
      it("should not allow to claim twice", async () => {
        await RewardVesting.claimLiquidity();
        await expect(
          RewardVesting.claimLiquidity()
        ).to.be.revertedWithCustomError(RewardVesting, "Vest__NothingToClaim");
      });
    });
  });

  describe("Vest Staking", async function () {
    describe("success", async () => {
      it("should vest an amount", async () => {
        await expect(RewardVesting.vestStaking(amount, owner.address))
          .to.emit(RewardVesting, "VestedStaking")
          .withArgs(amount, owner.address);
      });
      expect(await erc20.balanceOf(RewardVesting.address)).eq(amount);
      const position = await RewardVesting.liquidityVestedPositions(
        owner.address
      );
      const timestamp = await time.latest();
      expect(position[0]).eq(amount);
      expect(position[1]).eq(timestamp);
    });

    describe("failure", async () => {
      it("should not allow other addresses to vest", async () => {
        await expect(
          RewardVesting.connect(otherSigners[0]).vestStaking(
            amount,
            owner.address
          )
        ).to.be.revertedWithCustomError(RewardVesting, "Vest__InvalidCaller");
      });

      it("should not allow benificary to ve zero address", async () => {
        await expect(
          RewardVesting.vestStaking(amount, constants.AddressZero)
        ).to.be.revertedWithCustomError(RewardVesting, "Vest__ZeroAddress");
      });

      it("should not allow zero amount to vest", async () => {
        await expect(
          RewardVesting.vestStaking(constants.Zero, owner.address)
        ).to.be.revertedWithCustomError(
          RewardVesting,
          "Vest__InvalidVestingAmount"
        );
      });

      it("should not allow to vest if vested", async () => {
        await RewardVesting.vestLiquidity(amount, owner.address);

        await expect(
          RewardVesting.vestLiquidity(amount, owner.address)
        ).to.be.revertedWithCustomError(RewardVesting, "Vest__AlreadyVested");
      });
    });
  });

  describe("Claim Staking", async function () {
    beforeEach(async function () {
      await RewardVesting.vestStaking(amount, owner.address);
    });

    describe("success", async () => {
      it("should claim full amount", async () => {
        ethers.provider.send("evm_increaseTime", [30 * 24 * 60 * 60]);

        await expect(RewardVesting.claimStaking())
          .to.emit(RewardVesting, "VestingStakingClaimed")
          .withArgs(amount, owner.address);

        expect(await erc20.balanceOf(owner.address)).eq(amount);
   
        const position = await RewardVesting.liquidityVestedPositions(
          owner.address
        );
        expect(position[0]).eq(constants.Zero);
      });

      it("should claim half amount", async () => {
        ethers.provider.send("evm_increaseTime", [15 * 24 * 60 * 60]);

        await expect(RewardVesting.claimStaking())
          .to.emit(RewardVesting, "VestingStakingClaimed")
          .withArgs(amount * 0.75, owner.address);

        expect(await erc20.balanceOf(owner.address)).eq(amount * 0.75);
       
        const position = await RewardVesting.liquidityVestedPositions(
          owner.address
        );
        expect(position[0]).eq(constants.Zero);
      });
    });

    describe("failure", async () => {
      it("should not allow to claim twice", async () => {
        await RewardVesting.claimStaking();
        await expect(
          RewardVesting.claimStaking()
        ).to.be.revertedWithCustomError(RewardVesting, "Vest__NothingToClaim");
      });
    });
  });
});
