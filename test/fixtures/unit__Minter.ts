import { Minter, Minter__factory } from '../../typechain-types';
import { ethers } from 'hardhat';
import { deployMockJellyNoReverts, deployMockStakingRewardContract } from '../shared/mocks';
import { MockContract } from '@ethereum-waffle/mock-contract';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';

type UnitMinterFixtureType = {
	minter: Minter;
    jellyToken: MockContract;
    deployer: SignerWithAddress;
    otherAccount: SignerWithAddress;
    lpRewardsContract: SignerWithAddress;
    stakingRewardsContract: MockContract;
};

export async function unitMinterFixture(): Promise<UnitMinterFixtureType> {
    const [deployer, otherAccount, lpRewardsContract] = await ethers.getSigners();
    const jellyToken = await deployMockJellyNoReverts(deployer);
    const stakingRewardsContract = await deployMockStakingRewardContract(deployer);

    const MinterFactory: Minter__factory = await ethers.getContractFactory("Minter");
    const minter: Minter = await MinterFactory.deploy(
        jellyToken.address, 
        lpRewardsContract.address, 
        stakingRewardsContract.address, 
        deployer.address, 
        otherAccount.address
    );

    return { minter, jellyToken, deployer, otherAccount, lpRewardsContract, stakingRewardsContract };
}