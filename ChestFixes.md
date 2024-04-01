# Chest Bug Fixes from [audit-report](https://github.com/MVPWorkshop/jelly-verse-contracts/blob/feat/JELLY-936/audit/report.md)

# Findings Summary

| ID     | Title                                                                                          | Severity      | Status |
| ------ | ---------------------------------------------------------------------------------------------- | ------------- | ------ |
| [H-01] | Faulty Randomness Generation                                                                   | High          |        |
| [H-02] | Hardcoded Block Time Dependency                                                                | High          |        |
| [H-03] | Underflow in `releasableAmount` Calculation                                                    | High          |        |
| [H-04] | Missing Input Validation in `stakeSpecial` Allows Excessive Voting Power                       | High          |        |
| [H-05] | No Minimum freezingPeriod Validation in `stakeSpecial` Enables Immediate Unstaking             | High          |        |
| [H-06] | Inaccurate Voting Power Calculation Due to Exclusion of `releasedAmount` in `calculatePower`   | High          |        |
| [H-07] | Absence of `extendFreezingPeriod` Validation Enables Immediate Unstaking                       | High          |        |
| [H-08] | Double Spending Vulnerability in `Governor`                                                    | High          |        |
| [H-09] | Unrestricted Proposer Role in `Timelock` Enables Governance Disruption                         | High          |        |
| [H-10] | Token Ratio Does Not Support a Realistic Price Range                                           | High          |        |
| [M-01] | Minting of `JellyToken` is centralized                                                         | Medium        |        |
| [M-02] | Burned Tokens Can Be Reissued by Minters                                                       | Medium        |        |
| [M-03] | `timeFactor` Initialization Risks                                                              | Medium        | Fixed  |
| [M-04] | Excessive Fee Settings Could Render Staking Protocol Inoperable                                | Medium        |        |
| [M-05] | Lack of vestingPosition Validation in `estimateChestPower` Risks Inaccurate Power Calculations | Medium        |        |
| [M-06] | Incomplete Voting Power                                                                        | Medium        |        |
| [M-07] | Unsafe usage of ERC20 transferFrom/transfer                                                    | Medium        |        |
| [L-01] | Missing input validation in constructor                                                        | Low           |        |
| [L-02] | Missing input validation in `premint`                                                          | Low           |        |
| [L-03] | No Check for Duplicate Pool Registration                                                       | Low           |        |
| [L-04] | Wasteful Pool Registration Logic                                                               | Low           |        |
| [L-05] | Redundant Pool Struct                                                                          | Low           |        |
| [L-06] | Redirecting `unstake` Withdrawals to Predefined Beneficiary                                    | Low           |        |
| [L-07] | Removal of Redundant Functions                                                                 | Low           |        |
| [L-08] | Missing Input Validation in `Minter` Constructor                                               | Low           |        |
| [L-09] | Missing Input Validation in `Minter` set functions                                             | Low           |        |
| [L-10] | Missing Input Validation in `Minter` for weight and beneficiary                                | Low           |        |
| [L-11] | Wasteful Beneficiary Set Logic                                                                 | Low           |        |
| [L-12] | Missing Input Validation in `PoolParty` Constructor                                            | Low           |        |
| [L-13] | Missing Input Validation in `PoolParty` set function                                           | Low           |        |
| [I-01] | Suboptimal Storage Layout                                                                      | Informational |        |
| [I-02] | Suboptimal Storage Layout for Struct                                                           | Informational |        |
| [I-03] | Redundant Check in `calculateBooster`                                                          | Informational |        |
| [I-04] | Unnecessary Initialization of Unused values                                                    | Informational |        |
| [I-05] | Redundant Storage Updates in `increaseStake` and `unstake` Functions                           | Informational |        |
| [I-06] | Suboptimal Storage Layout for Struct in `Minter`                                               | Informational |        |
| [I-07] | Suboptimal Storage Layout in `Minter`                                                          | Informational |        |
| [I-08] | `Minter` Code Style should follow official Solidity style guide                                | Informational |        |
| [I-09] | Potential Gas Limit Issues Due to Unbounded Beneficiary Array                                  | Informational |        |
| [I-10] | Suboptimal Storage Layout in `PoolParty`                                                       | Informational |        |
| [I-11] | Add Sale Duration in `PoolParty`                                                               | Informational |        |
| [I-12] | Code Style Enhancements                                                                        | Informational |        |
