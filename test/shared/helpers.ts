import { BigNumber, constants, utils } from 'ethers';

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

export function mapSlot(mapSlotRoot: any, key: any) {
	return utils.keccak256(utils.concat([fixedField(key), fixedField(mapSlotRoot)]));
}

export function fixedString(value: any, length = 32) {
	return utils.hexlify(fixedField(value, length));
}

export function fixedField(value: any, length = 32) {
	return utils.zeroPad(dynamicField(value), length);
}

export function dynamicField(value: any) {
	return utils.arrayify(value, { hexPad: "left" });
}