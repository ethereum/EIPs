# EIP-8288 benchmark protocol

This document gives the benchmark protocol for [EIP-8288](../../EIPS/eip-8288.md): the workloads, what each benchmark must show and what it reports. The EIP states which benchmarks are activation preconditions; this document does not add requirements beyond it. Counts marked provisional are fixed by the activating fork together with its proof format and verifier.

## Builder benchmark

### What is required

On reference hardware, the activating fork's reference construction retrieves required IL proofs and produces the block proof between the latest permitted list arrival, at view freeze, and the block's proposal deadline. Proofs must be verified and available to attesters earlier, by view freeze minus `IL_PROOF_CUTOFF_MARGIN_MS` (provisionally 1,000 ms), but a builder may learn which proofs the lists select only at view freeze. The benchmark covers network retrieval, every aggregation step and every input, including overlapping and discarded dependencies. Per-step fan-in, discard counts, step counts and work done ahead of the slot are parameters of the benchmarked construction, not circuit requirements.

The benchmark runs at the activation gas limit with headroom and again before any gas-limit increase, like any other gas-bound resource. It is a liveness precondition, not advisory: there is no per-block dependency cap, and a builder that cannot prove in time misses the slot. If the construction does not meet the deadline at the gas-derived count, proving rather than gas binds dependencies per block, and the gas costs or the gas limit must change before activation.

### Gas-derived count

A leanSPHINCS dependency costs `LEANSPHINCS_VERIFICATION_GAS + LEANSTARK_VERIFICATION_GAS` (33,000) gas and a leanSTARK dependency `2 * LEANSTARK_VERIFICATION_GAS` (60,000), so gas bounds `dependencies(block)` to fewer than `gas_limit` divided by those costs. The gas-derived count rounds these bounds up:

- leanSPHINCS: `ceil(gas_limit / (LEANSPHINCS_VERIFICATION_GAS + LEANSTARK_VERIFICATION_GAS))`;
- leanSTARK: `ceil(gas_limit / (2 * LEANSTARK_VERIFICATION_GAS))`.

| Gas limit | leanSPHINCS | leanSTARK |
| --------- | ----------- | --------- |
| 30M       | 910         | 500       |
| 60M       | 1,819       | 1,000     |
| 100M      | 3,031       | 1,667     |

The gas-derived count is a benchmark workload, not a valid block: every transaction also pays gas besides its dependencies, and 910 × 33,000 gas alone exceeds 30M. It bounds only the construction's output; its inputs' proofs can also cover dependencies of transactions the block omits.

### Running aggregate

Under [EIP-7805](../../EIPS/eip-7805.md), a builder can maintain a running aggregate ahead of the slot over the union of its validated mempool wrappers' `deps`. On the critical path it merges the running aggregate with the committed inclusion-list proofs it does not cover and discards every dependency outside `dependencies(block)`. The running aggregate's size is the builder's choice, so the benchmark fixes it as a parameter, provisionally twice the gas-derived count, and a builder keeps its running aggregate within what the benchmarked construction proves in time.

How the merge is split into steps is a parameter of the benchmarked construction. Merging the running aggregate and `IL_COMMITTEE_SIZE` committed proofs in one step takes `IL_COMMITTEE_SIZE + 1` (17) recursive inputs and as many discards as their dependency lists hold; smaller steps take fewer of each and more steps.

Builder liveness depends on the latency of one merge or aggregation step times the number of steps that run in sequence on the critical path. A step's latency need not track its discard count, so the protocol measures per-step latency against fan-in and prover parallelism, and reports discards separately.

### Gas-derived case

The construction produces a block proof over the gas-derived count from a running aggregate of, provisionally, twice that count, discarding its surplus: the running aggregate minus `dependencies(block)`.

| Gas limit | Output (`dependencies(block)`) | Running aggregate (provisional) | Discarded |
| --------- | ------------------------------ | ------------------------------- | --------- |
| 30M       | 910                            | 1,820                           | 910       |
| 60M       | 1,819                          | 3,638                           | 1,819     |
| 100M      | 3,031                          | 6,062                           | 3,031     |

Counts are leanSPHINCS dependencies.

### Cold inclusion-list case

Starting at view freeze with newly received lists, the builder retrieves `IL_COMMITTEE_SIZE` (16) committed proofs it does not hold, each over `MAX_DEPS_PER_IL_PROOF` (128) dependencies, then merges them with the running aggregate. These proofs were available to attesters before the proof deadline; the builder receives `PROOF_LATE` and includes their covered entries as for `VALID`. Its inputs cover up to 2,048 inclusion-list dependencies plus the running aggregate's; its output is at most the gas-derived count. Include lists with only one covered dependency each, forcing the remaining 127 per proof to be discarded. Gas bounds only the output.

