import { assert, expect } from 'chai';
import { utils, constants } from 'ethers';
import { mine, time } from '@nomicfoundation/hardhat-network-helpers';

export function shouldCancelScheduledOperations(): void {
	describe('#cancel', async function () {
		const SALT =
			'0x025e7b0be353a74631ad648c667493c0e1cd31caa4cc2d3520fdc171ea0cc726'; // a random value

		let id: string;
		let CANCELLER_ROLE: string;
		let mintFunctionCalldata: string;

		beforeEach(async function () {
			const amountToMint = utils.parseEther('100');
			mintFunctionCalldata =
				this.mocks.mockJellyToken.interface.encodeFunctionData('mint', [
					this.signers.beneficiary.address,
					amountToMint,
				]);

			await this.jellyTimelock
				.connect(this.signers.timelockProposer)
				.schedule(
					this.mocks.mockJellyToken.address,
					constants.Zero,
					mintFunctionCalldata,
					constants.HashZero,
					SALT,
					this.params.minTimelockDelay
				);

			id = await this.jellyTimelock.hashOperation(
				this.mocks.mockJellyToken.address,
				constants.Zero,
				mintFunctionCalldata,
				constants.HashZero,
				SALT
			);

			CANCELLER_ROLE = await this.jellyTimelock.CANCELLER_ROLE();
		});

		describe('failure', async function () {
			it('should revert if not called by an account with Canceller role', async function () {
				await expect(
					this.jellyTimelock.connect(this.signers.timelockAdmin).cancel(id)
				).to.be.revertedWith(
					`AccessControl: account ${this.signers.timelockAdmin.address.toLowerCase()} is missing role ${CANCELLER_ROLE}`
				);
			});

			it('should revert if operation is already executed', async function () {
				await time.increase(this.params.minTimelockDelay);

				await this.jellyTimelock
					.connect(this.signers.timelockExecutor)
					.execute(
						this.mocks.mockJellyToken.address,
						constants.Zero,
						mintFunctionCalldata,
						constants.HashZero,
						SALT
					);

				await expect(
					this.jellyTimelock.connect(this.signers.timelockProposer).cancel(id)
				).to.be.revertedWith(
					'TimelockController: operation cannot be cancelled'
				);
			});
		});

		describe('success', async function () {
			it('should cancel operation', async function () {
				await this.jellyTimelock
					.connect(this.signers.timelockProposer)
					.cancel(id);

				assert(
					!(await this.jellyTimelock.isOperation(id)),
					"Operation has't been cancelled"
				);
			});

			it('should emit Cancelled event', async function () {
				await expect(
					this.jellyTimelock.connect(this.signers.timelockProposer).cancel(id)
				)
					.to.emit(this.jellyTimelock, 'Cancelled')
					.withArgs(id);
			});
		});
	});
}
