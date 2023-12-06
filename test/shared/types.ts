import { MockContract } from '@ethereum-waffle/mock-contract';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { BigNumber } from 'ethers';
// import { JellyToken } from '../../typechain-types';

declare module 'mocha' {
	export interface Context {
		// jellyToken: JellyToken;
		// vesting: Vesting;
		signers: Signers;
		mocks: Mocks;
		params: Params;
	}
}

export interface Signers {
	deployer: SignerWithAddress;
	ownerMultiSig: SignerWithAddress;
	pendingOwner: SignerWithAddress;
	beneficiary: SignerWithAddress;
	revoker: SignerWithAddress;
	alice: SignerWithAddress;
	bob: SignerWithAddress;
	timelockAdmin: SignerWithAddress;
	timelockProposer: SignerWithAddress;
	timelockExecutor: SignerWithAddress;
}

export interface Mocks {
	mockJellyToken: MockContract;
	mockChest: MockContract;
	mockAllocator: MockContract;
	mockVestingTeam: MockContract;
	mockJellyTimelock: MockContract;
	mockVestingInvestor: MockContract;
	mockMinterContract: MockContract;
}


export interface Params {
	votingDelay: BigNumber;
	votingPeriod: BigNumber;
	proposalThreshold: BigNumber;
	quorum: BigNumber;
	minTimelockDelay: BigNumber;
	proposers: string[];
	executors: string[];
}