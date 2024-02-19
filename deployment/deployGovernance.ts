import { BigNumber } from 'ethers';
import {
	JellyTimelock__factory,
	JellyTimelock,
	JellyGovernor__factory,
	JellyGovernor,
} from '../typechain-types';
import { task } from 'hardhat/config';
import { HardhatRuntimeEnvironment, TaskArguments } from 'hardhat/types';

task(`deploy-jelly-governance`, `Deploys the Jelly Governance contracts`)
	.addParam(`chestAddress`, `The chest contract address`)
	.addParam(`timelockAdminAddress`, `The timelock admin address`)
	.setAction(
		async (taskArguments: TaskArguments, hre: HardhatRuntimeEnvironment) => {
			const { chestAddress, timelockAdminAddress } = taskArguments;
			const [deployer] = await hre.ethers.getSigners();

			console.log(
				`ℹ️  Attempting to deploy the Jelly Governance smart contracts to the ${hre.network.name} blockchain using ${deployer.address} address, by passing the ${chestAddress} as the chest contract address, ${timelockAdminAddress} as the timelock admin address if needed...`
			);

			const timelockProposerAddress = `0x0000000000000000000000000000000000000000`; // everyone can propose
			const timelockExecutorAddress = `0x0000000000000000000000000000000000000000`; // everyone can execute

			const ONE_DAYS_IN_SOLIDITY = BigNumber.from('86400');
			const minTimelockDelay = ONE_DAYS_IN_SOLIDITY;

			const proposers = [timelockProposerAddress];
			const executors = [timelockExecutorAddress];

			const jellyTimelockFactory: JellyTimelock__factory =
				await hre.ethers.getContractFactory('JellyTimelock');
			const jellyTimelock: JellyTimelock = await jellyTimelockFactory.deploy(
				minTimelockDelay,
				proposers,
				executors,
				timelockAdminAddress
			);
			await jellyTimelock.deployed();

			console.log(`✅ JellyTimelock deployed to: ${jellyTimelock.address}`);

			const jellyGovernorFactory: JellyGovernor__factory =
				await hre.ethers.getContractFactory('JellyGovernor') as JellyGovernor__factory;

			const jellyGovernance: JellyGovernor = await jellyGovernorFactory.deploy(
				chestAddress,
				jellyTimelock.address
			);
			await jellyGovernance.deployed();

			console.log(`✅ JellyGovernor deployed to: ${jellyGovernance.address}`);

			console.log(
				`ℹ️  Attempting to verify the Jelly Governance smart contracts on Etherscan...`
			);

			try {
				await hre.run('verify:verify', {
					address: jellyTimelock.address,
					constructorArguments: [
						minTimelockDelay,
						proposers,
						executors,
						timelockAdminAddress,
					],
				});

				await hre.run('verify:verify', {
					address: jellyGovernance.address,
					constructorArguments: [
						chestAddress,
						jellyTimelock.address,
					],
				});
			} catch (error) {
				console.log(
					`❌ Failed to verify the Jelly Governance smart contracts on Etherscan: ${error}`
				);

				console.log(
					`📝 Try to verify it manually with:\n
					 npx hardhat verify --network ${hre.network.name} ${jellyTimelock.address} ${minTimelockDelay} ${proposers} ${executors} ${timelockAdminAddress} &&
					 npx hardhat verify --network ${hre.network.name} ${jellyGovernance.address} ${chestAddress} ${jellyTimelock.address}`
				);
			}
		}
	);
