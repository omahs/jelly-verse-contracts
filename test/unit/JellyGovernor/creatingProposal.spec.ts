import { assert, expect } from 'chai';
import { utils, constants, BigNumber } from 'ethers';
import {
	time,
	getStorageAt,
	setStorageAt,
} from '@nomicfoundation/hardhat-network-helpers';

export function shouldCreateProposals(): void {
	describe('#propose', async function () {
		const amountToMint = utils.parseEther('100');
		const proposalDescription = 'Test Proposal #1: Mint 100 JLY tokens to Alice';
		let mintFunctionCalldata: string;

		beforeEach(async function () {
			mintFunctionCalldata =
				this.mocks.mockJellyToken.interface.encodeFunctionData('mint', [
					this.signers.alice.address,
					amountToMint,
				]);
		});

		describe('failure', async function () {
			it('should revert if proposal has invalid length of values', async function () {
				await expect(
					this.jellyGovernor.propose(
						[this.mocks.mockJellyToken.address],
						[amountToMint, amountToMint],
						[mintFunctionCalldata],
						proposalDescription
					)
				).to.be.revertedWith('Governor: invalid proposal length');
			});

			it('should revert if proposal has invalid length of calldatas', async function () {
				await expect(
					this.jellyGovernor.propose(
						[this.mocks.mockJellyToken.address],
						[amountToMint],
						[mintFunctionCalldata, mintFunctionCalldata],
						proposalDescription
					)
				).to.be.revertedWith('Governor: invalid proposal length');
			});

			it('should revert if proposal is empty', async function () {
				await expect(
					this.jellyGovernor.propose([], [], [], proposalDescription)
				).to.be.revertedWith('Governor: empty proposal');
			});

			it('should revert if proposal has suffix in description that doesn\'t match caller', async function () {
				await expect(
					this.jellyGovernor.propose(
						[this.mocks.mockJellyToken.address],
						[amountToMint],
						[mintFunctionCalldata],
						proposalDescription + ' #proposer=' + this.signers.bob.address
					)
				).to.be.revertedWith('Governor: proposer restricted');
			});

			it('should revert if proposal already exists', async function () {
				await this.jellyGovernor.propose(
					[this.mocks.mockJellyToken.address],
					[amountToMint],
					[mintFunctionCalldata],
					proposalDescription
				);

				await expect(
					this.jellyGovernor.propose(
						[this.mocks.mockJellyToken.address],
						[amountToMint],
						[mintFunctionCalldata],
						proposalDescription
					)
				).to.be.revertedWith('Governor: proposal already exists');
			});
		});

		describe('success', async function () {
			let proposalId: BigNumber;

			beforeEach(async function () {
				proposalId = await this.jellyGovernor.callStatic.propose(
					[this.mocks.mockJellyToken.address],
					[amountToMint],
					[mintFunctionCalldata],
					proposalDescription
				);

				if (this.currentTest) {
					if (this.currentTest.title === 'should emit ProposalCreated event')
						return;
				}

				await this.jellyGovernor.propose(
					[this.mocks.mockJellyToken.address],
					[amountToMint],
					[mintFunctionCalldata],
					proposalDescription
				);
			});

			it('should set snapshot', async function () {
				const latestBlockTime = BigNumber.from(await time.latest());
				const expectedSnapshot = latestBlockTime.add(this.params.votingDelay);
				const actualSnapshot = await this.jellyGovernor.proposalSnapshot(
					proposalId
				);

				assert(expectedSnapshot.eq(actualSnapshot), 'Incorrect snapshot value');
			});

			it('should set final chest id that can vote', async function () {
				const actualFinalSnapshot = await this.jellyGovernor.proposalFinalChest(
					proposalId
				);

				assert(actualFinalSnapshot.eq(this.params.lastChestId), 'Incorrect final chest id value');
			});

			it('should set proposal proposer', async function () {
				const proposer = await this.jellyGovernor.proposalProposer(
					proposalId
				);

				assert(proposer === this.signers.deployer.address, 'Incorrect proposal proposer');
			});

			it('should have 0 votes', async function () {
				const votes = await this.jellyGovernor.proposalVotes(
					proposalId
				);

				assert(votes.againstVotes.eq(0), 'Incorrect against votes value');
				assert(votes.abstainVotes.eq(0), 'Incorrect abstain votes value');
				assert(votes.forVotes.eq(0), 'Incorrect for votes value');
			});

			it('should set deadline', async function () {
				const latestBlockTime = BigNumber.from(await time.latest());
				const expectedDeadline = latestBlockTime
					.add(this.params.votingDelay)
					.add(this.params.votingPeriod);
				const actualDeadline = await this.jellyGovernor.proposalDeadline(
					proposalId
				);

				assert(expectedDeadline.eq(actualDeadline), 'Incorrect deadline value');
			});

			it('should emit ProposalCreated event', async function () {
				const targetsLength = [''];
				const nextBlockNumberTimestamp = BigNumber.from(await time.latest()).add(
					constants.One
				);
				const snapshot = nextBlockNumberTimestamp.add(this.params.votingDelay);
				const deadline = snapshot.add(this.params.votingPeriod);

				await expect(
					this.jellyGovernor
						.connect(this.signers.alice)
						.propose(
							[this.mocks.mockJellyToken.address],
							[amountToMint],
							[mintFunctionCalldata],
							proposalDescription
						)
				)
					.to.emit(this.jellyGovernor, 'ProposalCreated')
					.withArgs(
						proposalId,
						this.signers.alice.address,
						[this.mocks.mockJellyToken.address],
						[amountToMint],
						targetsLength,
						[mintFunctionCalldata],
						snapshot,
						deadline,
						proposalDescription
					);
			});

			it('should create new proposal and return proposal id', async function () {
				const abiEncodedParams = utils.defaultAbiCoder.encode(
					['address[]', 'uint256[]', 'bytes[]', 'bytes32'],
					[
						[this.mocks.mockJellyToken.address],
						[amountToMint],
						[mintFunctionCalldata],
						utils.keccak256(utils.toUtf8Bytes(proposalDescription)),
					]
				);

				const expectedProposalId = BigNumber.from(
					utils.keccak256(abiEncodedParams)
				);

				assert(expectedProposalId.eq(proposalId), 'Incorrect proposal id');
			});
		});
	});

	describe('#proposeCustom', async function () {
		const amountToMint = utils.parseEther('100');
		const proposalDescription = 'Test Proposal #1: Mint 100 JLY tokens to Alice';
		const minVotingDelay = 3600 /* 1 hour */;
		const minVotingPeriod =  86400 /* 1 day */
		let mintFunctionCalldata: string;

		beforeEach(async function () {
			mintFunctionCalldata =
				this.mocks.mockJellyToken.interface.encodeFunctionData('mint', [
					this.signers.alice.address,
					amountToMint,
				]);
		});

		describe('failure', async function () {
			it('should revert if proposal has invalid length of values', async function () {
				await expect(
					this.jellyGovernor.proposeCustom(
						[this.mocks.mockJellyToken.address],
						[amountToMint, amountToMint],
						[mintFunctionCalldata],
						proposalDescription,
						minVotingDelay,
						minVotingPeriod
					)
				).to.be.revertedWith('Governor: invalid proposal length');
			});

			it('should revert if proposal has invalid voting delay', async function () {
				await expect(
					this.jellyGovernor.proposeCustom(
						[this.mocks.mockJellyToken.address],
						[amountToMint],
						[mintFunctionCalldata],
						proposalDescription,
						minVotingDelay - 1,
						minVotingPeriod
					)
				).to.be.revertedWith('Governor: voting delay must exceed minimum voting delay');
			});

			it('should revert if proposal has invalid voting period', async function () {
				await expect(
					this.jellyGovernor.proposeCustom(
						[this.mocks.mockJellyToken.address],
						[amountToMint],
						[mintFunctionCalldata],
						proposalDescription,
						minVotingDelay,
						minVotingPeriod - 1
					)
				).to.be.revertedWith('Governor: voting period must exceed minimum voting period');
			});

			it('should revert if proposal has suffix in description that doesn\'t match caller', async function () {
				await expect(
					this.jellyGovernor.proposeCustom(
						[this.mocks.mockJellyToken.address],
						[amountToMint],
						[mintFunctionCalldata],
						proposalDescription + ' #proposer=' + this.signers.bob.address,
						minVotingDelay,
						minVotingPeriod
					)
				).to.be.revertedWith('Governor: proposer restricted');
			});

			it('should revert if proposal has invalid length of calldatas', async function () {
				await expect(
					this.jellyGovernor.proposeCustom(
						[this.mocks.mockJellyToken.address],
						[amountToMint],
						[mintFunctionCalldata, mintFunctionCalldata],
						proposalDescription,
						minVotingDelay,
						minVotingPeriod
					)
				).to.be.revertedWith('Governor: invalid proposal length');
			});

			it('should revert if proposal is empty', async function () {
				await expect(
					this.jellyGovernor.proposeCustom([], [], [], proposalDescription,minVotingDelay,minVotingPeriod)
				).to.be.revertedWith('Governor: empty proposal');
			});

			it('should revert if proposal already exists', async function () {
				await this.jellyGovernor.proposeCustom(
					[this.mocks.mockJellyToken.address],
					[amountToMint],
					[mintFunctionCalldata],
					proposalDescription,
					minVotingDelay,
					minVotingPeriod
				);

				await expect(
					this.jellyGovernor.proposeCustom(
						[this.mocks.mockJellyToken.address],
						[amountToMint],
						[mintFunctionCalldata],
						proposalDescription,
						minVotingDelay,
						minVotingPeriod
					)
				).to.be.revertedWith('Governor: proposal already exists');
			});
		});

		describe('success', async function () {
			let proposalId: BigNumber;

			beforeEach(async function () {
				proposalId = await this.jellyGovernor.callStatic.proposeCustom(
					[this.mocks.mockJellyToken.address],
					[amountToMint],
					[mintFunctionCalldata],
					proposalDescription,
					minVotingDelay,
					minVotingPeriod
				);

				if (this.currentTest) {
					if (this.currentTest.title === 'should emit ProposalCreated event')
						return;
				}

				await this.jellyGovernor.proposeCustom(
					[this.mocks.mockJellyToken.address],
					[amountToMint],
					[mintFunctionCalldata],
					proposalDescription,
					minVotingDelay,
					minVotingPeriod
				);
			});

			it('should set snapshot', async function () {
				const latestBlockTime = BigNumber.from(await time.latest());
				const expectedSnapshot = latestBlockTime.add(minVotingDelay);
				const actualSnapshot = await this.jellyGovernor.proposalSnapshot(
					proposalId
				);

				assert(expectedSnapshot.eq(actualSnapshot), 'Incorrect snapshot value');
			});

			it('should set proposal proposer', async function () {
				const proposer = await this.jellyGovernor.proposalProposer(
					proposalId
				);
				
				assert(proposer === this.signers.deployer.address, 'Incorrect proposal proposer');
			});

			it('should have 0 votes', async function () {
				const votes = await this.jellyGovernor.proposalVotes(
					proposalId
				);

				assert(votes.againstVotes.eq(0), 'Incorrect against votes value');
				assert(votes.abstainVotes.eq(0), 'Incorrect abstain votes value');
				assert(votes.forVotes.eq(0), 'Incorrect for votes value');
			});

			it('should set final chest id that can vote', async function () {
				const actualFinalSnapshot = await this.jellyGovernor.proposalFinalChest(
					proposalId
				);

				assert(actualFinalSnapshot.eq(this.params.lastChestId), 'Incorrect final chest id value');
			});

			it('should set deadline', async function () {
				const latestBlockTime = BigNumber.from(await time.latest());
				const expectedDeadline = latestBlockTime
					.add(minVotingDelay)
					.add(minVotingPeriod);
				const actualDeadline = await this.jellyGovernor.proposalDeadline(
					proposalId
				);

				assert(expectedDeadline.eq(actualDeadline), 'Incorrect deadline value');
			});

			it('should emit ProposalCreated event', async function () {
				const targetsLength = [''];
				const nextBlockNumberTimestamp = BigNumber.from(await time.latest()).add(
					constants.Two
				);
				const snapshot = nextBlockNumberTimestamp.add(minVotingDelay);
				const deadline = snapshot.add(minVotingPeriod);

				await expect(
					this.jellyGovernor
						.connect(this.signers.alice)
						.proposeCustom(
							[this.mocks.mockJellyToken.address],
							[amountToMint],
							[mintFunctionCalldata],
							proposalDescription,
							minVotingDelay,
							minVotingPeriod
						)
				)
					.to.emit(this.jellyGovernor, 'ProposalCreated')
					.withArgs(
						proposalId,
						this.signers.alice.address,
						[this.mocks.mockJellyToken.address],
						[amountToMint],
						targetsLength,
						[mintFunctionCalldata],
						snapshot,
						deadline,
						proposalDescription
					);
			});

			it('should create new proposal and return proposal id', async function () {
				const abiEncodedParams = utils.defaultAbiCoder.encode(
					['address[]', 'uint256[]', 'bytes[]', 'bytes32'],
					[
						[this.mocks.mockJellyToken.address],
						[amountToMint],
						[mintFunctionCalldata],
						utils.keccak256(utils.toUtf8Bytes(proposalDescription)),
					]
				);

				const expectedProposalId = BigNumber.from(
					utils.keccak256(abiEncodedParams)
				);

				assert(expectedProposalId.eq(proposalId), 'Incorrect proposal id');
			});
		});
	});
}
