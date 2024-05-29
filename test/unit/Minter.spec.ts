import { loadFixture, time } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { MockContract } from "@ethereum-waffle/mock-contract";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { Minter } from "../../typechain-types";
import { BigNumber } from "ethers";
import { unitMinterFixture } from "../fixtures/unit__Minter";

describe("Minter", function () {
  let minter: Minter;
  let jellyToken: MockContract;
  let deployer: SignerWithAddress;
  let otherAccount: SignerWithAddress;
  let lpRewardsContract: SignerWithAddress;
  let stakingRewardsContract: MockContract;

  beforeEach(async function () {
    const fixture = await loadFixture(unitMinterFixture);
    minter = fixture.minter;
    jellyToken = fixture.jellyToken;
    deployer = fixture.deployer;
    otherAccount = fixture.otherAccount;
    lpRewardsContract = fixture.lpRewardsContract;
    stakingRewardsContract = fixture.stakingRewardsContract;
  });

  describe("Deployment", function () {
    it("should set the correct owner", async function () {
      expect(await minter.owner()).to.equal(deployer.address);
    });

    it("should set the correct pending owner", async function () {
      expect(await minter.getPendingOwner()).to.equal(otherAccount.address);
    });

    it("should set the correct _jellyToken address", async function () {
      expect(await minter.i_jellyToken()).to.equal(jellyToken.address);
    });

    it("should set the correct _jellyToken address", async function () {
      expect(await minter.i_jellyToken()).to.equal(jellyToken.address);
    });


    it("should set the correct _stakingRewardsContract address", async function () {
      expect(await minter.stakingRewardsContract()).to.equal(
        stakingRewardsContract.address
      );
    });

    it("should set the correct _lastMintedTimestamp", async function () {
      expect(await minter.lastMintedTimestamp()).to.equal(0);
    });

    it("should set the correct _mintingStartedTimestamp", async function () {
      expect(await minter.mintingStartedTimestamp()).to.equal(0);
    });
  });

  describe("#calculateMintAmount", function () {
    describe("success", function () {
      it("should be able to calculate mint amount at 0 days since start", async function () {
        const daysSinceMintingStarted = 0;
        const expectedMintAmount = "656567";
        expect(
          await minter.calculateMintAmount(daysSinceMintingStarted)
        ).to.equal(expectedMintAmount);
      });

      it("should be able to calculate mint amount at 10 days since start", async function () {
        const daysSinceMintingStarted = 10;
        const expectedMintAmount = "646791";
        expect(
          await minter.calculateMintAmount(daysSinceMintingStarted)
        ).to.equal(expectedMintAmount);
      });

      it("should be able to calculate mint amount at 100 days since start", async function () {
        const daysSinceMintingStarted = 100;
        const expectedMintAmount = "565112";
        expect(
          await minter.calculateMintAmount(daysSinceMintingStarted)
        ).to.equal(expectedMintAmount);
      });

      it("should be able to calculate mint amount at 1000 days since start", async function () {
        const daysSinceMintingStarted = 1000;
        const expectedMintAmount = "146499";
        expect(
          await minter.calculateMintAmount(daysSinceMintingStarted)
        ).to.equal(expectedMintAmount);
      });

      it("should be able to calculate mint amount at 10000 days since start", async function () {
        const daysSinceMintingStarted = 10000;
        const expectedMintAmount = 0;
        expect(
          await minter.calculateMintAmount(daysSinceMintingStarted)
        ).to.equal(expectedMintAmount);
      });
    });
  });

  describe("#mint", function () {
    describe("success", function () {
      it("should emit JellyMinted event", async function () {
        await minter.startMinting();
        const epochId = 0; // defined in stakingRewardsContract mock
        const mintingPeriod = await minter.mintingPeriod();
        const lastMintedTimestampOld = await minter.lastMintedTimestamp();
        const lastMintedTimestampNew =
          lastMintedTimestampOld + mintingPeriod;
        const mintAmount = BigNumber.from("656567000000000000000000");
        

        let newBeneficiaries = [
            {
              beneficiary: stakingRewardsContract.address,
              weight: BigNumber.from(500),
            },
            {
              beneficiary: lpRewardsContract.address,
              weight: BigNumber.from(500),
            },
          ];
  
        await minter.setBeneficiaries(newBeneficiaries);
        await time.increase(mintingPeriod + 1);
        await expect(minter.mint())
          .to.emit(minter, "JellyMinted")
          .withArgs(
            deployer.address,
            stakingRewardsContract.address,
            lastMintedTimestampNew,
            mintingPeriod,
            mintAmount,
            epochId
          );
      });
    
    });

    describe("failure", function () {
      it("should revert if minting has not started", async function () {
        await expect(minter.mint()).to.be.revertedWithCustomError(
          minter,
          "Minter_MintingNotStarted"
        );
      });
      it("should revert if mint is called too soon", async function () {
        await minter.startMinting();
        await expect(minter.mint()).to.be.revertedWithCustomError(
          minter,
          "Minter_MintTooSoon"
        );
      });
    });
  });


  describe("#startMinting", function () {
    describe("success", function () {
      it("should emit MintingStarted event", async function () {
        const currentTime = (await time.latest()) + 1;
        await expect(minter.startMinting())
          .to.emit(minter, "MintingStarted")
          .withArgs(deployer.address, currentTime);
      });

      it("should set started to true", async function () {
        await minter.startMinting();
        expect(await minter.started()).to.equal(true);
      });

      it("should set lastMintedTimestamp corectlly", async function () {
        const currentTime = await time.latest();
        const lastMintedTimestamp = BigNumber.from(currentTime).add(1);
        await minter.startMinting();
        expect(await minter.lastMintedTimestamp()).to.equal(
          lastMintedTimestamp
        );
      });

      it("should set mintingStartedTimestamp corectlly", async function () {
        const currentTime = await time.latest();
        const mintingStartedTimestamp = BigNumber.from(currentTime).add(1);
        await minter.startMinting();
        expect(await minter.mintingStartedTimestamp()).to.equal(
          mintingStartedTimestamp
        );
      });
    });

    describe("failure", function () {
      it("should revert if a non-owner tries to call startMinting function", async function () {
        await expect(
          minter.connect(otherAccount).startMinting()
        ).to.be.revertedWithCustomError(minter, "Ownable__CallerIsNotOwner");
      });

      it("should revert if a owner tries to start it twice", async function () {
        await minter.startMinting();
        await expect(minter.startMinting()).to.be.revertedWithCustomError(
          minter,
          "Minter_MintingAlreadyStarted"
        );
      });
    });
  });

  describe("#setStakingRewardsContract", function () {
    describe("success", function () {
      it("should emit StakingRewardsContractSet event", async function () {
        const newStakingRewardsContract = otherAccount.address;
        await expect(
          minter.setStakingRewardsContract(newStakingRewardsContract)
        )
          .to.emit(minter, "StakingRewardsContractSet")
          .withArgs(deployer.address, newStakingRewardsContract);
      });

      it("should set new staking reward contract address", async function () {
        const newStakingRewardsContract = otherAccount.address;
        await minter.setStakingRewardsContract(newStakingRewardsContract);
        expect(await minter.stakingRewardsContract()).to.equal(
          newStakingRewardsContract
        );
      });
    });

    describe("failure", function () {
      it("should revert if a non-owner tries to set the staking rewards contract", async function () {
        const newStakingRewardsContract = otherAccount.address;
        await expect(
          minter
            .connect(otherAccount)
            .setStakingRewardsContract(newStakingRewardsContract)
        ).to.be.revertedWithCustomError(minter, "Ownable__CallerIsNotOwner");
      });
    });
  });

  describe("#setMintingPeriod", function () {
    describe("success", function () {
      it("should set new mintingPeriod", async function () {
        const newMintingPeriod = 7200;
        await minter.setMintingPeriod(newMintingPeriod);
        expect(await minter.mintingPeriod()).to.equal(newMintingPeriod);
      });

      it("should emit event", async function () {
        const newMintingPeriod = 7200;
        await expect(minter.setMintingPeriod(newMintingPeriod))
          .to.emit(minter, "MintingPeriodSet")
          .withArgs(deployer.address, newMintingPeriod);
      });
    });
    describe("failure", function () {
      it("should revert if a non-owner tries to set the staking rewards contract", async function () {
        const newStakingRewardsContract = otherAccount.address;
        await expect(
          minter
            .connect(otherAccount)
            .setStakingRewardsContract(newStakingRewardsContract)
        ).to.be.revertedWithCustomError(minter, "Ownable__CallerIsNotOwner");
      });
    });
  });

  describe("#setBeneficiraies", function () {
    describe("success", function () {
      it("should set new benefciraies", async function () {
        let newBeneficiaries = [
          {
            beneficiary: stakingRewardsContract.address,
            weight: BigNumber.from(500),
          },
          {
            beneficiary: lpRewardsContract.address,
            weight: BigNumber.from(500),
          },
        ];

        await minter.setBeneficiaries(newBeneficiaries);
        for (let i = 0; i < newBeneficiaries.length; i++) {
          const beneficiary = await minter.beneficiaries(i);
          expect(beneficiary[0]).to.equal(newBeneficiaries[i].beneficiary);
          expect(beneficiary[1]).to.equal(newBeneficiaries[i].weight);
        }
      });
    });
    describe("failure", function () {
      it("should revert if a non-owner tries to set the staking rewards contract", async function () {
        const newStakingRewardsContract = otherAccount.address;
        await expect(
          minter
            .connect(otherAccount)
            .setStakingRewardsContract(newStakingRewardsContract)
        ).to.be.revertedWithCustomError(minter, "Ownable__CallerIsNotOwner");
      });
    });
  });

  describe("#fundPoolParty", function () {
    describe("success", function () {
      it("should fund pool party", async function () {
        

        await expect( minter.fundPoolParty(deployer.address)).to.emit(minter, "PoolPartyFunded")
        .withArgs(deployer.address);;
        
      });
    });
    describe("failure", function () {
      it("should revert if a non-owner tries to fund", async function () {
 
        await expect(
          minter
            .connect(otherAccount)
            .fundPoolParty(deployer.address)
        ).to.be.revertedWithCustomError(minter, "Ownable__CallerIsNotOwner");
      });

      it("should revert if already funded", async function () {
        await minter.fundPoolParty(deployer.address);
        await expect(
          minter
            .fundPoolParty(deployer.address)
        ).to.be.revertedWithCustomError(minter, "Minter_AlreadyFunded");
      });
    });
  });
});
