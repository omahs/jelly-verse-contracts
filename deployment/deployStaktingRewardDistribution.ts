import { task } from "hardhat/config";
import { HardhatRuntimeEnvironment, TaskArguments } from "hardhat/types";
import {
  StakingRewardDistribution,
  StakingRewardDistribution__factory,
} from "../typechain-types";

task(
  `deploy-staking-reward-distribution`,
  `Deploys the StakingRewardDistribution contract`
)
  .addParam(`owner`, `The multisig owner address`)
  .addParam(`pendingowner`, `The pending owner address`)
  .addParam(`token`, `The token address`)
  .setAction(
    async (taskArguments: TaskArguments, hre: HardhatRuntimeEnvironment) => {
      const { owner, pendingowner, token } = taskArguments;
      const [deployer] = await hre.ethers.getSigners();

      console.log(
        `ℹ️  Attempting to deploy the StakingRewardDistribution smart contract to the ${hre.network.name} blockchain using ${deployer.address} address, by passing the ${owner} as the multisig owner address,  with ${token} as the token address, ${pendingowner} as the pending owner address if needed...`
      );

      const StakingRewardDistributionFactory: StakingRewardDistribution__factory =
        await hre.ethers.getContractFactory("StakingRewardDistribution");
      const StakingRewardDistribution: StakingRewardDistribution =
        await StakingRewardDistributionFactory.deploy(
          token,
          owner,
          pendingowner
        );

      await StakingRewardDistribution.deployed();

      console.log(
        `✅ StakingRewardDistribution deployed to: ${StakingRewardDistribution.address}`
      );

      console.log(
        `ℹ️  Attempting to verify the StakingRewardDistribution smart contract on Etherscan...`
      );

      try {
        await hre.run(`verify:verify`, {
          address: StakingRewardDistribution.address,
          constructorArguments: [token, owner, pendingowner],
        });
      } catch (error) {
        console.log(
          `❌ Failed to verify the StakingRewardDistribution smart contract on Etherscan: ${error}`
        );

        console.log(
          `📝 Try to verify it manually with: npx hardhat verify --network ${hre.network.name} ${StakingRewardDistribution.address} ${token} ${owner} ${pendingowner}`
        );
      }
    }
  );
