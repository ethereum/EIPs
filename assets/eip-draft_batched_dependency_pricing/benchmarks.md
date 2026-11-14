# Batched generic proof dependencies: benchmarks

This document supplies the measurement procedure for the EIP's activation requirements. The calibration notes below are informative and do not select the activation hardware baseline.

## Configuration

Publish the prover and verifier revisions and configurations, commitment construction, hashes, gas schedule, gas limit and verifier resource bounds. Record hardware, worker count, threads and memory per worker, and safety margins. Specify numerical builder aggregation and validator execution/verification time and peak-memory budgets before calibration. Fix memory per worker jointly with the commitment construction and `MAX_INNER_PROOFS_PER_STEP`: a full maximum-resource step must fit within one worker's memory. Take provable trace and joint committed-witness bounds from the pinned proof-system specification; do not equate a witness-size bound with an attainable trace height.

## Workloads

- Use jointly valid resource combinations. A maximum-resource leaf maximizes recursive verification work within the permitted program size, trace dimensions, committed values, bus interactions, proof bytes and claim count. Include support code, padding, program-commitment authentication and all opening verification.
- Measure full aggregation steps at the proposed arity: maximum-resource leaves under distinct keys, recursive inputs and permitted mixtures. Check outer trace and proof-size bounds as well as time and memory. Individual-leaf measurements do not establish full-step feasibility.
- Construct blocks satisfying both gas and dependency limits, using complete transaction gas accounting. Cover EVM-dominated blocks, native signatures, unaggregated singleton generic proofs under distinct keys, full batch leaves, and blocks retaining one claim per maximum-resource leaf with its payment. Include adversarial mixtures. Calibrate generic and leaf charges with one leaf per initial step, without shared-key preprocessing savings.
- Check that ordinary singleton and leaf-payment transactions fit the applicable transaction gas limit, including intrinsic gas, calldata, authorization and other required execution. A calibration admitting no such transactions cannot pass the generic or batch workloads.
- Exercise overlapping leaves, source selection, payment lookup, pruning and finalization across the complete block aggregation tree. Invalidate a sponsorship transaction after finalization; measure repair with changed dependencies, including reaggregation and a new finalization proof, within the remaining builder budget. Compare a valid replacement preserving the dependency set, where proof reuse suffices.
- Demonstrate circuit output capacity of at least `MAX_DEPS_PER_BLOCK` and block rejection above that limit. Exercise 65,535- and 65,536-entry intermediate unions pruned to supported outputs without truncation. Report output-capacity measurements separately when those outputs exceed the calibrated gas budget.
- Demonstrate that intended application verifiers fit the resource bounds for both leaf proving and recursive aggregation.

## Measurements

Measure complete scheduled wall-clock completion time (makespan) at the stated worker count, including recursive critical paths and inter-worker transfers. Total work divided by worker count is not a completion-time measurement.

Report program-commitment authentication and other recursion costs, total work, tree depth, critical-path latency, per-worker and aggregate peak memory, proof sizes and transmitted bytes. Measure validator execution and proof verification against their stated budgets as well. Include 192-byte intermediate records in memory and serialization measurements where they are materialized or transmitted.

Run each measured step in its own process, discard a warm-up run and take at least three timed repetitions, reporting the median and range. Measure without competing load or swap growth; repeat a measurement that violates these conditions and exclude it if the repeat also does. Report deterministic cycle counts alongside times.

Measure cumulative claim hashing and payment binding throughout the tree, not only a single hashing pass. State the depths used to calibrate carry charges and verify that the schedules for the largest admissible blocks are covered. Compare ordinary dependency carry and batch-claim carry at the same depths, separating per-record work from amortized leaf and recursive-node overhead. Account for each component once. Measure a maximum-resource batch leaf separately from an ordinary generic leaf, assigning fixed payment-binding overhead to the leaf-payment charge and marginal record costs to the claim charge.

Separate measured results from models and extrapolations. Measure the selected commitment construction, permitted resource extremes and payment binding; projected full-block timings do not establish activation readiness.

## Calibration

Derive native, ordinary generic, intrinsic proof-share, leaf-payment and batch-claim charges from the same time and memory budgets. The leaf-payment charge must cover maximum permitted verification and fixed binding work; the claim charge must cover cumulative marginal carry and payment binding through finalization. Repeat the block workloads with the proposed gas schedule. All must fit, including mixtures and the most expensive valid proofs. If they do not, revise charges, resource bounds or the interface before activation. Dividing single-worker charges by a worker count does not validate multi-worker schedules or their critical paths.

The calibration covers only the measured gas limits, configurations and bounds. Recalibrate for higher gas limits or changed prices within the fixed block dependency limit. Raising that limit requires a fork, a matching aggregation key and renewed capacity measurements.

## Provisional calibration notes

The [calibration suite](https://github.com/NethermindEth/lean-bindings/pull/13) and [committed-key study](https://github.com/NethermindEth/lean-bindings/pull/10) report single-machine measurements on GCP `c3-highmem-22`. The committed-key batch build is `a344762eee45e9807db07e010d30e6fe5cc41962`; its 16-worker figures are modelled, using a 60M gas limit, a six-second builder budget, a 1.5 safety margin and three recursive carry levels. These figures do not establish multi-machine readiness.

The provisional 5,100 proof share rounds the model's depth-three carry estimate. The 675,000 leaf-payment allowance includes the fixed binding overhead measured separately from generic verification, with headroom for slower reference hardware; it is not an algebraic sum of the other charges. The 4,200 claim allowance remains conservative until complete-tree binding, overlaps and finalization are measured at the intended block capacity. All charges still require joint calibration on the selected reference configuration.

The measured committed construction supports a 16-leaf step; the flat-key run supports only 12. Their largest tested leaf trace was approximately `2**29.5` under a `2**30` stacked-witness bound. Exact limits belong in the pinned proof-system specification. Neither run establishes jointly maximal resource combinations, 16,384-dependency output capacity, late sponsor repair, or distributed makespan including network transfers and EVM execution. A per-cell or partial-workload PASS is not completion of the activation gate.
