import { loadFixture } from '@nomicfoundation/hardhat-network-helpers';
import { unitJellyGovernorFixture } from '../../fixtures/unit__Governor';
import { Mocks, Params } from '../../shared/types';
import { shouldCreateProposals } from './creatingProposal.spec';
import { shouldDeploy } from './deployment.spec';

export function shouldBehaveLikeJellyGovernor(): void {
	describe('JellyGovernor', async function () {
		beforeEach(async function () {
			const {
				jellyGovernor,
				mockJellyToken,
				mockChest,
				mockJellyTimelock,
				votingDelay,
				votingPeriod,
				proposalThreshold,
				quorum,
			} = await loadFixture(unitJellyGovernorFixture);

			this.jellyGovernor = jellyGovernor;

			this.mocks = {} as Mocks;
			this.mocks.mockJellyToken = mockJellyToken;
			this.mocks.mockChest = mockChest;
			this.mocks.mockJellyTimelock = mockJellyTimelock;

			this.params = {} as Params;
			this.params.votingDelay = votingDelay;
			this.params.votingPeriod = votingPeriod;
			this.params.proposalThreshold = proposalThreshold;
			this.params.quorum = quorum;
		});

		shouldDeploy();
	});
}
