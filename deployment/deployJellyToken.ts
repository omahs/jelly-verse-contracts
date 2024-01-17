import {
	JellyTokenDeployer__factory,
	JellyTokenDeployer
} from '../typechain-types';
import { task } from 'hardhat/config';
import { HardhatRuntimeEnvironment, TaskArguments } from 'hardhat/types';

task(`deploy-jelly-token`, `Deploys the Jelly Token contract`)
	.addParam(`admin`, `The Jelly Governace contract address (Timelock)`)
	.setAction(
		async (taskArguments: TaskArguments, hre: HardhatRuntimeEnvironment) => {
			const {admin} = taskArguments;
			const [deployer] = await hre.ethers.getSigners();

			console.log(
				`ℹ️  Attempting to deploy the Jelly Token smart contract to the ${hre.network.name} blockchain using ${deployer.address} address, by passing the ${admin} as the Jelly Governace contract address (Timelock)`
			);

			const jellyTokenDeployerFactory: JellyTokenDeployer__factory = 
				await hre.ethers.getContractFactory('JellyTokenDeployer') as JellyTokenDeployer__factory;
		
			const jellyTokenDeployer: JellyTokenDeployer =
				await jellyTokenDeployerFactory.connect(deployer).deploy();
		
			await jellyTokenDeployer.deployed();
		
			const salt = hre.ethers.utils.keccak256('0x01');
		
			const jellyTokenAddress =
				await jellyTokenDeployer.callStatic.deployJellyToken(
					salt,
					admin
				);
		
			const deploymentTx = await jellyTokenDeployer
				.connect(deployer)
				.deployJellyToken(
					salt,
					admin
				);
		
			await deploymentTx.wait();
		
			console.log('✅ JellyToken deployed to:', jellyTokenAddress);

			console.log(
				`ℹ️  Attempting to verify the Jelly Token smart contracts on Etherscan...`
			);

			try {
				await hre.run('verify:verify', {
					address: jellyTokenDeployer.address,
					constructorArguments: [],
				});

				await hre.run('verify:verify', {
					address: jellyTokenAddress,
					constructorArguments: [
						admin
					],
				});
			} catch (error) {
				console.log(
					`❌ Failed to verify the Jelly Token smart contracts on Etherscan: ${error}`
				);

				console.log(
					`📝 Try to verify it manually with:\n
					 npx hardhat verify --network ${hre.network.name} ${jellyTokenDeployer.address} &&
					 npx hardhat verify --network ${hre.network.name} ${jellyTokenAddress} ${admin}`
				);
			}
		}
	);