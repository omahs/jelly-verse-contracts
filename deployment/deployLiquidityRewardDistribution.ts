import { task } from 'hardhat/config';
import { HardhatRuntimeEnvironment, TaskArguments } from 'hardhat/types';
import { LiquidityRewardDistribution, LiquidityRewardDistribution__factory } from '../typechain-types';


task(`deploy-liquidity-reward-distribution`, `Deploys the LiquidityRewardDistributioncontract`)
	.addParam(`owner`, `The multisig owner address`)
	.addParam(`pendingowner`, `The pending owner address`)
	.addParam(`token`, `The token address`)
	.setAction(
		async (taskArguments: TaskArguments, hre: HardhatRuntimeEnvironment) => {
			const { owner, pendingowner,token } = taskArguments;
			const [deployer] = await hre.ethers.getSigners();

			console.log(
				`ℹ️  Attempting to deploy the LiquidityRewardDistributionsmart contract to the ${hre.network.name} blockchain using ${deployer.address} address, with ${token} as the token address, by passing the ${owner} as the multisig owner address, ${pendingowner} as the pending owner address if needed...`
			);

			const LiquidityRewardDistributionFactory: LiquidityRewardDistribution__factory =
				await hre.ethers.getContractFactory('LiquidityRewardDistribution');
			const LiquidityRewardDistribution: LiquidityRewardDistribution= await LiquidityRewardDistributionFactory.deploy(token, owner, pendingowner);

			await LiquidityRewardDistribution.deployed();

			console.log(`✅ LiquidityRewardDistributiondeployed to: ${LiquidityRewardDistribution.address}`);

			console.log(
				`ℹ️  Attempting to verify the LiquidityRewardDistributionsmart contract on Etherscan...`
			);

			try {
				await hre.run(`verify:verify`, {
					address: LiquidityRewardDistribution.address,
					constructorArguments: [token, owner, pendingowner],
				});
			} catch (error) {
				console.log(
					`❌ Failed to verify the LiquidityRewardDistributionsmart contract on Etherscan: ${error}`
				);

				console.log(
					`📝 Try to verify it manually with: npx hardhat verify --network ${hre.network.name} ${LiquidityRewardDistribution.address} ${token} ${owner} ${pendingowner}`
				);
			}
		}
	);
	