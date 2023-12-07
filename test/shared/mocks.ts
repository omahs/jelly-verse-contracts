import {
	MockContract,
	deployMockContract,
} from '@ethereum-waffle/mock-contract';
import { BigNumber, Signer } from 'ethers';
import { artifacts, ethers } from 'hardhat';
import { Artifact } from 'hardhat/types';

export async function deployMockJelly(deployer: Signer): Promise<MockContract> {
	const jellyTokenArtifact: Artifact = await artifacts.readArtifact(
		`JellyToken`
	);

	const mockJelly: MockContract = await deployMockContract(
		deployer,
		jellyTokenArtifact.abi
	);

	const premintAmount: number = 3 * 133_000_000;
	await mockJelly.mock.totalSupply.returns(
		ethers.utils.parseEther(premintAmount.toString())
	);
	await mockJelly.mock.cap.returns(ethers.utils.parseEther(`1000000000`));
	await mockJelly.mock.transfer.returns(true);
	await mockJelly.mock.transferFrom.returns(true);
	await mockJelly.mock.mint.returns();

	return mockJelly;
}

export async function deployMockJellyTimelock(deployer: Signer): Promise<MockContract> {
	const jellyTimelockArtifact: Artifact = await artifacts.readArtifact(
		`JellyTimelock`
	);

	const mockJellyTimelock: MockContract = await deployMockContract(
		deployer,
		jellyTimelockArtifact.abi
	);

	await mockJellyTimelock.mock.execute.returns();
	await mockJellyTimelock.mock.executeBatch.returns();

	return mockJellyTimelock;
}

export async function deployMockChest(deployer: Signer): Promise<MockContract> {
	const chestArtifact: Artifact = await artifacts.readArtifact(
		`Chest`
	);

	const chest: MockContract = await deployMockContract(
		deployer,
		chestArtifact.abi
	);

	await chest.mock.getVotingPower.returns(BigNumber.from(1000));
	await chest.mock.totalSupply.returns(BigNumber.from(10));
	await chest.mock.stake.returns();

	return chest;
}

export async function deployMockVestingTeam(
	deployer: Signer
): Promise<MockContract> {
	const vestingTeamArtifact: Artifact = await artifacts.readArtifact(
		`VestingTeam`
	);

	const mockVestingTeam: MockContract = await deployMockContract(
		deployer,
		vestingTeamArtifact.abi
	);

	return mockVestingTeam;
}

export async function deployMockVestingInvestor(
	deployer: Signer
): Promise<MockContract> {
	const vestingInvestorArtifact: Artifact = await artifacts.readArtifact(
		`VestingInvestor`
	);

	const mockVestingInvestor: MockContract = await deployMockContract(
		deployer,
		vestingInvestorArtifact.abi
	);

	return mockVestingInvestor;
}

export async function deployMockAllocator(
	deployer: Signer
): Promise<MockContract> {
	const allocatorArtifact: Artifact = await artifacts.readArtifact(`Allocator`);

	const mockAllocator: MockContract = await deployMockContract(
		deployer,
		allocatorArtifact.abi
	);

	return mockAllocator;
}

export async function deployMockMinter(
	deployer: Signer
): Promise<MockContract> {
	const minterArtifact: Artifact = await artifacts.readArtifact(`Minter`);

	const mockMinter: MockContract = await deployMockContract(
		deployer,
		minterArtifact.abi
	);

	return mockMinter;
}