| Gas limit | Inclusion-list inputs | Running aggregate | Input dependencies in all | Output at most |
| --------- | --------------------- | ----------------- | ------------------------- | -------------- |
| 30M       | 2,048                 | 1,820             | 3,868                     | 910            |
| 60M       | 2,048                 | 3,638             | 5,686                     | 1,819          |
| 100M      | 2,048                 | 6,062             | 8,110                     | 3,031          |

### Fixtures and workloads

The builder workloads are not valid blocks. Valid-block fixtures are blocks of transactions with one dependency each, as many as fit: with `o` the gas each transaction uses besides its dependency, `floor(gas_limit / (33,000 + o))` leanSPHINCS or `floor(gas_limit / (60,000 + o))` leanSTARK transactions. The table uses `o` = 21,000, a transfer; fixtures recompute their counts from the `o` of the transactions they build.

| Gas limit | Fixture, leanSPHINCS | Fixture, leanSTARK | Workload, leanSPHINCS | Workload, leanSTARK |
| --------- | -------------------- | ------------------ | --------------------- | ------------------- |
| 30M       | 555                  | 370                | 910                   | 500                 |
| 60M       | 1,111                | 740                | 1,819                 | 1,000               |
| 100M      | 1,851                | 1,234              | 3,031                 | 1,667               |

### Reporting

A builder benchmark run reports, for each case:

- the reference hardware;
- the case, the gas limit, the running aggregate's size and the input, output and discarded dependency counts;
- the construction's parameters: step count, each step's fan-in and discard count, and the work done ahead of the slot;
- per-step latency, the time for one merge or aggregation step, for each fan-in and prover parallelism benchmarked, reported separately from the step's discard count, and the number of steps that run in sequence;
- the measured size of each aggregate proof the construction produces;
- retrieval time and aggregation time separately, and their total from view freeze to the finished block proof, against the proposal deadline; report gains from earlier processing separately.

## Attester benchmark

### What is required

Attesters need their own benchmark; builder benchmark success alone does not establish it. On reference hardware, reliable delivery on the honest paths up to the permitted volume is an activation requirement:

- proofs within the IL bounds published by the `t=0s` target of slot `N` (provisional) reach a cached verdict before the proof deadline;
- authenticated lists committing to those proofs or to eligible wrapper proofs already held by the proof deadline are checked through `engine_verifyInclusionListProofV1` by view freeze, with coverage evaluated per transaction.

