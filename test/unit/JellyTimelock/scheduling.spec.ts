import { assert, expect } from 'chai';
import { utils, constants } from 'ethers';

export function shouldScheduleOperations(): void {
	const SALT =
		'0x025e7b0be353a74631ad648c667493c0e1cd31caa4cc2d3520fdc171ea0cc726'; // a random value

	let idMint: string;
	let idBatch: string;
	let mintFunctionCalldata: string;
	let burnFunctionCalldata: string;
	let PROPOSER_ROLE: string;

	beforeEach(async function () {
		const amountToMint = utils.parseEther('100');
		mintFunctionCalldata =
			this.mocks.mockJellyToken.interface.encodeFunctionData('mint', [
				this.signers.beneficiary.address,
				amountToMint,
			]);
		burnFunctionCalldata =
			this.mocks.mockJellyToken.interface.encodeFunctionData('mint', [
				constants.AddressZero,
				amountToMint,
			]);

		idMint = await this.jellyTimelock.hashOperation(
			this.mocks.mockJellyToken.address,
			constants.Zero,
			mintFunctionCalldata,
			constants.HashZero,
			SALT
		);

		idBatch = await this.jellyTimelock.hashOperationBatch(
			[this.mocks.mockJellyToken.address, this.mocks.mockJellyToken.address],
			[constants.Zero, constants.Zero],
			[mintFunctionCalldata, burnFunctionCalldata],
			constants.HashZero,
			SALT
		);

		PROPOSER_ROLE = await this.jellyTimelock.PROPOSER_ROLE();
	});

	context('Schedulling single operation', async function () {
		describe('#schedule', async function () {
			describe('failure', async function () {
				it('should revert if not called by the Proposer role', async function () {
					await expect(
						this.jellyTimelock
							.connect(this.signers.timelockAdmin)
							.schedule(
								this.mocks.mockJellyToken.address,
								constants.Zero,
								mintFunctionCalldata,
								constants.HashZero,
								SALT,
								this.params.minTimelockDelay
							)
					).to.be.revertedWith(
						`AccessControl: account ${this.signers.timelockAdmin.address.toLowerCase()} is missing role ${PROPOSER_ROLE}`
					);
				});

				it('should revert if operation is already scheduled', async function () {
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

					await expect(
						this.jellyTimelock
							.connect(this.signers.timelockProposer)
							.schedule(
								this.mocks.mockJellyToken.address,
								constants.Zero,
								mintFunctionCalldata,
								constants.HashZero,
								SALT,
								this.params.minTimelockDelay
							)
					).to.be.revertedWith(
						'TimelockController: operation already scheduled'
					);
				});

				it('should revert if insufficient delay is provided', async function () {
					await expect(
						this.jellyTimelock
							.connect(this.signers.timelockProposer)
							.schedule(
								this.mocks.mockJellyToken.address,
								constants.Zero,
								mintFunctionCalldata,
								constants.HashZero,
								SALT,
								constants.Zero
							)
					).to.be.revertedWith('TimelockController: insufficient delay');
				});
			});

			describe('success', async function () {
				it('should schedule operation when proposer calls', async function () {
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

					assert(
						await this.jellyTimelock.isOperationPending(idMint),
						'Operation not scheduled'
					);
				});

				it('should emit CallScheduled event', async function () {
					await expect(
						this.jellyTimelock
							.connect(this.signers.timelockProposer)
							.schedule(
								this.mocks.mockJellyToken.address,
								constants.Zero,
								mintFunctionCalldata,
								constants.HashZero,
								SALT,
								this.params.minTimelockDelay
							)
					)
						.to.emit(this.jellyTimelock, 'CallScheduled')
						.withArgs(
							idMint,
							constants.Zero,
							this.mocks.mockJellyToken.address,
							constants.Zero,
							mintFunctionCalldata,
							constants.HashZero,
							this.params.minTimelockDelay
						);
				});
			});
		});
	});

	context('Schedulling batch of operations', async function () {
		describe('#scheduleBatch', async function () {
			describe('failure', async function () {
				it('should revert if there is a values length missmatch', async function () {
					await expect(
						this.jellyTimelock
							.connect(this.signers.timelockProposer)
							.scheduleBatch(
								[
									this.mocks.mockJellyToken.address,
									this.mocks.mockJellyToken.address,
								],
								[constants.Zero],
								[mintFunctionCalldata, burnFunctionCalldata],
								constants.HashZero,
								SALT,
								this.params.minTimelockDelay
							)
					).to.be.revertedWith('TimelockController: length mismatch');
				});

				it('should revert if there is a payloads length missmatch', async function () {
					await expect(
						this.jellyTimelock
							.connect(this.signers.timelockProposer)
							.scheduleBatch(
								[
									this.mocks.mockJellyToken.address,
									this.mocks.mockJellyToken.address,
								],
								[constants.Zero, constants.Zero],
								[mintFunctionCalldata],
								constants.HashZero,
								SALT,
								this.params.minTimelockDelay
							)
					).to.be.revertedWith('TimelockController: length mismatch');
				});
			});

			describe('success', async function () {
				it('should schedule the batch of operations', async function () {
					await this.jellyTimelock
						.connect(this.signers.timelockProposer)
						.scheduleBatch(
							[
								this.mocks.mockJellyToken.address,
								this.mocks.mockJellyToken.address,
							],
							[constants.Zero, constants.Zero],
							[mintFunctionCalldata, burnFunctionCalldata],
							constants.HashZero,
							SALT,
							this.params.minTimelockDelay
						);

					assert(
						await this.jellyTimelock.isOperationPending(idBatch),
						'Operation not scheduled'
					);
				});
			});
		});
	});
}
