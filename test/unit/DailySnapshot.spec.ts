import { loadFixture, mine, time, setPrevRandao } from '@nomicfoundation/hardhat-network-helpers';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { expect } from 'chai';
import { unitDailySnapshotFixture } from '../fixtures/unit__DailySnapshot';
import { DailySnapshot } from '../../typechain-types';

// @notice -- I did not test ownable cuz it is not necessary and it is community approved

describe('DailySnapshot', function () {
  let dailySnapshot: DailySnapshot;
  let owner: SignerWithAddress;
  let pendingOwner: SignerWithAddress;
  const ONE_DAY_BLOCKS = 192000; // 192000 blocks = 1 day, 0.45s per block
  const ONE_DAY_SECONDS = 86400; // one day in seconds
  
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

  describe("#startSnapshotting", async function () {
    describe("success", async () => {
      it("should set started to true", async () => {
        await dailySnapshot.startSnapshotting();
        expect(await dailySnapshot.started()).to.be.true;
      });

      it("should set beginningOfTheNewDayBlocknumber to current blockNumber", async () => {
        const currentBlockNumber = await time.latestBlock();
        await dailySnapshot.startSnapshotting();
        expect(await dailySnapshot.beginningOfTheNewDayBlocknumber()).to.equal(currentBlockNumber + 1);
      });

      it("should set beginningOfTheNewDayTimestamp to current block timestamp", async () => {
        const currentBlockTimestamp = await time.latest();
        await dailySnapshot.startSnapshotting();
        expect(await dailySnapshot.beginningOfTheNewDayTimestamp()).to.equal(currentBlockTimestamp + 1);
      });

      it("should emit SnapshottingStarted event", async () => {
        await expect(dailySnapshot.startSnapshotting())
        .to.emit(dailySnapshot, 'SnapshottingStarted')
        .withArgs(owner.address);
      });
    })

    describe("failure", async () => {
      it("should revert if already started", async () => {
        await dailySnapshot.startSnapshotting();
        await expect(
          dailySnapshot.startSnapshotting(),
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
        await dailySnapshot.startSnapshotting();
      });

      it("should increase epochDaysIndex by 1", async () => {
        const epochDaysIndexBefore = await dailySnapshot.epochDaysIndex();
        await time.increase(ONE_DAY_SECONDS);
        await dailySnapshot.dailySnapshot();
        const epochDaysIndexAfter = await dailySnapshot.epochDaysIndex();
        expect(epochDaysIndexAfter).to.equal(epochDaysIndexBefore + 1);
      });

      it("should increase beginningOfTheNewDayBlocknumber by ONE_DAY", async () => {
        const beginningOfTheNewDayBlocknumberBefore = await dailySnapshot.beginningOfTheNewDayBlocknumber();
        await time.increase(ONE_DAY_SECONDS);
        await dailySnapshot.dailySnapshot();
        const beginningOfTheNewDayBlocknumberAfter = await dailySnapshot.beginningOfTheNewDayBlocknumber();
        expect(beginningOfTheNewDayBlocknumberAfter).to.equal(beginningOfTheNewDayBlocknumberBefore + ONE_DAY_BLOCKS);
      });

      it("should increase beginningOfTheNewDayTimestamp by ONE_DAY", async () => {
        const beginningOfTheNewDayTimestampBefore = await dailySnapshot.beginningOfTheNewDayTimestamp();
        await time.increase(ONE_DAY_SECONDS);
        await dailySnapshot.dailySnapshot();
        const beginningOfTheNewDayTimestampAfter = await dailySnapshot.beginningOfTheNewDayTimestamp();
        expect(beginningOfTheNewDayTimestampAfter).to.equal(beginningOfTheNewDayTimestampBefore + ONE_DAY_SECONDS);
      });

      it("should set dailySnapshotsPerEpoch correctly", async () => {
        await time.increase(ONE_DAY_SECONDS);
        const epoch = await dailySnapshot.epoch();
        const epochDaysIndex = await dailySnapshot.epochDaysIndex();
        const beginningOfTheNewDayBlocknumber = await dailySnapshot.beginningOfTheNewDayBlocknumber();
        const prevrandao = 12340; // prevrandao is used to generate random value and it's % 7200
        await setPrevRandao(prevrandao);
        await dailySnapshot.dailySnapshot();
        expect(await dailySnapshot.dailySnapshotsPerEpoch(epoch, epochDaysIndex)).to.equal(beginningOfTheNewDayBlocknumber + prevrandao % 192000);
      });

      it("should emit DailySnapshotAdded event", async () => {
        const beginningOfTheNewDayBlocknumber = await dailySnapshot.beginningOfTheNewDayBlocknumber();
        const epoch = await dailySnapshot.epoch();
        const epochDaysIndex = await dailySnapshot.epochDaysIndex();
        await time.increase(ONE_DAY_SECONDS);
        const prevrandao = 12340; // prevrandao is used to generate random value and it's % 7200
        await setPrevRandao(prevrandao);        
        await expect(dailySnapshot.dailySnapshot())
        .to.emit(dailySnapshot, 'DailySnapshotAdded')
        .withArgs(owner.address, epoch, beginningOfTheNewDayBlocknumber + prevrandao % 192000, epochDaysIndex);
      });

      it("should set epochDaysIndex to 0 if 7 snapshoots done", async () => {
        for (let i = 0; i < 6; i++) {
          await time.increase(ONE_DAY_SECONDS);
          await dailySnapshot.dailySnapshot();
        }
        const epochDaysIndexBefore = await dailySnapshot.epochDaysIndex();
        expect(epochDaysIndexBefore).to.equal(6);

        await time.increase(ONE_DAY_SECONDS);
        await dailySnapshot.dailySnapshot();
        const epochDaysIndexAfter = await dailySnapshot.epochDaysIndex();
        expect(epochDaysIndexAfter).to.equal(0);
      });

      it("should increase epoch after 7 snapshots", async () => {
        const epochBefore = await dailySnapshot.epoch();
        expect(epochBefore).to.equal(0);
        for (let i = 0; i < 7; i++) {
          await time.increase(ONE_DAY_SECONDS);
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
        await dailySnapshot.startSnapshotting();
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
