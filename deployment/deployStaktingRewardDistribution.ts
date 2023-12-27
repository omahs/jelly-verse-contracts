import { task } from 'hardhat/config';
import { HardhatRuntimeEnvironment, TaskArguments } from 'hardhat/types';
import { StakingRewardDistrubtion, StakingRewardDistrubtion__factory } from '../typechain-types';

task(`deploy-staking-reward-distribution`, `Deploys the StakingRewardDistrubtion contract`)
	.addParam(`owner`, `The multisig owner address`)
	.addParam(`pendingowner`, `The pending owner address`)
	.setAction(
		async (taskArguments: TaskArguments, hre: HardhatRuntimeEnvironment) => {
			const { owner, pendingowner} = taskArguments;
			const [deployer] = await hre.ethers.getSigners();

			console.log(
				`ℹ️  Attempting to deploy the StakingRewardDistrubtion smart contract to the ${hre.network.name} blockchain using ${deployer.address} address, by passing the ${owner} as the multisig owner address, ${pendingowner} as the pending owner address if needed...`
			);

			const StakingRewardDistrubtionFactory: StakingRewardDistrubtion__factory =
				await hre.ethers.getContractFactory('StakingRewardDistrubtion');
			const StakingRewardDistrubtion: StakingRewardDistrubtion = await StakingRewardDistrubtionFactory.deploy( owner, pendingowner);

			await StakingRewardDistrubtion.deployed();

			console.log(`✅ StakingRewardDistrubtion deployed to: ${StakingRewardDistrubtion.address}`);

			console.log(
				`ℹ️  Attempting to verify the StakingRewardDistrubtion smart contract on Etherscan...`
			);

			try {
				await hre.run(`verify:verify`, {
					address: StakingRewardDistrubtion.address,
					constructorArguments: [ owner, pendingowner],
				});
			} catch (error) {
				console.log(
					`❌ Failed to verify the StakingRewardDistrubtion smart contract on Etherscan: ${error}`
				);

				console.log(
					`📝 Try to verify it manually with: npx hardhat verify --network ${hre.network.name} ${StakingRewardDistrubtion.address} ${owner} ${pendingowner}`
				);
			}
		}
	);
	