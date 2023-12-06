import { loadFixture } from '@nomicfoundation/hardhat-network-helpers';
import { unitJellyTimelockFixture } from '../../fixtures/unit__Timelock';
import { Mocks, Params } from '../../shared/types';
import { shouldCancelScheduledOperations } from './cancellation.spec';
import { shouldDeploy } from './deployment.spec';
import { shouldExecuteScheduledOperations } from './execution.spec';
import { shouldScheduleOperations } from './scheduling.spec';
import { shouldSetRoles } from './settingRoles.spec';
import { getSigners } from '../../shared/utils';

export function shouldBehaveLikeJellyTimelock(): void {
	describe('JellyTimelock', async function () {
		beforeEach(async function () {
			const {
				jellyTimelock,
				mockJellyToken,
				minTimelockDelay,
				proposers,
				executors,
			} = await loadFixture(unitJellyTimelockFixture);

			this.jellyTimelock = jellyTimelock;

			this.mocks = {} as Mocks;
			this.mocks.mockJellyToken = mockJellyToken;

			this.params = {} as Params;
			this.params.minTimelockDelay = minTimelockDelay;
			this.params.proposers = proposers;
			this.params.executors = executors;
		});

		shouldDeploy();
		shouldSetRoles();
		shouldScheduleOperations();
		shouldCancelScheduledOperations();
		shouldExecuteScheduledOperations();
	});
}
