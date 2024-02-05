import { assert, expect } from 'chai';
import { utils } from 'ethers';

export function shouldDeploy(): void {
	context('Deployment', async function () {
		it('should deploy JellyGovernor smart contract', async function () {
			expect(this.jellyGovernor.address).to.be.properAddress;
		});

		describe('#constructor', async function () {
			it('should set the Governance name', async function () {
				const expectedName = 'JellyGovernor';
				const actualName = await this.jellyGovernor.name();
				assert(expectedName === actualName, 'Name not set');
			});

			it('should set JLY chest address', async function () {
				const governanceVotingTokenAddress = await this.jellyGovernor.chest();
				assert(
					this.mocks.mockChest.address === governanceVotingTokenAddress,
					'JLY chest address not set'
				);
			});

			it('should set Jelly Timelock address', async function () {
				const timelock = await this.jellyGovernor.timelock();
				assert(
					this.mocks.mockJellyTimelock.address === timelock,
					'Timelock not set'
				);
			});

			it('should set Jelly Timelock address as executor', async function () {
				const executor = await this.jellyGovernor.getExecutor();
				assert(
					this.mocks.mockJellyTimelock.address === executor,
					'Timelock is not an executor'
				);
			});

			it('should set voting delay', async function () {
				const votingDelay = await this.jellyGovernor.votingDelay();
				assert(this.params.votingDelay.eq(votingDelay), 'Voting delay not set');
			});

			it('should set voting period', async function () {
				const votingPeriod = await this.jellyGovernor.votingPeriod();
				assert(
					this.params.votingPeriod.eq(votingPeriod),
					'Voting period not set'
				);
			});

			it('should set proposal threshold', async function () {
				const proposalThreshold = await this.jellyGovernor.proposalThreshold();
				assert(
					this.params.proposalThreshold.eq(proposalThreshold),
					'Proposal threshold not set'
				);
			});

			it('should set quorum', async function () {
				const quorum = await this.jellyGovernor.quorum(1);
				assert(this.params.quorum.eq(quorum), 'Quorum not set');
			});

			it('should set version of the governor instance', async function () {
				const version = await this.jellyGovernor.version();
				const defaultVersionValue = '1';
				assert(defaultVersionValue === version, 'Version not set');
			});

			it('should set BALLOT_TYPEHASH', async function () {
				const expectedBallotTypehash = utils.keccak256(
					utils.toUtf8Bytes('Ballot(uint256 proposalId,uint8 support)')
				);
				const actualBallotTypehash =
					await this.jellyGovernor.BALLOT_TYPEHASH();
				assert(
					expectedBallotTypehash === actualBallotTypehash,
					'BALLOT_TYPEHASH not set'
				);
			});

			it('should set EXTENDED_BALLOT_TYPEHASH', async function () {
				const expectedBallotTypehash = utils.keccak256(
					utils.toUtf8Bytes(
						'ExtendedBallot(uint256 proposalId,uint8 support,string reason,bytes params)'
					)
				);
				const actualBallotTypehash =
					await this.jellyGovernor.EXTENDED_BALLOT_TYPEHASH();
				assert(
					expectedBallotTypehash === actualBallotTypehash,
					'EXTENDED_BALLOT_TYPEHASH not set'
				);
			});
		});
	});
}
