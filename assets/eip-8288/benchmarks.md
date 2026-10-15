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

### Gas-derived case

The construction produces a block proof over the gas-derived count from inputs whose dependency union is, provisionally, twice that count, discarding the surplus: the input union minus `dependencies(block)`.

| Gas limit | Output (`dependencies(block)`) | Input union (provisional) | Discarded |
| --------- | ------------------------------ | ------------------------- | --------- |
| 30M       | 910                            | 1,820                     | 910       |
| 60M       | 1,819                          | 3,638                     | 1,819     |
| 100M      | 3,031                          | 6,062                     | 3,031     |

Counts are leanSPHINCS dependencies.

### Reporting

A builder benchmark run reports:

- the reference hardware;
- the gas limit and the input, output and discarded dependency counts;
- the construction's parameters: step count, each step's fan-in and discard count, and the work done ahead of the slot;
- the time from the last input to the finished block proof, against the proving budget.
