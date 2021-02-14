---
eip: 3267
title: Giving Ethereum fees to Future Salaries
author: Victor Porton (@vporton), Victor Porton <porton@narod.ru>
status: Draft
type: Standards Track
category: Core
created: 2021-02-13
---

## Simple Summary
Transfer a part of Ethereum transfer/mining fees to Future Salaries contract

## Abstract
Transfer a part (exact fractions - TBD) of mining/transfer fees to the contract `DonateETH` contract configured to transfer to `SalaryWithDAO` contract.

## Motivation
There are two motivations:

1. It provides a big amount of "money" to common good producers. That obviously personally benefits common good producers, allowing them to live better human lives, it increases peoples' and organizations' both abilities and incentives to produce common goods. That benefits the humanity as a whole and the Ethereum ecosystem in particular. In my opinion (Victor Porton), this is crucial for survival of mankind because of the following reasons: a. Suppose an important scientific discovery was wrongly published and because of the wide-spread "no-republication of already published" scientific ethic it may become that there will be nothing in the mankind what would make this discovery to enter into scientific databases and/or raise reasonably high in search engines result pages. This would effectively mean that a part of science is missing in human knowledge (it could be rediscovered but not re-published due to the above described reasons). A missing part of the science would make the entire science development stuck. So, mankind would become unable to resist exestential problems (like climate change or asteroid impact) and likely die completely in near future. b. There is no other known (already discovered) economical incentive to finance climate actions than this proposal. So if this proposal won't be accepted, we are unable to resist climate change. You may assume that humanity has a way to overcome these problems and you are right: a way is this EIP.

2. This would effectively decrease circulating ETH supply. The necessity to decrease the (circulating) ETH supply (by locking ETH in Future Salaries system for a long time) is a well-known important things to be done.

> For a multi-asset smart contract platform to function as a store of value, proper incentives must be put in place to align in the growth in value of a network's assets with its underlying security. Or put another way, the platform's native token must be a good value capture of the platform's aggregate asset value. If the intrinsic value of a platform's native token is limited to transaction fee payment, its value would be determined solely by transaction demand, instead of the demand of asset storage. (https://github.com/nervosnetwork/rfcs/blob/master/rfcs/0001-positioning/0001-positioning.md)

In other words, we need to measure the ETH "real" value. This EIP proposes to allocate *much* (it probably may be more than 90%) of miner's ETH fees to Future Salaries contract. So the cost of ETH will be associated with the real ("job") value of the conditional tokens of this contract.

So, this proposal partly solves both the well-known problems of
- decreasing (ciculating) ETH supply
- making ETH cost proportionally increasing when tokens' value increases (in other word incresing the ETH intristic value)

As the above mentioned RFC explains, it is good for miners/validators, because:
- It reduces manipulation incentives such as selfish mining
- It highly increases the security of the Ethereum network
- It increases the ETH intristic value, so miners/validators spend less on energy per amount of money earned.
- There is the danger (https://github.com/nervosnetwork/rfcs/blob/master/rfcs/0001-positioning/0001-positioning.md) that without radical measures like this proposal the value of ETH (not of Ethereum tokens) will become zero in some future, so greatly downshifting miners/validators.

## Specification
1. Finish the smart contract audit (it was already paid for) of [SalaryWithDAO](https://github.com/vporton/future-contracts/blob/master/contracts/SalaryWithDAO.sol) and [DefaultDAOInterface](https://github.com/vporton/future-contracts/blob/master/contracts/DefaultDAOInterface.sol) contracts.
2. After the audit is finished, deploy these contracts (together with a DAOstack DAO controlling the `DefaultDAOInterface` with voting tokens initially allocated by a community consensus) and create an oracle ID using the `SalaryWithDAO` API.
3. Audit and deploy [DonateETH](https://github.com/vporton/donations/blob/main/contracts/DonateETH.sol) redirecting ETH payments to this oracle, too.
4. Discuss the fractions of miners fees and transfer fees of ETH to be transferred to `DonateETH` at every mining and transfer operation.
5. Change the Ethereum clients to do these ETH transfers.

In the future (it should be a separate EIP) we can switch to some more sophisticated DeFi scheme (`SalaryWithDAO` contract does support donations in DeFi token) of converting ETH to ERC-1155 tokens to be transferred to `SalaryWithDAO` than simply wrapping ETH into ERC-1155 token by `DonateETH`, to increase future value of the tokens transferred to `SalaryWithDAO`.

Additional proposal for future consideration:

- Consider (by the DAO voting) "obliging" the above mentioned DAO by a smart contract (with ownership transfer) to set the minimum oracle finish date in the future to some fixed value (need to discuss the exact number of years to lock funds for).
- Consider (in a separate EIP) creating new oracles with shifted to father future (e.g. by one year forward once per year) the minimum finish times and spreading the transferred funds between several such oracles.

## Rationale
The Future Salaries is the _only_ known system of distributing significant funds to common good producers. (Quadratic funding aimed to do a similar thing, but in practice as we see on GitCoin it favors a few developers, ignores project of highly advanced scientific research that is hard to explain to an average developer, and encourages colluding, and it just highly random due to small number of donors. Also quadratic funding simply does not gather enough funds to cover common good needs). So this EIP is the only known way to recover the economy.

The economical model of Future Salaries is described in [this research article preprint](https://github.com/vporton/gitcoin-web/blob/future/app/assets/docs/science-salaries.pdf).

Funding multiple oracles with different finish time would alleviate the future trouble that the circulating ETH (or other tokens) supply would suddenly increase when the oracle finishes.

## Backwards Compatibility
This EIP requires a hard fork, so we need some time for all clients to be updated. The change in clients is however trivial and the update won't require much time.

## Security Considerations
The security considerations are:
- The contract audit of `SalaryWithDAO` and of `DefaultDAOInterface` was paid for. But the re-audit would be good for such a drastic change.
- `DonateETH` also needs to be audited.
- The value of wrapped ETH transferred to `SalaryWithDAO` may happen to decrease with time (despite that this EIP itself and some others aim to increase ETH value), so (as it were told to be discussed in a separate EIP) need to consider alternative DeFi schemes than simply wrapping ETH in ERC-1155.
- Future Salaries system is expected to create big unfounded bubbles of somebody's personal tokens. This problem seems inevitable, but the existing problems this EIP aims to solve are much worse.
- The DAO may switch to a non-effective or biased way of voting (for example to being controlled by one human) thus distributing funds unfairly. This problem could be solved by a future fork of Ethereum that would "confiscate" funds from the DAO.

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
