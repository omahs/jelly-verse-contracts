import { task } from 'hardhat/config';
import { HardhatRuntimeEnvironment, TaskArguments } from 'hardhat/types';
import { TeamDistribution, TeamDistribution__factory } from '../typechain-types';

task(`deploy-liqidty-reward-distribution`, `Deploys the TeamDistribution contract`)
	.addParam(`owner`, `The multisig owner address`)
	.addParam(`pendingowner`, `The pending owner address`)
	.addParam(`token`, `The token address`)
	.setAction(
		async (taskArguments: TaskArguments, hre: HardhatRuntimeEnvironment) => {
			const { owner, pendingowner,token } = taskArguments;
			const [deployer] = await hre.ethers.getSigners();

			console.log(
				`ℹ️  Attempting to deploy the TeamDistribution smart contract to the ${hre.network.name} blockchain using ${deployer.address} address, with ${token} as the token address, by passing the ${owner} as the multisig owner address, ${pendingowner} as the pending owner address if needed...`
			);

			const TeamDistributionFactory: TeamDistribution__factory =
				await hre.ethers.getContractFactory('TeamDistribution');
			const TeamDistribution: TeamDistribution = await TeamDistributionFactory.deploy(token, owner, pendingowner);

			await TeamDistribution.deployed();

			console.log(`✅ TeamDistribution deployed to: ${TeamDistribution.address}`);

			console.log(
				`ℹ️  Attempting to verify the TeamDistribution smart contract on Etherscan...`
			);

			try {
				await hre.run(`verify:verify`, {
					address: TeamDistribution.address,
					constructorArguments: [token, owner, pendingowner],
				});
			} catch (error) {
				console.log(
					`❌ Failed to verify the TeamDistribution smart contract on Etherscan: ${error}`
				);

				console.log(
					`📝 Try to verify it manually with: npx hardhat verify --network ${hre.network.name} ${TeamDistribution.address} ${token} ${owner} ${pendingowner}`
				);
			}
		}
	);
	