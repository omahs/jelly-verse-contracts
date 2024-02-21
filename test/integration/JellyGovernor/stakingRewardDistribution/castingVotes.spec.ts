import { assert, expect } from 'chai';
import { mine } from '@nomicfoundation/hardhat-network-helpers';
import { utils, BigNumber, constants } from 'ethers';
import { ProposalState, VoteType } from '../../../shared/types';
import { StandardMerkleTree } from "@openzeppelin/merkle-tree";

export function shouldCastVotes(): void {
    context(
        'Staking Rewards Distribution Preparing scenario: Creating proposal & Delegating tokens',
        async function () {
            const proposalDescription = 'Test Proposal #1: Create epoch';
            let aliceValues: any[];
            let merkleTree;
            let merkleRoot;
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
                        "300", /* 300 blocks = 1hour */
                        "7200" /* 7200 blocks = 1 day */
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

            describe('#castVote', async function () {
                describe('failure', async function () {
                    it('should revert if proposal is not currently active', async function () {
                        const proposalState = await this.jellyGovernor.state(proposalId);

                        assert(
                            proposalState === ProposalState.Pending,
                            'Proposal should be in pending state'
                        );
                        await expect(
                            this.jellyGovernor
                                .connect(this.signers.alice)
                                .castVote(proposalId, VoteType.For)
                        ).to.be.revertedWith('Governor: vote not currently active');
                    });

                    it('should revert if user has already voted', async function () {
                        await mine(this.params.votingDelay.add(constants.One));

                        proposalParams = utils.defaultAbiCoder.encode(
                            ['uint256[]'],
                            [[chestIDs[0]]]
                        );

                        await this.jellyGovernor
                            .connect(this.signers.alice)
                            .castVoteWithReasonAndParams(proposalId, VoteType.For, "", proposalParams);

                        await expect(
                            this.jellyGovernor
                                .connect(this.signers.alice)
                                .castVoteWithReasonAndParams(proposalId, VoteType.For, "", proposalParams)
                        ).to.be.revertedWith('GovernorVotingSimple: vote already cast');
                    });

                });

                describe('success', async function () {
                    beforeEach(async function () {
                        await mine(this.params.votingDelay.add(constants.One));
                    });

                    proposalParams = utils.defaultAbiCoder.encode(
                        ['uint256[]'],
                        [[chestIDs[0]]]
                    );

                    it('should cast vote', async function () {
                        const delegatedVotesTotal = await this.jellyGovernor.getVotesWithParams(
                            this.signers.alice.address,
                            2,
                            proposalParams
                        );

                        await this.jellyGovernor
                            .connect(this.signers.alice)
                            .castVoteWithReasonAndParams(proposalId, VoteType.For, "", proposalParams);

                        const hasAliceVoted = await this.jellyGovernor.hasVoted(
                            proposalId,
                            this.signers.alice.address
                        );

                        assert(hasAliceVoted, 'Alice should have voted');

                        const proposalVotes = await this.jellyGovernor.proposalVotes(
                            proposalId
                        );

                        assert(
                            proposalVotes.forVotes.eq(delegatedVotesTotal),
                            'For votes should be equal to total delegated votes of Alice'
                        );
                    });

                    it('should emit VoteCast event', async function () {
                        const delegatedVotesTotal = await this.jellyGovernor.getVotesWithParams(
                            this.signers.alice.address,
                            2,
                            proposalParams
                        );

                        const weight = delegatedVotesTotal;
                        const reason = '';

                        await expect(
                            await this.jellyGovernor
                                .connect(this.signers.alice)
                                .castVoteWithReasonAndParams(proposalId, VoteType.For, "", proposalParams)
                        )
                            .to.emit(this.jellyGovernor, 'VoteCastWithParams')
                            .withArgs(
                                this.signers.alice.address,
                                proposalId,
                                VoteType.For,
                                weight,
                                reason,
                                proposalParams
                            );
                    });
                });
            });
        }
    );
}