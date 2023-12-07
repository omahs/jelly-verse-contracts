import { JellyGovernor, JellyGovernor__factory } from '../../typechain-types';
import { getSigners } from '../shared/utils';
import { ethers } from 'hardhat';
import { BigNumber, constants } from 'ethers';
import { MockContract } from '@ethereum-waffle/mock-contract';
import { deployMockJelly, deployMockChest, deployMockJellyTimelock } from '../shared/mocks';

type UnitJellyGovernorFixtureType = {
	jellyGovernor: JellyGovernor;
	mockJellyToken: MockContract;
	mockJellyTimelock: MockContract;
	mockChest: MockContract;
	votingDelay: BigNumber;
	votingPeriod: BigNumber;
	proposalThreshold: BigNumber;
	quorum: BigNumber;
	lastChestId: BigNumber;
};


export async function unitJellyGovernorFixture(): Promise<UnitJellyGovernorFixtureType> {
	const { deployer } = await getSigners();

	const votingDelay = BigNumber.from('7200'); // 1 day
	const votingPeriod = BigNumber.from('50400'); // 1 week
	const proposalThreshold = BigNumber.from('0'); // anyone can create a proposal
	const quorum = BigNumber.from('1000000'); // 1000000
	const lastChestId = BigNumber.from('9'); // 9 (chest.totalSupply() - 1)

	const mockJellyToken = await deployMockJelly(deployer);
	const mockChest = await deployMockChest(deployer);
	const mockJellyTimelock = await deployMockJellyTimelock(deployer);

	const jellyGovernorFactory: JellyGovernor__factory =
		await ethers.getContractFactory('JellyGovernor') as JellyGovernor__factory;

	const jellyGovernor: JellyGovernor = await jellyGovernorFactory.deploy(
		mockChest.address,
		mockJellyTimelock.address
	);
	await jellyGovernor.deployed();

	return {
		jellyGovernor,
		mockJellyToken,
		mockChest,
		mockJellyTimelock,
		votingDelay,
		votingPeriod,
		proposalThreshold,
		quorum,
		lastChestId,
	};
}
