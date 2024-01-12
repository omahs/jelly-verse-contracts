import { loadFixture, time } from '@nomicfoundation/hardhat-network-helpers';
import { unitVestingFixture } from '../../fixtures/vesting_lib/unit__Vesting';
import { expect, assert } from 'chai';
import { BigNumber, constants } from 'ethers';
import { calculateVestedAmountJs } from '../../shared/helpers';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';

export function shouldBehaveLikeVesting(): void {
	describe(`Vesting`, () => {
		const ONE_DAY = 86400;
		const ONE_MONTH = 2629743;

		let _cliffDuration: number;
		let _startTimestamp: BigNumber;
		let _cliffTimestamp: BigNumber;
		let _vestingDuration: number;
		let _totalDuration: number;
		let _amount: BigNumber;
		let _beneficiary: SignerWithAddress;

		beforeEach(async function () {
			const {
				vesting,
				beneficiary,
				cliffDuration,
				vestingDuration,
				amount,
			} = await loadFixture(unitVestingFixture);

			this.vesting = vesting;
			_beneficiary = beneficiary;
			_cliffDuration = cliffDuration;
			_vestingDuration = vestingDuration;
			_startTimestamp = BigNumber.from(await time.latest());
			_amount = amount;

			_cliffTimestamp = _startTimestamp.add(_cliffDuration);
			_totalDuration = _cliffTimestamp.add(vestingDuration).toNumber();
			await this.vesting.createNewVestingPosition(_amount, _beneficiary.address, _cliffDuration, _vestingDuration)
		});

		describe(`#createVestingPosition`, async function () {
			describe(`success`, async function () {
				it('should create vesting position with correct parameters', async function () {
					await this.vesting.createNewVestingPosition(_amount, _beneficiary.address, _cliffDuration, _vestingDuration);

					const vestingPosition = await this.vesting.getVestingPosition(1);
					expect(vestingPosition.totalVestedAmount).to.equal(_amount);
					expect(vestingPosition.releasedAmount).to.equal(0);
					expect(vestingPosition.beneficiary).to.equal(_beneficiary.address);
					expect(vestingPosition.cliffTimestamp).to.equal(_cliffTimestamp.add(2));
					expect(vestingPosition.vestingDuration).to.equal(_vestingDuration);
				});

				it('should emit proper event', async function () {
					expect(await this.vesting.createNewVestingPosition(_amount, _beneficiary.address, _cliffDuration, _vestingDuration))
						.to.emit(this.vesting, 'NewVestingPosition')
						.withArgs(await this.vesting.getVestingPosition(1), 1);
				});
			});

			describe(`failure`, async function () {
				it('should revert if cliffDuration is == 0', async function () {
					await expect(this.vesting.createNewVestingPosition(_amount, _beneficiary.address, 0, _vestingDuration))
						.to.be.revertedWithCustomError(this.vesting, 'VestingLib__InvalidDuration');
				});

				it('should revert if amount is == 0', async function () {
					await expect(this.vesting.createNewVestingPosition(0, _beneficiary.address, _cliffDuration, _vestingDuration))
						.to.be.revertedWithCustomError(this.vesting, 'VestingLib__InvalidVestingAmount');
				});

				it('should revert if beneficiary is zero address 0x00...', async function () {
					await expect(this.vesting.createNewVestingPosition(_amount, constants.AddressZero, _cliffDuration, _vestingDuration))
						.to.be.revertedWithCustomError(this.vesting, 'VestingLib__InvalidBeneficiary');
				});
			});
		})

		describe(`#updateReleasedAmount`, async function () {
			describe(`success`, async function () {
				it('should only update released amount', async function () {
					await time.increase(_totalDuration);

					const oldPosition = await this.vesting.getVestingPosition(0);

					await this.vesting.connect(_beneficiary).updateReleasedAmountPublic(0, _amount.div(2));

					const vestingPosition = await this.vesting.getVestingPosition(0);
					expect(vestingPosition.totalVestedAmount).to.equal(oldPosition.totalVestedAmount);
					expect(vestingPosition.releasedAmount).to.equal(_amount.div(2));
					expect(vestingPosition.beneficiary).to.equal(oldPosition.beneficiary);
					expect(vestingPosition.cliffTimestamp).to.equal(oldPosition.cliffTimestamp);
					expect(vestingPosition.vestingDuration).to.equal(oldPosition.vestingDuration);
				});
			});

			describe(`failure`, async function () {
				it('should revert if vesting position doesn\'t exists, vesting index > index', async function () {
					await expect(this.vesting.updateReleasedAmountPublic(1, 1000))
						.to.be.revertedWithCustomError(this.vesting, 'VestingLib__InvalidIndex');
				});

				it('should revert if releaseAmount is == 0', async function () {
					await expect(this.vesting.updateReleasedAmountPublic(0, 0))
						.to.be.revertedWithCustomError(this.vesting, 'VestingLib__InvalidReleaseAmount');
				});

				it('should revert if releaseAmount is > releasable amount before vesting period ended', async function () {
					const oldPosition = await this.vesting.getVestingPosition(0);
					await time.increaseTo(oldPosition.cliffTimestamp + oldPosition.vestingDuration / 3);
					await expect(this.vesting.connect(_beneficiary).updateReleasedAmountPublic(0, _amount.div(2)))
						.to.be.revertedWithCustomError(this.vesting, 'VestingLib__InvalidReleaseAmount');
				});

				it('should revert if releaseAmount is > releasable amount after vesting period ended', async function () {
					await time.increase(_totalDuration);
					await expect(this.vesting.connect(_beneficiary).updateReleasedAmountPublic(0, _amount.add(1)))
						.to.be.revertedWithCustomError(this.vesting, 'VestingLib__InvalidReleaseAmount');
				});

				it('should revert if message signer is not benefitiary', async function () {
					await time.increase(_totalDuration);
					await expect(this.vesting.updateReleasedAmountPublic(0, _amount))
						.to.be.revertedWithCustomError(this.vesting, 'VestingLib__InvalidSender');
				});
			});
		})

		describe(`#vestedAmount`, async function () {
			context(
				`should calculate the vested amount in different moments of time. The cliff duration is 6 months. The vesting duration is 18 months, resulting in 2 years in total`,
				async function () {
					let compareVestedAmountCalculations: () => Promise<BigNumber>;
					let numberOfMonths: number;

					before(async function () {
						numberOfMonths = (_totalDuration - _cliffDuration) / ONE_MONTH;

						compareVestedAmountCalculations = async () => {
							const blockTimestamp = await time.latest();

							const vestedAmountSol = await this.vesting.releasableAmount(0);
							const position = await this.vesting.getVestingPosition(0);
							const vestedAmountJs = calculateVestedAmountJs(
								BigNumber.from(blockTimestamp),
								BigNumber.from(position.cliffTimestamp),
								BigNumber.from(position.vestingDuration),
								BigNumber.from(position.totalVestedAmount)
							);

							assert(
								vestedAmountSol.eq(vestedAmountJs),
								`vestedAmountSol: ${vestedAmountSol} != vestedAmountJs: ${vestedAmountJs}`
							);

							return vestedAmountSol;
						};
					});

					it(`At start timestamp`, async function () {
						await compareVestedAmountCalculations();
					});

					it(`Slightly before cliff timestamp`, async function () {
						const beforeCliffTimestamp = _cliffDuration - ONE_DAY;
						await time.increase(beforeCliffTimestamp);

						await compareVestedAmountCalculations();

						const vestedAmount = await this.vesting.getVestedAmount(0);
						assert(
							vestedAmount.eq(constants.Zero),
							`vestedAmount: ${vestedAmount} != 0`
						);
					});

					it(`At cliff timestamp`, async function () {
						await time.increase(_cliffDuration);

						await compareVestedAmountCalculations();
						const vestedAmount = await this.vesting.getVestedAmount(0);
						assert(
							vestedAmount.eq(constants.Zero),
							`vestedAmount: ${vestedAmount} == 0`
						);
					});

					let previousVestedAmount = constants.Zero;

					for (let i = 1; i <= 18; i++) {
						it(`Month ${i} after cliff timestamp`, async () => {
							await time.increase(_cliffDuration + i * ONE_MONTH);
							const currentVestedAmount =
								await compareVestedAmountCalculations();
							assert(
								currentVestedAmount.gte(previousVestedAmount),
								`currentVestedAmount: ${currentVestedAmount} < previousVestedAmount: ${previousVestedAmount}`
							);
							previousVestedAmount = currentVestedAmount;
						});
					}

					it(`Slightly before the end of vesting duration`, async function () {
						const beforeEndOfVestingDuration = _cliffDuration + _vestingDuration - ONE_DAY;

						await time.increase(beforeEndOfVestingDuration);

						await compareVestedAmountCalculations();

						const vestedAmount = await this.vesting.getVestedAmount(0);
						assert(
							vestedAmount.lt(_amount),
							`vestedAmount: ${vestedAmount} == ${_amount}`
						);
					});

					it(`At the end of vesting duration`, async function () {
						await time.increase(_totalDuration);

						await compareVestedAmountCalculations();

						const vestedAmount = await this.vesting.getVestedAmount(0);
						assert(
							vestedAmount.eq(_amount),
							`vestedAmount: ${vestedAmount} != ${_amount}`
						);
					});

					it(`Slightly after the end of vesting duration`, async function () {
						const afterEndOfVestingDuration = _totalDuration + ONE_DAY;
						await time.increase(afterEndOfVestingDuration);

						await compareVestedAmountCalculations();

						const vestedAmount = await this.vesting.getVestedAmount(0);
						assert(
							vestedAmount.eq(_amount),
							`vestedAmount: ${vestedAmount} != ${_amount}`
						);
					});
				}
			);
		});


		describe(`#releasableAmount`, async function () {
			context(
				`should calculate the releasable amount in different moments of time. The cliff duration is 6 months. The vesting duration is 18 months, resulting in 2 years in total`,
				async function () {
					let compareVestedAmountCalculations: (amount?: BigNumber) => Promise<BigNumber>;
					let numberOfMonths: number;

					before(async function () {
						numberOfMonths = (_totalDuration - _cliffDuration) / ONE_MONTH;

						compareVestedAmountCalculations = async (amount: BigNumber = _amount) => {
							const blockTimestamp = await time.latest();

							const vestedAmountSol = await this.vesting.releasableAmount(0);
							const position = await this.vesting.getVestingPosition(0);
							const vestedAmountJs = calculateVestedAmountJs(
								BigNumber.from(blockTimestamp),
								BigNumber.from(position.cliffTimestamp),
								BigNumber.from(position.vestingDuration),
								amount
							);

							assert(
								vestedAmountSol.eq(vestedAmountJs),
								`vestedAmountSol: ${vestedAmountSol} != vestedAmountJs: ${vestedAmountJs}`
							);

							return vestedAmountSol;
						};
					});

					it(`At start timestamp`, async function () {
						await compareVestedAmountCalculations();
					});

					it(`Slightly before cliff timestamp`, async function () {
						const beforeCliffTimestamp = _cliffDuration - ONE_DAY;
						await time.increase(beforeCliffTimestamp);

						await compareVestedAmountCalculations();

						const vestedAmount = await this.vesting.releasableAmount(0);
						assert(
							vestedAmount.eq(constants.Zero),
							`vestedAmount: ${vestedAmount} != 0`
						);
					});

					it(`At cliff timestamp`, async function () {
						await time.increase(_cliffDuration);

						await compareVestedAmountCalculations();
						const vestedAmount = await this.vesting.releasableAmount(0);
						assert(
							vestedAmount.eq(constants.Zero),
							`vestedAmount: ${vestedAmount} == 0`
						);
					});

					let previousVestedAmount = constants.Zero;

					for (let i = 1; i <= 18; i++) {
						it(`Month ${i} after cliff timestamp`, async () => {
							await time.increase(_cliffDuration + i * ONE_MONTH);
							const currentVestedAmount =
								await compareVestedAmountCalculations();
							assert(
								currentVestedAmount.gte(previousVestedAmount),
								`currentVestedAmount: ${currentVestedAmount} < previousVestedAmount: ${previousVestedAmount}`
							);
							previousVestedAmount = currentVestedAmount;
						});
					}

					it(`Slightly before the end of vesting duration`, async function () {
						const beforeEndOfVestingDuration = _cliffDuration + _vestingDuration - ONE_DAY;

						await time.increase(beforeEndOfVestingDuration);

						await compareVestedAmountCalculations();

						const vestedAmount = await this.vesting.releasableAmount(0);
						assert(
							vestedAmount.lt(_amount),
							`vestedAmount: ${vestedAmount} == ${_amount}`
						);
					});

					it(`At the end of vesting duration`, async function () {
						await time.increase(_totalDuration);

						await compareVestedAmountCalculations();

						const vestedAmount = await this.vesting.releasableAmount(0);
						assert(
							vestedAmount.eq(_amount),
							`vestedAmount: ${vestedAmount} != ${_amount}`
						);
					});

					it(`Slightly after the end of vesting duration`, async function () {
						const afterEndOfVestingDuration = _totalDuration + ONE_DAY;
						await time.increase(afterEndOfVestingDuration);

						await compareVestedAmountCalculations();

						const vestedAmount = await this.vesting.releasableAmount(0);
						assert(
							vestedAmount.eq(_amount),
							`vestedAmount: ${vestedAmount} != ${_amount}`
						);
					});

					it(`Slightly after the end of vesting duration with half amount already released`, async function () {
						const afterEndOfVestingDuration = _totalDuration + ONE_DAY;
						const halfAmount = _amount.div(2);
						await time.increase(afterEndOfVestingDuration);
						await this.vesting.connect(_beneficiary).updateReleasedAmountPublic(0, halfAmount);
						await compareVestedAmountCalculations(halfAmount);

						const vestedAmount = await this.vesting.releasableAmount(0);
						assert(
							vestedAmount.eq(halfAmount),
							`vestedAmount: ${vestedAmount} != ${halfAmount}`
						);
					});
				}
			);
		});
	});

}