import { BigNumber } from "ethers";
import { ethers } from "hardhat";
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { DailySnapshot } from "../../typechain-types";

type UnitDailySnapshotFixtureType = {
    dailySnapshot: DailySnapshot;
	deployer: SignerWithAddress;
	user: SignerWithAddress;
};

export async function unitDailySnapshotFixture(): Promise<UnitDailySnapshotFixtureType>{
    const [deployer, user] = await ethers.getSigners();

    const DailySnapshotFactory = await ethers.getContractFactory('DailySnapshot');
    const dailySnapshot = await DailySnapshotFactory.deploy(
        deployer.address,
        user.address
    );

    return { dailySnapshot, deployer, user };
  }