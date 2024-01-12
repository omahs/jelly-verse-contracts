import { loadFixture, time } from '@nomicfoundation/hardhat-network-helpers';
import { unitVestingFixture } from '../../fixtures/vesting_lib/unit__VestingChest';
import { expect, assert } from 'chai';
import { BigNumber, constants } from 'ethers';
import { calculateVestedAmountJs } from '../../shared/helpers';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';

export function shouldBehaveLikeVestingChest(): void {
	describe(`VestingChest`, () => {
		const ONE_DAY = 86400;
		const ONE_MONTH = 2629743;

		let _cliffDuration: number;
		let _startTimestamp: BigNumber;
		let _cliffTimestamp: BigNumber;
		let _vestingDuration: number;
		let _totalDuration: number;
		let _amount: BigNumber;
		let _booster: BigNumber;
		let _nerfParameter: number;

		beforeEach(async function () {
			const {
				vesting,
				cliffDuration,
				vestingDuration,
				amount,
				booster,
				nerfParameter
			} = await loadFixture(unitVestingFixture);

			this.vesting = vesting;
			_cliffDuration = cliffDuration;
			_vestingDuration = vestingDuration;
			_startTimestamp = BigNumber.from(await time.latest());
			_amount = amount;
			_booster = booster;
			_nerfParameter = nerfParameter;

			_cliffTimestamp = _startTimestamp.add(_cliffDuration);
			_totalDuration = _cliffTimestamp.add(vestingDuration).toNumber();
			await this.vesting.createNewVestingPosition(_amount, _cliffDuration, _vestingDuration, _booster, _nerfParameter);
		});

		describe(`#createVestingPosition`, async function () {
			describe(`success`, async function () {
				it('should create vesting position with correct parameters', async function () {
					await this.vesting.createNewVestingPosition(_amount, _cliffDuration, _vestingDuration, _booster, _nerfParameter);

					const vestingPosition = await this.vesting.getVestingPosition(1);
					expect(vestingPosition.totalVestedAmount).to.equal(_amount);
					expect(vestingPosition.releasedAmount).to.equal(0);
					expect(vestingPosition.cliffTimestamp).to.equal(_cliffTimestamp.add(2));
					expect(vestingPosition.vestingDuration).to.equal(_vestingDuration);
					expect(vestingPosition.freezingPeriod).to.equal(_cliffDuration);
					expect(vestingPosition.booster).to.equal(_booster);
					expect(vestingPosition.nerfParameter).to.equal(_nerfParameter);
				});

				it('should emit proper event', async function () {
					expect(await this.vesting.createNewVestingPosition(_amount, _cliffDuration, _vestingDuration, _booster, _nerfParameter))
						.to.emit(this.vesting, 'NewVestingPosition')
						.withArgs(await this.vesting.getVestingPosition(1), 1);
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
						await this.vesting.updateReleasedAmount(0, halfAmount);
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