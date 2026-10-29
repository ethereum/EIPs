# Proof-reuse benchmarks

Compare fresh aggregation with proof reuse on the same transaction workload, peer graph and network conditions. These are measurements, not additional validity rules.

Use identical and partially overlapping mempool views, transaction arrivals and evictions, different transaction sets sharing dependencies, and unavailable or invalid reuse offers. Vary the number of aggregators and transaction-hash prefix length; report bucket subdivision policy and wrapper/circuit bounds. Each node runs its own aggregation timer without coordinated phases.

Report:

- **Proofs produced per transaction network-wide:** total completed recursive proofs across all participating aggregators, including intermediate and discarded results, divided by distinct valid transactions introduced during the measured run. Relaying or verifying a proof does not count as producing one; input witnesses and user-produced proofs are excluded.
- Total proving time, including abandoned work; proof verifications; exact-set reuse and partial-coverage merge rates.
- Bytes transferred and transaction propagation latency, including fetches that fail or return invalid data.
- Workload duration and drain period, transaction count, dependency counts, node hardware, peer topology, aggregator count, network conditions and partition parameters.

Use the same observation window and drain policy for both runs. Lower proof counts alone do not establish an improvement if transactions propagate later or less reliably.
