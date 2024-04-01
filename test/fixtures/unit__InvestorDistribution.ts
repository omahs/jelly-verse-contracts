import {
  InvestorDistribution,
  InvestorDistribution__factory,
  Chest,
  Chest__factory,
  ERC20Token,
  ERC20Token__factory,
} from "../../typechain-types";
import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

type UnitInvestorDistributionFixtureType = {
  investorDistribution: InvestorDistribution;
  jellyToken: ERC20Token;
  chest: Chest;
  deployer: SignerWithAddress;
  otherAccount: SignerWithAddress;
};

export async function deployInvestorDistributionFixture(): Promise<UnitInvestorDistributionFixtureType> {
  const [deployer, otherAccount] = await ethers.getSigners();

  const ERC20TokenFactory: ERC20Token__factory =
    await ethers.getContractFactory("ERC20Token");
  const jellyToken: ERC20Token = await ERC20TokenFactory.deploy("Jelly", "JLY");

  const InvestorDistributionFactory: InvestorDistribution__factory =
    await ethers.getContractFactory("InvestorDistribution");
  const investorDistribution: InvestorDistribution =
    await InvestorDistributionFactory.deploy(
      jellyToken.address,
      deployer.address,
      otherAccount.address
    );

  const ChestFactory: Chest__factory = await ethers.getContractFactory("Chest");
  const chest: Chest = await ChestFactory.deploy(
    jellyToken.address,
    0,
    deployer.address,
    otherAccount.address
  );

  return { investorDistribution, jellyToken, chest, deployer, otherAccount };
}
