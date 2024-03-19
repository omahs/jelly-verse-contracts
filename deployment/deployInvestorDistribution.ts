import { task } from 'hardhat/config';
import { HardhatRuntimeEnvironment, TaskArguments } from 'hardhat/types';
import { InvestorDistribution, InvestorDistribution__factory } from '../typechain-types';

task(`deploy-investor-distribution`, `Deploys the InvestorDistribution contract`)
  .addParam(`owner`, `The multisig owner address`)
  .addParam(`pendingOwner`, `The pending owner address`)
  .addParam(`jellyToken`, `The jelly token address`)
  .setAction(
    async (taskArguments: TaskArguments, hre: HardhatRuntimeEnvironment) => {
      const { owner, pendingOwner, jellyToken } = taskArguments;
      const [deployer] = await hre.ethers.getSigners();

      console.log(
        `ℹ️  Attempting to deploy the InvestorDistribution smart contract to the ${hre.network.name} blockchain using ${deployer.address} address, with ${jellyToken} as the jelly token address, by passing the ${owner} as the multisig owner address, ${pendingOwner} as the pending owner address if needed...`
      );

      const InvestorDistributionFactory: InvestorDistribution__factory =
        await hre.ethers.getContractFactory('InvestorDistribution');
      const InvestorDistribution: InvestorDistribution = await InvestorDistributionFactory.deploy(jellyToken, owner, pendingOwner);

      await InvestorDistribution.deployed();

      console.log(`✅ InvestorDistribution deployed to: ${InvestorDistribution.address}`);

      console.log(
        `ℹ️  Attempting to verify the InvestorDistribution smart contract on Etherscan...`
      );

      try {
        await hre.run(`verify:verify`, {
          address: InvestorDistribution.address,
          constructorArguments: [jellyToken, owner, pendingOwner],
        });
      } catch (error) {
        console.log(
          `❌ Failed to verify the InvestorDistribution smart contract on Etherscan: ${error}`
        );

        console.log(
          `📝 Try to verify it manually with: npx hardhat verify --network ${hre.network.name} ${InvestorDistribution.address} ${jellyToken} ${owner} ${pendingOwner}`
        );
      }
    }
  );