---
title: Tranche Sequence
description: A tranche sequence refers to a series of payment opportunities that occur at specified time intervals.

author: Anwar Alruwaili @pcanwar <ipcanw@gmail.com>, Shaun Cole @secole1
discussions-to: https://github.com/pcanwar/TrancheSequence
status: Draft
type: Standards Track
category: ERC # Only required for Standards Track. Otherwise, remove this field.
created: 2020
# requires: <EIP number(s)> # Only required when you reference an EIP in the `Specification` section. Otherwise, remove this field.
---

## Abstract:

This concept is extended through a library that builds on ERC20, ERC721, and other standards, offering a transparent and structured approach to on-chain time management. With the help of additional functions, the library enables stakeholders to define time milestones and a sequence of opportunities to evaluate and decide on the next steps.

## Motivation:

The motivation behind this library is to overcome the challenges of managing multi-stage projects or use cases on utility tokens or NFTs while providing a fair and transparent approach to on-chain time management. This structured approach facilitates effective smart contract management and enables stakeholders to progress and make informed decisions. The library can be applied to various use cases, such as salary negotiations, project funding, or resource allocation, promoting trust and collaboration among stakeholders. The library's flexibility and transparency can result in a fairer and more effective decision-making process for all parties involved.

The following properties make tranche sequences an effective tool for managing multi-stage use cases and projects on utility tokens or NFTs in a structured and transparent manner:

### Features

Flexible Time Units: The library allows you to define time in various units: minutes, hours, days, and weeks. This enables flexibility when dealing with different periods.

Customizable Tranches: The library is built around tranches or blocks of time that can be used to represent milestones. These tranches can be initialized according to your needs.

Dynamic Time Sequencing: It enables dynamic time sequencing. The time sequence can be increased based on the existing series in the smart contract.

Rest Time Inclusion: The library includes a feature for a rest time on the sequence. This offers flexibility for stakeholders, allowing for pauses or intervals between different time sequences.

Time Extension: The library allows for the time of a particular sequence to be increased if needed. This is particularly useful when an ongoing event or process needs an extended time duration.

Immutable Time Entries: Once a timestamp is added, it cannot be removed or modified. This feature offers immutability for time entries, ensuring the integrity and reliability of the time sequences.

Milestone Tracking: The library provides utilities to track milestones and understand their progress. You can get the number of completed and missed milestones, check if the current timestamp is within a milestone, and even forcibly advance to the next milestone.

Timestamp Reporting: The library provides utilities for reporting missed timestamps, getting the start and end times of the current milestone, and listing all missing timestamps since the last completed milestone.

Force Increase of Milestones: If needed, milestones can be forcibly advanced manually, regardless of whether they're currently extendable.

Start Time Customization: The library allows the initialization of milestones with a custom start time instead of the current block timestamp, which can be helpful for specific project timelines.

Effective Milestone Management: Functions such as resetMileStone, isCurrentMilestone, isMilestoneStarted, and isMilestoneExpired provide the ability to effectively manage milestones, including initiating, resetting, tracking, and identifying the completion of a milestone.

Precision and Accuracy: The library uses block.timestamp for timekeeping, which ensures precise and accurate timestamps for all operations. This accuracy is essential for a fair and accurate representation of project progress.


### Tech

- InitMileStone function should be init in the smart contract constructor and also after reset the milestone

## Specification

Library

NOTE:

The following specifications use syntax from Solidity 0.7.0 (or above).

initTranches

Initializes the tranches with a sequence of timestamps.

```js 
function initTranches(uint256[] memory _sequence) public 
```

addTranche
Adds a new tranche to the sequence.

```js
function addTranche(uint256 _timestamp) public returns (bool success)

```

extendTranche
Extends the time of a particular tranche.

```js
function extendTranche(uint256 _index, uint256 _additionalTime) public returns (bool success)
```

listMissingTimestamps

Lists all the missing timestamps from the last completed milestone.

```js
function listMissingTimestamps() public view returns (uint256[] memory)
```

nextMilestone
Returns the timestamp of the next milestone.

```js
function nextMilestone() public view returns (uint256)
```

