import { expect } from 'chai';
import { Signer } from 'ethers';
import { ethers } from 'hardhat';

// @notice -- I did not test ownable cuz it is not necessary and it is community approved

describe('OfficialPoolsRegister', function () {
  let officialPoolsRegister: any;
  let owner: Signer;
  let pendingOwner: Signer;
  let otherSigners: Signer[];
  const poolId = "100";

  beforeEach(async function () {
    [owner, pendingOwner, ...otherSigners] = await ethers.getSigners();

    const OfficialPoolsRegisterFactory = await ethers.getContractFactory(
      "OfficialPoolsRegister",
    );
    officialPoolsRegister = await OfficialPoolsRegisterFactory.deploy(
      await owner.getAddress(),
      await pendingOwner.getAddress(),
    );
    await officialPoolsRegister.deployed();
  });

  describe("Check for initial state after deployment", async function () {
    it("should have correct initial owner and pending owner", async () => {
      expect(await owner.getAddress(), await officialPoolsRegister.owner());
      expect(
        await pendingOwner.getAddress(),
        await officialPoolsRegister.getPendingOwner(),
      );
    });

    it("should have the expected initial owner", async () => {
      const initialOwner = await officialPoolsRegister.owner();
      expect(initialOwner).to.equal(await owner.getAddress());
    });
  });

  describe("registerOfficialPool", async function () {
    it("should create pool successfully", async () => {
      expect(officialPoolsRegister.registerOfficialPool(poolId))
        .to.emit(officialPoolsRegister, "OfficialPoolRegistered")
        .withArgs(await owner.getAddress(), poolId);

      const officialPoolsIds =
        await officialPoolsRegister.getAllOfficialPools();
      expect(officialPoolsIds[0], poolId);
    });

    it("should revert on create the same pool", async () => {
      expect(
        officialPoolsRegister.registerOfficialPool(poolId),
      ).to.be.revertedWithCustomError(
        officialPoolsRegister,
        "OfficialPoolsRegister_InvalidPool",
      );
    });

    it("should revert when registering a pool by a non-owner", async () => {
      expect(
        officialPoolsRegister
          .connect(otherSigners[0])
          .registerOfficialPool(poolId),
      ).to.be.revertedWithCustomError(
        officialPoolsRegister,
        "Ownable__CallerIsNotOwner",
      );
    });
  });

  describe("deregisterOfficialPool", async function () {
    it("should emit event", async () => {
      expect(officialPoolsRegister.deregisterOfficialPool(0))
        .to.emit(officialPoolsRegister, "OfficalPoolDeregistered")
        .withArgs(await owner.getAddress(), poolId);
    });

    it("should revert when deregistering an invalid pool", async () => {
      expect(
        officialPoolsRegister.deregisterOfficialPool(5),
      ).to.be.revertedWithCustomError(
        officialPoolsRegister,
        "OfficialPoolsRegister_InvalidPool",
      );
    });

    it("should revert when deregistering a pool by a non-owner", () => {
      expect(
        officialPoolsRegister
          .connect(otherSigners[0])
          .deregisterOfficialPool(0),
      ).to.be.revertedWithCustomError(
        officialPoolsRegister,
        "Ownable__CallerIsNotOwner",
      );
    });
  });
});
