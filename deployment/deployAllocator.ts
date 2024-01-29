import { task } from 'hardhat/config';
import { HardhatRuntimeEnvironment, TaskArguments } from 'hardhat/types';
import { Allocator__factory } from '../typechain-types';

task(`deploy-allocator`, `Deploys the Allocator contract`)
    .addParam(`jellyToken`, `The Jelly token address`)
    .addParam(`nativeToJellyRatio`, `Ratio of native token to Jelly token`)
    .addParam(`vault`, `The Vault address`)
    .addParam(`poolId`, `Pool ID which will be joined`)
    .addParam(`owner`, `The multisig owner address`)
    .addParam(`pendingOwner`, `The pending owner address if needed`)
    .setAction(
        async (taskArguments: TaskArguments, hre: HardhatRuntimeEnvironment) => {
            const {
                jellyToken,
                nativeToJellyRatio,
                vault,
                poolId,
                owner,
                pendingOwner,
            } = taskArguments;
            const [deployer] = await hre.ethers.getSigners();

            console.log(
                `ℹ️  Attempting to deploy the Allocator smart contract to the ${hre.network.name} blockchain using ${deployer.address} address, by passing the ${jellyToken} as the Jelly token address, ${nativeToJellyRatio} as the ratio of Native Tokens To Jelly, ${vault} as the vault contract address, ${poolId} as the poolID which will be joined, ${owner} as the multisig owner address, ${pendingOwner} as the pending owner address if needed...`
            );

            const AllocatorFactory: Allocator__factory = await hre.ethers.getContractFactory(
                'Allocator'
            );

            const allocator = await AllocatorFactory.deploy(
                jellyToken,
                nativeToJellyRatio,
                vault,
                poolId,
                owner,
                pendingOwner
            );

            await allocator.deployed();

            console.log(`✅ Allocator deployed to: ${allocator.address}`);

            // Verify the contract on Etherscan
            console.log(
                `ℹ️  Attempting to verify the Allocator smart contract on Etherscan...`
            );

            try {
                await hre.run(`verify:verify`, {
                    address: allocator.address,
                    constructorArguments: [
                        jellyToken,
                        nativeToJellyRatio,
                        vault,
                        poolId,
                        owner,
                        pendingOwner,
                    ],
                });
            } catch (error) {
                console.log(
                    `❌ Failed to verify the Allocator smart contract on Etherscan: ${error}`
                );

                console.log(
                    `📝 Try to verify it manually with: npx hardhat verify --network ${hre.network.name} ${allocator.address} ${jellyToken} ${nativeToJellyRatio} ${vault} ${poolId} ${owner} ${pendingOwner}`
                );
            }

        }
    );
