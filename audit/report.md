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

---

The following number of issues were found, categorized by their severity:

- High: 7 issues
- Medium: 5 issues
- Low: 6 issues
- Informational: 6 issues

# Findings Summary

| ID     | Title                                                                                          | Severity      |
| ------ | ---------------------------------------------------------------------------------------------- | ------------- |
| [H-01] | Faulty Randomness Generation                                                                   | High          |
| [H-02] | Hardcoded Block Time Dependency                                                                | High          |
| [H-03] | Underflow in `releasableAmount` Calculation                                                    | High          |
| [H-04] | Missing Input Validation in `stakeSpecial` Allows Excessive Voting Power                       | High          |
| [H-05] | No Minimum freezingPeriod Validation in `stakeSpecial` Enables Immediate Unstaking             | High          |
| [H-06] | Inaccurate Voting Power Calculation Due to Exclusion of releasedAmount in calculatePower       | High          |
| [H-07] | Absence of extendFreezingPeriod Validation Enables Immediate Unstaking                         | High          |
| [M-01] | Minting of `JellyToken` is centralized                                                         | Medium        |
| [M-02] | Burned Tokens Can Be Reissued by Minters                                                       | Medium        |
| [M-03] | timeFactor Initialization Risks                                                                | Medium        |
| [M-04] | Excessive Fee Settings Could Render Staking Protocol Inoperable                                | Medium        |
| [M-05] | Lack of vestingPosition Validation in `estimateChestPower` Risks Inaccurate Power Calculations | Medium        |
| [L-01] | Missing input validation in constructor                                                        | Low           |
| [L-02] | Missing input validation in premint                                                            | Low           |
| [L-03] | No Check for Duplicate Pool Registration                                                       | Low           |
| [L-04] | Wasteful Pool Registration Logic                                                               | Low           |
| [L-05] | Redundant Pool Struct                                                                          | Low           |
| [L-06] | Redirecting unstake Withdrawals to Predefined Beneficiary                                      | Low           |
| [I-01] | Suboptimal Storage Layout                                                                      | Informational |
| [I-02] | Suboptimal Storage Layout for Struct                                                           | Informational |
| [I-03] | Redundant Check in `calculateBooster`                                                          | Informational |
| [I-04] | Unnecessary Initialization of Unused values                                                    | Informational |
| [I-05] | Redundant Storage Updates in `increaseStake` and `unstake` Functions                           | Informational |
| [I-06] | Code Style Enhancements                                                                        | Informational |

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

# [I-06] Code Style Enhancements

- Replace hardcoded magic numbers with named constants for better code clarity.
- Use IJellyToken/IERC20 instead of IERC20(address) in `Chest`
- Correct spelling errors, such as changing "Snapshoting" to "Snapshotting," for consistency and professionalism.
- Utilize the import { } from syntax to maintain clean and organized code imports.
- Follow the official Solidity style guide. The current declaration style in `VestingLib/VestingLibChest` lacks consistency and does not align with the recommended guidelines.
- Pass the `VestingPosition` struct to the `vestedAmount` function in `VestingLib/VestingLibChest` instead of the index to avoid code duplication.
- Change function reference parameters in external functions from memory to calldata.
- Improve NatSpec, more detailed descriptions/explanations.
