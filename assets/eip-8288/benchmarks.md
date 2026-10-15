# EIP-8288 benchmark protocol

This document gives the benchmark protocol for [EIP-8288](../../EIPS/eip-8288.md): the workloads, what each benchmark must show and what it reports. The EIP states which benchmarks are activation preconditions; this document does not add requirements beyond it. Counts marked provisional are fixed by the activating fork together with its proof profile.

## Builder benchmark

### What is required

On reference hardware, the activating fork's reference construction produces the block proof from the builder's inputs within the builder's proving budget: the time between the builder's last input and the block's proposal deadline. The benchmark covers the complete construction, every aggregation step and every input, including overlapping dependencies and dependencies the construction discards. Per-step fan-in, discard counts, step counts and work done ahead of the slot are parameters of the benchmarked construction, not circuit requirements; any construction that meets the deadline on the benchmarked inputs conforms.

The benchmark runs at the activation gas limit with headroom and again before any gas-limit increase, like any other gas-bound resource. It is a liveness precondition, not advisory: there is no per-block dependency cap, and a builder that cannot prove in time misses the slot. If the construction does not meet the deadline at the gas-derived count, proving rather than gas binds dependencies per block, and the gas costs or the gas limit must change before activation.

### Gas-derived count

A leanSPHINCS dependency costs `LEANSPHINCS_VERIFICATION_GAS + LEANSTARK_VERIFICATION_GAS` (33,000) gas and a leanSTARK dependency `2 * LEANSTARK_VERIFICATION_GAS` (60,000), so gas bounds `dependencies(block)` to fewer than `gas_limit` divided by those costs. The gas-derived count rounds these bounds up:

- leanSPHINCS: `ceil(gas_limit / (LEANSPHINCS_VERIFICATION_GAS + LEANSTARK_VERIFICATION_GAS))`;
- leanSTARK, with `LEANSTARK_SCHEME` enabled: `ceil(gas_limit / (2 * LEANSTARK_VERIFICATION_GAS))`.

| Gas limit | leanSPHINCS | leanSTARK |
| --------- | ----------- | --------- |
| 30M       | 910         | 500       |
| 60M       | 1,819       | 1,000     |
| 100M      | 3,031       | 1,667     |

The gas-derived count is a benchmark workload, not a valid block: every transaction also pays gas besides its dependencies, and 910 × 33,000 gas alone exceeds 30M. It bounds only the construction's output; its inputs' proofs can also cover dependencies of transactions the block omits.

### Running aggregate

Under [EIP-7805](../../EIPS/eip-7805.md), a builder can maintain a running aggregate ahead of the slot over the union of its validated mempool wrappers' `deps`. On the critical path it merges the running aggregate with the committed inclusion-list proofs it does not cover and discards every dependency outside `dependencies(block)`. The running aggregate's size is the builder's choice, so the benchmark fixes it as a parameter, provisionally twice the gas-derived count, and a builder keeps its running aggregate within what the benchmarked construction proves in time.

How the merge is split into steps is a parameter of the benchmarked construction. Merging the running aggregate and `IL_COMMITTEE_SIZE` committed proofs in one step takes `IL_COMMITTEE_SIZE + 1` (17) recursive inputs and as many discards as their dependency lists hold; smaller steps take fewer of each and more steps.

### Gas-derived case

The construction produces a block proof over the gas-derived count from a running aggregate of, provisionally, twice that count, discarding its surplus: the running aggregate minus `dependencies(block)`.

| Gas limit | Output (`dependencies(block)`) | Running aggregate (provisional) | Discarded |
| --------- | ------------------------------ | ------------------------------- | --------- |
| 30M       | 910                            | 1,820                           | 910       |
| 60M       | 1,819                          | 3,638                           | 1,819     |
| 100M      | 3,031                          | 6,062                           | 3,031     |

Counts are leanSPHINCS dependencies.

### Cold inclusion-list case

The construction merges `IL_COMMITTEE_SIZE` (16) committed proofs the builder does not hold, each over `MAX_DEPS_PER_AGGREGATE_WRAPPER` (4,096) dependencies and fetched after the view freeze deadline, with the running aggregate into the block proof. Its inputs cover up to 65,536 inclusion-list dependencies plus the running aggregate's; its output is at most the gas-derived count, so most input dependencies are discarded. Gas bounds only that output.

| Gas limit | Inclusion-list inputs | Running aggregate | Input dependencies in all | Output at most |
| --------- | --------------------- | ----------------- | ------------------------- | -------------- |
| 30M       | 65,536                | 1,820             | 67,356                    | 910            |
| 60M       | 65,536                | 3,638             | 69,174                    | 1,819          |
| 100M      | 65,536                | 6,062             | 71,598                    | 3,031          |

