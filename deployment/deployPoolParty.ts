import { task } from 'hardhat/config';
import { HardhatRuntimeEnvironment, TaskArguments } from 'hardhat/types';
import { PoolParty__factory } from '../typechain-types';

task(`deploy-pool-party`, `Deploys the Pool contract`)
    .addParam(`jellyToken`, `The Jelly token address`)
    .addParam(`usdToken`, `The WETH token address`)
    .addParam(`usdToJellyRatio`, `Ratio of usd token to Jelly token`)
    .addParam(`vault`, `The Vault address`)
    .addParam(`poolId`, `Pool ID which will be joined`)
    .addParam(`owner`, `The multisig owner address`)
    .addParam(`pendingOwner`, `The pending owner address if needed`)
    .setAction(
        async (taskArguments: TaskArguments, hre: HardhatRuntimeEnvironment) => {
            const {
                jellyToken,
                usdToken,
                usdToJellyRatio,
                vault,
                poolId,
                owner,
                pendingOwner,
            } = taskArguments;
            const [deployer] = await hre.ethers.getSigners();

            console.log(
                `ℹ️  Attempting to deploy the PoolParty smart contract to the ${hre.network.name} blockchain using ${deployer.address} address, by passing the ${jellyToken} as the Jelly token address, the ${usdToken} as the USD pegged token address, ${usdToJellyRatio} as the ratio of Usd Tokens To Jelly, ${vault} as the vault contract address, ${poolId} as the poolID which will be joined, ${owner} as the multisig owner address, ${pendingOwner} as the pending owner address if needed...`
            );

            const PoolPartyFactory: PoolParty__factory = await hre.ethers.getContractFactory(
                'PoolParty'
            );

            const poolParty = await PoolPartyFactory.deploy(
                jellyToken,
                usdToken,
                usdToJellyRatio,
                vault,
                poolId,
                owner,
                pendingOwner
            );

            await poolParty.deployed();

            console.log(`✅ PoolParty deployed to: ${poolParty.address}`);

            // Verify the contract on Etherscan
            console.log(
                `ℹ️  Attempting to verify the PoolParty smart contract on Etherscan...`
            );

            try {
                await hre.run(`verify:verify`, {
                    address: poolParty.address,
                    constructorArguments: [
                        jellyToken,
                        usdToken,
                        usdToJellyRatio,
                        vault,
                        poolId,
                        owner,
                        pendingOwner,
                    ],
                });
            } catch (error) {
                console.log(
                    `❌ Failed to verify the PoolParty smart contract on Etherscan: ${error}`
                );

                console.log(
                    `📝 Try to verify it manually with: npx hardhat verify --network ${hre.network.name} ${poolParty.address} ${jellyToken} ${usdToken} ${usdToJellyRatio} ${vault} ${poolId} ${owner} ${pendingOwner}`
                );
            }

        }
    );
