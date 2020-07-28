---
sip: 73
title: Binary Market Competition
status: WIP
author: CryptoToit (@FarmerT), Danijel (@Danijel)
discussions-to: https://research.synthetix.io/t/sip-binary-competition/119

created: 2020-07-25
requires (*optional): <SIP number(s)>
---

<!--You can leave these HTML comments in your merged SIP and delete the visible duplicate text guides, they will not appear and may be helpful to refer to if you edit it again. This is the suggested template for new SIPs. Note that an SIP number will be assigned by an editor. When opening a pull request to submit your SIP, please use an abbreviated title in the filename, `sip-draft_title_abbrev.md`. The title should be 44 characters or less.-->


## Simple Summary
<!--"If you can't explain it simply, you don't understand it well enough." Simply describe the outcome the proposed changes intends to achieve. This should be non-technical and accessible to a casual community member.-->
Up to now, Binary market Creators and Bidders had to rely on the strike price in sUSD to create their market or place their bids.  
By allowing markets to be created with two coins, betting one against the other, we increase the number of options for creators, and make markets more attractive to a wider range of bidders.

## Abstract
<!--A short (~200 word) description of the proposed change, the abstract should clearly describe the proposed change. This is what *will* be done if the SIP is implemented, not *why* it should be done or *how* it will be done. If the SIP proposes deploying a new contract, write, "we propose to deploy a new contract that will do x".-->
Allow for a new type of Binary Option to be created where the performance of two crypto assets are tracked over a period of time. The winning Bet is the asset that performed best.
## Motivation
<!--This is the problem statement. This is the *why* of the SIP. It should clearly explain *why* the current state of the protocol is inadequate.  It is critical that you explain *why* the change is needed, if the SIP proposes changing how something is calculated, you must address *why* the current calculation is innaccurate or wrong. This is not the place to describe how the SIP will address the issue!-->
Betting on a specific price outcome could stop people participating who are overall, more risk averse. However the general performance between two crypto assets is more of a personal belief in their (bags) project and related fundamentals and “pumpanomics” and could get a lot more people to participate.
And sometimes people just don’t want to bet on a strike price but rather that one coin would outperform another.  
E.g. We could bet that SNX will outperform LINK on 01.01.2021.   
## Specification
<!--The specification should describe the syntax and semantics of any new feature, there are five sections
1. Overview
2. Rationale
3. Technical Specification
4. Test Cases
5. Configurable Values
-->
The sip would allow users to bet that one coin/token will outperform the other at a certain date without thinking about strike prices.
### Overview
<!--This is a high level overview of *how* the SIP will solve the problem. The overview should clearly describe how the new feature will be implemented.-->
The sip would allow users to bet that one coin will outperform the other at a certain date without thinking about strike prices.
### Rationale
<!--This is where you explain the reasoning behind how you propose to solve the problem. Why did you propose to implement the change in this way, what were the considerations and trade-offs. The rationale fleshes out what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion.-->
As betting only on a strike price has its limitation, because the whole crypto market is still driven by BTC and ETH marketcaps, it would be useful to let bidders bet on how one coin will perform against another.  
With this someone can simultaneously long one coin while shorting the other.  
Some popular choices were already thrown in discord, e.g. Will YFI outperform BTC 1 to 1? Of course YFI would have to be added as an BO option first. New assets for Binary Options were proposed in a SIP by @PSYBULL

### Technical Specification
<!--The technical specification should outline the public API of the changes proposed. That is, changes to any of the interfaces Synthetix currently exposes or the creations of new ones.-->
We are proposing 2 models here, which either one or both could be implemented with this specific “Performance” based Binary Option.  
 
### Model 1 - Direct Percentage Growth
This model will track the ‘direct’ percentage growth of two competing crypto assets over a period of time. At the end of the period the asset with the largest % growth in USD* value will be the “winner”. The mechanism will be as follows (within the current BO framework):
Select the 2 competing assets (Select from available list of assets i.e. $BTC, $ETH or $YFI etc)
Set ‘Start’ date = the “Bidding Date End”
Set ‘Maturity’ date  

On ‘maturity’ the % growth in USD will be calculated for each asset and compared. If the ‘start’ date price is available to be retrieved at this point, then there is no need to capture and store it on ‘start’ date.   
*In the future this could be enhanced to track growth against $BTC or $ETH instead of only USD.  

### Model 2 - Weighted coin values
This model compares factored values of coins at the maturity date.  
The market creator selects two coins and the multiplier for each coin. There are no other changes to the current mechanism (bidding date, maturity date).  
Default multiplier is **one**, e.g. **SNX>LINK@01.01.2021.** -> a single SNX coin will be worth more than a single LINK coin at the maturity date.  
A case with multiplier set could be: **30xSNX>ETH@01.01.2021.** -> SNX coin value multiplied by 30 will be worth more than 1 EHT at the maturity date.

For both cases UI should be updated to show the both coins on the chart in the BO detailed view.  

### Test Cases
<!--Test cases for an implementation are mandatory for SIPs but can be included with the implementation..-->
* Model 1  
    * SNX % growth will outperform ETH % growth from 1.10.2020. till 1.11.2020.
    
* Model 2
    * SNX>LINK@01.01.2021.->   a single SNX coin will be worth more than a single LINK coin at the maturity date.
    * 30xSNX>ETH@01.01.2021. -> SNX coin value multiplied by 30 will be worth more than 1 EHT at the maturity date.

### Configurable Values (Via SCCP)
<!--Please list all values configurable via SCCP under this implementation.-->

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
