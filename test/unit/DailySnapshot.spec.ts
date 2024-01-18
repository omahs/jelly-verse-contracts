import { loadFixture, mine, time,  } from '@nomicfoundation/hardhat-network-helpers';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { expect } from 'chai';
import { unitDailySnapshotFixture } from '../fixtures/unit__DailySnapshot';
import { DailySnapshot } from '../../typechain-types';

// @notice -- I did not test ownable cuz it is not necessary and it is community approved

describe('DailySnapshot', function () {
  let dailySnapshot: DailySnapshot;
  let owner: SignerWithAddress;
  let pendingOwner: SignerWithAddress;
  const ONE_DAY = 7200; // one day in blocks

  beforeEach(async function () {
    const fixture = await loadFixture(unitDailySnapshotFixture);
    dailySnapshot = fixture.dailySnapshot;
    owner = fixture.deployer;
    pendingOwner = fixture.user;
  });

  describe("Check for initial state after deployment", async function () {
    it("should have correct initial owner and pending owner", async () => {
      expect(await owner.getAddress(), await dailySnapshot.owner());
      expect(
        await pendingOwner.getAddress(),
        await dailySnapshot.getPendingOwner(),
      );
    });

    it("should have the expected initial owner", async () => {
      const initialOwner = await dailySnapshot.owner();
      expect(initialOwner).to.equal(await owner.getAddress());
    });
  });

  describe("#startSnapshoting", async function () {
    describe("success", async () => {
      it("should set started to true", async () => {
        await dailySnapshot.startSnapshoting();
        expect(await dailySnapshot.started()).to.be.true;
      });

      it("should set beginningOfTheNewDayBlocknumber to current blockNumber", async () => {
        const currentBlockNumber = await time.latestBlock();
        await dailySnapshot.startSnapshoting();
        expect(await dailySnapshot.beginningOfTheNewDayBlocknumber()).to.equal(currentBlockNumber + 1);
      });

      it("should emit SnapshotingStarted event", async () => {
        await expect(dailySnapshot.startSnapshoting())
        .to.emit(dailySnapshot, 'SnapshotingStarted')
        .withArgs(owner.address);
      });
    })

    describe("failure", async () => {
      it("should revert if already started", async () => {
        await dailySnapshot.startSnapshoting();
        await expect(
          dailySnapshot.startSnapshoting(),
        ).to.be.revertedWithCustomError(
          dailySnapshot,
          "DailySnapshot_AlreadyStarted",
        );
      });
    })
  });

  describe("#dailySnapshot", async function () {
    describe("success", async () => {
      beforeEach(async function () {
        await dailySnapshot.startSnapshoting();
      });

      it("should increase epochDaysIndex by 1", async () => {
        const epochDaysIndexBefore = await dailySnapshot.epochDaysIndex();
        await mine(ONE_DAY);
        await dailySnapshot.dailySnapshot();
        const epochDaysIndexAfter = await dailySnapshot.epochDaysIndex();
        expect(epochDaysIndexAfter).to.equal(epochDaysIndexBefore + 1);
      });

      it("should increase beginningOfTheNewDayBlocknumber by ONE_DAY", async () => {
        const beginningOfTheNewDayBlocknumberBefore = await dailySnapshot.beginningOfTheNewDayBlocknumber();
        await mine(ONE_DAY);
        await dailySnapshot.dailySnapshot();
        const beginningOfTheNewDayBlocknumberAfter = await dailySnapshot.beginningOfTheNewDayBlocknumber();
        expect(beginningOfTheNewDayBlocknumberAfter).to.equal(beginningOfTheNewDayBlocknumberBefore + ONE_DAY);
      });

      it("should set dailySnapshotsPerEpoch correctly", async () => {
        await mine(ONE_DAY);
        const epoch = await dailySnapshot.epoch();
        const epochDaysIndex = await dailySnapshot.epochDaysIndex();
        const beginningOfTheNewDayBlocknumber = await dailySnapshot.beginningOfTheNewDayBlocknumber();
        const randomValueBasedOnPrevrandao = 6204; // always the same in tests (block.prevrandao % 7200)
        await dailySnapshot.dailySnapshot();
        expect(await dailySnapshot.dailySnapshotsPerEpoch(epoch, epochDaysIndex)).to.equal(beginningOfTheNewDayBlocknumber + randomValueBasedOnPrevrandao);
      });

      it("should emit DailySnapshotAdded event", async () => {
        const beginningOfTheNewDayBlocknumber = await dailySnapshot.beginningOfTheNewDayBlocknumber();
        const randomValueBasedOnPrevrandao = 6204; // always the same in tests
        const epoch = await dailySnapshot.epoch();
        const epochDaysIndex = await dailySnapshot.epochDaysIndex();
        await mine(ONE_DAY);
        await expect(dailySnapshot.dailySnapshot())
        .to.emit(dailySnapshot, 'DailySnapshotAdded')
        .withArgs(owner.address, epoch, beginningOfTheNewDayBlocknumber + randomValueBasedOnPrevrandao, epochDaysIndex);
      });

      it("should set epochDaysIndex to 0 if 7 snapshoots done", async () => {
        for (let i = 0; i < 6; i++) {
          await mine(ONE_DAY);
          await dailySnapshot.dailySnapshot();
        }
        const epochDaysIndexBefore = await dailySnapshot.epochDaysIndex();
        expect(epochDaysIndexBefore).to.equal(6);

        await mine(ONE_DAY);
        await dailySnapshot.dailySnapshot();
        const epochDaysIndexAfter = await dailySnapshot.epochDaysIndex();
        expect(epochDaysIndexAfter).to.equal(0);
      });

      it("should increase epoch after 7 snapshots", async () => {
        const epochBefore = await dailySnapshot.epoch();
        expect(epochBefore).to.equal(0);
        for (let i = 0; i < 7; i++) {
          await mine(ONE_DAY);
          await dailySnapshot.dailySnapshot();
        }
        const epochAfter = await dailySnapshot.epoch();
        expect(epochAfter).to.equal(1);
      });
    })

    describe("failure", async () => {
      it("should revert if snapshoting has not started", async () => {
        await expect(
          dailySnapshot.dailySnapshot(),
        ).to.be.revertedWithCustomError(
          dailySnapshot,
          "DailySnapshot_NotStarted",
        );
      });

      it("should revert if snapshoting attempt was done too early (day not finished)", async () => {
        await dailySnapshot.startSnapshoting();
        await expect(
          dailySnapshot.dailySnapshot(),
        ).to.be.revertedWithCustomError(
          dailySnapshot,
          "DailySnapshot_TooEarly",
        );
      });
    })
  });
});
