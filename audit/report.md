# Introduction

A time-boxed practice security review of the **JellyVerse** protocol was done by **vani**.

# Disclaimer

A smart contract security review can never verify the complete absence of vulnerabilities. This is a time, resource and expertise bound effort where I try to find as many vulnerabilities as possible. I can not guarantee 100% security after the review or even if the review will find any problems with your smart contracts. Subsequent security reviews, bug bounty programs and on-chain monitoring are strongly recommended.

# About **JellyVerse**

TBF

## Observations

TBF

## Privileged Roles & Actors

TBF

# Severity classification

| Severity               | Impact: High | Impact: Medium | Impact: Low |
| ---------------------- | ------------ | -------------- | ----------- |
| **Likelihood: High**   | Critical     | High           | Medium      |
| **Likelihood: Medium** | High         | Medium         | Low         |
| **Likelihood: Low**    | Medium       | Low            | Low         |

**Impact** - the technical, economic and reputation damage of a successful attack

**Likelihood** - the chance that a particular vulnerability gets discovered and exploited

**Severity** - the overall criticality of the risk

# Security Assessment Summary

**_review commit hash_ - [bc27b5fe86e714a9266ea9cbc5c483a7381d7c1a](https://github.com/MVPWorkshop/jelly-verse-contracts/commit/bc27b5fe86e714a9266ea9cbc5c483a7381d7c1a)**

**_review commit hash_ governance contracts -[c9bf2c684df4dcb85222b53383648e5dbf9106ce](https://github.com/MVPWorkshop/jelly-verse-contracts/commit/c9bf2c684df4dcb85222b53383648e5dbf9106ce)**

**_review commit hash_ minter contract -[5ed44bbe4dc8a2cf93a5dcf1f808a35544b37529](https://github.com/MVPWorkshop/jelly-verse-contracts/commit/5ed44bbe4dc8a2cf93a5dcf1f808a35544b37529)**

**No fixes implemented.**

### Scope

The following smart contracts were in scope of the audit:

- `JellyToken.sol`
- `JellyTokenDeployer.sol`
- `DailySnapshot.sol`
- `OfficialPoolRegister.sol`
- `VestingLib.sol`
- `VestingLibChest.sol`
- `Chest.sol`
- `JellyGovernor.sol`
- `Governor.sol`
- `GovernorVotes.sol`
- `JellyTimelock.sol`
- `TimelockController.sol`
- `Minter.sol`

---

The following number of issues were found, categorized by their severity:

- High: 9 issues
- Medium: 6 issues
- Low: 7 issues
- Informational: 7 issues

# Findings Summary

| ID     | Title                                                                                          | Severity      |
| ------ | ---------------------------------------------------------------------------------------------- | ------------- |
| [H-01] | Faulty Randomness Generation                                                                   | High          |
| [H-02] | Hardcoded Block Time Dependency                                                                | High          |
| [H-03] | Underflow in `releasableAmount` Calculation                                                    | High          |
| [H-04] | Missing Input Validation in `stakeSpecial` Allows Excessive Voting Power                       | High          |
| [H-05] | No Minimum freezingPeriod Validation in `stakeSpecial` Enables Immediate Unstaking             | High          |
| [H-06] | Inaccurate Voting Power Calculation Due to Exclusion of `releasedAmount` in `calculatePower`   | High          |
| [H-07] | Absence of `extendFreezingPeriod` Validation Enables Immediate Unstaking                       | High          |
| [H-08] | Double Spending Vulnerability in `Governor`                                                    | High          |
| [H-09] | Unrestricted Proposer Role in `Timelock` Enables Governance Disruption                         | High          |
| [M-01] | Minting of `JellyToken` is centralized                                                         | Medium        |
| [M-02] | Burned Tokens Can Be Reissued by Minters                                                       | Medium        |
| [M-03] | `timeFactor` Initialization Risks                                                              | Medium        |
| [M-04] | Excessive Fee Settings Could Render Staking Protocol Inoperable                                | Medium        |
| [M-05] | Lack of vestingPosition Validation in `estimateChestPower` Risks Inaccurate Power Calculations | Medium        |
| [M-06] | Incomplete Voting Power                                                                        | Medium        |
| [L-01] | Missing input validation in constructor                                                        | Low           |
| [L-02] | Missing input validation in `premint`                                                          | Low           |
| [L-03] | No Check for Duplicate Pool Registration                                                       | Low           |
| [L-04] | Wasteful Pool Registration Logic                                                               | Low           |
| [L-05] | Redundant Pool Struct                                                                          | Low           |
| [L-06] | Redirecting `unstake` Withdrawals to Predefined Beneficiary                                    | Low           |
| [L-07] | Removal of Redundant Functions                                                                 | Low           |
| [L-08] | Missing Input Validation in `Minter` Constructor                                               | Low           |
| [L-09] | Missing Input Validation in `Minter` set functions                                             | Low           |
| [L-10] | Missing Input Validation in `Minter` for weight and beneficiary                                | Low           |
| [L-11] | Wasteful Beneficiary Set Logic                                                                 | Low           |
| [I-01] | Suboptimal Storage Layout                                                                      | Informational |
| [I-02] | Suboptimal Storage Layout for Struct                                                           | Informational |
| [I-03] | Redundant Check in `calculateBooster`                                                          | Informational |
| [I-04] | Unnecessary Initialization of Unused values                                                    | Informational |
| [I-05] | Redundant Storage Updates in `increaseStake` and `unstake` Functions                           | Informational |
| [I-06] | Suboptimal Storage Layout for Struct in `Minter`                                               | Informational |
| [I-07] | Suboptimal Storage Layout in `Minter`                                                          | Informational |
| [I-08] | `Minter` Code Style should follow official Solidity style guide                                | Informational |
| [I-09] | Potential Gas Limit Issues Due to Unbounded Beneficiary Array                                  | Informational |
| [I-10] | Code Style Enhancements                                                                        | Informational |

# [H-01] Faulty Randomness Generation

Use of `block.prevrandao` as random seed, depends heavily on the selected chain.

## Recommendations

Consider using a decentralized oracle for the generation of random numbers. If `DailySnapshot` data is solely for off-chain purposes, consider moving the entire process off-chain to avoid on-chain manipulation, as the data isn't utilized within the smart contract itself.

# [H-02] Hardcoded Block Time Dependency

The contract assumes a fixed number of blocks per day (`ONE_DAY = 7200`), which is a brittle design choice because block times can vary and change. This can lead to inaccuracies in determining the start of a new day.

## Recommendations

Replace the reliance on block numbers with Unix timestamps, which are consistent and independent of block time variability.

# [H-03] Underflow in `releasableAmount` Calculation

## Severity

**Impact:**
High, as this underflow can cause the releasableAmount function to revert, potentially disrupting the intended vesting mechanics.

**Likelihood:**
Medium, depends on the usage of the vesting library. If positions are not updated, the problem won't exist.

## Descripton

An underflow occurs in the `releasableAmount` function when a vesting position's total amount is increased after some tokens have been released. The test case demonstrates this by creating a vesting position, releasing part of the vested tokens, and then updating the position with an increased total vested amount and a new future cliff. When releasableAmount is called after the new cliff, the calculation underflows because it subtracts the previously released amount from the newly vested amount, which is not yet greater than the released amount due to the vesting schedule reset.

```solidity
function test_vestingLib() external {
    address beneficiary = msg.sender;
    uint256 amount = 1000;
    uint32 cliffDuration = 100;
    uint32 vestingDuration = 100;

    uint256 withrawAmount = 500;

    // Initial position state
    // totalVestedAmount = 1000
    // releasedAmount = 0
    // cliffDuration = 100
    // vestingDuration = 100
    VestingLib.VestingPosition memory vestingPosition =
        createVestingPosition(amount, beneficiary, cliffDuration, vestingDuration);
    uint256 positionIndex = index - 1;

    vm.warp(vestingPosition.cliffTimestamp + vestingDuration);

    updateReleasedAmount(0, withrawAmount);

    // Now imagine update of position happens
    vestingPositions[positionIndex].totalVestedAmount += amount; // totalVestedAmount is now 2x amount
    vestingPositions[positionIndex].cliffTimestamp = uint48(block.timestamp + cliffDuration);

    vm.warp(vestingPositions[positionIndex].cliffTimestamp + 1);
    vm.expectRevert();
    uint256 releasableAmount = releasableAmount(0);
}
```

## Recommendations

Ensure that any updates to vesting positions properly handle previously released amounts to prevent underflow.

# [H-04] Missing Input Validation in `stakeSpecial` Allows Excessive Voting Power

## Severity

**Impact:**
High, as user can obtain excessive voting power.

**Likelihood:**
High, as there are no limitations on inputs.

## Description

Currently, the `stakeSpecial` function lacks proper validation for the `vestingDuration` and `nerfParameter` inputs. This oversight permits users to input the maximum allowable values for these parameters, resulting in disproportionately high voting power, even when staking the minimum required amount.

## Recommendations

Implement input validation to restrict the `vestingDuration` to a predefined maximum value and constrain the `nerfParameter` within a range of 0 to 10, to match the nerf scaling factor of 10.

# [H-05] No Minimum freezingPeriod Validation in `stakeSpecial` Enables Immediate Unstaking

## Severity

**Impact:**
High, as users can stake, vote, and unstake in rapid succession, undermining governance mechanism.

**Likelihood:**
Medium, as malicious actor would need to frontrun governance proposal.

## Description

Currently, the `stakeSpecial` function lacks proper validation for the `freezingPeriod` which allows users to stake, vote, and unstake in rapid succession, undermining governance mechanism.

## Recommendations

Add minimum `freezingPeriod` check.

# [H-06] Inaccurate Voting Power Calculation Due to Exclusion of releasedAmount in calculatePower

## Severity

**Impact:**
High, The calculation error leads to incorrect voting power.

**Likelihood:**
High, The incorrect value is consistently used in the calculation.

## Description

In the `calculatePower` function, the `totalVestedAmount` is incorrectly utilized as the staked amount, which does not accurately represent the total funds because it excludes the `releasedAmount`.

## Recommendations

Include `releasedAmount` in calculation.

```diff
-   vestingPosition.totalVestedAmount
+   vestingPosition.totalVestedAmount -  vestingPosition.releasedAmount
```

# [H-07] Absence of extendFreezingPeriod Validation Enables Immediate Unstaking

## Severity

**Impact:**
High, as users can stake, vote, and unstake in rapid succession, undermining governance mechanism.

**Likelihood:**
High, as there are no limitations on inputs.

## Description

The function `increaseStake` fails to properly validate the `extendedFreezingPeriod` when dealing with an open chest. In scenarios where the chest is open and a user attempts to reactivate it, the `extendedFreezingPeriod` should be set to at least `MIN_FREEZING_PERIOD_REGULAR_CHEST`.

## Recommendations

Implement a check to ensure the `extendedFreezingPeriod` meets the minimum required value for such circumstances.

# [H-08] Double Spending Vulnerability in `Governor`

## Severity

**Impact**: High, Users can potentially vote multiple times with the same tokens.

**Likelihood**: High, The current system does not prevent token reuse for voting.

## Description

The `Governor` contract's `propose` and `proposeCustom` functions use `lastChestId` to determine the last eligible `Chest` for voting. However, the `snapshot` only marks the start of the voting period (including delay) and does not capture the state of `Chest` positions at that time. This gap allows users to alter their `Chests` to gain additional voting power during the voting process. Moreover, it creates an opportunity for double spending, where a user votes with one `Chest`, then transfers tokens to another `Chest` after it becomes available within the voting window, and votes again.

## Recommendations

Introduce a robust snapshot mechanism that captures the state of `Chest` holdings at the proposal's snapshot time. Alternatively, restrict voting to `Chests` that are locked for the duration of the proposal's voting period, preventing the transfer of tokens and subsequent double voting.

# [H-09] Unrestricted Proposer Role in Timelock Enables Governance Disruption

## Severity

**Impact**: High, Allows any user to create or cancel proposals, leading to potential protocol disruption.

**Likelihood**: High, No current safeguards against malicious activity.

## Description

The deployment script incorrectly sets the proposers array to include `address(0)`, effectively granting proposal creation and cancellation rights to any address. This oversight permits any user to interfere with the governance process, including the ability to cancel legitimately voted proposals or to schedule unauthorized operations.

## Recommendations

Restrict the proposer role exclusively to the `Governor` contract to ensure only legitimate governance actions are executable. Remove `address(0)` from the proposers array to prevent unauthorized proposal management.

# [M-01] Minting of `JellyToken` is centralized

## Severity

**Impact:**
High, as token supply can be minted to cap value at any moment.

**Likelihood:**
Low, as it requires a malicious or compromised admin/minter

## Description

Currently the `mint` method in `JellyToken` is controlled by `MINTER_ROLE`. Minter roles are controlled by the `DEFAULT_ADMIN_ROLE` which is given to the `_defaultAdminRole` on deployment. This means that if the admin or minter account is malicious or compromised it can decide to mint token supply to cap which would lead to a loss of funds for users.

## Recommendations

Give those roles only to contracts that have a Timelock mechanism so that users have enough time to exit their `JellyToken` positions if they decide that they don't agree with a transaction of the admin/minter.

# [M-02] Burned Tokens Can Be Reissued by Minters

This issue permits any entity with the `Minter` role to re-mint tokens that have been previously burned. This could affect scenarios like a presale where unsold tokens are burned, as they might be re-minted later. It's important to verify within the tokenomics whether the cap refers to the circulating supply or the total minted supply.

# [M-03] timeFactor Initialization Risks

## Severity

**Impact:**
High, An incorrect assignment of timeFactor can result in erroneous calculations of booster or voting power values.

**Likelihood:**
Low, The issue arises only if the deployer inputs an incorrect value.

## Description

The `i_timeFactor` is an immutable variable initialized in the constructor, where its value is not validated. It should perpetually be set to `7 days`. Any deviation due to incorrect initialization can lead to inaccurate calculations for booster or voting power.

## Recommendations

Change `i_timeFactor` from an immutable variable to a constant to ensure its value remains correct

```diff
- uint256 immutable i_timeFactor
+ uint256 constant TIME_FACTOR = 7 days;
```

# [M-04] Excessive Fee Settings Could Render Staking Protocol Inoperable

## Severity

**Impact:**
High, Configuring the fee to an excessively high value could render the protocol unusable.

**Likelihood:**
Low, Implementing such a change requires a successful governance vote, and malicious actors would likely devalue the protocol.

## Description

The `setFee` function lacks an upper limit for the `fee_` parameter, allowing it to be set to `type(uint128).max`. Such an extreme setting could effectively disrupt the protocol, as staking would necessitate stakers to possess an amount exceeding the total token supply, rendering the staking function inaccessible.

## Recommendations

Implement an upper limit for the fee to prevent excessively high values.

# [M-05] Lack of vestingPosition Validation in `estimateChestPower` Risks Inaccurate Power Calculations

## Severity

**Impact:**
High, The function `calculatePower` assumes that a valid `vestingPosition` is provided, but without proper validation, this assumption may lead to miscalculated power estimates for unrealistic vesting positions.

**Likelihood:**
Low, this issue requires the caller to intentionally input invalid values.

## Description

The function `estimateChestPower` does not perform validation checks on the `vestingPosition` input parameters. This omission can result in the calculation of power estimates for non-existent or invalid vesting positions, potentially leading to erroneous outputs.

## Recommendations

Incorporate validation checks for the `vestingPosition` input to ensure only realistic and valid positions are processed.

# [M-06] Incomplete Voting Power

## Severity

**Impact:**
Medium, Users may not fully leverage their voting power.

**Likelihood:**
Medium, Depends on provided input parameters and number of chests(gas limit).

## Description

The `_getVotes` function requires users to input an array of `Chest` IDs to calculate their voting power. If a user doesn't include all owned `Chest` IDs or owns a large number of `Chests`, they may be unable to vote with their full entitlement as `hasVoted` is set on first vote.

## Recommendations

Consider implementing a one-chest-per-account functionallity so users can fully leverage their voting power without manual enumeration. This change simplifies the governance mechanism and avoids potential gas limitations. However, it may require users to manage multiple accounts if they wish to own more than one chest. Evaluate the impact on user experience and the protocol's objectives before proceeding with this change.

# [L-01] Missing Input Validation in Constructor

The `_defaultAdminRole `is a critical parameter in the `JellyToken` contract, initialized in the constructor. Assigning a address zero to this parameter would require re-deployment.

```diff
+ if (_defaultAdminRole == address(0)) {
+   revert CustomError();
+ }
```

# [L-02] Missing Input Validation in Premint Function

The `_minterContract `is a parameter passed in the `JellyToken` contract in the `premint` function. Assigning a role to address zero would require doing the action again.

```diff
+ if (_minterContract == address(0)) {
+   revert CustomError();
+ }
```

# [L-03] No Check for Duplicate Pool Registration

The `registerOfficialPool` function doesn't prevent registering a pool more than once. Add a check to avoid duplicates.

# [L-04] Wasteful Pool Registration Logic

Updating the list of official pools requires clearing and re-adding all pools, which is inefficient. Improve the update process to modify only what's necessary.
Check `OfficialPoolsRegisterNew.sol` implementation for reference.

# [L-05] Redundant Pool Struct

The `Pool` struct is not effectively used. Remove it if the `weight` field is unnecessary, and simplify the pool registration process.

# [L-06] Redirecting unstake Withdrawals to Predefined Beneficiary

The `unstake` function currently allows an approved account to withdraw funds to their own address. A design reconsideration could involve sending these funds directly to the originally specified beneficiary, enhancing predictability and security in fund management, especially in scenarios where account permissions are delegated.

# [L-07] Removal of Redundant Functions

The functions `castVote`, `castVoteBySig`, `castVoteWithReason` and `getVotes` are not usable in their current form as they do not provide an array of `Chest IDs`, which is necessary for calculating the voting power of a user. These functions should be removed to avoid confusion and potential misuse.

# [L-08] Missing Input Validation in `Minter` Constructor

The `_jellyToken` and `_stakingRewardsContract` are critical parameters in the `Minter` contract, initialized in the constructor. Assigning a address zero to these parameters would require re-deployment.

```diff
+ if (_jellyToken == address(0) || _stakingRewardsContract == address(0)) {
+   revert CustomError();
+ }
```

# [L-09] Missing Input Validation in `Minter` set functions

The `setStakingRewardsContract` and `setMintingPeriod` functions assign critical contract parameters based on the provided input values. Ensure these values are not `address(0)` and that the minting period is neither 0 nor an excessively long duration. Such conditions could allow for continuous token minting or restrict it to vast time intervals, thereby disrupting the tokenomics.

```diff
+ if newStakingRewardsContract_ == address(0) {
+   revert CustomError();
+ }

+ if _mintingPeriod == 0 || _mintingPeriod > MAX_MINTING_PERIOD {
+   revert CustomError();
+ }
```

# [L-10] Missing Input Validation in `Minter` for weight and beneficiary

Ensure that in the `setBeneficiaries` function, both the `weight` parameter and the `beneficiary` address are properly validated. The weight must be within the `0-1000` range to prevent issuing an unreasonably large number of tokens. Additionally, verify that the beneficiary address is not `address(0)`, as minting tokens to the zero address would be futile and could disrupt the intended distribution mechanism. It's also critical to check if a `beneficiary` already exists in the list. Allowing duplicate entries could lead to unintended token allocations, potentially skewing the distribution of minted tokens.

# [L-11] Wasteful Beneficiary Set Logic

Updating the beneficiary list by deleting and re-adding everyone is not efficient. It’s better to just update what needs changing. Also, avoid using the viaIR compiler option to bypass code limitations; it makes things compile slower. Instead of copying the whole array at once, add or update beneficiaries one by one. This avoids the need for viaIR and keeps the contracts compiling smoothly. Using `push` also makes using viaIR obsolete.

# [I-01] Suboptimal Storage Layout

The contract's storage layout is suboptimal, with `beginningOfTheNewDayBlocknumber` unnecessarily consuming a full 32-byte storage slot. Reducing `epoch` and `beginningOfTheNewDayBlocknumber` types to uint40 allows for tighter packing of these state variables.

```diff
-uint48 public epoch;
+uint40 public epoch;
-uint48 public beginningOfTheNewDayBlocknumber;
+uint40 public beginningOfTheNewDayBlocknumber;
```

# [I-02] Suboptimal Storage Layout for Struct

The original order of fields within the `VestingPosition` struct is not optimized. By rearranging the fields to group variables of similar types and sizes together, we can minimize storage slots used and reduce gas costs for contract operations involving this struct.

```diff
- struct VestingPosition {
-   address beneficiary;
-   uint256 totalVestedAmount;
-   uint256 releasedAmount;
-   uint48 cliffTimestamp;
-   uint32 vestingDuration;
- }

+struct VestingPosition {
+   uint256 totalVestedAmount;
+   uint256 releasedAmount;
+   address beneficiary;
+   uint48 cliffTimestamp;
+   uint32 vestingDuration;
+ }
```

# [I-03] Redundant Check in `calculateBooster`

Booster is not included in special chests calculations.

```diff
-   if (vestingPosition.vestingDuration > 0) {
-            // special chest
-            return INITIAL_BOOSTER;
-        }
```

# [I-04] Unnecessary Initialization of Unused values

In the `stake` and `stakeSpecial` functions, the `nerfParameter` and `booster` values are initialized with non-zero default values. This initialization is redundant since these variables are not utilized in subsequent calculations or logic within these functions.

# [I-05] Redundant Storage Updates in increaseStake and unstake Functions

The `increaseStake` function unnecessarily updates storage values when the `amount` or `extendFreezingPeriod` is zero. Similarly, `unstake` function updates `accumulatedBooster` and `boosterTimestamp` even when no actual change occurs. These redundant operations can waste gas.

# [I-06] Suboptimal Storage Layout for Struct in `Minter`

The original order of fields within the `VestingPosition` struct is not optimized. By rearranging the fields to group variables of similar types and sizes together, we can minimize storage slots used and reduce gas costs for contract operations involving this struct.

```diff
  struct Beneficiary {
        address beneficiary;
-        uint256 weight; //BPS
    }

  struct Beneficiary {
        address beneficiary;
+        uint96 weight; //BPS
    }
```

# [I-07] Suboptimal Storage Layout in `Minter`

The contract's storage layout is suboptimal, with `_jellyToken` unnecessarily consuming a full 32-byte storage slot. Reducing timestamps types allows packing of state variables into single slot instead of six slots.

```diff
-address public _jellyToken;
+address immutable jellyToken // or address constant jellyToken
```

```diff
-uint256 public _mintingStartedTimestamp;
-address public _stakingRewardsContract;
- uint256 public _lastMintedTimestamp;
- uint256 public _mintingPeriod = 7 days; // i has setter

+ uint32 public mintingStartedTimestamp;
+ address public stakingRewardsContract;
+ uint32 public lastMintedTimestamp
+ uint24 public mintingPeriod = 7 days;
```

# [I-08] `Minter` Code Style should follow official Solidity style guide

- **Naming Conventions for Visibility**: Public variables should not use underscores in their names. This convention is typically reserved for private or internal variables to differentiate them from public ones, improving code clarity and readability.

- **Function Visibility Optimization**: The `calculateMintAmount` function's visibility should be changed to `public` to avoid indirect calls using `this.calculateMintAmount`. Direct access to functions within the contract is more gas efficient and simplifies the code.

- **Efficient Use of Variables**: It's recommended to utilize `mintAmountWithDecimals` in place of `mintAmount` to eliminate redundant calculations.

- **Code Clarity and Readability**: To enhance the contract's readability, use either `currentTimestamp` or `block.timestamp`.

- **Clean Code Practices**: Unnecessary comments, especially those indicating potential future code paths like "maybe check size," should be removed if they're not part of the immediate implementation plan. Use `IERC20(jellyToken).functionName()` consistently instead of mixing it with `jellyToken(_jellyToken).functionName()`.

# [I-09] Potential Gas Limit Issues Due to Unbounded Beneficiary Array

Having unbounded `beneficiaries` in the `Minter` contract could cause minting to fail, as it may exceed the maximum gas limit. To prevent this, it's recommended to set a maximum length for the array, taking into account gas consumption.

# [I-10] Code Style Enhancements

- Replace hardcoded magic numbers with named constants for better code clarity.
- Use IJellyToken/IERC20 instead of IERC20(address) in `Chest`
- Correct spelling errors, such as changing "Snapshoting" to "Snapshotting," for consistency and professionalism.
- Utilize the import { } from syntax to maintain clean and organized code imports.
- Follow the official Solidity style guide. The current declaration style in `VestingLib/VestingLibChest` lacks consistency and does not align with the recommended guidelines.
- Pass the `VestingPosition` struct to the `vestedAmount` function in `VestingLib/VestingLibChest` instead of the index to avoid code duplication.
- Change function reference parameters in external functions from memory to calldata.
- Improve NatSpec, more detailed descriptions/explanations.
- Use same License Identifier and compiler versions across codebase.
- Lower number of local variables in `propose` and `proposeCustom` or make internal function to remove need of viaIR.
