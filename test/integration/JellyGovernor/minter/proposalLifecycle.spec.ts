import { assert } from 'chai';
import { mine } from '@nomicfoundation/hardhat-network-helpers';
import { utils, BigNumber, constants } from 'ethers';
import { ProposalState, VoteType } from '../../../shared/types';

export function shouldFollowProposalLifeCycle(): void {
  context('Minter Set new Staking Rewards Distribution Contract Proposal Lifecycle', async function () {
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

    it('should be in pending state', async function () {
      const proposalState = await this.jellyGovernor.state(proposalId);

      assert(
        proposalState === ProposalState.Pending,
        'Proposal should be in pending state'
      );
    });

    it('should be in active state', async function () {
      await mine(this.params.votingDelay.add(constants.One));

      const proposalState = await this.jellyGovernor.state(proposalId);

      assert(
        proposalState === ProposalState.Active,
        'Proposal should be in active state'
      );
    });

    it('should be in succeeded state', async function () {
      await mine(this.params.votingDelay.add(constants.One));

      proposalParams = utils.defaultAbiCoder.encode(
        ['uint256[]'],
        [[chestIDs[0]]]
      );

      await this.jellyGovernor
        .connect(this.signers.alice)
        .castVoteWithReasonAndParams(proposalId, VoteType.For, "", proposalParams);

      await mine(this.params.votingPeriod.add(constants.One));

      const proposalState = await this.jellyGovernor.state(proposalId);

      assert(
        proposalState === ProposalState.Succeeded,
        'Proposal should be in succeeded state'
      );
    });

    it('should be in defeated state', async function () {
      await mine(this.params.votingDelay.add(constants.One));

      proposalParams = utils.defaultAbiCoder.encode(
        ['uint256[]'],
        [[chestIDs[0]]]
      );

      await this.jellyGovernor
        .connect(this.signers.alice)
        .castVoteWithReasonAndParams(proposalId, VoteType.Against, "", proposalParams);

      await mine(this.params.votingPeriod.add(constants.One));

      const proposalState = await this.jellyGovernor.state(proposalId);

      assert(
        proposalState === ProposalState.Defeated,
        'Proposal should be in defeated state'
      );
    });

    it('should be in queued state', async function () {
      await mine(this.params.votingDelay.add(constants.One));

      proposalParams = utils.defaultAbiCoder.encode(
        ['uint256[]'],
        [[chestIDs[0]]]
      );

      await this.jellyGovernor
        .connect(this.signers.alice)
        .castVoteWithReasonAndParams(proposalId, VoteType.For, "", proposalParams);

      await mine(this.params.votingPeriod.add(constants.One));

      const proposalDescriptionHash = utils.id(proposalDescription);

      await this.jellyGovernor
        .connect(this.signers.alice)
        .queue(
          [this.minter.address],
          [0],
          [setStakingRewardsContractFunctionCalldata],
          proposalDescriptionHash
        );

      const proposalState = await this.jellyGovernor.state(proposalId);

      assert(
        proposalState === ProposalState.Queued,
        'Proposal should be in queued state'
      );
    });
    it('should be in executed state', async function () {
      await mine(this.params.votingDelay.add(constants.One));

      proposalParams = utils.defaultAbiCoder.encode(
        ['uint256[]'],
        [[chestIDs[0]]]
      );

      await this.jellyGovernor
        .connect(this.signers.alice)
        .castVoteWithReasonAndParams(proposalId, VoteType.For, "", proposalParams);

      await mine(this.params.votingPeriod.add(constants.One));

      const proposalDescriptionHash = utils.id(proposalDescription);

      await this.jellyGovernor
        .connect(this.signers.alice)
        .queue(
          [this.minter.address],
          [0],
          [setStakingRewardsContractFunctionCalldata],
          proposalDescriptionHash
        );

      await mine(this.params.minTimelockDelay.add(constants.One));

      await this.jellyGovernor
        .connect(this.signers.alice)
        .execute(
          [this.minter.address],
          [0],
          [setStakingRewardsContractFunctionCalldata],
          proposalDescriptionHash
        );

      const proposalState = await this.jellyGovernor.state(proposalId);
      const stakingRewardsContract = await this.minter._stakingRewardsContract();

      assert(
        proposalState === ProposalState.Executed,
        'Proposal should be in executed state'
      );
      assert(stakingRewardsContract === this.signers.newStakingRewardsContractAddress.address, 'New Staking Rewards Contract should be set');
    });
  });
}