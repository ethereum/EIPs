## Preamble

    EIP: <to be assigned>
    Title: EnsIP: Auto Reveal
    Author: Alex Van de Sande (avsa@ethereum.org)
    Type: Ens Improvement Proposal
    Status: Draft
    Created: 2017-09-06


## Goal

Blind Vickrey Auctions, the process in which initial name distribution is set on ENS, is considered one of the most efficient resource allocation systems and has been considered a good approach for the initial distribution of names. Yet, this implementation is also responsible for the most common criticism about ENS is the multiple transaction process, which includes a time sensitive aspect that can result in total loss of funds. Also, since the soft launch period ended, more than 90% of the names go undisputed, so it is a waste to have a complex system requiring multiple interactions from the user to create a dispute resolution, when in most cases names are only requested by a single entity. The goal here is to propose a solution that keeps the advantages of Vickrey Auction while simplifying the process to the user.

**Side note** *Simplicity is not necessarily the opposite of complexity*, specially when we are talking about different levels. Sometimes the most apparently simple looking systems have a great deal of complexity underneath, invisible to most users.

### Why keep Vickrey Auctions at all?

One way to deal with the situation would be to remove Vickrey Auctions alltogether. For example the [Domain Sale contract](https://github.com/wealdtech/domainsale/blob/master/contracts/DomainSale.sol) created by Jim McDonald (with some inputs by myself) uses a standard auctions system that expires after 24h after the last bid was made. This means that if a domain goes undisputed, the buyer needs only to make a single transaction and wait. Standard auctions are known to create inflated prices, specially if bidders get into emotional bidding wars, which might be good for the seller, but since there isn't a concept of original seller in ENS, this isn't necessarily a good thing. Ideally we want users to pay rational utility price for domains.

Also, not necessarily the initial allocations needs to be the most common way to acquire a domain: if a system like Jim's becomes very popular for secondary markets, then we might be able to see a competition betweeen multiple models, which is good in the long run.

## Overview

The purpose of this document is to explore a way in which the properties of a blind vickrey auction can be kept, while removing the requirement of the user to reveal it a posteriori, by making bids as time-locked messages that can be "mined" by a network of computers. The process would be as follows:

1) **Encoding the bid** The potential bidder decides a name and then creates a random private key, with a small amount of bytes according to a **difficulty factor** given by the contract. Then it uses this small key to encrypt a message containing the name it wants and the amount it is willing to pay for it.

2) **Bidding** the bidder then makes a transaction to the chain with an amount of ether equal to or larger than their secret price. The contract doesn't need to store the full message, only a hash of it, the rest of the message can either be given off-chain to "miners" or it can be logged into an event on-chain to ensure it's available for everyone. The bidder also must reveal the size of the key they picked.

3) **Unlocking** anyone is able to "reveal" the bid by revealing the private key. It can be done by the bidder themselves or by other machines by bruteforcing them. Since the owner has revealed the size of the key, machines can decide not to try to unlock a message if they believe it will not be able to do so

4) **difficulty adjustments** If a key is found in less than 48 hours, the **difficulty** factor is slightly increased, in order to target a median of 48 hours. And in the same manner, whenever a bid is revealed after 48h the difficulty should also decrease ever so slightly

5) **Rewards** Rewards are given to the first person to reveal the key, so anyone bruteforcing it should reveal theirs as soon as they find one, or they might lose the chance of a reward. If no one has found any key after 48h, then the reward should increase exponentially, until a maximum period of 120 hours. After that period, it can only be revealed by the owner, and if the auction has been won by someone else, the bid will be declared invalid. If a large amount of bids go unrevealed, then the rewards should also adjust automatically.

6) **Minimum deposits** The current system has a minimum deposit hard coded to 0.01. This was never considered a final solution because of the floating value of ether and demand for ENS names. In this method the minimum deposit would be proportional to the revealer's fees. A value of twice the reveal fee would be suggested.

7) **Invalid bids** one extra factor would go into checking if a bid was valid: if the bid was revealed and the private key was larger than the size they had revealed, then the bid is declared invalid. Users are free to pick keys larger than the difficulty if they want to reveal it themselves, but they must be honest on the minimum size, so that revealers can choose to ignore bids that would take longer than 24 hours.

7) **Rewards origin** the system can pay itself, not only by requiring deposit fees but also by removing the **burning** of fees that occur in the current system. If a bid is revealed in 48h or less, then the reveal fee is paid directly from the bidder's deposit. The larger reveal fees, paid when a bid isn't revealed after 48h are taken from the larger fee pile, because it's not necessarily the bidder's fault. Bids encrypted with a larger key than the suggested difficulty pay no revealer's fee.

## Possible issues

* The process of bruteforcing keys could be considered a waste of electricity and a step back to the environment just as ethereum moves to a less resource intensive consensus engine.
* There is a non-trivial coordination issue when miners are deciding which bids to work on. If it takes 48h of constant bruteforcing to find a key, then all is wasted if another miners finds the same key before you. Miners could coordinate to attempt to bruteforce different bids, but this could create an unfair competition among parties that trust themselves not to lie.
* If there is enough collusion and not enough competition for bids, revealers can inflate the reward by finding bids and not revealing them until later when the rewards are larger.
* If there's not enough competition, revealers can find a way to bids for fake names just for the purpose of draining the ether on the fee accounts


## Conclusion

In the proposed system, the users would only need to do one transaction. Since the message is signed locally on a private key created on the client, that part can be also invisible to the user. All bids are revealed automatically for those who opted in the system, but can be also revealed manually if the user so desires (they can decide to give the key to a trusted third party to reveal it). This also would give a more useful utility for the thousands of ethers that have been currently [burned in the bidding fees](https://etherscan.io/address/0x000000000000000000000000000000000000dead), and could create another source of revenue for old mining machines.


I welcome discussions and ideas on this area: there might be some other more clever uses of zk-snarks that can accomplish the same result without having to bruteforce keys.

## Acknowledgements

I'd like to thank Nick Johnson for organizing the ENS workshop in London and all those who have attended for the very useful debates

