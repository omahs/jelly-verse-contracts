import { PoolParty, PoolParty__factory } from '../../typechain-types';
import { ethers } from 'hardhat';
import { deployMockJellyNoReverts, deployMockJellyVault } from '../shared/mocks';
import { MockContract } from '@ethereum-waffle/mock-contract';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';

type UnitAlloctorFixtureType = {
	poolParty: PoolParty;
    jellyToken: MockContract;
    usdToken: MockContract;
    owner: SignerWithAddress;
    pendingOwner: SignerWithAddress;
    vaultMockContract: MockContract;
    usdToJellyRatio: number;
    poolId: string;
};

export async function unitPoolPartyFixture(): Promise<UnitAlloctorFixtureType> {
    const [owner, pendingOwner] = await ethers.getSigners();
    const jellyToken = await deployMockJellyNoReverts(owner);
    const usdToken = await deployMockJellyNoReverts(owner);
    const vaultMockContract = await deployMockJellyVault(owner, jellyToken.address, usdToken.address);
    const usdToJellyRatio = 25;
    const poolId = "0x034e2d995b39a88ab9a532a9bf0deddac2c576ea0002000000000000000005d1";

    const PoolPartyFactory: PoolParty__factory = await ethers.getContractFactory("PoolParty");
    const poolParty: PoolParty = await PoolPartyFactory.deploy(
        jellyToken.address, 
        usdToken.address,
        usdToJellyRatio,
        vaultMockContract.address, 
        poolId, 
        owner.address, 
        pendingOwner.address
    );

    return { poolParty, jellyToken, usdToken: usdToken, owner, pendingOwner, vaultMockContract, usdToJellyRatio, poolId};
}