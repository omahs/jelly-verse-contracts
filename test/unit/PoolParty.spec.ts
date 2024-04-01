import { loadFixture, mine, time,  } from '@nomicfoundation/hardhat-network-helpers';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { expect } from 'chai';
import { unitPoolPartyFixture } from '../fixtures/unit__PoolParty';
import { PoolParty } from '../../typechain-types/index.js';
import { MockContract } from '@ethereum-waffle/mock-contract';

// @notice -- I did not test ownable cuz it is not necessary and it is community approved

describe('PoolParty', function () {
  let poolParty: PoolParty;
  let owner: SignerWithAddress;
  let pendingOwner: SignerWithAddress;
  let jellyToken: MockContract;
  let usdToken: MockContract;
  let vaultContract: MockContract;
  let usdToJellyRatio: number;
  let poolId: string;

  beforeEach(async function () {
    const fixture = await loadFixture(unitPoolPartyFixture);
    poolParty = fixture.poolParty;
    owner = fixture.owner;
    pendingOwner = fixture.pendingOwner;
    jellyToken = fixture.jellyToken;
    usdToken = fixture.usdToken;
    vaultContract = fixture.vaultMockContract;
    usdToJellyRatio = fixture.usdToJellyRatio;
    poolId = fixture.poolId;
  });

  describe("Check for initial state after deployment", async function () {
    it("should have correct initial owner and pending owner", async () => {
      expect(await owner.getAddress(), await poolParty.owner());
      expect(
        await pendingOwner.getAddress(),
        await poolParty.getPendingOwner(),
      );
    });

    it("should have the expected initial owner", async () => {
      const initialOwner = await poolParty.owner();
      expect(initialOwner).to.equal(await owner.getAddress());
    });

    it("should have the expected jelly token address", async () => {
      const initialJellyTokenAddress = await poolParty.i_jellyToken();
      expect(initialJellyTokenAddress).to.equal(jellyToken.address);
    });

    it("should have the expected usd token address", async () => {
      const initialWethAddress = await poolParty.usdToken();
      expect(initialWethAddress).to.equal(usdToken.address);
    });

    it("should have the expected usd to jelly ratio", async () => {
      const initialNativeToJellyRatio = await poolParty.usdToJellyRatio();
      expect(initialNativeToJellyRatio).to.equal(usdToJellyRatio);
    });

    it("should have the expected valut address", async () => {
      const initialVaultAddress = await poolParty.jellySwapVault();
      expect(initialVaultAddress).to.equal(vaultContract.address);
    });

    it("should have the expected poolID", async () => {
      const initialPoolId = await poolParty.jellySwapPoolId();
      expect(initialPoolId).to.equal(poolId);
    });

    it("should have the expected isOver flag", async () => {
      const initialIsOver = await poolParty.isOver();
      expect(initialIsOver).to.equal(false);
    });
  });

  describe("#setUSDToJellyRatio", async function () {
    describe("success", async () => {
      it("should set usd to token ration", async () => {
        await poolParty.setUSDToJellyRatio(2);
        expect(await poolParty.usdToJellyRatio()).to.be.equal(2);
      });

      it("should emit NativeToJellyRatioSet event", async () => {
        await expect(poolParty.setUSDToJellyRatio(2))
        .to.emit(poolParty, 'NativeToJellyRatioSet')
        .withArgs(2);
      });
    })

    describe("failure", async () => {
      it("should revert if not called by owner", async () => {
        await expect(
          poolParty.connect(pendingOwner).setUSDToJellyRatio(2),
        ).to.be.revertedWithCustomError(
          poolParty,
          "Ownable__CallerIsNotOwner",
        );
      });
    })
  });

  describe("#endBuyingPeriod", async function () {
    describe("success", async () => {
      it("should set isOver flag to true", async () => {
        expect(await poolParty.isOver()).to.be.equal(false);
        await poolParty.endBuyingPeriod();
        expect(await poolParty.isOver()).to.be.equal(true);
      });

      it("should emit EndBuyingPeriod event", async () => {
        await expect(poolParty.endBuyingPeriod())
        .to.emit(poolParty, 'EndBuyingPeriod');
      });
    })

    describe("failure", async () => {
      it("should revert if not called by owner", async () => {
        await expect(
          poolParty.connect(pendingOwner).endBuyingPeriod(),
        ).to.be.revertedWithCustomError(
          poolParty,
          "Ownable__CallerIsNotOwner",
        );
      });
    })
  });

  describe("#buyWithUsd", async function () {
    describe("success", async () => {
      it("should emit BuyWithNative event", async () => {
        const usdToJellyRatio = await poolParty.usdToJellyRatio();
        const amount = 1000;
        console.log("usdToJellyRatio", usdToJellyRatio);
        await expect(poolParty.buyWithUsd(amount))
        .to.emit(poolParty, 'BuyWithUsd')
        .withArgs(amount, usdToJellyRatio.mul(amount), owner.address);
      });
    })

    describe("failure", async () => {
      it("should revert if buying period is over", async () => {
        await poolParty.endBuyingPeriod();
        const amount = 1000;
        await expect(
          poolParty.buyWithUsd(amount),
        ).to.be.revertedWithCustomError(
          poolParty,
          "PoolParty__CannotBuy",
        );
      });

      it("should revert if called with zero amount", async () => {
        await expect(
          poolParty.buyWithUsd(0),
        ).to.be.revertedWithCustomError(
          poolParty,
          "PoolParty__NoValueSent",
        );
      });
    })
  });
});
