# EIP-8288 benchmark methodology

This document supplies the measurement procedure for EIP-8288's activation requirements. It contains no benchmark results or selected hardware baseline.

## Configuration

Publish the prover and verifier revisions and configurations, commitment construction, hashes, gas schedule, gas limit and verifier resource bounds. Record hardware, worker count, threads and memory per worker, and safety margins. Specify numerical builder aggregation and validator execution/verification time and peak-memory budgets before calibration.

## Workloads

- Use jointly valid resource combinations. A maximum-resource leaf maximizes recursive verification work within the permitted program size, trace dimensions, committed values, bus interactions and proof bytes. Include support code, padding, program-commitment authentication and all opening verification.
- Measure full aggregation steps at the proposed arity: maximum-resource leaves under distinct keys, recursive inputs and permitted mixtures. Check outer trace and proof-size bounds as well as time and memory. Individual-leaf measurements do not establish full-step feasibility.
- Construct gas-admissible blocks using complete transaction gas accounting. Cover EVM-dominated blocks, native signatures, unaggregated singleton generic proofs under distinct keys, and adversarial mixtures. Calibrate generic charges with one leaf per initial step, without shared-key preprocessing savings.
- Demonstrate that intended application verifiers fit the resource bounds for both leaf proving and recursive aggregation.

## Measurements

Measure complete scheduled wall-clock completion time (makespan) at the stated worker count, including recursive critical paths and inter-worker transfers. Total work divided by worker count is not a completion-time measurement.

Report program-commitment authentication and other recursion costs, total work, tree depth, critical-path latency, per-worker and aggregate peak memory, proof sizes and transmitted bytes. Measure validator execution and proof verification against their stated budgets as well.

Separate measured results from models and extrapolations. Measure the selected commitment construction and permitted resource extremes; projected full-block timings do not establish activation readiness.

## Calibration

Derive native, generic and intrinsic proof-share charges from the same time and memory budgets. Repeat the block workloads with the proposed gas schedule. All workloads must fit, including mixtures and the most expensive valid proofs. If they do not, revise the charges, resource bounds or interface before activation.

The calibration covers only the measured gas limits, configurations and bounds. Recalibrate for higher gas limits and reassess circuit capacity if the block-size bound increases.
