import { task } from "hardhat/config";
import { HardhatRuntimeEnvironment, TaskArguments } from "hardhat/types";
import { RewardVesting, RewardVesting__factory } from "../typechain-types";

task(`deploy-reward-vesting`, `Deploys the StakingRewardDistrubtion contract`)
  .addParam(`owner`, `The multisig owner address`)
  .addParam(`pendingowner`, `The pending owner address`)
  .addParam(`stakingContract`, `Staking contract address`)
  .addParam(`liquidityContract`, `Liquidty contract address`)
  .addParam(`token`, `The token address`)
  .setAction(
    async (taskArguments: TaskArguments, hre: HardhatRuntimeEnvironment) => {
      const { owner, pendingowner, token, liquidityContract, stakingContract } =
        taskArguments;
      const [deployer] = await hre.ethers.getSigners();

      console.log(
        `ℹ️  Attempting to deploy the RewardVesting smart contract to the ${hre.network.name} blockchain using ${deployer.address} address, by passing the ${owner} as the multisig owner address, ${pendingowner} as the pending owner address if needed...`
      );

      const RewardVestingFactory: RewardVesting__factory =
        await hre.ethers.getContractFactory("RewardVesting");
      const RewardVesting: RewardVesting = await RewardVestingFactory.deploy(
        owner,
        pendingowner,
        liquidityContract,
        stakingContract,
        token
      );

      await RewardVesting.deployed();

      console.log(`✅ RewardVesting deployed to: ${RewardVesting.address}`);

      console.log(
        `ℹ️  Attempting to verify the RewardVesting smart contract on Etherscan...`
      );

      try {
        await hre.run(`verify:verify`, {
          address: RewardVesting.address,
          constructorArguments: [owner, pendingowner],
        });
      } catch (error) {
        console.log(
          `❌ Failed to verify the RewardVesting smart contract on Etherscan: ${error}`
        );

        console.log(
          `📝 Try to verify it manually with: npx hardhat verify --network ${hre.network.name} ${RewardVesting.address} ${owner} ${pendingowner}`
        );
      }
    }
  );
