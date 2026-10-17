# EIP-8288 FOCIL conformance cases

These cases extend Test Case 9 of [EIP-8288](../../EIPS/eip-8288.md), FOCIL with Recursive STARK. Each row is one required behavior.

| # | Case |
| --- | --- |
| 1 | For an empty dependency set, only a null `recursive_stark` is valid; an empty `stark_proof` is not a valid proof. |
| 2 | A list containing a transaction that fails to decode, or whose dependency frame uses a scheme outside `ENABLED_SCHEMES`, derives `deps` without that transaction's dependencies. |
| 3 | A list whose non-null commitment names a proof the execution layer does not hold, a proof that fails, or one whose `proof_deps` omits a dependency of the list stays counted with the commitment treated as null, obligating only its dependency-free transactions. |
| 4 | A non-null commitment on a list whose derived `deps` is empty, including one whose only dependency-bearing transaction fails static validity, gets `INVALID` and is treated as null; that transaction is not dependency-free, so it is not obligated. |
| 5 | A transaction with a dependency verification frame carrying no triples is likewise dependency-bearing, not dependency-free. |
| 6 | With a `timestamp` in a fork whose `AGGREGATED_VK` differs from the one a held proof verified under, that proof does not count: `PROOF_UNKNOWN` without an `il_proof`, and `INVALID` with it. |
| 7 | An `il_proof` first obtained after the view freeze deadline does not make an attester obligate the list's dependency-bearing transactions, while a builder may still fetch it before the proposal deadline. |
| 8 | An execution layer that returned `VALID` for a wrapper proof still serves it until the supplied `attestation_deadline_ms` after evicting the wrapper. |
| 9 | A commitment to a mode-1 wrapper's proof whose `deps` strictly contain the list's dependencies is valid: `engine_verifyInclusionListProofV1` returns `VALID` without verifying a proof for an execution layer holding the wrapper, and `PROOF_UNKNOWN` for one holding neither the wrapper nor an `il_proof`, until a matching `il_proof` is supplied. |
| 10 | `engine_getInclusionListProofV1` on the execution layer holding the wrapper returns `[stark_proof, deps]` for the wrapper's proof hash, which the other execution layer accepts, and returns null for an unknown hash. |
| 11 | An `il_proof` whose `proof_deps` do not hash to `deps_hash` is ignored. |
| 12 | On the proof topic, a valid `SignedInclusionListProof` from a slot-`N` committee member is forwarded once `engine_submitInclusionListProofV1` returns `VALID`, after which `engine_verifyInclusionListProofV1` returns `VALID` by cache lookup, without an `il_proof` argument, for a later list committing to it. |
| 13 | Once the execution layer has released that proof's bytes at `view_freeze_deadline_ms` but kept its verdict, it returns `PROOF_UNKNOWN` without an `il_proof`, and `VALID` with a matching one, reusing the verdict without verifying again; `engine_getInclusionListProofV1` returns null until the bytes are supplied again. |
| 14 | After `engine_submitInclusionListProofV1` returns `INVALID` for a proof, `engine_verifyInclusionListProofV1` returns `INVALID` for a list committing to it under the same `AGGREGATED_VK`, with or without an `il_proof`, rather than `PROOF_UNKNOWN`. |
| 15 | A proof signed by a validator not at `committee_index` of slot `N`'s IL committee, one whose `stark_proof` or `proof_deps` does not hash to `stark_proof_hash` or `deps_hash`, one over the size bounds, or one whose `stark_proof` fails verification is rejected and not forwarded. |
| 16 | A second signed proof from the same member for the slot with a different `stark_proof_hash`, arriving during the slot, is forwarded once `engine_submitInclusionListProofV1` returns `VALID`; a third, one repeating an accepted `stark_proof_hash`, or a second arriving before the slot is dropped without marking the member an equivocator, and the member's list, which may commit to null or a different proof, is checked as usual. |
| 17 | A CL that has accepted proofs A and B from a member whose counted list commits to a third, C, requests C and, on `VALID` from `engine_verifyInclusionListProofV1` with the supplied `il_proof` by the view freeze deadline, obligates all the list's transactions, as an attester that already held C does; a CL requests no hash that no counted, non-equivocating member's list commits to, so it verifies at most three proofs per member per slot. |
| 18 | An attester holding a valid proof for a counted list's commitment obligates all its transactions; one without it, or under a null commitment, obligates only the dependency-free ones. |
| 19 | A CL passes the commitment to block building or `engine_newPayload` only after `VALID` on its own EL, and null otherwise. |
| 20 | Re-signing a list with a re-proved proof is handled by EIP-7805's equivocation rule: a CL fetches and verifies a proof for at most one list per member, cancels pending work for the member once it receives a second list, and its EL retains at most `IL_COMMITTEE_SIZE` proofs per slot. |
| 21 | One aggregate proof covers list A but not list B: verification returns `INVALID` for B without invalidating the aggregate verdict; A still returns `VALID` with the retained proof. |