Both must hold under the full permitted background load (see [Required workload](#required-workload)). Without this delivery, the null fallback preserves the lists' dependency-free obligations but may substantially weaken censorship resistance for dependency-bearing transactions.

### Timing

| Time in slot `N` | Event |
| ---------------- | ----- |
| From slot `N - 1` to `t=0s` (provisional target) | Members publish committed wrapper proofs on the proof topic. |
| By `t=8s` (provisional list publication target) | Members release lists with proof commitments, leaving time for list delivery and coverage checks. |
| Proof deadline (`t=8s` with the provisional margin) | Proofs must be verified and available; lists may still arrive afterward. |
| View freeze deadline (currently `t=9s`) | Authenticate lists and obtain `VALID` using proofs available by the earlier cutoff. Builders begin the cold retrieval-and-proving benchmark. |
| Proposal deadline (currently `t=12s`) | Builders finish retrieval and block-proof construction; the provisional cold-path budget is three seconds. |

The publication targets are benchmark inputs, not extra validity rules. The proof deadline and its margin are protocol parameters. Three seconds is a candidate budget, not a measured result. Moving the proof deadline earlier does not enlarge the cold builder window while the list deadline remains unchanged; proof parameters or fork timing must change if the required workload does not fit. A skipped slot or key change must not cause the EL to select the mempool's older verifier for an IL proof.

### Required workload

The attester receives and verifies 16 topic proofs by the proof deadline, up to 20 MiB of proof data plus 128 dependencies per proof, measuring delivery from publication. It receives 16 lists with at most 8 KiB of transaction data each, released by the provisional publication target, and completes their checks by view freeze. Include mixtures of covered, uncovered and statically invalid entries, and lists arriving after the proof deadline that select timely proofs. The appended commitment and SSZ offsets are measured separately from EIP-7805's transaction-byte budget.

The required workload must be met while the node also receives and verifies the full permitted background load:

- slot `N`: up to 16 second topic publications and 16 separately retrieved committed proofs, for 48 `il_proof`s (60.5625 MiB before serialization) per committee with the required 16;
- slot `N - 1`, until the attestation deadline of slot `N`: requests for its committed proofs, sent and served, and its retained proofs;
- slot `N + 1`: up to 16 early topic proofs.

Late proofs in the background, second publications and committed proofs fetched by request, keep their weaker guarantee and are measured below, not required.

### Measured workloads

These are reported, not required:

- Reproven proofs: up to 16 further proofs published as second topic publications, for 32 topic proofs and 40.375 MiB before serialization. Measure the fraction verified by the proof deadline and selected by lists checked by view freeze; later proofs cannot enable new obligations.
- Freshness: a proof selected before slot `N` cannot cover dependencies first received during it. Report the fraction of newly received transactions covered by timely proofs and lists.
- Attester cold case: fetch committed proofs not already held, beginning one second before the proof deadline, from peers serving other attesters concurrently. The 16 proofs and dependency lists total up to 20.1875 MiB before serialization. Report delivery failures as reduced dependency-bearing obligations. This optional attester stress case does not relax the required builder cold case.

### Member proof reuse

Compare retaining only large aggregates with a bounded selection of recent intermediate wrappers of at most 128 dependencies alongside them, held through the next view freeze. Use the same transaction arrivals and list-selection policy, including selections spanning several wrappers. Report:

- the fraction of selected lists covered by one retained proof without new proving;
- retained proof and envelope bytes, added announcement and transfer traffic, and wrapper age;
- the fraction requiring a new merge or prune, its proving latency on reference member hardware, and whether the result can be verified by attesters before the proof deadline.

Include pruning a 4,096-dependency wrapper to at most 128 when no eligible intermediate covers the selection. This measures the fallback cost; small intermediates do not guarantee that arbitrary lists can avoid proving. Select the cap and retention recommendation from measured reuse and bandwidth, without assuming a high reuse rate.

### Reporting

An attester benchmark run reports:

- the reference hardware and network conditions, and the background load applied;
- measured `stark_proof` and `proof_deps` sizes, separately, and the resulting `il_proof` volume per committee, against the payload bounds in [Resource accounting](#resource-accounting), with encoding and transport overhead reported separately;
- the fraction of topic proofs reaching a cached verdict by the proof deadline, separately for proofs published by the `t=0s` target and for reproven proofs;
- the fraction of lists checked by view freeze using timely proofs, how many were cache lookups, and the fraction of dependency-bearing entries covered;
- for the freshness variant, the fraction of affected lists' committed proofs with a cached verdict by the proof deadline;
- for the cold case, fetch time, bandwidth and the fraction of committed proofs held by the deadline.

## Resource accounting

At the provisional bounds, each proof contributes at most 1,310,720 bytes and its dependency list 128 × 96 = 12,288 bytes: 1.26171875 MiB combined. The SSZ `InclusionListProof` adds eight offset bytes; the signed gossip container adds 180 bytes for its fixed message, proof offset and signature. The following totals exclude those serialization bytes and transport overhead; shared proofs reduce them.

The 128-dependency cap bounds metadata to 12 KiB per proof, or 192 KiB for 16 committed proofs. A 4,096-dependency cap would permit 384 KiB per proof, or 6 MiB per committee, independently of proof bytes. The lower cap trades unchanged-wrapper reuse for lower dissemination and retention volume; it does not bound the work that produced the proofs.

| Scope | Proofs | Proof and dependency bytes |
| ----- | ------ | -------------------------- |
| Topic publications per committee | 32 | 40.375 MiB |
| Topic publications plus committed proofs retrieved separately | 48 | 60.5625 MiB |
| Peak retention across overlapping committees | 80 | 100.9375 MiB |

Peak retention occurs before slot `N + 1`'s attestation deadline: 16 committed proofs from slot `N`, up to 48 topic and committed proofs from slot `N + 1`, and 16 early first publications for slot `N + 2`. Slot `N`'s uncommitted topic proofs were released at its view freeze deadline; second publications for slot `N + 2` are not yet admitted. Other retention requirements may share these bytes. Ordinary mempool caching is additional.

Actual retention ends at the supplied CL deadlines. The provisional 48,000 ms ceiling is an API safety bound independent of slot length; verify that the deadlines fit it and recompute overlap if fork timing changes.
