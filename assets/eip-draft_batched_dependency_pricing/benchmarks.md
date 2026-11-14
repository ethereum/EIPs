# Batched generic proof dependencies: benchmarks

This document supplies the EIP's calibration and activation methodology. Shared validation costs, private proving work and inclusion-list latency are separate measurements; a throughput price is not a substitute for the required inclusion path meeting its deadline.

## Configuration

Publish prover and verifier revisions, commitment construction, hashes, gas schedule, gas limit and resource bounds. Record node-class verification hardware separately from prover hardware, including workers, threads and memory per worker. State numerical validator, includer and builder time/memory budgets and safety margins before testing. Record the interval available for inclusion-list proof construction and for builder integration after the latest permitted arrival.

Fix maximum step arity jointly with the commitment construction and memory per worker. Take provable trace and joint committed-witness bounds from the pinned proof-system specification; a witness-size bound is not necessarily an attainable trace height.

## Verification and gas

- Measure mempool-only leanSPHINCS and leanSTARK verification on node-class hardware, including decoding, key authentication, maximum proofs and failures at different stages. Measure aggregation-hint generation separately. Compare with uncached `ecrecover` on the same machine as a work ratio, not an automatic execution-gas conversion.
- Exercise admission budgets with direct witnesses, singleton and dense mode 1 wrappers, overlaps, invalid proofs and many peers. Report verification rate, queued work, retained bytes and useful new coverage. Show that mode 1 cannot bypass per-peer or global budgets. Measure proof transport separately from transaction calldata; proof bytes are not charged at the calldata rate.
- Measure shared block-proof verification and relay costs for the proof-share allowance. Separate fixed per-block overhead from dependency-dependent hashing and data costs, avoiding double charging transaction bytes. Neither a builder's recursive-carry timing nor a per-witness relay benchmark measures these shared block costs.
- Include complete transaction gas accounting and the applicable transaction gas limit. A calibration admitting no generic transactions cannot pass the generic workloads. Batching does not change the charge per declaration.
- Measure validator execution and final-proof verification for worst-case blocks permitted by both gas and dependency limits. Verification costs and data limits must remain safe independently of a builder's willingness to prove.

## Proving and inclusion-list liveness

- Use jointly valid maximum-resource leaves: permitted program size, trace dimensions, committed values, bus interactions, proof bytes and claim counts, including support code, padding and authentication. Demonstrate full steps of distinct-key leaves, recursive inputs and mixtures within the outer bounds.
- Demonstrate `MAX_DEPS_PER_BLOCK` output capacity and rejection above the block limit. Exercise 65,535- and 65,536-entry intermediate unions pruned to supported outputs without truncation.
- Construct a full committee's permitted inclusion lists and covering recursive proofs, with maximum transaction/dependency volume, overlapping coverage, invalid transaction entries and the maximum pruning work. Measure includer proof construction and the builder's remaining merge/prune path after the latest permitted arrival. Covered obligations cannot be treated as optional work when timing the builder.
- Exercise late native-signature and generic-proof arrivals separately. Include native leaf generation when it lies on the measured includer or builder path; pre-aggregated input results cannot establish that latency. Optional late transactions may be declined, but the required inclusion-list path must meet its deadlines.
- Measure cumulative recursive carry through the schedules' actual depths, separating per-record costs from fixed recursive-node overhead. Use this work to evaluate proving service costs and inclusion-list latency, not as a substitute for native verification measurements.
- Measure sustained optional throughput separately: native signatures, distinct-key singleton generic proofs, full batch leaves and adversarial mixtures. Report capacity and critical paths without assuming every gas-admissible selection must be proved by every builder. Include EVM execution, state changes requiring pruning, and inter-worker transfers.

## Measurements and acceptance

Measure complete scheduled wall-clock completion time (makespan) at the stated worker count, including critical paths and transfers between machines. Total work divided by worker count is not a completion-time measurement. Report cycles, peak memory per worker and in aggregate, proof sizes and transferred bytes alongside times.

Run each measured step in its own process, discard a warm-up and take at least three timed repetitions, reporting median and range. Exclude competing load and swap growth; repeat a measurement that violates these conditions and exclude it if the repeat also does.

Activation requires measured verifier safety, effective admission budgets, permitted circuit capacity and the mandatory inclusion-list paths within their stated budgets. If the inclusion path fails, revise the circuit, bounds or timing rules before activation; higher optional priority fees cannot excuse an inclusion obligation. Recheck changed prices, gas limits or proof-system parameters. Raising `MAX_DEPS_PER_BLOCK` requires a fork and matching aggregation key.

## Calibration status

The [calibration suite](https://github.com/NethermindEth/lean-bindings/pull/13) and [committed-key study](https://github.com/NethermindEth/lean-bindings/pull/10) report node and single-machine measurements. The committed construction supports a tested 16-leaf step; the flat-key run supports only 12. Their largest tested leaf trace was approximately `2**29.5` under a `2**30` stacked-witness bound. Exact limits belong in the pinned proof-system specification.

The suite's native-verification run used a `c4-standard-8` (4 cores / 8 vCPU, 30 GB), lean-bindings revision `e87b7b0`, and five timed repetitions after warm-up. It reports:

| Operation | Median time |
| --- | --- |
| Uncached `ecrecover`, cycling distinct signatures | 29.6 µs |
| leanSPHINCS signature | 0.303 ms |
| Generic proof, small / maximum tested program | 8.97 / 13.17 ms |
| 256-claim leaf using the measured payment-binding guest | 13.08 ms |
| Mode 1 proof covering one leaf and 64 signatures | 10.35 ms |

The STARK path also generates aggregation hints, so these are not isolated mempool-verification timings. The payment-binding guest is not the ordinary multi-claim interface specified here. A verification-only run must separate these effects. Similar results with one and all threads indicate little within-proof parallelism in this path; independent verifications may still run concurrently. First-run timings differed by 15–18%, so the report's variation also matters.

The 3,000 / 30,000 / 2,700 charges remain uncalibrated placeholders. The measurements establish material relay costs, not an execution-gas price, and neither confirm these low values nor require the `ecrecover`-equivalent million-gas figure. Wrapper composition and unpaid submissions require measured admission budgets regardless of the eventual charges.

Published two-budget results miss the tested late-native-arrival target on the measured machine; scaling them to an M4-Max-class reference is modelled. Real multi-machine schedules, inclusion-list deadline workloads, jointly maximal resources and 16,384-dependency output capacity remain to be demonstrated with the selected circuit.