isCurrentMilestone
Checks if the current timestamp is within a milestone.

```js
function isCurrentMilestone(uint256 _timestamp) public view returns (bool)
```

isMilestoneStarted
Checks if a milestone has started.

```js 
function isMilestoneStarted(uint256 _index) public view returns (bool)
```

isMilestoneExpired

Checks if a milestone has expired.

```js
function isMilestoneExpired(uint256 _index) public view returns (bool)

```
forceMilestone
Forcibly advance to the next milestone.

```js
function forceMilestone(uint256 _index) public 
```


### Events

TrancheAdded
MUST trigger when a new tranche is added.

```js
event TrancheAdded(uint256 _timestamp)
```

TrancheExtended
MUST trigger when a tranche is extended.


```js
event TrancheExtended(uint256 _index, uint256 _additionalTime)

```

MilestoneForced
MUST trigger when a milestone is forcibly advanced.

```js
event MilestoneForced(uint256 _index)

```






## Test Cases

```js
    // Define a custom error for when an extension is not allowed
    // Define the different time units
    enum TimeUnit {
        Minutes,
        Hours,
        Days,
        Weeks
    }

    // Structure for the library
    struct Data {
        uint256 startTime;
        uint256 endTime;
        uint256 tranche;
        uint256 extendTimeSequence;
    }

    ////////////////////////
    // Utility functions
    ////////////////////////

    /**
     * @dev Convert time units to seconds.
     */
    function convertTimeUnitToSeconds(
        TimeUnit timeUnit
    ) private pure returns (uint256) {
        // uint256 timeUint = 0;
        if (timeUnit == TimeUnit.Minutes) {
            return 1 minutes;
        } else if (timeUnit == TimeUnit.Hours) {
            return 1 hours;
        } else if (timeUnit == TimeUnit.Days) {
            return 1 days;
        } else if (timeUnit == TimeUnit.Weeks) {
            return 1 weeks;
        }
        revert("Invalid TimeUnit provided.");

        // return timeUint;
    }

    ////////////////////////////////////////////////
    // Initialization functions
    ////////////////////////////////////////////////

    /**
     * @dev Init MileStone
     *
     * @notice this should be run in the smart contract constructor and also after reset the milestone
     */
    function initMileStone(
        Data storage self, // Initialization storage ones
        uint256 newTranchePeriod,
        TimeUnit trancheTimeUnit,
        uint256 newExtendSequence,
        TimeUnit extendTimeUnit
    ) internal {
        // require(!ones.isStarted);
        // require(self.tranche > 0 && self.startTime <= block.timestamp);

        uint256 currentTime = uint256(block.timestamp);
        updateTranchePeriod(self, newTranchePeriod, trancheTimeUnit);
        updateExtendSequence(self, newExtendSequence, extendTimeUnit);
        // ones.isStarted = true;
        self.startTime = currentTime;
        self.endTime = currentTime + self.tranche;
        // self.tranche = self.tranche;
    }

    /**
     * @dev Initialize with Custom Start Time: A function to initialize the milestone with a custom start time instead of the current block timestamp.
     * This can be helpful if you want to start the milestones from a specific time in the past or future.
     */
    function initMileStoneWithCustomStartTime(
        Data storage self,
        // Initialization storage ones,
        uint256 customStartTime
    ) internal {
        // require(!ones.isStarted);
        require(
            self.tranche > 0 && customStartTime <= block.timestamp,
            "Invalid start time or tranche"
        );


        self.startTime = customStartTime;
        self.endTime = self.tranche + customStartTime;
    }

    /**
     * @dev Increase MileStone based on the exsiting MileStone in the contract.
     */

    function increaseMileStone(Data storage self) internal {
        require(isExtandable(self), "Not Extandable");
        uint256 currentTime = self.endTime;
        uint256 newStartTime = currentTime + getElapsedExcessTime(self);
        uint256 newEndTime = self.tranche + newStartTime;
        self.startTime = newStartTime;
        self.endTime = newEndTime;
    }

    ////////////////////////
    // Update functions
    ////////////////////////

    /**
     * @dev Update Tranche Period: to update the tranche period,
     * in case there's a need to change the tranche duration after the library has been deployed.
     */
    function updateTranchePeriod(
        Data storage self,
        uint256 newTranchePeriod,
        TimeUnit timeUnit
    ) private {
        require(newTranchePeriod > 0, "Tranche period must be positive");
        require(uint(timeUnit) <= 3, "Invalid time unit for tranche period");
        self.tranche = newTranchePeriod * convertTimeUnitToSeconds(timeUnit);
    }

    /**
     * @dev Update Extend Time Sequence: to update the extend time sequence,
     * allowing the contract administrator to change the time sequence after deployment.
     */
    function updateExtendSequence(
        Data storage self,
        uint256 newExtendSequence,
        TimeUnit timeUnit
    ) private {
        require(newExtendSequence > 0, "Extend sequence must be positive");
        require(uint(timeUnit) <= 3, "Invalid time unit for extend sequence");
        uint256 time = convertTimeUnitToSeconds(timeUnit);
        self.extendTimeSequence = newExtendSequence * time;
    }

```

