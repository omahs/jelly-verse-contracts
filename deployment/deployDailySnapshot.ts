import { task } from 'hardhat/config';
import { HardhatRuntimeEnvironment, TaskArguments } from 'hardhat/types';
import { DailySnapshot, DailySnapshot__factory } from '../typechain-types';

task(`deploy-daily-snapshot`, `Deploys the DailySnapshot contract`)
	.addParam(`owner`, `The multisig owner address`)
	.addParam(`pendingOwner`, `The pending owner address`)
	.setAction(
		async (taskArguments: TaskArguments, hre: HardhatRuntimeEnvironment) => {
			const { owner, pendingOwner } = taskArguments;
			const [deployer] = await hre.ethers.getSigners();

			console.log(
				`ℹ️  Attempting to deploy the DailySnapshot smart contract to the ${hre.network.name} blockchain using ${deployer.address} address, by passing the ${owner} as the multisig owner address, ${pendingOwner} as the pending owner address if needed...`
			);

			const DailySnapshotFactory: DailySnapshot__factory =
				await hre.ethers.getContractFactory('DailySnapshot');
			const dailySnapshot: DailySnapshot = await DailySnapshotFactory.deploy(owner, pendingOwner);

			await dailySnapshot.deployed();

			console.log(`✅ DailySnapshot deployed to: ${dailySnapshot.address}`);

			console.log(
				`ℹ️  Attempting to verify the DailySnapshot smart contract on Etherscan...`
			);

			try {
				await hre.run(`verify:verify`, {
					address: dailySnapshot.address,
					constructorArguments: [owner, pendingOwner],
				});
			} catch (error) {
				console.log(
					`❌ Failed to verify the DailySnapshot smart contract on Etherscan: ${error}`
				);

				console.log(
					`📝 Try to verify it manually with: npx hardhat verify --network ${hre.network.name} ${dailySnapshot.address} ${owner} ${pendingOwner}`
				);
			}
		}
	);