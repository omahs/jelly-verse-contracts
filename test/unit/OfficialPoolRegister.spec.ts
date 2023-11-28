import { loadFixture } from '@nomicfoundation/hardhat-network-helpers';
import { expect } from 'chai';
import { Signer } from 'ethers';
import { ethers } from 'hardhat';

// @notice -- I did not test ownable cuz it is not necessary and it is community approved

describe('OfficialPoolsRegister', function () {
  async function deployUnitFixture() {
    const [deployer, user, ...otherSigners] = await ethers.getSigners();

    const OfficialPoolsRegisterFactory = await ethers.getContractFactory('OfficialPoolsRegister');
    const officialPoolsRegister = await OfficialPoolsRegisterFactory.deploy(
        deployer.address,
        user.address
    );

    return { officialPoolsRegister, deployer, user, otherSigners };
  }

  let officialPoolsRegister: any;
  let owner: Signer;
  let pendingOwner: Signer;
  let otherSigners: Signer[];
  const pool1Id = "0x7f65ce7eed9983ba6973da773ca9d574f285a24c000200000000000000000000";
  const pool2Id = "0x8r23ce7eed9983ba6973da773ca9d574f285a24c000200000000000000000000";

  beforeEach(async function () {
    const fixture = await loadFixture(deployUnitFixture);
    officialPoolsRegister = fixture.officialPoolsRegister;
    owner = fixture.deployer;
    pendingOwner = fixture.user;
    otherSigners = fixture.otherSigners;
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

  describe("#registerOfficialPool", async function () {
    describe("success", async () => {
      it("should register pools", async () => {
        const pools: string[] = [pool1Id, pool2Id];

        for (const poolId of pools) {
          expect(officialPoolsRegister.registerOfficialPool(pools))
          .to.emit(officialPoolsRegister, "OfficialPoolRegistered")
          .withArgs(await owner.getAddress(), poolId);
        }

        const officialPoolsIds = await officialPoolsRegister.getAllOfficialPools();

        for (const [i, pool] of pools.entries()) {
          expect(officialPoolsIds[i], pool);
        }
      });
    })

    describe("failure", async () => {
      it("should revert on register the same pool", async () => {
        expect(
          officialPoolsRegister.registerOfficialPool(pool1Id),
        ).to.be.revertedWithCustomError(
          officialPoolsRegister,
          "OfficialPoolsRegister_InvalidPool",
        );
      });
  
      it("should revert when registering a pool by a non-owner", async () => {
        expect(
          officialPoolsRegister
            .connect(otherSigners[0])
            .registerOfficialPool(pool1Id),
        ).to.be.revertedWithCustomError(
          officialPoolsRegister,
          "Ownable__CallerIsNotOwner",
        );
      });
    })
  });

  describe("#deregisterOfficialPool", async function () {
    describe("success", async () => {
      it("should emit event", async () => {
        expect(officialPoolsRegister.deregisterOfficialPool(0))
          .to.emit(officialPoolsRegister, "OfficialPoolDeregistered")
          .withArgs(await owner.getAddress(), pool1Id);


        const officialPoolsIds =
          await officialPoolsRegister.getAllOfficialPools();
        expect(officialPoolsIds[0], undefined);
      });
    })

    describe("failure", async () => {
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
    })
  });
});
