# EIP-8288 FOCIL conformance cases

These cases extend Test Case 9 of [EIP-8288](../../EIPS/eip-8288.md), FOCIL with Recursive STARK. Each row is one required behavior.

| # | Case |
| --- | --- |
| 1 | For an empty dependency set, only a null `recursive_stark` is valid; an empty `stark_proof` is not a valid proof. |
| 2 | A list containing a transaction that fails to decode, or whose dependency frame uses a scheme outside `ENABLED_SCHEMES`, derives `deps` without that transaction's dependencies. |
| 3 | A list whose non-null commitment names an unavailable or invalid proof, or one covering no statically valid dependency-bearing entry, stays counted with the commitment treated as null, obligating only its dependency-free transactions. |
| 4 | A non-null commitment on a list whose derived `deps` is empty, including one whose only dependency-bearing transaction fails static validity, gets `INVALID` and is treated as null; that transaction is not dependency-free, so it is not obligated. |
| 5 | A transaction with a dependency verification frame carrying no triples is likewise dependency-bearing, not dependency-free. |
| 6 | With a `timestamp` in a fork whose `AGGREGATED_VK` differs from the one a held proof verified under, that proof does not count: `PROOF_UNKNOWN` without an `il_proof`, and `INVALID` with it. |
| 7 | A proof or its authenticated list first obtained after the proof deadline does not create dependency-bearing obligations, even if both arrive before view freeze. A builder may still fetch it before the proposal deadline to satisfy another attester's view. |
| 8 | An execution layer that returned `VALID` for a wrapper proof still serves it until the supplied `attestation_deadline_ms` after evicting the wrapper. |
| 9 | Within `MAX_DEPS_PER_IL_PROOF`, a wrapper proof covering the list's dependencies returns `VALID` without repeat verification when held, or `PROOF_UNKNOWN` when neither wrapper nor matching `il_proof` is held. |
| 10 | `engine_getInclusionListProofV1` returns the held `InclusionListProof` for the wrapper's proof hash; it returns null for an unknown hash or a wrapper proof exceeding IL bounds. |
| 11 | An `il_proof` whose `proof_deps` do not hash to `deps_hash` is ignored. |
| 12 | On the proof topic, a valid `SignedInclusionListProof` from a slot-`N` committee member is forwarded once `engine_submitInclusionListProofV1` returns `VALID`, after which `engine_verifyInclusionListProofV1` returns `VALID` by cache lookup, without an `il_proof` argument, for a later list committing to it. |
| 13 | Once the execution layer has released that proof's bytes at `view_freeze_deadline_ms` but kept its verdict, it returns `PROOF_UNKNOWN` without an `il_proof`, and `VALID` with a matching one, reusing the verdict without verifying again; `engine_getInclusionListProofV1` returns null until the bytes are supplied again. |
| 14 | After `engine_submitInclusionListProofV1` returns `INVALID` for a proof, `engine_verifyInclusionListProofV1` returns `INVALID` for a list committing to it under the same `AGGREGATED_VK`, with or without an `il_proof`, rather than `PROOF_UNKNOWN`. |
| 15 | A proof signed by a validator not at `committee_index` of slot `N`'s IL committee, one whose `stark_proof` or `proof_deps` does not hash to `stark_proof_hash` or `deps_hash`, one over the size bounds, or one whose `stark_proof` fails verification is rejected and not forwarded. |
| 16 | A second signed proof from the same member for the slot with a different `stark_proof_hash`, arriving during the slot, is forwarded once `engine_submitInclusionListProofV1` returns `VALID`; a third, one repeating an accepted `stark_proof_hash`, or a second arriving before the slot is dropped without marking the member an equivocator, and the member's list, which may commit to null or a different proof, is checked as usual. |
| 17 | A CL that accepted topic proofs A and B may fetch a distinct proof C committed by that member's first counted list. `VALID` by the proof deadline enables only C's covered entries. At most three proofs per member per slot are authorized: two topic proofs and one list-committed proof. |
| 18 | An attester with an authenticated list and a valid committed proof by the proof deadline obligates its covered transactions; an attester without them obligates only dependency-free entries. |
| 19 | A CL passes a non-null commitment for its inclusion view only after `VALID` on its own EL by the proof deadline, and null otherwise. Builders may separately obtain later proofs. |
| 20 | List equivocation cancels that member's pending list-proof work. Two topic proofs plus one separately retrieved committed proof permit up to `3 × IL_COMMITTEE_SIZE` (48) proofs per committee, and 80 across overlapping committees as detailed in the benchmark asset; the 16-proof bound applies only to list-committed proofs per committee. |
| 21 | One aggregate proof covers list A but not list B: verification returns `INVALID` for B without invalidating the aggregate verdict; A still returns `VALID` with the retained proof. |
| 22 | A list contains covered transaction A, uncovered transaction B, and a malformed entry. Return `VALID` for the committed proof and enforce A independently; B and the malformed entry introduce no dependency-bearing obligations. Coverage uses the named state-independent predicate under the target block's fork. |
| 23 | A valid proof has 128 dependencies, one needed by its list. It passes the IL count bound; 129 fails before verification. The larger proof may remain valid as a mempool wrapper and its aggregate verdict is not invalidated. |
| 24 | An omitted, proven transaction passes the EIP-7805 inclusion check except that its dependencies are absent from the current block proof. This absence does not excuse omission; the hypothetical check does not rebuild or test coverage of the current proof. |
| 25 | Before fork F, submit an early proof for a slot-F target using F's key while the mempool still targets the preceding fork. The IL-proof Engine methods select F from `timestamp` and accept it; ordinary wrapper admission does not change. |
| 26 | Encode null as an empty `List[InclusionListProofCommitment, 1]` and a commitment as a singleton. Their signing roots differ. Reject a two-entry list and a proof signature under the list-signing domain. |
| 27 | Request retention beyond either the target-time or local-time ceiling. Return `-32602`, without silently clamping or caching a cryptographic failure. Storage exhaustion returns an API error rather than `INVALID`. |