```sh
    constructor(
        uint64 newTranchePeriod,
        uint64 newExtendSequence,
        TrancheSequence.TimeUnit UTNewTranchePeriod,
        TrancheSequence.TimeUnit UTnewExtendSequence
    ) {
        trancheData.initMileStone(
            newTranchePeriod,
            UTNewTranchePeriod,
            newExtendSequence,
            UTnewExtendSequence
        );
    }
```

- Increase MileStone based on the exsiting MileStone in the contract.

```sh
    function initMileStone(
        Data storage self, // Initialization storage ones
        uint64 newTranchePeriod,
        TimeUnit trancheTimeUnit,
        uint64 newExtendSequence,
        TimeUnit extendTimeUnit
    ) internal {
        // require(!ones.isStarted);
        // require(self.tranche > 0 && self.startTime <= block.timestamp);

        uint64 currentTime = uint64(block.timestamp);
        updateTranchePeriod(self, newTranchePeriod, trancheTimeUnit);
        updateExtendSequence(self, newExtendSequence, extendTimeUnit);
        // ones.isStarted = true;
        self.startTime = currentTime;
        self.endTime = currentTime + self.tranche;
        // self.tranche = self.tranche;
    }
```

- Pass the missing time at the end of the MileStone if there was no extended
  - it works only if there is no extanded occur or missing to increase the milestone..

```sh


```

## Backwards Compatibility
No backward compatibility issues found. Thus, the library is designed with high compatibility while aligning with existing contracts' structures and logic, so its design allows for usage in diverse contexts.


## Reference

Crowdfunding with Periodic Milestone Payments Using a Smart Contract to Implement Fair E-Voting


## Security Considerations

Considering the security considerations when using this library, you can mitigate potential risks and ensure a secure deployment:

Accurate Timekeeping: As the library relies heavily on timestamps for operation, accurate timekeeping is paramount. The blockchain's block.timestamp is used, which provides an accurate and secure time reference. However, it's still crucial to understand that validators could have a small discretion over its exact value.
Solidity Overflow and Underflow: The library must ensure that it correctly handles overflow and underflow conditions that might occur during arithmetic operations. This is particularly relevant during timestamp and tranche calculations.

Smart Contract Permissions: It's crucial to control who can call functions that modify the state of the library, such as extending time sequences, resetting milestones, etc. These functions should be restricted to avoid misuse by unauthorized entities.

Reentrancy Attacks: While the library functions provided in the given code snippet are not prone to reentrancy attacks, it's still important to consider this when further developing the library or integrating it with other contracts.

Testing and Auditing: Any developed smart contracts using this library should be thoroughly tested and audited to ensure no vulnerabilities could be exploited. This should include both automated testing and manual code review.

Gas Optimization: Functions should be optimized to consume as little gas as possible, reducing the cost for users and mitigating the possibility of transactions failing due to exceeding gas limits.


The provided functions in the library involve looping structures (```listMissingTimestamps```) but aren't expected to cause a DoS vulnerability based on how it's implemented. However, as a best practice, developers should always be mindful of potential DoS situations in the broader context when designing and implementing smart contracts.


## License

MIT
