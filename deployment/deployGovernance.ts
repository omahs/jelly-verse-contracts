import { ethers, run } from 'hardhat';
import { BigNumber } from 'ethers';
import {
	Chest__factory,
	Chest,
	JellyTimelock__factory,
	JellyTimelock,
	JellyGovernor__factory,
	JellyGovernor,
} from '../typechain-types';

async function main() {
	const timelockProposerAddress = `0x0000000000000000000000000000000000000000`;
	const timelockExecutorAddress = `0x0000000000000000000000000000000000000000`;
	const timelockAdminAddress = ``;

	const ONE_DAYS_IN_SOLIDITY = BigNumber.from('86400');
	const minTimelockDelay = ONE_DAYS_IN_SOLIDITY;

	const proposers = [timelockProposerAddress];
	const executors = [timelockExecutorAddress];

	const chestTokenFactory: Chest__factory = await ethers.getContractFactory(
		'Chest'
	);
	const chest: Chest = await chestTokenFactory.deploy();
	await chest.deployed();

	console.log('Chest deployed to:', chest.address);

	const jellyTimelockFactory: JellyTimelock__factory =
		await ethers.getContractFactory('JellyTimelock');
	const jellyTimelock: JellyTimelock = await jellyTimelockFactory.deploy(
		minTimelockDelay,
		proposers,
		executors,
		timelockAdminAddress
	);
	await jellyTimelock.deployed();

	console.log('JellyTimelock deployed to:', jellyTimelock.address);

	const jellyGovernorFactory: JellyGovernor__factory =
		await ethers.getContractFactory('JellyGovernance') as JellyGovernor__factory;

	const jellyGovernance: JellyGovernor = await jellyGovernorFactory.deploy(
		chest.address,
		jellyTimelock.address
	);
	await jellyGovernance.deployed();

	console.log('JellyGovernance deployed to:', jellyGovernance.address);

	// verify contracts
	await run('verify:verify', {
		address: chest.address,
		constructorArguments: [],
	});

	await run('verify:verify', {
		address: jellyTimelock.address,
		constructorArguments: [
			minTimelockDelay,
			proposers,
			executors,
			timelockAdminAddress,
		],
	});

	await run('verify:verify', {
		address: jellyGovernance.address,
		constructorArguments: [
			chest.address,
			jellyTimelock.address,
		],
	});
}

main().catch((error) => {
	console.error(error);
	process.exitCode = 1;
});
