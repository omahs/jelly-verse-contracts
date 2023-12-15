import { expect } from 'chai';
import { utils } from 'ethers';
import { JellyGovernor__factory, JellyGovernor } from '../../../typechain-types';
import { ethers } from 'hardhat';
import { setStorageAt } from '@nomicfoundation/hardhat-network-helpers';
import { mapSlot } from '../../shared/helpers';

export function shouldRelayCallToGovernor(): void {
	describe('#relay', async function () {
		const amountToMint = utils.parseEther('100');
		let mintFunctionCalldata: string;

		beforeEach(async function () {
			mintFunctionCalldata =
				this.mocks.mockJellyToken.interface.encodeFunctionData('mint', [
					this.signers.alice.address,
					amountToMint,
				]);
		});

		describe('failure', async function () {
			it('should revert if relay is called by non timelock contract', async function () {
				await expect(
					this.jellyGovernor.relay(
						this.mocks.mockJellyToken.address,
						0,
						mintFunctionCalldata
					)
				).to.be.revertedWith('Governor: onlyGovernance');
			});

			it('should revert if relayed function call in not in queue', async function () {
				const jellyGovernorFactory: JellyGovernor__factory =
					await ethers.getContractFactory('JellyGovernor') as JellyGovernor__factory;

				const jellyGovernor: JellyGovernor = await jellyGovernorFactory.deploy(
					this.mocks.mockChest.address,
					this.signers.timelockAdmin.address,
				);
				const governor = await jellyGovernor.deployed();

				await expect(
					governor.connect(this.signers.timelockAdmin).relay(
						this.mocks.mockJellyToken.address,
						0,
						mintFunctionCalldata
					)
				).to.be.revertedWithCustomError(governor, 'Empty');
			});

			it('should revert if relayed function call reverts', async function () {
				const jellyGovernorFactory: JellyGovernor__factory =
					await ethers.getContractFactory('JellyGovernor') as JellyGovernor__factory;

				const jellyGovernor: JellyGovernor = await jellyGovernorFactory.deploy(
					this.mocks.mockChest.address,
					this.signers.timelockAdmin.address,
				);
				const governor = await jellyGovernor.deployed();

				const GOVERNANCE_CALL_STORAGE_SLOT = 5;
				const GOVERNANCE_CALL_DATA_MEMBER_STORAGE_SLOT = mapSlot(6, 0);

				const approveFunctionCalldata =
				this.mocks.mockJellyToken.interface.encodeFunctionData('approve', [
					this.signers.alice.address,
					amountToMint,
				]);

				const calldata =
				governor.interface.encodeFunctionData('relay', [
					this.mocks.mockJellyToken.address,
					0,
					approveFunctionCalldata
				]);
				await setStorageAt(
					governor.address,
					GOVERNANCE_CALL_DATA_MEMBER_STORAGE_SLOT,
					utils.keccak256(calldata)
				);
				await setStorageAt(
					governor.address,
					GOVERNANCE_CALL_STORAGE_SLOT,
					'0x0000000000000000000000000000000100000000000000000000000000000000'
				);

				await expect(
					governor.connect(this.signers.timelockAdmin).relay(
						this.mocks.mockJellyToken.address,
						0,
						approveFunctionCalldata
					)
				).to.be.revertedWith('Mock test revert');
			});
		});

		describe('success', async function () {
			let hashedDescription: string;

			it('should set proposal as executed', async function () {
				const jellyGovernorFactory: JellyGovernor__factory =
					await ethers.getContractFactory('JellyGovernor') as JellyGovernor__factory;

				const jellyGovernor: JellyGovernor = await jellyGovernorFactory.deploy(
					this.mocks.mockChest.address,
					this.signers.timelockAdmin.address,
				);
				const governor = await jellyGovernor.deployed();

				const GOVERNANCE_CALL_STORAGE_SLOT = 5;
				const GOVERNANCE_CALL_DATA_MEMBER_STORAGE_SLOT = mapSlot(6, 0);

				const calldata =
				governor.interface.encodeFunctionData('relay', [
					this.mocks.mockJellyToken.address,
					0,
					mintFunctionCalldata
				]);
				await setStorageAt(
					governor.address,
					GOVERNANCE_CALL_DATA_MEMBER_STORAGE_SLOT,
					utils.keccak256(calldata)
				);
				await setStorageAt(
					governor.address,
					GOVERNANCE_CALL_STORAGE_SLOT,
					'0x0000000000000000000000000000000100000000000000000000000000000000'
				);

				await expect(
					governor.connect(this.signers.timelockAdmin).relay(
						this.mocks.mockJellyToken.address,
						0,
						mintFunctionCalldata
					)
				).to.be.fulfilled;
			});
		});
	});
}
