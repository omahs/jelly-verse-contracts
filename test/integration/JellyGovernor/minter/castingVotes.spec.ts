import { assert, expect } from 'chai';
import { mine } from '@nomicfoundation/hardhat-network-helpers';
import { utils, BigNumber, constants } from 'ethers';
import { ProposalState, VoteType } from '../../../shared/types';

export function shouldCastVotes(): void {
    context(
        'Minter Preparing scenario: Creating proposal & Delegating tokens',
        async function () {
            const proposalDescription = 'Test Proposal #1: Set new Staking Rewards Distribution Contract';
            let setStakingRewardsContractFunctionCalldata: string;
            let proposalId: BigNumber;
            let proposalParams: string;
            const chestIDs: number[] = [0, 1, 2];
            beforeEach(async function () {
                setStakingRewardsContractFunctionCalldata = this.minter.interface.encodeFunctionData(
                    'setStakingRewardsContract',
                    [this.signers.newStakingRewardsContractAddress.address]
                );
                await this.jellyGovernor
                    .connect(this.signers.alice)
                    .propose(
                        [this.minter.address],
                        [0],
                        [setStakingRewardsContractFunctionCalldata],
                        proposalDescription
                    );

                const abiEncodedParams = utils.defaultAbiCoder.encode(
                    ['address[]', 'uint256[]', 'bytes[]', 'bytes32'],
                    [
                        [this.minter.address],
                        [0],
                        [setStakingRewardsContractFunctionCalldata],
                        utils.keccak256(utils.toUtf8Bytes(proposalDescription)),
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