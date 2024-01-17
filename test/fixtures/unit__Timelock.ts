import { JellyTimelock, JellyTimelock__factory } from '../../typechain-types';
import { getSigners } from '../shared/utils';
import { ethers } from 'hardhat';
import { BigNumber, constants } from 'ethers';
import { MockContract } from '@ethereum-waffle/mock-contract';
import { deployMockJelly } from '../shared/mocks';

type UnitJellyTimelockFixtureType = {
	jellyTimelock: JellyTimelock;
	mockJellyToken: MockContract;
	minTimelockDelay: BigNumber;
	proposers: string[];
	executors: string[];
};


export async function unitJellyTimelockFixture(): Promise<UnitJellyTimelockFixtureType> {
	const ONE_DAYS_IN_SOLIDITY = BigNumber.from('7200');
	const {
		deployer,
		alice,
		timelockProposer,
		bob,
		timelockExecutor,
		timelockAdmin,
	} = await getSigners();

	const mockJellyToken = await deployMockJelly(deployer);

	const minTimelockDelay = ONE_DAYS_IN_SOLIDITY;
	const proposers = [alice.address, timelockProposer.address, constants.AddressZero];
	const executors = [bob.address, timelockExecutor.address, constants.AddressZero];

	const jellyTimelockFactory: JellyTimelock__factory =
		await ethers.getContractFactory('JellyTimelock');

	const jellyTimelock: JellyTimelock = await jellyTimelockFactory
		.connect(deployer)
		.deploy(minTimelockDelay, proposers, executors, timelockAdmin.address);

	await jellyTimelock.deployed();

	return {
		jellyTimelock,
		mockJellyToken,
		minTimelockDelay,
		proposers,
		executors,
	};
}
