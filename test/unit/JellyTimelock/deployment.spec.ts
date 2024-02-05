import { assert, expect } from 'chai';
import { utils } from 'ethers';

export function shouldDeploy(): void {
	context('Deployment', async function () {
		it('should deploy JellyTimelock smart contract', async function () {
			expect(this.jellyTimelock.address).to.be.properAddress;
		});
	});

	describe('#constructor', async function () {
		it('should set minimum delay', async function () {
			const expectedMinDelay = this.params.minTimelockDelay;
			const actualMinDelay = await this.jellyTimelock.getMinDelay();

			assert(expectedMinDelay.eq(actualMinDelay), 'Minimum Delay not set');
		});

		it('should set Timelock Admin Role', async function () {
			const actualTimelockAdminRole =
				await this.jellyTimelock.TIMELOCK_ADMIN_ROLE();

			const expectedTimelockAdminRole = utils.keccak256(
				utils.toUtf8Bytes('TIMELOCK_ADMIN_ROLE')
			);

			assert(
				expectedTimelockAdminRole === actualTimelockAdminRole,
				'TIMELOCK_ADMIN_ROLE missmatch'
			);
			assert(
				await this.jellyTimelock.hasRole(
					actualTimelockAdminRole,
					this.signers.timelockAdmin.address
				),
				'Timelock Admin Role not set'
			);
		});

		it('should set Timelock Proposer Role', async function () {
			const actualTimelockProposerRole =
				await this.jellyTimelock.PROPOSER_ROLE();

			const expectedTimelockProposerRole = utils.keccak256(
				utils.toUtf8Bytes('PROPOSER_ROLE')
			);

			assert(
				expectedTimelockProposerRole === actualTimelockProposerRole,
				'PROPOSER_ROLE missmatch'
			);

			this.params.proposers.map(async (proposerAddress: string) => {
				assert(
					await this.jellyTimelock.hasRole(
						actualTimelockProposerRole,
						proposerAddress
					),
					`Timelock Proposer Role not set for ${proposerAddress}`
				);
			});
		});

		it('should set Timelock Executor Role', async function () {
			const actualTimelockExecutorRole =
				await this.jellyTimelock.EXECUTOR_ROLE();

			const expectedTimelockExecutorRole = utils.keccak256(
				utils.toUtf8Bytes('EXECUTOR_ROLE')
			);

			assert(
				expectedTimelockExecutorRole === actualTimelockExecutorRole,
				'EXECUTOR_ROLE missmatch'
			);

			this.params.proposers.map(async (proposerAddress: string) => {
				assert(
					await this.jellyTimelock.hasRole(
						actualTimelockExecutorRole,
						proposerAddress
					),
					`Timelock Executor Role not set for ${proposerAddress}`
				);
			});
		});

		it('should set Timelock Canceller Role', async function () {
			const actualTimelockCancellerRole =
				await this.jellyTimelock.CANCELLER_ROLE();

			const expectedTimelockCancellerRole = utils.keccak256(
				utils.toUtf8Bytes('CANCELLER_ROLE')
			);

			assert(
				expectedTimelockCancellerRole === actualTimelockCancellerRole,
				'CANCELLER_ROLE missmatch'
			);

			this.params.proposers.map(async (proposerAddress: string) => {
				assert(
					await this.jellyTimelock.hasRole(
						actualTimelockCancellerRole,
						proposerAddress
					),
					`Timelock Canceller Role not set for ${proposerAddress}`
				);
			});
		});
	});
}
