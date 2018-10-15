```
EIP: <tbd>
Title: A process for finalizing Metropolis/Byzantium EIPs
Author: Casey Detrio
Type: Meta
Status: Draft
Created: 2017-08-14
```

## Abstract

To help coordinate the upcoming hard fork (Metropolis/Byzantium), a new status term `Complete (pending)` is introduced for use in a Finalization Table. Process guidelines for updating the Finalization Table are outlined.


## Specification

The Finalization Table includes the following column names and status terms:

* Specification:
  * **Finalized** - The specification is fully determined and ready for activation on the network, pending choice of the activation block.
  * **Complete (pending)** - The specification is pending a final decision on choice of gas costs or other constant parameters, but is otherwise not expected to change. It has at least two implementations, and test cases in the Test Suite. 
  * **Accepted** - The specification is undergoing initial implementation, and may change in response to feedback.
* Params (gas costs):
  * **Finalized** - Values for all parameters (except for the activation block) have been chosen in a final decision.
  * **Tentative** - Temporary values are being used in implementations to facilitate testing, pending a final decision.
* Test Suite and Yellow Paper:
  * **Updated** - A change has been made in accordance with a recent decision or clarification. Updates to the test suite include breaking changes (e.g. to reflect a decision to change gas costs), or the addition of new test cases.
  * **Waiting** - Waiting for an initial update or creation of test cases.
  * **(Inapplicable)** - Indicates that a column is not relevant to a particular EIP. For the Test Suite, EIPs that change block-level structures are only covered by Blockchain Tests.


### Example Finalization Table

| Number                                                  |Title                                                      | Specification           |  Params (gas costs)        | State Tests (Test Suite)                       | Blockchain and Other Tests (Test Suite)      | Yellow Paper                         |
| ------------------------------------------------------- | ----------------------------------------------------------| ----------------------- | ---------------------------| -----------------------------------------------| ---------------------------------------------| -------------------------------------|
| [155](https://github.com/ethereum/EIPs/issues/155)      | Simple replay attack protection                           | Accepted                |  Tentative                 |      Inapplicable                              | Updated [2016-11-07][155-txtest-11-07]       |     Waiting                          |
| [160][160-file]                                         | EXP cost increase                                         | Finalized (2016-10-29)  |  Finalized (2016-10-29)    |  Updated [2016-10-31][160-statetest-10-31]     | Updated [2017-02-01][160-blocktest-02-01]    | Updated [2017-07-10][160-yp-07-10]   |
| [161][161-file]                                         | State trie clearing (invariant-preserving alternative)    | Complete (pending)      |  Tentative                 |  Updated [2016-11-23][161-statetest-11-23]     |        Waiting                               |     Waiting                          |
| [170][170-file]                                         | Contract code size limit                                  | Complete (pending)      |  Tentative                 |  Updated [2016-11-14][170-statetest-11-14]     |        Waiting                               | Updated [2017-07-05][170-yp-07-05]   |


## Process guidelines for updating the Finalization Table

Note that this process only applies to Core EIPs, which require a hard fork for adoption.

* EIPs should begin as Pull Requests to add a file with `Draft` status
* The EIP number assigned by editors may or may not correspond to the Pull Request number on github. EIPs that were previously submitted as github issues may inherit the Issue number in their preamble.
* An EIP's status is upgraded to `Accepted` after a consensus decision at an AllCoreDevs meeting.
* Once an EIP is `Accepted`, it is listed in the Accepted Table in the README with a link to the pull request.
* EIPs undergoing active discussion remain as open PRs. This facilitates keeping the discussion/review cycle in one place (rather than fragmented across multiple PRs).
* An EIP's status is upgraded to `Complete` once it has been implemented in at least two clients and has corresponding test cases, and once the text is approved by an EIP editor.
* Editors should strive to ensure that an EIP's text meets the following standards before approving:
  * The EIP text should not include multiple versions (e.g. option A and option B); only the specification that corresponds to the implementations and test cases should be described.
  * The EIP text should resolve questions raised during review and implementation. For example, where someone asked for clarification on a certain point, the text should be edited to incorporate a clarifying statement.
  * The EIP text should specify the tentative values for all constants (except the activation block) used in implementations and tests, including assigned instructions (for opcodes), addresses (for precompiles), gas costs, etc.
* When an EIP is otherwise `Complete` but the text does not conform to the above standards, editors are expected to make the edits needed for approval.
* Once an EIP is `Complete`, it is merged (if still an open PR). All links to the EIP (e.g. from the README) are updated to reference the merged file.
* An EIP's status is upgraded from `Complete` to `Finalized` after a consensus decision at an AllCoreDevs meeting.
* Each update to the Finalization Table should be recorded in a Changelog.


### Example Changelog

#### 2016-11-01
- State Tests for EIP 160 (EXP cost increase) were [updated][160-statetest-10-31].

#### 2016-10-30
- Specification status for EIP 160 (EXP cost increase) upgraded to **Finalized**, per All Core Devs [2016-10-29 meeting](https://github.com/ethereum/pm/issues/1).

#### 2016-10-20
- Specification status for EIP 170 (Contract code size limit) upgraded to **Complete**, and [merged][170-file].

#### 2016-10-05
- Created Finalization Table for Spurious Dragon


## References

See also [EIP 233](https://github.com/ethereum/EIPs/pull/233) (Formal process of hard forks).


[160-file]: https://github.com/ethereum/EIPs/blob/master/EIPS/eip-160.md
[161-file]: https://github.com/ethereum/EIPs/blob/master/EIPS/eip-161.md
[170-file]: https://github.com/ethereum/EIPs/blob/master/EIPS/eip-170.md

[160-yp-07-10]: https://github.com/ethereum/yellowpaper/pull/281
[155-yp-03-31]: https://github.com/ethereum/yellowpaper/pull/282
[170-yp-07-05]: https://github.com/ethereum/yellowpaper/pull/290

[155-txtest-11-07]: https://github.com/ethereum/tests/commit/72eb9bf567af047aa521afb7a6edba32fd98db53

[160-statetest-10-31]: https://github.com/ethereum/tests/pull/126/commits/00dffea5dfe055b5c45efc197ed9e24e23ae44a7
[160-blocktest-02-01]: https://github.com/ethereum/tests/commit/8566f092c3f567a511d625329a7fa96c620f06b0

[161-statetest-11-23]: https://github.com/ethereum/tests/pull/126

[170-statetest-11-14]: https://github.com/ethereum/tests/commit/289b3e4524786618c7ec253b516bc8e76350f947


## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
