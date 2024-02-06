import { Allocator, Allocator__factory } from '../../typechain-types';
import { ethers } from 'hardhat';
import { deployMockJellyNoReverts, deployMockJellyVault } from '../shared/mocks';
import { MockContract } from '@ethereum-waffle/mock-contract';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';

type UnitAlloctorFixtureType = {
	allocator: Allocator;
    jellyToken: MockContract;
    wethToken: MockContract;
    owner: SignerWithAddress;
    pendingOwner: SignerWithAddress;
    vaultMockContract: MockContract;
    nativeToJellyRatio: number;
    poolId: string;
};

export async function unitAllocatorFixture(): Promise<UnitAlloctorFixtureType> {
    const [owner, pendingOwner] = await ethers.getSigners();
    const jellyToken = await deployMockJellyNoReverts(owner);
    const wethToken = await deployMockJellyNoReverts(owner);
    const vaultMockContract = await deployMockJellyVault(owner, jellyToken.address, wethToken.address);
    const nativeToJellyRatio = 1;
    const poolId = "0x034e2d995b39a88ab9a532a9bf0deddac2c576ea0002000000000000000005d1";

    const AllocatorFactory: Allocator__factory = await ethers.getContractFactory("Allocator");
    const allocator: Allocator = await AllocatorFactory.deploy(
        jellyToken.address, 
        wethToken.address,
        nativeToJellyRatio,
        vaultMockContract.address, 
        poolId, 
        owner.address, 
        pendingOwner.address
    );

    return { allocator, jellyToken, wethToken, owner, pendingOwner, vaultMockContract, nativeToJellyRatio, poolId};
}