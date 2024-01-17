import { JellyToken, JellyTokenDeployer, JellyTokenDeployer__factory, JellyToken__factory } from '../../typechain-types';
import { getSigners } from '../shared/utils';
import { ethers } from 'hardhat';
import { assert } from 'chai';

type UnitJellyTokenFixtureType = {
	jellyToken: JellyToken;
};

export async function unitJellyTokenFixture(): Promise<UnitJellyTokenFixtureType> {
	const { deployer } = await getSigners();

    const jellyTokenDeployerFactory: JellyTokenDeployer__factory = 
    await ethers.getContractFactory('JellyTokenDeployer') as JellyTokenDeployer__factory;

    const jellyTokenDeployer: JellyTokenDeployer =
        await jellyTokenDeployerFactory.connect(deployer).deploy();

    await jellyTokenDeployer.deployed();

    const salt = ethers.utils.keccak256('0x01');

    const jellyTokenAddress =
        await jellyTokenDeployer.callStatic.deployJellyToken(
            salt,
            deployer.address
        );

    const deploymentTx = await jellyTokenDeployer
        .connect(deployer)
        .deployJellyToken(
            salt,
            deployer.address
        );

    await deploymentTx.wait();
	const computedCreate2Address = await jellyTokenDeployer.computeAddress(
		salt,
        deployer.address
	);

	assert.equal(jellyTokenAddress, computedCreate2Address);

	const jellyToken: JellyToken = JellyToken__factory.connect(
		jellyTokenAddress,
		deployer
	);
	return {
		jellyToken
	};
}
