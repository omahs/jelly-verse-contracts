import { task } from 'hardhat/config';
import { HardhatRuntimeEnvironment, TaskArguments } from 'hardhat/types';
import { Chest__factory } from '../typechain-types';

task(`deploy-chest`, `Deploys the Chest contract`)
    .addParam(`jellyToken`, `The Jelly token address`)
    .addParam(`allocator`, `The allocator address`)
    .addParam(`distributor`, `The distributor address`)
    .addParam(`fee`, `The minting fee`)
    .addParam(`maxBooster`, `The max booster`)
    .addParam(`timeFactor`, `The time factor`)
    .addParam(`owner`, `The multisig owner address`)
    .addParam(`pendingOwner`, `The pending owner address if needed`)
    .setAction(
        async (taskArguments: TaskArguments, hre: HardhatRuntimeEnvironment) => {
            const {
                jellyToken,
                allocator,
                distributor,
                fee,
                maxBooster,
                timeFactor,
                owner,
                pendingOwner,
            } = taskArguments;
            const [deployer] = await hre.ethers.getSigners();

            console.log(
                `ℹ️  Attempting to deploy the Chest smart contract to the ${hre.network.name} blockchain using ${deployer.address} address, by passing the ${jellyToken} as the Jelly token address, ${allocator} as the allocator address, ${distributor} as the distributor address, ${fee_} as the minting fee, ${maxBooster_} as the max booster, ${timeFactor_} as the time factor, ${owner} as the multisig owner address, ${pendingOwner} as the pending owner address if needed...`
            );

            const ChestFactory: Chest__factory = await hre.ethers.getContractFactory(
                'Chest'
            );

            const chest = await ChestFactory.deploy(
                jellyToken,
                allocator,
                distributor,
                fee,
                maxBooster,
                timeFactor,
                owner,
                pendingOwner
            );

            await chest.deployed();

            console.log(`✅ Chest deployed to: ${chest.address}`);

            /*
            // Verify the contract on Etherscan
            console.log(
                `ℹ️  Attempting to verify the Chest smart contract on Etherscan...`
            );

            try {
                await hre.run(`verify:verify`, {
                    address: chest.address,
                    constructorArguments: [
                        jellyToken,
                        fee,
                        boosterThreshold,
                        minimalStakingPower,
                        maxBooster,
                        timeFactor,
                        startTimestamp,
                        cliffDuration,
                        owner,
                        pendingOwner,
                    ],
                });
            } catch (error) {
                console.log(
                    `❌ Failed to verify the Chest smart contract on Etherscan: ${error}`
                );

                console.log(
                    `📝 Try to verify it manually with: npx hardhat verify --network ${hre.network.name} ${chest.address} ${jellyToken} ${fee} ${boosterThreshold} ${minimalStakingPower} ${maxBooster} ${timeFactor} ${startTimestamp} ${cliffDuration} ${owner} ${pendingOwner}`
                );
            }
            */
        }
    );
