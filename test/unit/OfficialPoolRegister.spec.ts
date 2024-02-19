import { loadFixture } from '@nomicfoundation/hardhat-network-helpers';
import { SignerWithAddress } from '@nomicfoundation/harhdat-ethers/signers';
import { expect } from 'chai';
import { OfficialPoolsRegister } from '../../typechain-types';
import { unitOficialPoolRegisterFixture } from '../fixtures/unit__OfficialPoolRegister';
import { BigNumber, BytesLike } from 'ethers';
import { ethers } from 'hardhat';

// @notice -- I did not test ownable cuz it is not necessary and it is community approved

describe('OfficialPoolsRegister', function() {
  let officialPoolsRegister: OfficialPoolsRegister;
  let owner: SignerWithAddress;
  let pendingOwner: SignerWithAddress;

  beforeEach(async function() {
    const fixture = await loadFixture(unitOficialPoolRegisterFixture);
    officialPoolsRegister = fixture.officialPoolsRegister;
    owner = fixture.owner;
    pendingOwner = fixture.pendingOwner;
  });

  describe("Check for initial state after deployment", async function() {
    it("should have correct initial owner and pending owner", async () => {
      expect(await owner.getAddress(), await officialPoolsRegister.owner());
      expect(await pendingOwner.getAddress, await officialPoolsRegister.getPendingOwner());
    });

    it("should have the expected initial owner", async () => {
      const initialOwner = await officialPoolsRegister.owner();
      expect(initialOwner).to.equal(await owner.getAddress());
    });
  });

  describe("#registerOfficialPool", async function() {
    type PoolStruct = {
      poolId: BytesLike,
      weight: BigNumber
    }
    let pools: PoolStruct[] = [];

    beforeEach(async function() {
      pools = [
        {
          poolId: ethers.utils.formatBytes32String("pool1"),
          weight: BigNumber.from(20)
        },
        {
          poolId: ethers.utils.formatBytes32String("pool2"),
          weight: BigNumber.from(30)
        }
      ];
    })

    describe("success", async () => {
      it("should register pools", async () => {
        await officialPoolsRegister.registerOfficialPool(pools);
        const officialPools = await officialPoolsRegister.getAllOfficialPools();

        for (let i = 0; i < pools.length; i++) {
          expect(officialPools[i]).to.equal(pools[i].poolId);
        }
      });

      it("should emit OfficialPoolRegistered event", async () => {
        for (const pool of pools) {
          await expect(officialPoolsRegister.registerOfficialPool(pools))
            .to.emit(officialPoolsRegister, "OfficialPoolRegistered")
            .withArgs(pool.poolId, pool.weight);
        }
      });

      it("should deregister old pools and register all again", async () => {
        await officialPoolsRegister.registerOfficialPool(pools);
        let newPools = [
          {
            poolId: ethers.utils.formatBytes32String("pool3"),
            weight: BigNumber.from(15)
          },
          {
            poolId: ethers.utils.formatBytes32String("pool1"),
            weight: BigNumber.from(18)
          }
        ];

        for (let i = 0; i < newPools.length; i++) {
          await expect(officialPoolsRegister.registerOfficialPool(newPools))
            .to.emit(officialPoolsRegister, "OfficialPoolRegistered")
            .withArgs(newPools[i].poolId, newPools[i].weight);
        }
        const officialPools = await officialPoolsRegister.getAllOfficialPools();
        for (let i = 0; i < officialPools.length; i++) {
          expect(officialPools[i]).to.equal(newPools[i].poolId);
        }
      });
    });

    describe("failure", async () => {
      it("should revert when registering a pool by a non-owner", async () => {
        await expect(officialPoolsRegister.connect(pendingOwner).registerOfficialPool(pools))
          .to.be.revertedWithCustomError(officialPoolsRegister, "Ownable__CallerIsNotOwner");
      });

      it("should revert when register more then 50 pools", async () => {
        let newPools: PoolStruct[] = [];
        for (let i = 0; i < 50; i++) {
          const poolIndex = i + 3;
          newPools.push({
            poolId: ethers.utils.formatBytes32String(`pool${poolIndex}`),
            weight: BigNumber.from(10)
          })
        }
        const combinedPools: PoolStruct[] = [...pools, ...newPools];

        await expect(officialPoolsRegister.registerOfficialPool(combinedPools))
          .to.revertedWithCustomError(officialPoolsRegister, "OfficialPoolsRegister_MaxPools50");
      });
    });
  });
});
