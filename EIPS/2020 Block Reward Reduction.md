---
eip: <to be assigned>
title: 2020 Block Reward Reduction to 0.5 ETH
author: John Lilic @jlilic twitter.com/johnlilic johnlilicEIP@gmail.com, Jerome de Tychey @jdetychey twitter.com/jdetychey,  Others
discussions-to: 
status: Draft
type: Standards Track
category Core
created: 2020-08-11
---


## Simple Summary

This EIP will reduce the block reward paid to proof-of-work validators.  Reducing the block reward will maintain the status quo of periodic community-activated block reward reductions.  

## Abstract
Of the top 4 Proof-of-Work blockchains, Ethereum pays the highest inflation rate for block validation.  Blockchains both larger, and smaller than Ethereum pay lower rates without any adverse effects.  Over-paying for block validators is an inefficiency that negatively affects all ETH holders, as it unnecessarily inflates the montary base and reduces the purchasing power of all Ether holders.   This EIP will reduce the block reward to bring inflation in-line with Bitcoin, which is the largest cryptocurrency by market cap.   Block rewards will thus be adjusted to a base of 0.5ETH, uncle and nephew rewards will be adjusted accordingly.    

## Motivation

A block reward that is too high is inefficient and negatively impacts the ecosystem economically. There is prior precedent for reducing the block reward; it has been done twice in the past in tandem with the diffusion of prior difficulty bombs.  The most recent diffusion, Muir Glacier, did not include a block reward reduction and thus broke the prior status-quo.  This EIP will revive the previous status-quo of periodical block reward reductions based on economic conditions.   With the upcoming release of ETH2.0 Phase 0 staking, inflationary pressures on Ethereum will be further increased.  Reducing the block reward prior to ETH2.0 Phase 0 staking will assist in alleviating negative inflationary effects.

## Specification
Parameters in the source code that define the block reward will be adjusted accordingly.

## Rationale
We determine the target block reward by first comparing the Bitcoin inflation rate:

At the Bitcoin Halving there were 18,375,000 Bitcoins in circulation.   There are 328,500 new bitcoins mined each year (6.25 BTC/Day * 144 Blocks per day * 365 Days in a year).  The annual inflation rate for Bitcoin is is thus  1.78%. (328,500 / 18,375,000 * 100) 

At the time of writing, there were 110,875,500 Ether in circulation.  There are 4,982,250 Ether mined each year (13,650 ETH/Day * 365 Days in a year).  The annual inflation rate for Ethereum is thus 4.49%.  (4,982,250 / 110,875,500 * 100). (See https://etherscan.io/chart/blockreward for the approximate daily Ether reward)

The result of this comparison shows that Ethereum is currently paying a 2.52x higher block reward than Bitcoin.

To further illustrate the point, if the ETH/BTC ratio increases to 0.041, all else equal, Ethereum will be paying a higher reward in $USD than bitcoin, despite being 3 times smaller in Market Capitalization.
 Sometime after November 2020, the Ethereum 2.0 Phase 0 chain will launch.  This chain will further add to the inflation rate of Ethereum, as it will generate staking rewards for all users that stake a deposit and validate blocks on the chain. 

The annual issuance from staking rewards is planned to be equal to 181 * SQRT(total ETH staked).  A chart below illustrates some possible values.

| ETH validating | Max annual issuance | Max annual network inflation % |Max annual reward rate (for validators) |
| ------ | ------ | ------ | ------ |
|1,000,000	| 181,019|	0.17%|	18.10%|
|3,000,000	| 313,534|	0.30%|	10.45%|
|10,000,000	| 572,433|	0.54%|	5.72%|
|30,000,000	| 991,483|	0.94%|	3.30%|
|100,000,000|1,810,193|	1.71%|	1.81%|

It it highly unlikely that 100,000,000 ETH will stake on the beacon chain.  So we will use the lower number of 10M for our estimations.

At this rate, the ETH inflation rate will increase to  5,554,683 ETH/yr. (4,982,250+572,433 =5,554,683). This yields an annual inflation rate of  ~ 5.00% (5,554,683/110,875,500 * 100). At this rate, Ethereum’s inflation will be 2.81x (5.00/1.78) higher than bitcoin.

In order to calculate the block subsidy required to achieve inflation parity with Bitcoin, we must first back out our estimations for ETH2.0 issuance in order to determine the maximum annual POW reward.  

1,973,583.9 - 572,433 = 1,401,150.9 Max Annual PoW Rewards.

Now, we calculate the max daily reward.

1,401,150.9 / 365 = 3839 Max Daily PoW Rewards.

With a targeted block time of 13s, there are approximately 60*60*24 / 13.1 = 6,646 blocks per day.

3839/6646 = 0.5776 ETH per block.

According to Etherscan, uncle rewards are responsible for approximately 5% of the total daily reward emission. Therefore, the base block subsidy should be 0.5776 * 0.95 = 0.549.

Thus, we arrive at a rate of 0.55 ETH base block reward to match Bitcoin’s inflation rate. 

We further note however, that the transaction fee market for Ethereum has risen sharply this year. As of August 11 2020, at the time of publishing this EIP, the fees from transactions make up almost 80% the current block rewards (2ETH). Thus, even if the block reward was set to zero, miners would still earn 1.8ETH from transaction fees per block.  Due to a robust and thriving fee market, we prepose to round to round down our block reward calculation from 0.55 to 0.5, which means (at the time of writing) miners would earn 1.8ETH in fees + 0.5ETH block reward, for a total of 2.3ETH per block. 


## Backwards Compatibility
All nodes must be upgraded to reflect the change in the block reward.



## Security Considerations
Changing the block reward is purely an economic action, requiring only a change to the block reward parameter.

Economically speaking, a block reward that is too low may result in low miner participation due to insufficient financial incentives.  This may result in a decrease of network security that may put PoW blockchains at risk of 51% re-org attacks. 

In this EIP we have laid out our economic evidence that reducing the block reward to 0.5 ETH would not negatively affect security by comparing it to other blockchains with larger market capitalizations.  Furthurmore, we note that Miners' expenses for housing and electricity are priced in FIAT terms (no electrical utilities in the in the world currently charge for Kilowatt-Hours in ETH). Therefore, miners make their mining decisions based on FIAT revenues they expect to earn. In $USD terms, miners would still be paid more than they were 3 months ago if this EIP were accepted (and still more than the 12 month average).  Thus, with this EIP, mining security economics are still better than they were 3 months ago when the price of ETH was half of what it is now, and the transaction fees were a fraction of their current value. 

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).


