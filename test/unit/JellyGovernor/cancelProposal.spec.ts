import { assert, expect } from 'chai';
import { utils, constants, BigNumber } from 'ethers';
import { time, mine } from '@nomicfoundation/hardhat-network-helpers';
import { JellyGovernor__factory, JellyGovernor } from '../../../typechain-types';
import { ethers } from 'hardhat';
import { deployMockJellyTimelock } from '../../shared/mocks';

export function shouldCancelProposals(): void {
	describe('#cancel', async function () {
		const amountToMint = utils.parseEther('100');
		const proposalDescription = 'Test Proposal #1: Mint 100 JLY tokens to Alice';
		let proposalAddresses: string[];
		let proposalValues: BigNumber[];
		let proposalCalldata: string[];
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
			proposalAddresses = [this.mocks.mockJellyToken.address];
			proposalValues = [amountToMint];
			proposalCalldata = [mintFunctionCalldata];

			proposalId = await this.jellyGovernor.callStatic.propose(
				proposalAddresses,
				proposalValues,
				proposalCalldata,
				proposalDescription
			);

			await this.jellyGovernor.propose(
				proposalAddresses,
				proposalValues,
				proposalCalldata,
				proposalDescription
			);
			
			chestIDs = [1, 2, 3];

			proposalParams = utils.defaultAbiCoder.encode(
			['uint256[]'],
			[chestIDs]     
			);
		});

		describe('failure', async function () {
			it('should revert if proposal passed is invalid', async function () {
				await time.increase(this.params.votingDelay);
				await expect(
					this.jellyGovernor.cancel(
						proposalAddresses,
						proposalValues,
						proposalCalldata,
						constants.HashZero
					)
				).to.be.revertedWith('Governor: unknown proposal id');
			});

			it('should revert if proposal voting has started', async function () {
				await time.increase(this.params.votingDelay.add(constants.One));
				const descriptionBytes = utils.toUtf8Bytes(proposalDescription);
				const hashedDescription = utils.keccak256(descriptionBytes);
				await expect(
					this.jellyGovernor.cancel(
						proposalAddresses,
						proposalValues,
						proposalCalldata,
						hashedDescription
					)
				).to.be.revertedWith('Governor: too late to cancel');
			});

			it('should revert if called by anyone other than proposer', async function () {
				const descriptionBytes = utils.toUtf8Bytes(proposalDescription);
				const hashedDescription = utils.keccak256(descriptionBytes);
				await expect(
					this.jellyGovernor.connect(this.signers.bob).cancel(
						proposalAddresses,
						proposalValues,
						proposalCalldata,
						hashedDescription
					)
				).to.be.revertedWith('Governor: only proposer can cancel');
			});
		});

		describe('success', async function () {
			let hashedDescription: string;

			beforeEach(async function () {
				const descriptionBytes = utils.toUtf8Bytes(proposalDescription);
				hashedDescription = utils.keccak256(descriptionBytes);

				if (this.currentTest) {
					if (this.currentTest.title === 'should emit ProposalCanceled event')
						return;
				}

				await this.jellyGovernor.cancel(
					proposalAddresses,
					proposalValues,
					proposalCalldata,
					hashedDescription
				)
			});

			it('should set proposal in queue', async function () {
				const canceledState = 2;
				const state = await this.jellyGovernor.state(
					proposalId
				);

				assert(state == canceledState, 'Incorrect state');
			});

			it('should emit ProposalCanceled event', async function () {
				await expect(
					this.jellyGovernor.cancel(
						proposalAddresses,
						proposalValues,
						proposalCalldata,
						hashedDescription
					)
				)
					.to.emit(this.jellyGovernor, 'ProposalCanceled')
					.withArgs(proposalId);
			});
		});
	});

}
