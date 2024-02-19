import { assert, expect } from 'chai';
import { mine, time } from '@nomicfoundation/hardhat-network-helpers';
import { utils, BigNumber, constants } from 'ethers';
import { ProposalState, VoteType } from '../../../shared/types';

export function shouldFollowProposalLifeCycle(): void {
  context('Official Pools Register new Official Pool Proposal Lifecycle', async function () {
    const pool = { poolId: "0x7f65ce7eed9983ba6973da773ca9d574f285a24c000200000000000000000000", weight: 1 };    const proposalDescription = 'Test Proposal #1: Register new Official Pool';
    let registerOfficialPoolFunctionCalldata: string;
    let proposalId: BigNumber;
    let proposalParams: string;
    const chestIDs: number[] = [0, 1, 2];

    beforeEach(async function () {
      const pools: { poolId: string, weight: number }[] = [pool];
      registerOfficialPoolFunctionCalldata = this.officialPoolsRegister.interface.encodeFunctionData(
        'registerOfficialPool',
        [pools]
      );

      await this.jellyGovernor
        .connect(this.signers.alice)
        .propose(
          [this.officialPoolsRegister.address],
          [0],
          [registerOfficialPoolFunctionCalldata],
          proposalDescription
        );

      const abiEncodedParams = utils.defaultAbiCoder.encode(
        ['address[]', 'uint256[]', 'bytes[]', 'bytes32'],
        [
          [this.officialPoolsRegister.address],
          [0],
          [registerOfficialPoolFunctionCalldata],
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
          [this.officialPoolsRegister.address],
          [0],
          [registerOfficialPoolFunctionCalldata],
          proposalDescriptionHash
        );

      const proposalState = await this.jellyGovernor.state(proposalId);

      assert(
        proposalState === ProposalState.Queued,
        'Proposal should be in queued state'
      );
    });
    it('should be in executed state', async function () {
      const officialPoolsRegisteredBefore = await this.officialPoolsRegister.getAllOfficialPools();
      const numberOfOfficialPoolsRegisteredBefore = officialPoolsRegisteredBefore.length;

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
          [this.officialPoolsRegister.address],
          [0],
          [registerOfficialPoolFunctionCalldata],
          proposalDescriptionHash
        );

      await mine(this.params.minTimelockDelay.add(constants.One));

      await this.jellyGovernor
        .connect(this.signers.alice)
        .execute(
          [this.officialPoolsRegister.address],
          [0],
          [registerOfficialPoolFunctionCalldata],
          proposalDescriptionHash
        );

      const proposalState = await this.jellyGovernor.state(proposalId);
      const officialPoolsRegisteredAfter = await this.officialPoolsRegister.getAllOfficialPools();
      const numberOfOfficialPoolsRegisteredAfter = officialPoolsRegisteredAfter.length;
      assert(
        proposalState === ProposalState.Executed,
        'Proposal should be in executed state'
      );
      assert(numberOfOfficialPoolsRegisteredAfter === numberOfOfficialPoolsRegisteredBefore + 1, 'Official Pool should be registered');
      assert(JSON.stringify(officialPoolsRegisteredAfter) == JSON.stringify([...officialPoolsRegisteredBefore, pool.poolId]), 'Official Pool value should match');
    });
  });
}