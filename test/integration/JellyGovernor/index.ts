import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { integrationJellyGovernorFixture } from "../../fixtures/integration__Governor";
import { Params } from "../../shared/types";
import { utils, BigNumber } from "ethers";
import { assert, expect } from "chai";

export function shouldBehaveLikeJellyGovernor() {
    describe("JellyGovernor", function () {
        const amountToMint = utils.parseEther("10");
        const freezingPeriod = BigNumber.from("604800");
        const amountToStake = utils.parseEther("5");

        beforeEach(async function () {
            const {
                jellyGovernor,
                jellyToken,
                jellyTimelock,
                chest,
                stakingRewardDistribution,
                votingDelay,
                votingPeriod,
                proposalThreshold,
                quorum,
                minTimelockDelay,
                proposers,
                executors,
            } = await loadFixture(integrationJellyGovernorFixture);

            this.jellyGovernor = jellyGovernor;
            this.jellyToken = jellyToken;
            this.jellyTimelock = jellyTimelock;
            this.chest = chest;
            this.stakingRewardDistribution = stakingRewardDistribution;

            this.params = {} as Params;
            this.params.votingDelay = votingDelay;
            this.params.votingPeriod = votingPeriod;
            this.params.proposalThreshold = proposalThreshold;
            this.params.quorum = quorum;
            this.params.minTimelockDelay = minTimelockDelay;
            this.params.proposers = proposers;
            this.params.executors = executors;

            // mint tokens to alice, bob and allocator
            await this.jellyToken
                .connect(this.signers.deployer)
                .mint(this.signers.alice.address, amountToMint);

            await this.jellyToken
                .connect(this.signers.deployer)
                .mint(this.signers.bob.address, amountToMint);

            await this.jellyToken
                .connect(this.signers.deployer)
                .mint(this.signers.allocator.address, amountToMint);

            // stake tokens and mint chests
            await this.jellyToken
                .connect(this.signers.alice)
                .approve(this.chest.address, amountToStake);
            await this.chest
                .connect(this.signers.alice)
                .stake(amountToStake, this.signers.alice.address, freezingPeriod);

            await this.jellyToken
                .connect(this.signers.bob)
                .approve(this.chest.address, amountToStake);
            await this.chest
                .connect(this.signers.bob)
                .stake(amountToStake, this.signers.bob.address, freezingPeriod);

            await this.jellyToken
                .connect(this.signers.allocator)
                .approve(this.chest.address, amountToStake);
            await this.chest
                .connect(this.signers.allocator)
                .stakeSpecial(amountToStake, this.signers.investor.address);
        });
    });
}
