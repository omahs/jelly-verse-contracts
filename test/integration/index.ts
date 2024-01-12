import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { getSigners } from "../shared/utils";
import { Signers } from "../shared/types";
import { shouldBehaveLikeJellyGovernor } from "./JellyGovernor";

describe("Integration tests", async function () {
    before(async function () {
        const {
            deployer,
            alice,
            bob,
            timelockAdmin,
            timelockProposer,
            timelockExecutor,
        } = await loadFixture(getSigners);

        this.signers = {} as Signers;
        this.signers.deployer = deployer;
        this.signers.alice = alice;
        this.signers.bob = bob;
    });

    shouldBehaveLikeJellyGovernor();
});
