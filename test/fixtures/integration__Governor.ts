import { ethers } from "hardhat";
import { BigNumber, utils } from "ethers";
import { getSigners } from "../shared/utils";
import { Signers } from "./types";
import {
    JellyGovernor,
    JellyGovernor__factory,
    JellyTimelock,
    JellyTimelock__factory,
    JellyToken,
    JellyToken__factory,
    Chest,
    Chest__factory,
    StakingRewardDistribution,
    StakingRewardDistribution__factory,
    LiquidityRewardDistribution,
    LiquidityRewardDistribution__factory,
    OfficialPoolsRegister,
    OfficialPoolsRegister__factory,
    Minter,
    Minter__factory

} from "../../typechain";

type IntegrationJellyGovernorFixtureType = {
    jellyGovernor: JellyGovernor;
    jellyToken: JellyToken;
    jellyTimelock: JellyTimelock;
    chest: Chest;
    stakingRewardDistribution: StakingRewardDistribution;
    liqiuidityRewardDistribution: LiquidityRewardDistribution;
    officialPoolsRegister: OfficialPoolsRegister;
    minter: Minter;
    votingDelay: BigNumber;
    votingPeriod: BigNumber;
    proposalThreshold: BigNumber;
    quorum: BigNumber;
    minTimelockDelay: BigNumber;
    proposers: string[];
    executors: string[];
};
export async function integrationJellyGovernorFixture(): Promise<IntegrationJellyGovernorFixtureType> {
    const ONE_DAYS_IN_SOLIDITY = BigNumber.from("86400");
    const ONE_WEEK_IN_SOLIDITY = BigNumber.from("604800");
    const ADDRESS_ZERO = ethers.constants.AddressZero;

    const {
        deployer,
        alice,
        timelockProposer,
        bob,
        timelockExecutor,
        timelockAdmin,
        allocator,
        distributor
    } = await getSigners();

    const fee = BigNumber.from("10"); // 10 wei
    const maxBooster = utils.parseEther("2"); // 2e18
    const timeFactor = ONE_WEEK_IN_SOLIDITY; // 7 days in seconds

    const votingDelay = BigNumber.from("7200"); // 7200 blocks
    const votingPeriod = BigNumber.from("50400"); // 1 week
    const proposalThreshold = BigNumber.from("0"); // anyone can create a proposal
    const quorum = BigNumber.from("1001"); // 1001
    const minTimelockDelay = ONE_DAYS_IN_SOLIDITY;
    const proposers: string[] = [];
    const executors: string[] = [];

    const jellyTokenFactory: JellyToken__factory =
        await ethers.getContractFactory("JellyToken");
    const jellyToken: JellyToken = await jellyTokenFactory
        .connect(deployer)
        .deploy(deployer.address);
    await jellyToken.deployed();

    const jellyTimelockFactory: JellyTimelock__factory =
        await ethers.getContractFactory("JellyTimelock");
    const jellyTimelock: JellyTimelock = await jellyTimelockFactory
        .connect(deployer)
        .deploy(minTimelockDelay, proposers, executors, deployer.address);
    await jellyTimelock.deployed();

    const chestFactory: Chest__factory = await ethers.getContractFactory(
        "Chest"
    );
    const chest: Chest = await chestFactory
        .connect(deployer)
        .deploy(
            jellyToken.address,
            allocator.address,
            distributor.address,
            fee,
            maxBooster,
            timeFactor,
            deployer.address,
            jellyTimelock.address
        );
    await chest.deployed();

    const stakingRewardDistributionFactory: StakingRewardDistribution__factory =
        await ethers.getContractFactory("StakingRewardDistribution");
    const stakingRewardDistribution: StakingRewardDistribution =
        await stakingRewardDistributionFactory
            .connect(deployer)
            .deploy(jellyToken.address, jellyTimelock.address, ADDRESS_ZERO);
    await stakingRewardDistribution.deployed();

    const liqiuidityRewardDistributionFactory: LiquidityRewardDistribution__factory =
        await ethers.getContractFactory("LiquidityRewardDistribution");
    const liqiuidityRewardDistribution: LiquidityRewardDistribution =
        await liqiuidityRewardDistributionFactory
            .connect(deployer)
            .deploy(jellyToken.address, jellyTimelock.address, ADDRESS_ZERO);
    await liqiuidityRewardDistribution.deployed();

    const officialPoolsRegisterFactory: OfficialPoolsRegister__factory =
        await ethers.getContractFactory("OfficialPoolsRegister");
    const officialPoolsRegister: OfficialPoolsRegister = await officialPoolsRegisterFactory
        .connect(deployer)
        .deploy(jellyTimelock.address, ADDRESS_ZERO);
    await officialPoolsRegister.deployed();

    const minterFactory: Minter__factory = await ethers.getContractFactory(
        "Minter"
    );
    const minter: Minter = await minterFactory
        .connect(deployer)
        .deploy(jellyToken.address, liqiuidityRewardDistribution.address, stakingRewardDistribution.address, jellyTimelock.address, ADDRESS_ZERO);
    await minter.deployed();

    const jellyGovernorFactory: JellyGovernor__factory =
        await ethers.getContractFactory("JellyGovernor");
    const jellyGovernor: JellyGovernor = await jellyGovernorFactory
        .connect(deployer)
        .deploy(chest.address, jellyTimelock.address);
    await jellyGovernor.deployed();

    const TIME_LOCK_ADMIN_ROLE = await jellyTimelock.TIMELOCK_ADMIN_ROLE();
    const CANCELLER_ROLE = await jellyTimelock.CANCELLER_ROLE();
    const PROPOSER_ROLE = await jellyTimelock.PROPOSER_ROLE();
    const EXECUTOR_ROLE = await jellyTimelock.EXECUTOR_ROLE();

    await jellyTimelock
        .connect(deployer)
        .grantRole(CANCELLER_ROLE, jellyGovernor.address);

    await jellyTimelock
        .connect(deployer)
        .grantRole(PROPOSER_ROLE, jellyGovernor.address);

    await jellyTimelock
        .connect(deployer)
        .grantRole(EXECUTOR_ROLE, ADDRESS_ZERO);

    await jellyTimelock
        .connect(deployer)
        .revokeRole(TIME_LOCK_ADMIN_ROLE, deployer.address);

    return {
        jellyGovernor,
        jellyToken,
        jellyTimelock,
        chest,
        stakingRewardDistribution,
        liqiuidityRewardDistribution,
        officialPoolsRegister,
        minter,
        votingDelay,
        votingPeriod,
        proposalThreshold,
        quorum,
        minTimelockDelay,
        proposers,
        executors,
    };
}
