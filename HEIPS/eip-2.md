---
eip: 2
title: 하드포크 홈스테드(Homestead) 변경사항
author: Vitalik Buterin <v@buterin.com>
status: Final
type: Standards Track
category: Core
created: 2015-11-15
---

### Meta 참조문서

[홈스테드(Homestead)](https://github.com/ethereum/EIPs/blob/master/EIPS/eip-606.md).

### 매개 변수(Parameters)

|   FORK_BLKNUM   | CHAIN_NAME  |
|-----------------|-------------|
|    1,150,000    | Main net    |
|   494,000       | Morden      |
|    0            | Future testnets    |

# 사양

`block.number >= HOMESTEAD_FORK_BLKNUM`인 경우, 다음을 수행한다.:

1. *컨트랙트를 생성하는 트랜잭션*의 가스비는 21,000에서 53,000으로 증가한다. 즉, 당신이 보낸 트랜잭션의 주소가 빈 문자열이면, 초기 가스 비용은 53,000에 트랜잭션 데이터의 가스비를 더한 것이다. 현재의 경우는 21,000이다. `CREATE` opcode를 사용한 컨트랙트 생성은 영향을 받지 않는다.
2. s값이 `secp256k1n/2`보다 큰 모든 트랜잭션 서명은 유효하지 않은 것으로 간주된다. 사전 컴파일된 ECDSA 복원 컨트랙트는 변경되지 않은 채 큰 s값을 수용한다 (이것은 예전 비트코인 서명을 복원하는 컨트랙트에서 유용하다).
3. 컨트랙트 생성시 컨트랙트 코드를 상태에 추가하기 위한 최종 가스비를 지불하기에 가스가 부족한 경우, 이를 빈 컨트랙트로 남겨두기 보다는 컨트랙트 생성에 실패한다(즉, out-of-gas).
4. 난이도 조정 알고리즘을 현재 공식: `block_diff = parent_diff + parent_diff // 2048 * (1 if block_timestamp - parent_timestamp < 13 else -1) + int(2**((block.number // 100000) - 2))` (이 부분` + int(2**((block.number // 100000) - 2))`은 지수 난이도 조정 구성요소를 나타낸다)으로 부터 `block_diff = parent_diff + parent_diff // 2048 * max(1 - (block_timestamp - parent_timestamp) // 10, -99) + int(2**((block.number // 100000) - 2))`으로 변경한다, 이 부분(`//`)은 정수 나눗셈 연산이다. (예: `6 // 2 = 3`, `7 // 2 = 3`, `8 // 2 = 4`). `minDifficulty`은 여전히 허용되는 최소 난이도로 정의하고, 이 아래로는 조정되지 않는다.

# 근거

현재 트랜잭션을 통해 컨트랙트를 생성하는 것에는 과한 유인이 있다. 여기서 비용이 21,000인 것과 달리 컨트랙트에서는 비용이 32,000이다. 또한, 자가 종결 환불의 도움으로 간단히 11,664 가스의 이더값만 전송에 사용할 수 있다. 이렇게 하기위한 코드는 다음과 같다.

```python
from ethereum import tester as t
> from ethereum import utils
> s = t.state()
> c = s.abi_contract('def init():\n suicide(0x47e25df8822538a8596b28c637896b4d143c351e)', endowment=10**15)
> s.block.get_receipts()[-1].gas_used
11664
> s.block.get_balance(utils.normalize_address(0x47e25df8822538a8596b28c637896b4d143c351e))
1000000000000000
```
이것이 특별히 심각한 문제는 아니지만, 그래도 틀림없는 버그이다.

Allowing transactions with any s value with `0 < s < secp256k1n`, as is currently the case, opens a transaction malleability concern, as one can take any transaction, flip the s value from `s` to `secp256k1n - s`, flip the v value (`27 -> 28`, `28 -> 27`), and the resulting signature would still be valid. This is not a serious security flaw, especially since Ethereum uses addresses and not transaction hashes as the input to an ether value transfer or other transaction, but it nevertheless creates a UI inconvenience as an attacker can cause the transaction that gets confirmed in a block to have a different hash from the transaction that any user sends, interfering with user interfaces that use transaction hashes as tracking IDs. Preventing high s values removes this problem.

Making contract creation go out-of-gas if there is not enough gas to pay for the final gas fee has the benefits that:
- (i) it creates a more intuitive "success or fail" distinction in the result of a contract creation process, rather than the current "success, fail, or empty contract" trichotomy;
- (ii) makes failures more easily detectable, as unless contract creation fully succeeds then no contract account will be created at all; and
- (iii) makes contract creation safer in the case where there is an endowment, as there is a guarantee that either the entire initiation process happens or the transaction fails and the endowment is refunded.

The difficulty adjustment change conclusively solves a problem that the Ethereum protocol saw two months ago where an excessive number of miners were mining blocks that contain a timestamp equal to `parent_timestamp + 1`; this skewed the block time distribution, and so the current block time algorithm, which targets a *median* of 13 seconds, continued to target the same median but the mean started increasing. If 51% of miners had started mining blocks in this way, the mean would have increased to infinity. The proposed new formula is roughly based on targeting the mean; one can prove that with the formula in use, an average block time longer than 24 seconds is mathematically impossible in the long term.

The use of `(block_timestamp - parent_timestamp) // 10` as the main input variable rather than the time difference directly serves to maintain the coarse-grained nature of the algorithm, preventing an excessive incentive to set the timestamp difference to exactly 1 in order to create a block that has slightly higher difficulty and that will thus be guaranteed to beat out any possible forks. The cap of -99 simply serves to ensure that the difficulty does not fall extremely far if two blocks happen to be very far apart in time due to a client security bug or other black-swan issue.

# Implementation

This is implemented in Python here:

1. https://github.com/ethereum/pyethereum/blob/d117c8f3fd93359fc641fd850fa799436f7c43b5/ethereum/processblock.py#L130
2. https://github.com/ethereum/pyethereum/blob/d117c8f3fd93359fc641fd850fa799436f7c43b5/ethereum/processblock.py#L129
3. https://github.com/ethereum/pyethereum/blob/d117c8f3fd93359fc641fd850fa799436f7c43b5/ethereum/processblock.py#L304
4. https://github.com/ethereum/pyethereum/blob/d117c8f3fd93359fc641fd850fa799436f7c43b5/ethereum/blocks.py#L42
