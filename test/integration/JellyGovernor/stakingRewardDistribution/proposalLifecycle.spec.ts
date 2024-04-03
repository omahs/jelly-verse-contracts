import { assert, expect } from 'chai';
import { time } from '@nomicfoundation/hardhat-network-helpers';
import { utils, BigNumber, constants } from 'ethers';
import { ProposalState, VoteType } from '../../../shared/types';
import { StandardMerkleTree } from "@openzeppelin/merkle-tree";

export function shouldFollowProposalLifeCycle(): void {
    context('Staking Rewards Distribution Create epoch Proposal Lifecycle', async function () {
        const proposalDescription = 'Test Proposal #1: Create epoch';
        let aliceValues: any[];
        let merkleTree;
        let merkleRoot: string;
        const ipfsUri = "";
        let createEpochFunctionCalldata: string;
        let proposalId: BigNumber;
        let proposalParams: string;
        const chestIDs: number[] = [0, 1, 2];
        beforeEach(async function () {
            aliceValues = [this.signers.alice.address, "1000"];
            merkleTree = StandardMerkleTree.of([aliceValues], ['address', 'uint256']);
            merkleRoot = merkleTree.root;
            createEpochFunctionCalldata = this.stakingRewardDistribution.interface.encodeFunctionData(
                'createEpoch',
                [merkleRoot, ipfsUri]
            );
            await this.jellyGovernor
                .connect(this.signers.alice)
                .proposeCustom(
                    [this.stakingRewardDistribution.address],
                    [0],
                    [createEpochFunctionCalldata],
                    proposalDescription,
                    "3600", /* 1 hour in seconds */
                    "86400" /* 1 day in seconds */
                );

            const abiEncodedParams = utils.defaultAbiCoder.encode(
                ['address[]', 'uint256[]', 'bytes[]', 'bytes32'],
                [
                    [this.stakingRewardDistribution.address],
                    [0],
                    [createEpochFunctionCalldata],
                    utils.keccak256(utils.toUtf8Bytes(proposalDescription))
                ]
            );

            proposalId = BigNumber.from(utils.keccak256(abiEncodedParams));
        });
        it('should be in pending state', async function () {
            const proposalState = await this.jellyGovernor.state(proposalId);

            assert(
                proposalState === ProposalState.Pending,
                'Proposal should be in pending state'
            );
        });

        it('should be in active state', async function () {
            await time.increase(this.params.votingDelay.add(constants.One));

            const proposalState = await this.jellyGovernor.state(proposalId);

            assert(
                proposalState === ProposalState.Active,
                'Proposal should be in active state'
            );
        });

        it('should be in succeeded state', async function () {
            await time.increase(this.params.votingDelay.add(constants.One));

            proposalParams = utils.defaultAbiCoder.encode(
                ['uint256[]'],
                [[chestIDs[0]]]
            );

            await this.jellyGovernor
                .connect(this.signers.alice)
                .castVoteWithReasonAndParams(proposalId, VoteType.For, "", proposalParams);

            await time.increase(this.params.votingPeriod.add(constants.One));

            const proposalState = await this.jellyGovernor.state(proposalId);

            assert(
                proposalState === ProposalState.Succeeded,
                'Proposal should be in succeeded state'
            );
        });

        it('should be in defeated state', async function () {
            await time.increase(this.params.votingDelay.add(constants.One));

            proposalParams = utils.defaultAbiCoder.encode(
                ['uint256[]'],
                [[chestIDs[0]]]
            );

            await this.jellyGovernor
                .connect(this.signers.alice)
                .castVoteWithReasonAndParams(proposalId, VoteType.Against, "", proposalParams);

            await time.increase(this.params.votingPeriod.add(constants.One));

            const proposalState = await this.jellyGovernor.state(proposalId);

            assert(
                proposalState === ProposalState.Defeated,
                'Proposal should be in defeated state'
            );
        });

        it('should be in queued state', async function () {
            await time.increase(this.params.votingDelay.add(constants.One));

            proposalParams = utils.defaultAbiCoder.encode(
                ['uint256[]'],
                [[chestIDs[0]]]
            );

            await this.jellyGovernor
                .connect(this.signers.alice)
                .castVoteWithReasonAndParams(proposalId, VoteType.For, "", proposalParams);

            await time.increase(this.params.votingPeriod.add(constants.One));

            const proposalDescriptionHash = utils.id(proposalDescription);

            await this.jellyGovernor
                .connect(this.signers.alice)
                .queue(
                    [this.stakingRewardDistribution.address],
                    [0],
                    [createEpochFunctionCalldata],
                    proposalDescriptionHash
                );

            const proposalState = await this.jellyGovernor.state(proposalId);

            assert(
                proposalState === ProposalState.Queued,
                'Proposal should be in queued state'
            );
        });
        it('should be in executed state', async function () {
            const epochId = await this.stakingRewardDistribution.epoch();
            await time.increase(this.params.votingDelay.add(constants.One));

            proposalParams = utils.defaultAbiCoder.encode(
                ['uint256[]'],
                [[chestIDs[0]]]
            );

            await this.jellyGovernor
                .connect(this.signers.alice)
                .castVoteWithReasonAndParams(proposalId, VoteType.For, "", proposalParams);

            await time.increase(this.params.votingPeriod.add(constants.One));

            const proposalDescriptionHash = utils.id(proposalDescription);

            await this.jellyGovernor
                .connect(this.signers.alice)
                .queue(
                    [this.stakingRewardDistribution.address],
                    [0],
                    [createEpochFunctionCalldata],
                    proposalDescriptionHash
                );

            await time.increase(this.params.minTimelockDelay.add(constants.One));

            await this.jellyGovernor
                .connect(this.signers.alice)
                .execute(
                    [this.stakingRewardDistribution.address],
                    [0],
                    [createEpochFunctionCalldata],
                    proposalDescriptionHash
                );

            const proposalState = await this.jellyGovernor.state(proposalId);
            const newEpochId = await this.stakingRewardDistribution.epoch();

            assert(
                proposalState === ProposalState.Executed,
                'Proposal should be in executed state'
            );
            assert(await this.stakingRewardDistribution.merkleRoots(epochId) === merkleRoot, 'Epoch merkle root should be set');
            assert(newEpochId.eq(epochId.add(1)), 'Epoch id should be incremented');
        });
    });
}