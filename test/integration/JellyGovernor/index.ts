import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { integrationJellyGovernorFixture } from "../../fixtures/integration__Governor";
import { Params } from "../../shared/types";
import { utils, BigNumber } from "ethers";
import { assert, expect } from "chai";
import { shouldCastVotes as shouldCastVotesOfficialPoolRegister } from "./officialPoolRegister/castingVotes.spec";
import { shouldFollowProposalLifeCycle as shouldFollowProposalLifeCycleOfficialPoolRegister } from "./officialPoolRegister/proposalLifecycle.spec";

export function shouldBehaveLikeJellyGovernor() {
    describe("JellyGovernor", function () {
        const amountToMint = utils.parseEther("10");
        const freezingPeriod = BigNumber.from("604800"); // 1 week
        const vestingPeriod = BigNumber.from("31536000"); // 1 year
        const amountToStake = utils.parseEther("5");
        const nerfParameter = BigNumber.from(5); // 50% nerf
        beforeEach(async function () {
            const {
                jellyGovernor,
                jellyToken,
                jellyTimelock,
                chest,
                stakingRewardDistribution,
                officialPoolsRegister,
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
            this.officialPoolsRegister = officialPoolsRegister;

            this.params = {} as Params;
            this.params.votingDelay = votingDelay;
            this.params.votingPeriod = votingPeriod;
            this.params.proposalThreshold = proposalThreshold;
            this.params.quorum = quorum;
            this.params.minTimelockDelay = minTimelockDelay;
            this.params.proposers = proposers;
            this.params.executors = executors;

            // mint tokens to alice, bob and allocator
            const chestFee = await this.chest.fee();

            await this.jellyToken
                .connect(this.signers.deployer)
                .mint(this.signers.alice.address, amountToMint);

            await this.jellyToken
                .connect(this.signers.deployer)
                .mint(this.signers.bob.address, amountToMint);

            await this.jellyToken
                .connect(this.signers.deployer)
                .mint(this.signers.allocator.address, amountToMint);

            await this.jellyToken
                .connect(this.signers.alice)
                .approve(this.chest.address, amountToStake + chestFee);

            await this.chest
                .connect(this.signers.alice)
                .stake(amountToStake, this.signers.alice.address, freezingPeriod);

            await this.jellyToken
                .connect(this.signers.bob)
                .approve(this.chest.address, amountToStake + chestFee);
            await this.chest
                .connect(this.signers.bob)
                .stake(amountToStake, this.signers.bob.address, freezingPeriod);

            await this.jellyToken
                .connect(this.signers.allocator)
                .approve(this.chest.address, amountToStake + chestFee);
            await this.chest
                .connect(this.signers.allocator)
                .stakeSpecial(amountToStake, this.signers.investor.address, freezingPeriod, vestingPeriod, nerfParameter);
        });

        // Official Pool Register
        shouldCastVotesOfficialPoolRegister();
        shouldFollowProposalLifeCycleOfficialPoolRegister();
    });
}
