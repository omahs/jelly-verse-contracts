import {
	MockContract,
	deployMockContract,
} from '@ethereum-waffle/mock-contract';
import { BigNumber, Signer, constants, utils } from 'ethers';
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
	await mockJelly.mock.approve.revertsWithReason('Mock test revert');

	return mockJelly;
}

export async function deployMockStakingRewardContract(deployer: Signer): Promise<MockContract> {
	const lpRewardContractArtifact: Artifact = await artifacts.readArtifact(
		`StakingRewardDistrubtion`
	);

	const mockLpRewardContract: MockContract = await deployMockContract(
		deployer,
		lpRewardContractArtifact.abi
	);

	await mockLpRewardContract.mock.deposit.returns();

	return mockLpRewardContract;
}

export async function deployMockJellyNoReverts(deployer: Signer): Promise<MockContract> {
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
	await mockJelly.mock.approve.returns(true);

	return mockJelly;
}

export async function deployMockJellyTimelock(
	deployer: Signer, 
	jellyToken: MockContract, 
	aliceAddress: string, 
	operationDone: boolean, 
	operationPending: boolean
	): Promise<MockContract> {
	const jellyTimelockArtifact: Artifact = await artifacts.readArtifact(
		`JellyTimelock`
	);

	const mockJellyTimelock: MockContract = await deployMockContract(
		deployer,
		jellyTimelockArtifact.abi
	);
	const amountToMint = utils.parseEther('100');
	const targets = [jellyToken.address];
	const values = [amountToMint];
	const mintFunctionCalldata =
	jellyToken.interface.encodeFunctionData('mint', [
		aliceAddress,
		amountToMint,
	]); 
	const payloads = [
		mintFunctionCalldata
	];
	const predecessor = constants.HashZero; // Replace with actual bytes32 value
	const proposalDescription = 'Test Proposal #1: Mint 100 JLY tokens to Alice';
	const descriptionBytes = utils.toUtf8Bytes(proposalDescription);
	const hashedDescription = utils.keccak256(descriptionBytes);
	const encodedData = ethers.utils.defaultAbiCoder.encode(
		["address[]", "uint256[]", "bytes[]", "bytes32", "bytes32"],
		[targets, values, payloads, predecessor, hashedDescription]
	  );
	const hash = ethers.utils.keccak256(encodedData); // hash Operation Batch return value

	await mockJellyTimelock.mock.execute.returns();
	await mockJellyTimelock.mock.scheduleBatch.returns();
	await mockJellyTimelock.mock.getMinDelay.returns(BigNumber.from(7200)); // 1 day
	await mockJellyTimelock.mock.hashOperationBatch.returns(hash);
	await mockJellyTimelock.mock.executeBatch.returns();
	await mockJellyTimelock.mock.isOperationDone.returns(operationDone);
	await mockJellyTimelock.mock.isOperationPending.returns(operationPending);

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