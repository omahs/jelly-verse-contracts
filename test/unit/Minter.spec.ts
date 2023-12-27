import { loadFixture, time } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";
import { deployMockJelly } from "../shared/mocks";
import { MockContract } from "@ethereum-waffle/mock-contract";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { Minter } from '../../typechain-types';
import { BigNumber } from "ethers";

describe.only("Minter", function () {
    async function deployMinterFixture() {
        const [deployer, otherAccount, lpRewardsContract, stakingRewardsContract] = await ethers.getSigners();
        const jellyToken = await deployMockJelly(deployer);

        const MinterFactory = await ethers.getContractFactory("Minter");
        const minter = await MinterFactory.deploy(
            jellyToken.address, 
            lpRewardsContract.address, 
            stakingRewardsContract.address, 
            deployer.address, 
            otherAccount.address
        );

        return { minter, jellyToken, deployer, otherAccount, lpRewardsContract, stakingRewardsContract };
    }

    let minter: Minter;
    let jellyToken: MockContract;
    let deployer: SignerWithAddress;
    let otherAccount: SignerWithAddress;
    let lpRewardsContract: SignerWithAddress;
    let stakingRewardsContract: SignerWithAddress;

    beforeEach(async function () {
        const fixture = await loadFixture(deployMinterFixture);
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
            expect(await minter._jellyToken()).to.equal(jellyToken.address);
        });

        it("should set the correct _jellyToken address", async function () {
            expect(await minter._jellyToken()).to.equal(jellyToken.address);
        });

        it("should set the correct _lpRewardsContract address", async function () {
            expect(await minter._lpRewardsContract()).to.equal(lpRewardsContract.address);
        });

        it("should set the correct _stakingRewardsContract address", async function () {
            expect(await minter._stakingRewardsContract()).to.equal(stakingRewardsContract.address);
        });

        it("should set the correct _lastMintedTimestamp address", async function () {
            expect(await minter._lastMintedTimestamp()).to.equal(await time.latest());
        });
    });

    describe("#setInflationRate", function () {
        describe("success", function () {
            it("should allow the owner to set a new inflation rate", async function () {
                const newInflationRate = 5;
                await minter.setInflationRate(newInflationRate);
                expect(await minter._inflationRate()).to.equal(newInflationRate);
            });

            it("should emit InflationRateSet event", async function () {
                const newInflationRate = 5;
                await expect(minter.setInflationRate(newInflationRate))
                    .to.emit(minter, "InflationRateSet")
                    .withArgs(deployer.address, newInflationRate);
            });
        });

        describe("failure", function () {
            it("should revert if a non-owner tries to set the inflation rate", async function () {
                const newInflationRate = 5;
                await expect(minter.connect(otherAccount).setInflationRate(newInflationRate))
                    .to.be.revertedWithCustomError(minter, "Ownable__CallerIsNotOwner");
            });
        });
    });

    describe('#mint', function () {
        describe('success', function () {
            it('should emit JellyMinted event', async function () {
                await time.increase(7 * 24 * 60 * 60);

                const lastMintedTimestampOld = await minter._lastMintedTimestamp();
                const mintingPeriod = await minter._mintingPeriod();
                const inflationRate = await minter._inflationRate();
                const lastMintedTimestampNew = lastMintedTimestampOld.add(mintingPeriod);
                const mintAmount = BigNumber.from(inflationRate).mul(mintingPeriod);
                const currentTime = await time.latest();
                const currentTimePlusOne = currentTime + 1; // add 1 second to account for time passage during the test

                await expect(minter.mint()).to.emit(minter, 'JellyMinted')
                .withArgs(deployer.address, currentTimePlusOne, lastMintedTimestampNew, mintingPeriod, mintAmount);
            });
        });
        
        describe('failure', function () {
            it('should revert if mint is called too soon', async function () {
                await expect(minter.mint()).to.be.revertedWith("Minter: mint too soon");
            });
        });
    });
    
    describe('#setLpRewardsContract', function () {
        describe('success', function () {
            it('should emit LPRewardsContractSet event', async function () {
                const newLpRewardsContract = otherAccount.address;
                await expect(minter.setLpRewardsContract(newLpRewardsContract))
                    .to.emit(minter, 'LPRewardsContractSet')
                    .withArgs(deployer.address, newLpRewardsContract);
            });

            it('should set new LpRewardsContract address', async function () {
                const newLpRewardsContract = otherAccount.address;
                await minter.setLpRewardsContract(newLpRewardsContract) 
                expect(await minter._lpRewardsContract()).to.equal(newLpRewardsContract);
            });
        });
        
        describe('failure', function () {
            it('should revert if a non-owner tries to set the LP rewards contract', async function () {
                const newLpRewardsContract = otherAccount.address;
                await expect(minter.connect(otherAccount).setLpRewardsContract(newLpRewardsContract))
                    .to.be.revertedWithCustomError(minter, "Ownable__CallerIsNotOwner");
            });
        });
    });
    
    describe('#setStakingRewardsContract', function () {
        describe('success', function () {
            it('should emit StakingRewardsContractSet event', async function () {
                const newStakingRewardsContract = otherAccount.address;
                await expect(minter.setStakingRewardsContract(newStakingRewardsContract))
                    .to.emit(minter, 'StakingRewardsContractSet')
                    .withArgs(deployer.address, newStakingRewardsContract);
            });

            it('should set new staking reward contract address', async function () {
                const newStakingRewardsContract = otherAccount.address;
                await minter.setStakingRewardsContract(newStakingRewardsContract)     
                expect(await minter._stakingRewardsContract()).to.equal(newStakingRewardsContract);
            });
        });  

        describe('failure', function () {
            it('should revert if a non-owner tries to set the staking rewards contract', async function () {
                const newStakingRewardsContract = otherAccount.address;
                await expect(minter.connect(otherAccount).setStakingRewardsContract(newStakingRewardsContract))
                    .to.be.revertedWithCustomError(minter, "Ownable__CallerIsNotOwner");
            });
        });
    });

    describe('#setMintingPeriod', function () {
        describe('success', function () {
            it('should set new mintingPeriod', async function () {
                const newMintingPeriod = 7200;
                await minter.setMintingPeriod(newMintingPeriod)
                expect(await minter._mintingPeriod()).to.equal(newMintingPeriod);
            });

            it('should emit event', async function () {
                const newMintingPeriod = 7200;
                await expect(minter.setMintingPeriod(newMintingPeriod))
                    .to.emit(minter, 'MintingPeriodSet')
                    .withArgs(deployer.address, newMintingPeriod);
            });
        }); 
        describe('failure', function () {
            it('should revert if a non-owner tries to set the staking rewards contract', async function () {
                const newStakingRewardsContract = otherAccount.address;
                await expect(minter.connect(otherAccount).setStakingRewardsContract(newStakingRewardsContract))
                    .to.be.revertedWithCustomError(minter, "Ownable__CallerIsNotOwner");
            });
        });
    });
});
