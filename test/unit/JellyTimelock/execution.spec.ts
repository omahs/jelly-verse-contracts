import { assert, expect } from 'chai';
import { utils, constants } from 'ethers';
import { time } from '@nomicfoundation/hardhat-network-helpers';

export function shouldExecuteScheduledOperations(): void {
	const SALT =
		'0x025e7b0be353a74631ad648c667493c0e1cd31caa4cc2d3520fdc171ea0cc726'; // a random value

	context('Executing single operations', async function () {
		describe('#execute', async function () {
			let id: string;
			let EXECUTOR_ROLE: string;
			let mintFunctionCalldata: string;

			beforeEach(async function () {
				const amountToMint = utils.parseEther('100');
				mintFunctionCalldata =
					this.mocks.mockJelly.interface.encodeFunctionData('mint', [
						this.signers.beneficiary.address,
						amountToMint,
					]);

				await this.jellyTimelock
					.connect(this.signers.timelockProposer)
					.schedule(
						this.mocks.mockJelly.address,
						constants.Zero,
						mintFunctionCalldata,
						constants.HashZero,
						SALT,
						this.params.minTimelockDelay
					);

				id = await this.jellyTimelock.hashOperation(
					this.mocks.mockJelly.address,
					constants.Zero,
					mintFunctionCalldata,
					constants.HashZero,
					SALT
				);

				EXECUTOR_ROLE = await this.jellyTimelock.EXECUTOR_ROLE();
			});

			describe('failure', async function () {
				it('should revert if at least minimum delay has not passed', async function () {
					await expect(
						this.jellyTimelock
							.connect(this.signers.timelockExecutor)
							.execute(
								this.mocks.mockJelly.address,
								constants.Zero,
								mintFunctionCalldata,
								constants.HashZero,
								SALT
							)
					).to.be.revertedWith('TimelockController: operation is not ready');
				});
			});

			describe('success', async function () {
				it('should execute operation if called by anyone', async function () {
					time.increase(this.params.minTimelockDelay);

					await this.jellyTimelock
						.connect(this.signers.alice)
						.execute(
							this.mocks.mockJelly.address,
							constants.Zero,
							mintFunctionCalldata,
							constants.HashZero,
							SALT
						);

					assert(
						await this.jellyTimelock.isOperationDone(id),
						"Execution has't happened"
					);
				});
				
				it('should emit CallExecuted event', async function () {
					time.increase(this.params.minTimelockDelay);

					await expect(
						this.jellyTimelock
							.connect(this.signers.timelockExecutor)
							.execute(
								this.mocks.mockJelly.address,
								constants.Zero,
								mintFunctionCalldata,
								constants.HashZero,
								SALT
							)
					)
						.to.emit(this.jellyTimelock, 'CallExecuted')
						.withArgs(
							id,
							constants.Zero,
							this.mocks.mockJelly.address,
							constants.Zero,
							mintFunctionCalldata
						);
				});
			});
		});
	});

	context('Executing batch of operations', async function () {
		describe('#executeBatch', async function () {
			let id: string;
			let EXECUTOR_ROLE: string;
			let mintFunctionCalldata: string;
			let burnFunctionCalldata: string;

			beforeEach(async function () {
				const amountToMint = utils.parseEther('100');
				mintFunctionCalldata =
					this.mocks.mockJelly.interface.encodeFunctionData('mint', [
						this.signers.beneficiary.address,
						amountToMint,
					]);

				burnFunctionCalldata =
					this.mocks.mockJelly.interface.encodeFunctionData('mint', [
						constants.AddressZero,
						amountToMint,
					]);

				await this.jellyTimelock
					.connect(this.signers.timelockProposer)
					.scheduleBatch(
						[
							this.mocks.mockJelly.address,
							this.mocks.mockJelly.address,
						],
						[constants.Zero, constants.Zero],
						[mintFunctionCalldata, burnFunctionCalldata],
						constants.HashZero,
						SALT,
						this.params.minTimelockDelay
					);

				id = await this.jellyTimelock.hashOperationBatch(
					[this.mocks.mockJelly.address, this.mocks.mockJelly.address],
					[constants.Zero, constants.Zero],
					[mintFunctionCalldata, burnFunctionCalldata],
					constants.HashZero,
					SALT
				);

				EXECUTOR_ROLE = await this.jellyTimelock.EXECUTOR_ROLE();

				await time.increase(this.params.minTimelockDelay);
			});

			describe('failure', async function () {
				it('should revert if there is a values length missmatch', async function () {
					await expect(
						this.jellyTimelock
							.connect(this.signers.timelockExecutor)
							.executeBatch(
								[
									this.mocks.mockJelly.address,
									this.mocks.mockJelly.address,
								],
								[constants.Zero],
								[mintFunctionCalldata, burnFunctionCalldata],
								constants.HashZero,
								SALT
							)
					).to.be.revertedWith('TimelockController: length mismatch');
				});

				it('should revert if there is a payloads length missmatch', async function () {
					await expect(
						this.jellyTimelock
							.connect(this.signers.timelockExecutor)
							.executeBatch(
								[
									this.mocks.mockJelly.address,
									this.mocks.mockJelly.address,
								],
								[constants.Zero, constants.Zero],
								[mintFunctionCalldata],
								constants.HashZero,
								SALT
							)
					).to.be.revertedWith('TimelockController: length mismatch');
				});
			});

			describe('success', async function () {
				it('should execute operation', async function () {
					await this.jellyTimelock
						.connect(this.signers.timelockExecutor)
						.executeBatch(
							[
								this.mocks.mockJelly.address,
								this.mocks.mockJelly.address,
							],
							[constants.Zero, constants.Zero],
							[mintFunctionCalldata, burnFunctionCalldata],
							constants.HashZero,
							SALT
						);

					assert(
						await this.jellyTimelock.isOperationDone(id),
						"Execution has't happened"
					);
				});
			});
		});
	});
}