### Fixtures and workloads

The builder workloads are not valid blocks. Valid-block fixtures, in Test Case 11 of the EIP, are blocks of transactions with one dependency each, as many as fit: with `o` the gas each transaction uses besides its dependency, `floor(gas_limit / (33,000 + o))` leanSPHINCS or `floor(gas_limit / (60,000 + o))` leanSTARK transactions. The table uses `o` = 21,000, a transfer; fixtures recompute their counts from the `o` of the transactions they build.

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
- the time from the last input to the finished block proof, against the proving budget.

## Attester benchmark

### What is required

Attesters need their own benchmark; builder benchmark success alone does not establish it. On reference hardware, reliable delivery on the honest paths up to the permitted volume is an activation requirement:

- wrapper proofs published on the proof topic by the `t=0s` target of slot `N` (provisional) reach a cached verdict by the end of EIP-7805's construction window;
- lists committing to those proofs or to wrapper proofs the attester already holds are checked through `engine_verifyInclusionListProofV1` by a cache lookup by the EIP-7805 view freeze deadline.

Both must hold under the full permitted background load (see [Required workload](#required-workload)). Without this delivery, the null fallback preserves the lists' dependency-free obligations but may substantially weaken censorship resistance for dependency-bearing transactions.

### Timing

| Time in slot `N` | Event |
| ---------------- | ----- |
| From slot `N - 1` to `t=0s` (provisional target) | Members publish committed wrapper proofs on the proof topic. |
| During the construction window | Members publish reproven proofs, as their second topic publication, when proving completes, and publish their lists. |
| End of the construction window (currently `t=8s`) | Latest list release; topic proof delivery is measured to here. |
| View freeze deadline (currently `t=9s`) | Every list must be checked; on the required path that second carries lists and cache lookups, not proof bytes. |

### Required workload

The attester receives on the proof topic and verifies `IL_COMMITTEE_SIZE` (16) wrapper proofs, up to `IL_COMMITTEE_SIZE` × `MAX_AGGREGATE_PROOF_BYTES` (16 × 1.25 MiB = 20 MiB) of proof data plus their dependency lists, measuring delivery from each proof's publication. It then receives the committee's 16 lists, each at most EIP-7805's `MAX_BYTES_PER_INCLUSION_LIST` (8 KiB), released at the end of the construction window as the latest case, and checks each by the view freeze deadline, by a cache lookup when its execution layer already holds the committed proof from a mempool wrapper or the proof topic.

The required workload must be met while the node also receives and verifies the full permitted background load:

- slot `N`: up to 16 second topic publications and up to 16 committed proofs fetched by request and verified through `engine_verifyInclusionListProofV1`, for 48 `il_proof`s (78 MiB) per committee with the required 16;
- slot `N - 1`, until the attestation deadline of slot `N`: requests for its committed proofs, sent and served, and its retained proofs;
- slot `N + 1`: up to 16 early topic proofs.

Late proofs in the background, second publications and committed proofs fetched by request, keep their weaker guarantee and are measured below, not required.

### Measured workloads

These are reported, not required:

- Reproven proofs: up to 16 further proofs, one per member, published as second topic publications when proving completes during the construction window, for up to `2 × IL_COMMITTEE_SIZE` (32) topic proofs and 52 MiB of `il_proof`s per committee, before committed proofs fetched by request. A reproven proof published late in the window may miss, leaving its list's dependency-bearing entries unenforced in that attester's view.
- Freshness: a proof selected before slot `N` cannot cover dependencies first received during it. In a variant in which a fraction of the lists' dependency-bearing transactions first arrive during slot `N`, the benchmark reports the fraction of those lists' committed proofs reaching a cached verdict by the view freeze deadline. The delivery requirement otherwise mainly covers transactions seen before the slot.
- Cold case: fetching by request, in the second before the view freeze deadline, committed proofs the attester neither held nor received on the topic, from peers that serve every other attester at once. Up to 16 `il_proof`s of `MAX_AGGREGATE_PROOF_BYTES` with 4,096-entry dependency lists, about 26 MiB, do not reliably fit that second, so the cold case need not succeed under every network condition and is measured as a degradation.

### Reporting

An attester benchmark run reports:

- the reference hardware and network conditions, and the background load applied;
- the fraction of topic proofs reaching a cached verdict by the end of the construction window, separately for wrapper proofs published by the `t=0s` target and for reproven proofs;
- the fraction of lists checked by the view freeze deadline, and how many were cache lookups;
- for the freshness variant, the fraction of affected lists' committed proofs with a cached verdict by the view freeze deadline;
- for the cold case, fetch time, bandwidth and the fraction of committed proofs held by the deadline.
