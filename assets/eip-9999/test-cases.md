# Test Cases

Implementations must pass all tests in this file.

## Contract modes

| Current mode | Caller | Command | Expected result |
| --- | --- | --- | --- |
| `DISABLED` | `SYSTEM_ADDRESS` | `ENABLE_DEPOSITS_COMMAND` | Mode becomes `BLS_ENABLED` |
| `DISABLED` | `SYSTEM_ADDRESS` | `RETIRE_BLS_COMMAND` | Revert |
| `BLS_ENABLED` | `SYSTEM_ADDRESS` | `ENABLE_DEPOSITS_COMMAND` | Revert |
| `BLS_ENABLED` | `SYSTEM_ADDRESS` | `RETIRE_BLS_COMMAND` | Mode becomes `BLS_RETIRED` |
| `BLS_RETIRED` | `SYSTEM_ADDRESS` | Any command | Revert |
| Any mode | Other address | Any command | Revert |

Tests must execute the enable call after the EIP-4788 and EIP-2935 calls. They
must execute it before the first transaction in the activation block. If both
fork timestamps match, tests must execute the retirement call after the enable
call and before the first transaction.

## Deposit amounts

Use `BLS_ENABLED`, a nonzero scheme, and fields within their caps:

| `msg.value` | Expected result |
| --- | --- |
| `(MIN_DEPOSIT_AMOUNT - 1) * 1 gwei` | Revert |
| `MIN_DEPOSIT_AMOUNT * 1 gwei` | Accept and emit |
| `MIN_DEPOSIT_AMOUNT * 1 gwei + 1 wei` | Revert |
| `(2**64 - 1) * 1 gwei` | Accept and emit |
| `2**64 * 1 gwei` | Revert |

## Deposit schemes

For valid deposit amounts:

| Mode | Scheme | Pubkey length | Metadata length | Expected result |
| --- | ---: | ---: | ---: | --- |
| `DISABLED` | Any | Within cap | Within cap | Revert |
| `BLS_ENABLED` | 0 | 48 | 96 | Accept and emit |
| `BLS_ENABLED` | 0 | 47 | 96 | Revert |
| `BLS_ENABLED` | 0 | 48 | 95 | Revert |
| `BLS_ENABLED` | 1 | 0 | 0 | Accept and emit |
| `BLS_ENABLED` | 255 | 48 | 96 | Accept and emit |
| `BLS_RETIRED` | 0 | 48 | 96 | Revert |
| `BLS_RETIRED` | 1 | 0 | 0 | Accept and emit |
| `BLS_RETIRED` | 255 | 48 | 96 | Accept and emit |

For a nonzero scheme, the result does not depend on the field lengths when
both fields are within their caps.

## Field length caps

For a nonzero scheme and a valid deposit amount, implementations must test
these boundaries in both `BLS_ENABLED` and `BLS_RETIRED` modes:

| Pubkey length | Metadata length | Expected result |
| ---: | ---: | --- |
| 8192 | 8192 | Accept and emit the complete fields |
| 8193 | 0 | Revert |
| 0 | 8193 | Revert |

## Cross-layer behavior

Tests must also show that:

- Execution clients include every event accepted by
  `decode_credential_deposit_event` in canonical order.
- Execution clients convert each valid legacy deposit event into a scheme-0
  `CredentialDepositRequest` and omit its deposit index.
- The combined request list preserves log order across both contract addresses.
- Execution clients include requests with unassigned schemes.
- The generalized request SSZ encoding round-trips for variable field lengths.
- BLS requests append the expected existing `PendingDeposit`.
- Requests with unassigned schemes do not change consensus state at initial
  activation.
- Ignored requests accepted before a scheme's activation are not replayed
  later.
- A generalized deposit followed by a legacy deposit for the same new BLS key
  processes in that transaction order.
- Both BLS paths work before retirement.
- Legacy events do not produce EIP-6110 requests after initial activation.
- Valid activation-or-later payloads omit the EIP-6110 request type and keep
  `ExecutionRequests.deposits` empty.
