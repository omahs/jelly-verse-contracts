import { task } from 'hardhat/config';
import { HardhatRuntimeEnvironment, TaskArguments } from 'hardhat/types';
import { OfficialPoolsRegister, OfficialPoolsRegister__factory } from '../typechain-types';

task(`deploy-official-pools-register`, `Deploys the OfficialPoolsRegister contract`)
	.addParam(`owner`, `The multisig owner address`)
	.addParam(`pendingOwner`, `The pending owner address`)
	.setAction(
		async (taskArguments: TaskArguments, hre: HardhatRuntimeEnvironment) => {
			const { owner, pendingOwner } = taskArguments;
			const [deployer] = await hre.ethers.getSigners();

			console.log(
				`ℹ️  Attempting to deploy the OfficialPoolsRegister smart contract to the ${hre.network.name} blockchain using ${deployer.address} address, by passing the ${owner} as the multisig owner address, ${pendingOwner} as the pending owner address if needed...`
			);

			const OfficialPoolsRegisterFactory: OfficialPoolsRegister__factory =
				await hre.ethers.getContractFactory('OfficialPoolsRegister');
			const officialPoolsRegister: OfficialPoolsRegister = await OfficialPoolsRegisterFactory.deploy(owner, pendingOwner);

			await officialPoolsRegister.deployed();

			console.log(`✅ OfficialPoolsRegister deployed to: ${officialPoolsRegister.address}`);

			console.log(
				`ℹ️  Attempting to verify the OfficialPoolsRegister smart contract on Etherscan...`
			);

			try {
				await hre.run(`verify:verify`, {
					address: officialPoolsRegister.address,
					constructorArguments: [owner, pendingOwner],
				});
			} catch (error) {
				console.log(
					`❌ Failed to verify the OfficialPoolsRegister smart contract on Etherscan: ${error}`
				);

				console.log(
					`📝 Try to verify it manually with: npx hardhat verify --network ${hre.network.name} ${officialPoolsRegister.address} ${owner} ${pendingOwner}`
				);
			}
		}
	);