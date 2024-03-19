import { task } from 'hardhat/config';
import { HardhatRuntimeEnvironment, TaskArguments } from 'hardhat/types';
import { Minter, Minter__factory } from '../typechain-types';

task(`deploy-minter`, `Deploys the Minter contract`)
	.addParam(`jellyToken`, `The multisig owner address`)
	.addParam(`stakingRewardsContract`, `The Staking Rewards Contract address`)
	.addParam(`owner`, `The owner address`)
	.addParam(`pendingOwner`, `The pending owner address`)
	.setAction(
		async (taskArguments: TaskArguments, hre: HardhatRuntimeEnvironment) => {
			const { jellyToken,  stakingRewardsContract, owner, pendingOwner } = taskArguments;
			const [deployer] = await hre.ethers.getSigners();

			console.log(
				`ℹ️  Attempting to deploy the Minter smart contract to the ${hre.network.name} blockchain using ${deployer.address} address, by passing\n ${jellyToken} as the jelly token address,\n ${stakingRewardsContract} as the Staking Rewards Contract address,\n ${owner} as the owner address,\n ${pendingOwner} as the pending owner address if needed...`
			);

			const minterFactory: Minter__factory =
				await hre.ethers.getContractFactory('Minter');
			const minter: Minter = await minterFactory.deploy(
				jellyToken,
				stakingRewardsContract,
				owner,
				pendingOwner
			);

			await minter.deployed();

			console.log(`✅ Minter deployed to: ${minter.address}`);

			console.log(
				`ℹ️  Attempting to verify the Minter smart contract on Etherscan...`
			);

			try {
				await hre.run(`verify:verify`, {
					address: minter.address,
					constructorArguments: [
						jellyToken,
						
						stakingRewardsContract,
						owner,
						pendingOwner
					],
				});
			} catch (error) {
				console.log(
					`❌ Failed to verify the minter smart contract on Etherscan: ${error}`
				);

				console.log(
					`📝 Try to verify it manually with: npx hardhat verify --network ${hre.network.name} ${minter.address} ${jellyToken} ${stakingRewardsContract} ${owner} ${pendingOwner}`
				);
			}
		}
	);