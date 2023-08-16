import { ethers } from "hardhat";

import {
  JellyToken,
  JellyToken__factory,
  Minter,
  Minter__factory,
} from "../../typechain-types";

export async function deployMinter() {
  const MINTER_ROLE = "0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6";

  const inflationRate = 100;
  const inflationPeriod = 10000;

  const [
    owner,
    governance,
    otherAccount,
    beneficiary1,
    beneficiary2,
    vesting,
    vestingJelly,
    allocator
  ] = await ethers.getSigners();

  // Deploy Jelly Token
  const JellyTokenFactory: JellyToken__factory =
    await ethers.getContractFactory("JellyToken");
  const jellyToken: JellyToken = await JellyTokenFactory.deploy(
    vesting.address,
    vestingJelly.address,
    allocator.address
  );

  // Deploy Minter
  const MinterFactory: Minter__factory =
    await ethers.getContractFactory("Minter");
  const minter: Minter = await MinterFactory.deploy(
    jellyToken.target,
    inflationRate,
    inflationPeriod,
    governance.address,
    [beneficiary1.address, beneficiary2.address]
  );

  await jellyToken.connect(owner).grantRole(MINTER_ROLE, minter.target);

  return {
    minter,
    inflationRate,
    inflationPeriod,
    jellyToken,
    owner,
    governance,
    otherAccount,
    beneficiaries: [beneficiary1, beneficiary2]
  };
}
