## Preamble

EIP: X

Title: Pessimistic locking for SLOAD

Author: Egor Homakov <homakov@gmail.com>

Status: Draft

Type: Standards Track Core

Created: 2017-09-21

## Simple Summary

To improve security-in-depth and isolation of contract storage, every SLOAD-ed record must be locked until termination of the frame.

## Abstract

This is the formal proposal. Here is rather emotional rationale: https://medium.com/@homakov/make-ethereum-blockchain-again-ef73c5b86582

We expose similarities between traditional databases vs contract storage and between traditional race conditions vs re-entrancy attacks. As a result we offer a rather traditional (known since 1993) approach that all financial applications are using to this date: implementation of pessimistic locks on storage records to prevent a race condition-like attacks like the one that happened with the DAO.

## Motivation

> Storage State: The information particular to a given Account that is maintained between the times that the Account’s associated EVM Code runs.


Contract storage is a database (A database is an organized collection of data https://en.wikipedia.org/wiki/Database). To be more precise, it's a part of the global state which is the database, and each storage is alike a table in a database, where SLOAD is basically `select value from Storage0xA where key="Key0xA"`.

This wiki has some examples of why isolation is important: https://en.wikipedia.org/wiki/Record_locking

>To allow several users to edit a database table at the same time and also prevent inconsistencies created by unrestricted access, a single record can be locked when retrieved for editing or updating. Anyone attempting to retrieve the same record for editing is denied write access because of the lock (although, depending on the implementation, they may be able to view the record without editing it). Once the record is saved or edits are canceled, the lock is released

That's exactly what happened to the DAO and can happen to anyone else in the future: 2 users (frames) are operating on the same record (balance of tokens for example) and they are doing the same operation more times that it was supposed to be done.

Most traditional databases do not lock records by default. Which had its consequinces off-chain either: 

http://hackingdistributed.com/2014/04/06/another-one-bites-the-dust-flexcoin/

These bugs are literally everywhere. __Except, none of them yielded $150M on an unreversible public ledger.__ So unlike traditional databases, Ethereum like no one else should take this problem seriously.

Why does it happen and is not prevented on the database level? Because financial stuff is a tiny part of usage for them (__even for financial applications, fiat race condition is not a big deal as it can be reversed with a little hassle__). If they locked the tables/records _by default_, they would be way too slow _by default_ albeit much more secure against isolation vulnerabilities.

That's why __they__ don't do that, but __we should__. That's why a lot of traditional apps can be hacked by simply sending 10 parallel requests instead of one.

Re-entrancy is no different from a race condition: the same contract is invoked in the same frame stack, while they both can work on the same record from the table (not exactly in parallel, but frame 3 in the middle of frame 1). 

And Ethereum's key-value contract storage, unlike traditional databases, _is all about finance_ and highly sensitive balances/amounts. On top of that the extra locking performance overhead doesn't cost anything for a blockchain and its use cases. 

So since the storage is __a database that operates only with sensitive values__ - that's where we need isolation the most. Let's introduce __pessimistic locking by default__ and redefine the SLOAD opcode. That does not break a single valid usage of a contract, yet prevents DAO-like attacks including the DAO itself (__which will be considered a technical fork over a political one from now on__ if this EIP is accepted).

## Specification

Need your advices on this one. I'm sure the idea is outright obvious. The goal is to lock a key that was SLOAD-ed, i.e. turn `select value from Storage0xA where key="Key0xA"` into `select value from Storage0xA where key="Key0xA" SELECT FOR UPDATE`.

Entire Storage0xA locking is probably an overkill. That would kill a few use-cases when the contract is called again in the same frame stack yet operates with different storage keys - no race condition bug there. Instead we should add a global lock array. After each frame termination the locks ackquired in this particular frame must be released.


```
def SLOAD(account, key)
  lock_id = account+key
  if $locked.includes(lock_id)
    throw;
  else
    $locked.push(account)
    old_SLOAD(account, key)
  end
end

def RETURN
  remove last X lock_ids (ones that were added in this frame)
  old_RETURN
end
```


## Rationale

Any software (Ethereum is one of them) should make a design change when a specific vulnerability is found way too often. That means no amount of documentation has managed to prevent it and the vulnerability is in underlying platform not in the specific codebase. 

A personal example: a mass assignment vulnerability has been fixed only after it was demonstrated on a high profile website.

That's also what happened to the DAO: the EVM vulnerability was demonstrated (exploited) in a contract that held 14% of internal currency, but unlike Rails, it is not fixed on the underlying platform up to date. As outlined above, it's safe to say it was NOT a vulnerability in the DAO, like many tried to pretend. 

It also certainly does not make it a vulnerability in Solidity. Otherwise, it would be fixed in Solidity already. It is not. What would the fix be? Locks. 

Granular per-record locks inside Solidity would cost way too much gas - each SLOAD would have an overhead of another SLOAD/SSTORE on top of it. 

Per-contract locks would also cost quite some gas and most contracts would opt-out from it. 

## Backwards Compatibility

The behavior should be changed from a certain block height. We should run a test how many transactions throughout entire history would throw with new consensus (wild guess: only the DAO one)

The old_SLOAD might be added as a new opcode SLOADUNSAFE but can't see a single use case for it.

## Test Cases

The DAO + draining transaction = throw.

## Implementations

...

## Copyright

Copyright and related rights waived via <a href="https://creativecommons.org/publicdomain/zero/1.0/">CC0</a>.
