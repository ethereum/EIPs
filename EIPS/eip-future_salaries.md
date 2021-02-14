---
eip: 3267
title: Giving Ethereum fees to Future Salaries
author: Victor Porton (@vporton), Victor Porton <porton@narod.ru>
discussions-to: https://www.g2.com/discussions/38029-discussion-of-eip-3267 (TBD: moving to https://ethereum-magicians.org)
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
This proposal solves two problems at once:

1. It provides a big amount of "money" to common good producers. That obviously personally benefits common good producers, allowing them to live better human lives, it increases peoples' and organizations' both abilities and incentives to produce common goods. That benefits the humanity as a whole and the Ethereum ecosystem in particular. See more in the discussion why it's crucial.

2. This would effectively decrease circulating ETH supply. The necessity to decrease the (circulating) ETH supply (by locking ETH in Future Salaries system for a long time) is a well-known important thing to be done.

Paradoxically, it will directly benefit miners/validators, see the discussion.

## Specification
(TBD)

`SalaryWithDAO` = `TBD`

`DefaultDAOInterface` = `TBD`

Prior to `FORK_BLOCK_NUMBER`, the contracts [SalaryWithDAO](https://github.com/vporton/future-contracts/blob/master/contracts/SalaryWithDAO.sol) and [DefaultDAOInterface](https://github.com/vporton/future-contracts/blob/master/contracts/DefaultDAOInterface.sol) contracts will be deployed to the network and exist at the above specified addresses.

Change the Ethereum clients to create a transaction every some amount of time (the first transaction of every day in UTC? - TBD) to mint an agreed upon (requires further discussion) amount of ETH to `DonateETH`.

## Rationale
The Future Salaries is the _only_ known system of distributing significant funds to common good producers. (Quadratic funding aimed to do a similar thing, but in practice as we see on GitCoin it favors a few developers, ignores project of highly advanced scientific research that is hard to explain to an average developer, and encourages colluding, and it just highly random due to small number of donors. Also quadratic funding simply does not gather enough funds to cover common good needs). So this EIP is the only known way to recover the economy.

The economical model of Future Salaries is described in [this research article preprint](https://github.com/vporton/gitcoin-web/blob/future/app/assets/docs/science-salaries.pdf).

Funding multiple oracles with different finish time would alleviate the future trouble that the circulating ETH (or other tokens) supply would suddenly increase when the oracle finishes.

## Backwards Compatibility
There are no backward incompatibilities.

We do ETH transfers as transactions, so there are no troubles with applications that have made assumptions about ETH transfers all occurring either as miner payments or transactions.

## Security Considerations
The security considerations are:
- The DAO may switch to a non-effective or biased way of voting (for example to being controlled by one human) thus distributing funds unfairly. This problem could be solved by a future fork of Ethereum that would "confiscate" funds from the DAO.

See more in the discussion.

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
