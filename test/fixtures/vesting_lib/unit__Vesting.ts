import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { VestingLibTest, VestingLibTest__factory } from '../../../typechain-types';
import { getSigners } from '../../shared/utils';
import { ethers } from 'hardhat';
import { BigNumber } from 'ethers';

type UnitVestingFixtureType = {
	vesting: VestingLibTest;
	amount: BigNumber;
	beneficiary: SignerWithAddress;
	revoker: SignerWithAddress;
	startTimestamp: BigNumber;
	cliffDuration: number;
	vestingDuration: number;
};

export async function unitVestingFixture(): Promise<UnitVestingFixtureType> {
	const { deployer, beneficiary, revoker } = await getSigners();

	const amount: BigNumber = ethers.utils.parseEther(`133000000`);
	const cliffDuration: number = 15778458; // 6 months
	const vestingDuration: number = 47335374; // 18 months
	const startTimestamp: BigNumber = BigNumber.from(1704067200); // 01 January 2024
	const vestingFactory: VestingLibTest__factory = await ethers.getContractFactory(
		`VestingLibTest`
	);
	const vesting: VestingLibTest = await vestingFactory.deploy();

	return {
		vesting,
		amount,
		beneficiary,
		revoker,
		startTimestamp,
		cliffDuration,
		vestingDuration,
	};
}