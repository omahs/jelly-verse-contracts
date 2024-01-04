import { loadFixture } from '@nomicfoundation/hardhat-network-helpers';
import { Mocks, Params, Signers } from '../shared/types';
import { shouldBehaveLikeVesting } from './Vesting.spec';
import { getSigners } from '../shared/utils';
import {
	deployMockAllocator,
	deployMockJelly,
	deployMockMinter,
	deployMockVestingInvestor,
	deployMockVestingTeam,
} from '../shared/mocks';
import { shouldBehaveLikeJellyTimelock } from './JellyTimelock';
import { shouldBehaveLikeJellyGovernor } from './JellyGovernor';
import { shouldBehaveLikeJellyToken } from './JellyToken.spec';

context(`Unit tests`, async function () {
	before(async function () {
		this.signers = {} as Signers;

		const {
			deployer,
			ownerMultiSig,
			pendingOwner,
			beneficiary,
			revoker,
			alice,
			bob,
			timelockAdmin,
			timelockProposer,
			timelockExecutor
		} = await loadFixture(getSigners);

		this.signers.deployer = deployer;
		this.signers.ownerMultiSig = ownerMultiSig;
		this.signers.pendingOwner = pendingOwner;
		this.signers.beneficiary = beneficiary;
		this.signers.revoker = revoker;
		this.signers.alice = alice;
		this.signers.bob = bob;
		this.signers.timelockAdmin = timelockAdmin;
		this.signers.timelockProposer = timelockProposer;
		this.signers.timelockExecutor = timelockExecutor;

		this.mocks = {} as Mocks;

		// this.mocks.mockJelly = await deployMockJelly(deployer);
		// this.mocks.mockAllocator = await deployMockAllocator(deployer);
		// this.mocks.mockVestingTeam = await deployMockVestingTeam(deployer);
		// this.mocks.mockVestingInvestor = await deployMockVestingInvestor(deployer);
		// this.mocks.mockMinterContract = await deployMockMinter(deployer);
		this.params = {} as Params;
		this.params.allocatorAddress = timelockAdmin.address;
		this.params.vestingTeamAddress = timelockProposer.address;
		this.params.vestingInvestorsAddress = timelockExecutor.address;
		this.params.minterAddress = timelockExecutor.address;
	});

	shouldBehaveLikeVesting();
	shouldBehaveLikeJellyTimelock();
	shouldBehaveLikeJellyGovernor();
	shouldBehaveLikeJellyToken();
});