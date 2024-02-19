import { loadFixture, mine, time,  } from '@nomicfoundation/hardhat-network-helpers';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { expect } from 'chai';
import { unitAllocatorFixture } from '../fixtures/unit__Allocator';
import { Allocator } from '../../typechain-types';
import { MockContract } from '@ethereum-waffle/mock-contract';

// @notice -- I did not test ownable cuz it is not necessary and it is community approved

describe('Allocator', function () {
  let allocator: Allocator;
  let owner: SignerWithAddress;
  let pendingOwner: SignerWithAddress;
  let jellyToken: MockContract;
  let wethToken: MockContract;
  let vaultContract: MockContract;
  let nativeToJellyRatio: number;
  let poolId: string;

  beforeEach(async function () {
    const fixture = await loadFixture(unitAllocatorFixture);
    allocator = fixture.allocator;
    owner = fixture.owner;
    pendingOwner = fixture.pendingOwner;
    jellyToken = fixture.jellyToken;
    wethToken = fixture.wethToken;
    vaultContract = fixture.vaultMockContract;
    nativeToJellyRatio = fixture.nativeToJellyRatio;
    poolId = fixture.poolId;
  });

  describe("Check for initial state after deployment", async function () {
    it("should have correct initial owner and pending owner", async () => {
      expect(await owner.getAddress(), await allocator.owner());
      expect(
        await pendingOwner.getAddress(),
        await allocator.getPendingOwner(),
      );
    });

    it("should have the expected initial owner", async () => {
      const initialOwner = await allocator.owner();
      expect(initialOwner).to.equal(await owner.getAddress());
    });

    it("should have the expected jelly token address", async () => {
      const initialJellyTokenAddress = await allocator.i_jellyToken();
      expect(initialJellyTokenAddress).to.equal(jellyToken.address);
    });

    it("should have the expected weth token address", async () => {
      const initialWethAddress = await allocator.weth();
      expect(initialWethAddress).to.equal(wethToken.address);
    });

    it("should have the expected native to jelly ratio", async () => {
      const initialNativeToJellyRatio = await allocator.nativeToJellyRatio();
      expect(initialNativeToJellyRatio).to.equal(nativeToJellyRatio);
    });

    it("should have the expected valut address", async () => {
      const initialVaultAddress = await allocator.jellySwapVault();
      expect(initialVaultAddress).to.equal(vaultContract.address);
    });

    it("should have the expected poolID", async () => {
      const initialPoolId = await allocator.jellySwapPoolId();
      expect(initialPoolId).to.equal(poolId);
    });

    it("should have the expected isOver flag", async () => {
      const initialIsOver = await allocator.isOver();
      expect(initialIsOver).to.equal(false);
    });
  });

  describe("#setNativeToJellyRatio", async function () {
    describe("success", async () => {
      it("should set native to token ration", async () => {
        await allocator.setNativeToJellyRatio(2);
        expect(await allocator.nativeToJellyRatio()).to.be.equal(2);
      });

      it("should emit NativeToJellyRatioSet event", async () => {
        await expect(allocator.setNativeToJellyRatio(2))
        .to.emit(allocator, 'NativeToJellyRatioSet')
        .withArgs(2);
      });
    })

    describe("failure", async () => {
      it("should revert if not called by owner", async () => {
        await expect(
          allocator.connect(pendingOwner).setNativeToJellyRatio(2),
        ).to.be.revertedWithCustomError(
          allocator,
          "Ownable__CallerIsNotOwner",
        );
      });
    })
  });

  describe("#endBuyingPeriod", async function () {
    describe("success", async () => {
      it("should set isOver flag to true", async () => {
        expect(await allocator.isOver()).to.be.equal(false);
        await allocator.endBuyingPeriod();
        expect(await allocator.isOver()).to.be.equal(true);
      });

      it("should emit EndBuyingPeriod event", async () => {
        await expect(allocator.endBuyingPeriod())
        .to.emit(allocator, 'EndBuyingPeriod');
      });
    })

    describe("failure", async () => {
      it("should revert if not called by owner", async () => {
        await expect(
          allocator.connect(pendingOwner).endBuyingPeriod(),
        ).to.be.revertedWithCustomError(
          allocator,
          "Ownable__CallerIsNotOwner",
        );
      });
    })
  });

  describe("#buyWithNative", async function () {
    describe("success", async () => {
      it("should emit BuyWithNative event", async () => {
        const nativeToJellyRatio = await allocator.nativeToJellyRatio();
        const amount = 1000;
        await expect(allocator.buyWithNative({ value: amount }))
        .to.emit(allocator, 'BuyWithNative')
        .withArgs(amount, nativeToJellyRatio.mul(amount), owner.address);
      });
    })

    describe("failure", async () => {
      it("should revert if buying period is over", async () => {
        await allocator.endBuyingPeriod();
        await expect(
          allocator.buyWithNative(),
        ).to.be.revertedWithCustomError(
          allocator,
          "Allocator__CannotBuy",
        );
      });

      it("should revert if called with zero amount", async () => {
        await expect(
          allocator.buyWithNative(),
        ).to.be.revertedWithCustomError(
          allocator,
          "Allocator__NoValueSent",
        );
      });
    })
  });
});
