Here is a copy of the tl;dr section from an [extended analysis](https://hackmd.io/@adrninistrator1/SkHmz972n) of `pubkey2index` and `index2pubkey` cache usage provided by Navie Chan:

tl;dr: `index2Pubkey` is used in a lot more scenarios than `pubkey2Index`. The use cases for `index2Pubkey` do not require unfinalized information. `process_deposit()` is the only place in consensus spec that needs unfinalized information and it utilizes `pubkey2Index`.
In terms of the two-cache approach, `unfinalizedIndex2Pubkey` is not needed since there is not a place that utilizes it. `unfinalizedPubkey2Index`, however, is needed for `process_deposit()`.

|  | unfinalized pubkey2Index? | unfinalized index2Pubkey? |
|-|-|-|
| onBlock - state_transition - verify_block_signature | N/A | No |
| onBlock - state_transition - process_block - process_randao | N/A | No |
| onBlock - state_transition - process_block - process_operations - process_proposer_slashing | N/A | No |
| onBlock - state_transition - process_block - process_operations - process_attester_slashing - is_valid_indexed_attestation | N/A | No |
| onBlock - state_transition - process_block - process_operations - process_attestation - is_valid_indexed_attestation | N/A | No |
| onBlock - state_transition - process_block - process_operations - process_deposit - apply_deposit | Yes | N/A |
| onBlock - state_transition - process_block - process_operations - process_sync_aggregate - eth_fast_aggregate_verify | No | No |
| onBlock - state_transition - process_block - process_bls_to_execution_change | N/A | N/A |
| onBlock - state_transition - process_block - process_voluntary_exit | N/A | No |
| p2p - beacon_block ---- onBlock | N/A | No |
| p2p - beacon_aggregate_and_proof ---- onAttestation | N/A | No |
| p2p - voluntary_exit - process_voluntary_exit | N/A | No |
| p2p - proposer_slashing - process_proposer_slashing | N/A | No |
| p2p - attester_slashing - process_attester_slashing | N/A | No |
| p2p - beacon_attestation_{subnet_id} ---- onAttestation | N/A | No |
| p2p - sync_committee_contribution_and_proof | N/A | No |
| p2p - sync_committee_{subnet_id} | N/A | No |
| p2p - bls_to_execution_change - process_bls_to_execution_change | N/A | N/A |
| p2p - blob_sidecar_{subnet_id} - verify_blob_sidecar_signature | N/A | No |
