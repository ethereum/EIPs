# Generic proof verification and batching: benchmarks

This document supplies the measurement procedure for the EIP's activation requirements. It contains no benchmark results or selected hardware baseline.

## Configuration

Publish the prover and verifier revisions and configurations, commitment construction, hashes, gas schedule, gas limit and verifier resource bounds. Record hardware, worker count, threads and memory per worker, and safety margins. Specify numerical builder aggregation and validator execution/verification time and peak-memory budgets before calibration. Fix memory per worker jointly with the commitment construction and `MAX_INNER_PROOFS_PER_STEP`: a full maximum-resource step must fit within one worker's memory.

## Workloads

- Use jointly valid resource combinations. A maximum-resource leaf maximizes recursive verification work within the permitted program size, trace dimensions, committed values, bus interactions, proof bytes and claim count. Include support code, padding, program-commitment authentication and all opening verification.
- Measure full aggregation steps at the proposed arity: maximum-resource leaves under distinct keys, recursive inputs and permitted mixtures. Check outer trace and proof-size bounds as well as time and memory. Individual-leaf measurements do not establish full-step feasibility.
- Construct gas-admissible blocks using complete transaction gas accounting. Cover EVM-dominated blocks, native signatures, unaggregated singleton generic proofs under distinct keys, full batch leaves, and blocks retaining one claim per maximum-resource leaf with its payment. Include adversarial mixtures. Calibrate generic and leaf charges with one leaf per initial step, without shared-key preprocessing savings.
- Exercise overlapping leaves, source selection, payment lookup, pruning and finalization across the complete block aggregation tree.
- Demonstrate that intended application verifiers fit the resource bounds for both leaf proving and recursive aggregation.

## Measurements

Measure complete scheduled wall-clock completion time (makespan) at the stated worker count, including recursive critical paths and inter-worker transfers. Total work divided by worker count is not a completion-time measurement.

Report program-commitment authentication and other recursion costs, total work, tree depth, critical-path latency, per-worker and aggregate peak memory, proof sizes and transmitted bytes. Measure validator execution and proof verification against their stated budgets as well. Include 192-byte intermediate records in memory and serialization measurements where they are materialized or transmitted.

Run each measured step in its own process, discard a warm-up run and take at least three timed repetitions, reporting the median and range. Measure without competing load or swap growth; repeat a measurement that violates these conditions and exclude it if the repeat also does. Report deterministic cycle counts alongside times.

Measure cumulative claim hashing and payment binding throughout the tree, not only a single hashing pass. Compare ordinary dependency carry and batch-claim carry at the same tree depths, separating per-record work from amortized leaf and recursive-node overhead. Account for each component once. Measure a maximum-resource batch leaf, including its payment-binding work, separately from an ordinary generic leaf: the payment charge reuses the ordinary verification charge and proof share, so it must cover any additional per-leaf work.

Separate measured results from models and extrapolations. Measure the selected commitment construction, permitted resource extremes and payment binding; projected full-block timings do not establish activation readiness.

## Calibration

Derive native, ordinary generic, intrinsic proof-share and batch-claim charges from the same time and memory budgets. The leaf charge must cover maximum permitted verification work; the claim charge must cover cumulative carry and payment binding through finalization. Repeat the block workloads with the proposed gas schedule. All must fit, including mixtures and the most expensive valid proofs. If they do not, revise charges, resource bounds or the interface before activation.

The calibration covers only the measured gas limits, configurations and bounds. Recalibrate for higher gas limits and reassess circuit capacity if the block-size bound increases.
