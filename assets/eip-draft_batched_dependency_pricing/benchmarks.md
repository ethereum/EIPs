# Batch-pricing benchmark supplement

Apply EIP-8288's benchmark methodology, reference configuration and common capacity budgets. This supplement adds batching workloads and measurements; it contains no benchmark results.

## Workloads

- Extend maximum-resource leaf selection to include claim count, up to `MAX_CLAIMS_PER_BATCH_LEAF`. Measure jointly valid combinations of all resource bounds, including program-commitment authentication and opening verification.
- Retain ordinary singleton proofs under distinct keys in the workload set. Add full leaves and blocks retaining only one claim per maximum-resource leaf with its payment. Include mixtures with native signatures and EVM execution, using complete transaction gas accounting.
- Price unpacked leaves: one generic leaf per initial aggregation step, without shared-key preprocessing savings.
- Exercise overlapping leaves, source selection, payment lookup, pruning and finalization across the complete block aggregation tree.

## Measurements and calibration

Measure claim hashing and payment binding throughout the tree, not only a single hashing pass. Compare ordinary dependency carry and batch-claim carry at the same tree depths, separating per-record work from amortized leaf and recursive-node overhead. Account for each component once. Measure a maximum-resource batch leaf, including its payment-binding work, separately from an ordinary generic leaf: the payment charge reuses the ordinary verification charge and proof share, so it must cover any additional per-leaf work.

Report cumulative per-claim work alongside EIP-8288's full-block measurements: total work, depth, critical-path latency, scheduled completion time at the stated worker count, peak memory and transmitted bytes. Include the 192-byte intermediate records in memory and serialization measurements where they are materialized or transmitted.

Calibrate native, ordinary generic, proof-share and batch-claim charges together. The leaf charge must cover maximum permitted verification work; the claim charge must cover cumulative carry and payment binding through finalization. Verify gas-admissible blocks against the shared time and memory budgets, including recursive critical paths and transfers. Modelled timings and total work divided by worker count are insufficient; revise charges or the interface before activation if the measured schedules fail.
