import { task } from 'hardhat/config';
import { HardhatRuntimeEnvironment, TaskArguments } from 'hardhat/types';
import { InvestorDistribution, InvestorDistribution__factory, TeamDistribution, TeamDistribution__factory } from '../typechain-types';

task(`post-deploy-distribution`, `Deploys the InvestorDistribution contract`)
  .addParam(`investor`, `Investor address`)
  .addParam(`team`, `Investor address`)
  .addParam(`chest`, `Chest address`)
  .setAction(
    async (taskArguments: TaskArguments, hre: HardhatRuntimeEnvironment) => {
      const { investor, chest, team } = taskArguments;
      const [deployer] = await hre.ethers.getSigners();

      console.log(
        `ℹ️  Attempting post deploy script...`
      );
      const investorDistFactory: InvestorDistribution__factory =
      (await hre.ethers.getContractFactory(
        "InvestorDistribution"
      )) as InvestorDistribution__factory;
      const investorDistribution: InvestorDistribution = investorDistFactory.attach(investor);

      const teamDistFactory: TeamDistribution__factory =
      (await hre.ethers.getContractFactory(
        "TeamDistribution"
      )) as TeamDistribution__factory;
      const teamDistribution: TeamDistribution = teamDistFactory.attach(team);

      console.log(
        `ℹ️  Attempting to set chest...`
      );
        const setInvestorChestTx = await investorDistribution.connect(deployer).setChest(chest);
        await setInvestorChestTx.wait();
      const setTeamChestTx = await teamDistribution.connect(deployer).setChest(chest);
      await setTeamChestTx.wait();
      
      console.log(
        `ℹ️  Set chest done. Distributing...`
      );
      const tx = await investorDistribution.connect(deployer).distribute(50);
      await tx.wait();
      const tx2 = await investorDistribution.connect(deployer).distribute(37);
      await tx2.wait();
      const tx3 = await teamDistribution.connect(deployer).distribute(15);
      await tx3.wait();
        console.log(
            `✅ Investor and Team Distributions distrubted`
        );
    }
  );
