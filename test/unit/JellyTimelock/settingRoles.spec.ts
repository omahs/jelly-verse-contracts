import { assert, expect } from 'chai';

export function shouldSetRoles(): void {
	let TIMELOCK_ADMIN_ROLE: string;
	let CANCELLER_ROLE: string;

	beforeEach(async function () {
		TIMELOCK_ADMIN_ROLE = await this.jellyTimelock.TIMELOCK_ADMIN_ROLE();
		CANCELLER_ROLE = await this.jellyTimelock.CANCELLER_ROLE();
	});

	describe('#revokeRole', async function () {
		describe('failure', async function () {
			it('should revert if not called by an Admin', async function () {
				await expect(
					this.jellyTimelock
						.connect(this.signers.bob)
						.revokeRole(CANCELLER_ROLE, this.signers.alice.address)
				).to.be.revertedWith(
					`AccessControl: account ${this.signers.bob.address.toLowerCase()} is missing role ${TIMELOCK_ADMIN_ROLE}`
				);
			});

			it('should not make any effect if address already has role to be revoked ', async function () {
				await this.jellyTimelock
					.connect(this.signers.timelockAdmin)
					.revokeRole(CANCELLER_ROLE, this.signers.bob.address);

				assert(
					!(await this.jellyTimelock.hasRole(
						CANCELLER_ROLE,
						this.signers.bob.address
					)),
					'Revoke role made effect although it should not'
				);
			});
		});

		describe('success', async function () {
			it('should revoke Canceller role from Alice', async function () {
				await this.jellyTimelock
					.connect(this.signers.timelockAdmin)
					.revokeRole(CANCELLER_ROLE, this.signers.alice.address);

				assert(
					!(await this.jellyTimelock.hasRole(
						CANCELLER_ROLE,
						this.signers.alice.address
					)),
					"Canceller role hasn't been revoked from Alice"
				);
			});

			it('should emit RoleRevoked event', async function () {
				await expect(
					this.jellyTimelock
						.connect(this.signers.timelockAdmin)
						.revokeRole(CANCELLER_ROLE, this.signers.alice.address)
				)
					.to.emit(this.jellyTimelock, 'RoleRevoked')
					.withArgs(
						CANCELLER_ROLE,
						this.signers.alice.address,
						this.signers.timelockAdmin.address
					);
			});
		});
	});

	describe('#grantRole', async function () {
		describe('failure', async function () {
			it('should revert if not called by an Admin', async function () {
				await expect(
					this.jellyTimelock
						.connect(this.signers.bob)
						.grantRole(CANCELLER_ROLE, this.signers.bob.address)
				).to.be.revertedWith(
					`AccessControl: account ${this.signers.bob.address.toLowerCase()} is missing role ${TIMELOCK_ADMIN_ROLE}`
				);
			});

			it('should not make any effect if address already has role to be granted', async function () {
				assert(
					await this.jellyTimelock.hasRole(
						CANCELLER_ROLE,
						this.signers.alice.address
					),
					'Prepare Scenario: Alice should have Canceller role'
				);

				await this.jellyTimelock
					.connect(this.signers.timelockAdmin)
					.grantRole(CANCELLER_ROLE, this.signers.alice.address);

				assert(
					await this.jellyTimelock.hasRole(
						CANCELLER_ROLE,
						this.signers.alice.address
					),
					'Grant role made effect although it should not'
				);
			});
		});

		describe('success', async function () {
			it('should grant Canceller role to Bob', async function () {
				await this.jellyTimelock
					.connect(this.signers.timelockAdmin)
					.grantRole(CANCELLER_ROLE, this.signers.bob.address);

				assert(
					await this.jellyTimelock.hasRole(
						CANCELLER_ROLE,
						this.signers.bob.address
					),
					'Role not granted'
				);
			});

			it('should emit RoleGranted event', async function () {
				await expect(
					this.jellyTimelock
						.connect(this.signers.timelockAdmin)
						.grantRole(CANCELLER_ROLE, this.signers.bob.address)
				)
					.to.emit(this.jellyTimelock, 'RoleGranted')
					.withArgs(
						CANCELLER_ROLE,
						this.signers.bob.address,
						this.signers.timelockAdmin.address
					);
			});
		});
	});

	describe('#renounceRole', async function () {
		describe('failure', async function () {
			it('should revert if not called by the Role owner', async function () {
				await expect(
					this.jellyTimelock
						.connect(this.signers.timelockAdmin)
						.renounceRole(CANCELLER_ROLE, this.signers.alice.address)
				).to.be.revertedWith('AccessControl: can only renounce roles for self');
			});
		});

		describe('success', async function () {
			it('should renounce role', async function () {
				await this.jellyTimelock
					.connect(this.signers.alice)
					.renounceRole(CANCELLER_ROLE, this.signers.alice.address);

				assert(
					!(await this.jellyTimelock.hasRole(
						CANCELLER_ROLE,
						this.signers.alice.address
					)),
					"Canceller role hasn't been renounced from Alice"
				);
			});
		});
	});
}
