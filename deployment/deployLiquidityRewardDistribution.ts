import { task } from 'hardhat/config';
import { HardhatRuntimeEnvironment, TaskArguments } from 'hardhat/types';
import { LiquidityRewardDistrubtion, LiquidityRewardDistrubtion__factory } from '../typechain-types';

task(`deploy-liqidty-reward-distribution`, `Deploys the LiquidityRewardDistrubtion contract`)
	.addParam(`owner`, `The multisig owner address`)
	.addParam(`pendingowner`, `The pending owner address`)
	.addParam(`token`, `The token address`)
	.setAction(
		async (taskArguments: TaskArguments, hre: HardhatRuntimeEnvironment) => {
			const { owner, pendingowner,token } = taskArguments;
			const [deployer] = await hre.ethers.getSigners();

			console.log(
				`ℹ️  Attempting to deploy the LiquidityRewardDistrubtion smart contract to the ${hre.network.name} blockchain using ${deployer.address} address, with ${token} as the token address, by passing the ${owner} as the multisig owner address, ${pendingowner} as the pending owner address if needed...`
			);

			const LiquidityRewardDistrubtionFactory: LiquidityRewardDistrubtion__factory =
				await hre.ethers.getContractFactory('LiquidityRewardDistrubtion');
			const LiquidityRewardDistrubtion: LiquidityRewardDistrubtion = await LiquidityRewardDistrubtionFactory.deploy(token, owner, pendingowner);

			await LiquidityRewardDistrubtion.deployed();

			console.log(`✅ LiquidityRewardDistrubtion deployed to: ${LiquidityRewardDistrubtion.address}`);

			console.log(
				`ℹ️  Attempting to verify the LiquidityRewardDistrubtion smart contract on Etherscan...`
			);

			try {
				await hre.run(`verify:verify`, {
					address: LiquidityRewardDistrubtion.address,
					constructorArguments: [token, owner, pendingowner],
				});
			} catch (error) {
				console.log(
					`❌ Failed to verify the LiquidityRewardDistrubtion smart contract on Etherscan: ${error}`
				);

				console.log(
					`📝 Try to verify it manually with: npx hardhat verify --network ${hre.network.name} ${LiquidityRewardDistrubtion.address} ${token} ${owner} ${pendingowner}`
				);
			}
		}
	);
	