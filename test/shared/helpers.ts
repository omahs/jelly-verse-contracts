import { BigNumber, constants } from 'ethers';

export function calculateVestedAmountJs(
	blockTimestamp: BigNumber,
	cliffTimestamp: BigNumber,
	vestingDuration: BigNumber,
	amount: BigNumber
): BigNumber {
	if (blockTimestamp < cliffTimestamp) {
		return constants.Zero;
	} else if (blockTimestamp >= cliffTimestamp.add(vestingDuration)) {
		return amount;
	} else {
		return amount.mul(blockTimestamp.sub(cliffTimestamp)).div(vestingDuration);
	}
}