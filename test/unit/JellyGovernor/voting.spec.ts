import { assert, expect } from 'chai';
import { utils, constants, BigNumber } from 'ethers';
import {
	time,
	getStorageAt,
	setStorageAt,
	mine,
} from '@nomicfoundation/hardhat-network-helpers';
import { network } from 'hardhat';

export function shouldVoteOnProposals(): void {
	describe('#castVote: should always fail', async function () {
		const amountToMint = utils.parseEther('100');
		const proposalDescription = 'Test Proposal #1: Mint 100 JLY tokens to Alice';
		let mintFunctionCalldata: string;
		let proposalId: BigNumber;

		beforeEach(async function () {
			mintFunctionCalldata =
				this.mocks.mockJellyToken.interface.encodeFunctionData('mint', [
					this.signers.alice.address,
					amountToMint,
				]);

			proposalId = await this.jellyGovernor.callStatic.propose(
				[this.mocks.mockJellyToken.address],
				[amountToMint],
				[mintFunctionCalldata],
				proposalDescription
			);

			await this.jellyGovernor.propose(
				[this.mocks.mockJellyToken.address],
				[amountToMint],
				[mintFunctionCalldata],
				proposalDescription
			);
		});

		describe('failure', async function () {
			it('should revert if voting didn\'t start', async function () {
				await expect(
					this.jellyGovernor.castVote(proposalId, 0)
				).to.be.revertedWith('Governor: vote not currently active');
			});

			it('should revert because invalid proposal id', async function () {
				await mine(this.params.votingDelay);
				await expect(
					this.jellyGovernor.castVote(proposalId.add(1000), 0)
				).to.be.revertedWith('Governor: unknown proposal id');
			});

			it('should revert always because no params (chestIds) have been passed', async function () {
				await mine(this.params.votingDelay);
				await expect(
					this.jellyGovernor.castVote(proposalId, 0)
				).to.be.revertedWith('JellyGovernor: no params provided in voting weight query');
			});
		});

	});

	describe('#castVoteBySig: should always fail', async function () {
		const amountToMint = utils.parseEther('100');
		const proposalDescription = 'Test Proposal #1: Mint 100 JLY tokens to Alice';
		let mintFunctionCalldata: string;
		let proposalId: BigNumber;
		let v: number;
		let r: string;
		let s: string;

		beforeEach(async function () {
			mintFunctionCalldata =
				this.mocks.mockJellyToken.interface.encodeFunctionData('mint', [
					this.signers.alice.address,
					amountToMint,
				]);
			
			proposalId = await this.jellyGovernor.callStatic.propose(
				[this.mocks.mockJellyToken.address],
				[amountToMint],
				[mintFunctionCalldata],
				proposalDescription
			);

			await this.jellyGovernor.propose(
				[this.mocks.mockJellyToken.address],
				[amountToMint],
				[mintFunctionCalldata],
				proposalDescription
			);
			const support = 1;    // example support value
			const domain = {
				name: 'JellyGovernor',
				version: '1',
				chainId: network.config.chainId, // Using the chainId from Hardhat config
				verifyingContract: this.jellyGovernor.address // The deployed contract address
			  };

			const ballotType = {
			Ballot: [
				{ name: 'proposalId', type: 'uint256' },
				{ name: 'support', type: 'uint8' }
			]
			};

			const message = {
				proposalId,
				support,
			};

			const signature = await this.signers.alice._signTypedData(domain, ballotType, message);
			const splitSignature = utils.splitSignature(signature);
			v = splitSignature.v;
			r = splitSignature.r;
			s = splitSignature.s;
		});

		describe('failure', async function () {
			it('should revert if v is invalid', async function () {
				await expect(
					this.jellyGovernor.castVoteBySig(proposalId, 0, 8, r, s)
				).to.be.revertedWith('ECDSA: invalid signature');
			});

			it('should revert if r or s is invalid', async function () {
				await expect(
					this.jellyGovernor.castVoteBySig(proposalId, 0, v, '0x3397dbafb3e0afdb1991626fe731e09acee7393ed317b868547ee698405d4400', s)
				).to.be.revertedWith('ECDSA: invalid signature');
			});

			it('should revert because invalid proposal id', async function () {
				await mine(this.params.votingDelay);
				await expect(
					this.jellyGovernor.castVoteBySig(proposalId.add(1000), 0, v, r, s)
				).to.be.revertedWith('Governor: unknown proposal id');
			});

			it('should revert if voting didn\'t start', async function () {
				await expect(
					this.jellyGovernor.castVoteBySig(proposalId, 0, v, r, s)
				).to.be.revertedWith('Governor: vote not currently active');
			});

			it('should revert always because no params (chestIds) have been passed', async function () {
				await mine(this.params.votingDelay);
				await expect(
					this.jellyGovernor.castVoteBySig(proposalId, 0, v, r, s)
				).to.be.revertedWith('JellyGovernor: no params provided in voting weight query');
			});
		});

	});
	
	describe('#castVoteWithReason: should always fail', async function () {
		const amountToMint = utils.parseEther('100');
		const proposalDescription = 'Test Proposal #1: Mint 100 JLY tokens to Alice';
		let mintFunctionCalldata: string;
		let proposalId: BigNumber;

		beforeEach(async function () {
			mintFunctionCalldata =
				this.mocks.mockJellyToken.interface.encodeFunctionData('mint', [
					this.signers.alice.address,
					amountToMint,
				]);

			proposalId = await this.jellyGovernor.callStatic.propose(
				[this.mocks.mockJellyToken.address],
				[amountToMint],
				[mintFunctionCalldata],
				proposalDescription
			);

			await this.jellyGovernor.propose(
				[this.mocks.mockJellyToken.address],
				[amountToMint],
				[mintFunctionCalldata],
				proposalDescription
			);
		});

		describe('failure', async function () {
			it('should revert if voting didn\'t start', async function () {
				await expect(
					this.jellyGovernor.castVoteWithReason(proposalId, 0, 'I like this proposal.')
				).to.be.revertedWith('Governor: vote not currently active');
			});

			it('should revert because invalid proposal id', async function () {
				await mine(this.params.votingDelay);
				await expect(
					this.jellyGovernor.castVoteWithReason(proposalId.add(1000), 0, 'I like this proposal.')
				).to.be.revertedWith('Governor: unknown proposal id');
			});

			it('should revert always because no params (chestIds) have been passed', async function () {
				await mine(this.params.votingDelay);
				await expect(
					this.jellyGovernor.castVoteWithReason(proposalId, 0, 'I like this proposal.')
				).to.be.revertedWith('JellyGovernor: no params provided in voting weight query');
			});
		});
	});

	describe('#castVoteWithReasonAndParams:', async function () {
		const amountToMint = utils.parseEther('100');
		const proposalDescription = 'Test Proposal #1: Mint 100 JLY tokens to Alice';
		const proposalReason = 'I like this proposal.';
		let mintFunctionCalldata: string;
		let proposalParams: string;
		let proposalId: BigNumber;
		let chestIDs: number[];

		beforeEach(async function () {
			mintFunctionCalldata =
				this.mocks.mockJellyToken.interface.encodeFunctionData('mint', [
					this.signers.alice.address,
					amountToMint,
				]);

			proposalId = await this.jellyGovernor.callStatic.propose(
				[this.mocks.mockJellyToken.address],
				[amountToMint],
				[mintFunctionCalldata],
				proposalDescription
			);

			await this.jellyGovernor.propose(
				[this.mocks.mockJellyToken.address],
				[amountToMint],
				[mintFunctionCalldata],
				proposalDescription
			);

			chestIDs = [1, 2, 3];

			proposalParams = utils.defaultAbiCoder.encode(
			['uint256[]'],
			[chestIDs]     
			);
		});

		describe('failure', async function () {
			it('should revert if voting didn\'t start', async function () {
				await expect(
					this.jellyGovernor.castVoteWithReasonAndParams(proposalId, 0, proposalReason, proposalParams)
				).to.be.revertedWith('Governor: vote not currently active');
			});
			
			it('should revert because invalid proposal id', async function () {
				await mine(this.params.votingDelay);
				await expect(
					this.jellyGovernor.castVoteWithReasonAndParams(proposalId.add(1000), 0, proposalReason, proposalParams)
				).to.be.revertedWith('Governor: unknown proposal id');
			});

			it('should revert because no chestIds in enocoded params', async function () {
				await mine(this.params.votingDelay);
				const chestIDs: number[] = [];
				const invalidProposalParams = utils.defaultAbiCoder.encode(
				['uint256[]'],
				[chestIDs]     
				);
				await expect(
					this.jellyGovernor.castVoteWithReasonAndParams(proposalId, 0, proposalReason, invalidProposalParams)
				).to.be.revertedWith('JellyGovernor: no chest IDs provided');
			});

			it('should revert because provided chestId is not viable for voting', async function () {
				await mine(this.params.votingDelay);
				const chestIDs: number[] = [10, 1];
				const invalidProposalParams = utils.defaultAbiCoder.encode(
				['uint256[]'],
				[chestIDs]     
				);
				await expect(
					this.jellyGovernor.castVoteWithReasonAndParams(proposalId, 0, proposalReason, invalidProposalParams)
				).to.be.revertedWith('JellyGovernor: chest not viable for voting');
			});

			it('should revert because provided support parameter in invalid', async function () {
				await mine(this.params.votingDelay);
				await expect(
					this.jellyGovernor.castVoteWithReasonAndParams(proposalId, 3, proposalReason, proposalParams)
				).to.be.revertedWith('GovernorVotingSimple: invalid value for enum VoteType');
			});

			it('should revert because user already voted', async function () {
				await mine(this.params.votingDelay);
				await this.jellyGovernor.connect(this.signers.alice).castVoteWithReasonAndParams(proposalId, 0, proposalReason, proposalParams);

				await expect(
					this.jellyGovernor.connect(this.signers.alice).castVoteWithReasonAndParams(proposalId, 0, proposalReason, proposalParams)
				).to.be.revertedWith('GovernorVotingSimple: vote already cast');
			});
		});

		describe('success', async function () {
			beforeEach(async function () {
				await mine(this.params.votingDelay);
				await this.jellyGovernor.connect(this.signers.alice).castVoteWithReasonAndParams(proposalId, 0, proposalReason, proposalParams);
			});

			it('should set alice as user who voted for proposal', async function () {
				const hasVoted = await this.jellyGovernor.hasVoted(
					proposalId,
					this.signers.alice.address
				);

				assert(hasVoted === true, 'Incorrect hasVoted value');
			});
			
			it('should count alice\'s votes for proposal', async function () {
				const votes = await this.jellyGovernor.proposalVotes(
					proposalId
				);
				const alicesVotes =  1000; // mocked votingPower value on chest contract

				assert(votes.againstVotes.eq(alicesVotes), 'Incorrect against votes value');
				assert(votes.abstainVotes.eq(0), 'Incorrect abstain votes value');
				assert(votes.forVotes.eq(0), 'Incorrect for votes value');
			});

			it('should emit VoteCastWithParams event', async function () {
				await expect(
					this.jellyGovernor
						.connect(this.signers.bob)
						.castVoteWithReasonAndParams(
							proposalId,
							0,
							proposalReason, 
							proposalParams
						)
				)
					.to.emit(this.jellyGovernor, 'VoteCastWithParams')
					.withArgs(
						this.signers.bob.address,
						proposalId,
						0,
						1000,
						proposalReason,
						proposalParams
					);
			});
		});
	});

	describe('#castVoteWithReasonAndParamsBySig:', async function () {
		const amountToMint = utils.parseEther('100');
		const proposalDescription = 'Test Proposal #1: Mint 100 JLY tokens to Alice';
		const proposalReason = 'I like this proposal.';
		let mintFunctionCalldata: string;
		let proposalParams: string;
		let proposalId: BigNumber;
		let chestIDs: number[];
		let support: number;
		let v: number;
		let r: string;
		let s: string;

		beforeEach(async function () {
			mintFunctionCalldata =
				this.mocks.mockJellyToken.interface.encodeFunctionData('mint', [
					this.signers.alice.address,
					amountToMint,
				]);

			proposalId = await this.jellyGovernor.callStatic.propose(
				[this.mocks.mockJellyToken.address],
				[amountToMint],
				[mintFunctionCalldata],
				proposalDescription
			);

			await this.jellyGovernor.propose(
				[this.mocks.mockJellyToken.address],
				[amountToMint],
				[mintFunctionCalldata],
				proposalDescription
			);

			chestIDs = [1, 2, 3];

			proposalParams = utils.defaultAbiCoder.encode(
			['uint256[]'],
			[chestIDs]     
			);

			support = 1;    // example support value
			const domain = {
				name: 'JellyGovernor',
				version: '1',
				chainId: network.config.chainId, // Using the chainId from Hardhat config
				verifyingContract: this.jellyGovernor.address // The deployed contract address
			  };

			const ballotType = {
				ExtendedBallot: [
					{ name: 'proposalId', type: 'uint256' },
					{ name: 'support', type: 'uint8' },
					{ name: 'reason', type: 'string' },
					{ name: 'params', type: 'bytes' },
				]
			};

			const message = {
				proposalId,
				support,
				reason: proposalReason,
				params: proposalParams,
			};

			const signature = await this.signers.deployer._signTypedData(domain, ballotType, message);
			const splitSignature = utils.splitSignature(signature);
			v = splitSignature.v;
			r = splitSignature.r;
			s = splitSignature.s;
		});

		describe('failure', async function () {
			it('should revert if voting didn\'t start', async function () {
				await expect(
					this.jellyGovernor.castVoteWithReasonAndParamsBySig(proposalId, support, proposalReason, proposalParams, v, r, s)
				).to.be.revertedWith('Governor: vote not currently active');
			});

			it('should revert if v is invalid', async function () {
				await expect(
					this.jellyGovernor.castVoteWithReasonAndParamsBySig(proposalId, support, proposalReason, proposalParams, 8, r, s)
				).to.be.revertedWith('ECDSA: invalid signature');
			});

			it('should revert if r or s is invalid', async function () {
				await expect(
					this.jellyGovernor.castVoteWithReasonAndParamsBySig(proposalId, support, proposalReason, proposalParams, v, '0x3397dbafb3e0afdb1991626fe731e09acee7393ed317b868547ee698405d4400', s)
				).to.be.revertedWith('ECDSA: invalid signature');
			});

			it('should revert because invalid proposal id', async function () {
				await mine(this.params.votingDelay);
				await expect(
					this.jellyGovernor.castVoteWithReasonAndParamsBySig(proposalId.add(1000), support, proposalReason, proposalParams, v, r, s)
				).to.be.revertedWith('Governor: unknown proposal id');
			});

			it('should revert because no chestIds in enocoded params', async function () {
				await mine(this.params.votingDelay);
				const chestIDs: number[] = [];
				const invalidProposalParams = utils.defaultAbiCoder.encode(
				['uint256[]'],
				[chestIDs]     
				);
				await expect(
					this.jellyGovernor.castVoteWithReasonAndParamsBySig(proposalId, support, proposalReason, invalidProposalParams, v, r, s)
				).to.be.revertedWith('JellyGovernor: no chest IDs provided');
			});

			it('should revert because provided chestId is not viable for voting', async function () {
				await mine(this.params.votingDelay);
				const chestIDs: number[] = [10, 1];
				const invalidProposalParams = utils.defaultAbiCoder.encode(
				['uint256[]'],
				[chestIDs]     
				);
				await expect(
					this.jellyGovernor.castVoteWithReasonAndParamsBySig(proposalId, support, proposalReason, invalidProposalParams, v, r, s)
				).to.be.revertedWith('JellyGovernor: chest not viable for voting');
			});

			it('should revert because provided support parameter in invalid', async function () {
				await mine(this.params.votingDelay);
				await expect(
					this.jellyGovernor.castVoteWithReasonAndParamsBySig(proposalId, 8, proposalReason, proposalParams, v, r, s)
				).to.be.revertedWith('GovernorVotingSimple: invalid value for enum VoteType');
			});

			it('should revert because user already voted', async function () {
				await mine(this.params.votingDelay);
				await this.jellyGovernor.castVoteWithReasonAndParamsBySig(proposalId, support, proposalReason, proposalParams, v, r, s)

				await expect(
					this.jellyGovernor.castVoteWithReasonAndParamsBySig(proposalId, support, proposalReason, proposalParams, v, r, s)
				).to.be.revertedWith('GovernorVotingSimple: vote already cast');
			});
		});

		describe('success', async function () {
			beforeEach(async function () {
				await mine(this.params.votingDelay);
				await this.jellyGovernor.castVoteWithReasonAndParamsBySig(proposalId, support, proposalReason, proposalParams, v, r, s)
			});

			it('should set deployer as user who voted for proposal', async function () {
				const hasVoted = await this.jellyGovernor.hasVoted(
					proposalId,
					this.signers.deployer.address
				);
				assert(hasVoted === true, 'Incorrect hasVoted value');
			});
			
			it('should count deployer\'s votes for proposal', async function () {
				const votes = await this.jellyGovernor.proposalVotes(
					proposalId
				);
				const deployerVotes =  1000; // mocked votingPower value on chest contract

				assert(votes.againstVotes.eq(0), 'Incorrect against votes value');
				assert(votes.abstainVotes.eq(0), 'Incorrect abstain votes value');
				assert(votes.forVotes.eq(deployerVotes), 'Incorrect for votes value');
			});

			it('should emit VoteCastWithParams event', async function () {
				const domain = {
					name: 'JellyGovernor',
					version: '1',
					chainId: network.config.chainId, // Using the chainId from Hardhat config
					verifyingContract: this.jellyGovernor.address // The deployed contract address
				};

				const ballotType = {
					ExtendedBallot: [
						{ name: 'proposalId', type: 'uint256' },
						{ name: 'support', type: 'uint8' },
						{ name: 'reason', type: 'string' },
						{ name: 'params', type: 'bytes' },
					]
				};

				const message = {
					proposalId,
					support,
					reason: proposalReason,
					params: proposalParams,
				};

				const signature = await this.signers.bob._signTypedData(domain, ballotType, message);
				const splitSignature = utils.splitSignature(signature);

				await expect(
					this.jellyGovernor
						.castVoteWithReasonAndParamsBySig(
							proposalId,
							support,
							proposalReason, 
							proposalParams,
							splitSignature.v,
							splitSignature.r,
							splitSignature.s
						)
				)
					.to.emit(this.jellyGovernor, 'VoteCastWithParams')
					.withArgs(
						this.signers.bob.address,
						proposalId,
						support,
						1000,
						proposalReason,
						proposalParams
					);
			});
		});
	});
}
