---
sip: 62
title: Futures reference price methodology
status: WIP
author: Bill Mayott <bill.mayott@xbto.com>, Philippe Bekhazi <philippe@xbto.com>, Walton Comer <walton@xbto.com>, Kain Warwick (@kaiynne)
discussions-to: https://discord.gg/VNFYvny

created: 2020-05-18
---

## Simple Summary
A method for converting futures market prices into a single reference price for Synths.

## Abstract
This SIP describes a general approach to converting price data from futures markets into a single reference price, as well as a specific methodology for creating a non-expiring Crude Oil Index based on CME Light Sweet Crude Oil futures prices (Contract Code: CL) for a Synth with ticker symbol sOIL.

## Motivation
The creation of a single reference price for futures markets that incorporates information from the most liquid futures contracts enables assets like WTI and other commodities to be traded as synthetic assets within Synthetix. There is significant demand for these assets particularly given the liquidity of the underlying markets and the difficulty of access for the average trader. 
 
## Specification
There are many markets where price discovery occurs solely or predominantly in the futures markets, these futures markets are made up of individual contracts with varying expiry dates. This presents a problem when attempting to create a single reference price. The solution proposed is to employ a dynamic weighting scheme (in continuous time) of the near two contract months, with emphasis initially given to the near contract.  As expiry approaches, however, weight is progressively shifted out of the near contract in favor of the 2nd month.  Moreover, upon reaching 5 days (configurable via SCCP) prior the last trade time (2:30PM EST on the exchange stipulated Last Trade day), zero weighting in the near contract is achieved, with the weight instead being allocated between the 2nd and 3rd contract months.  Once the front month expires, the next nearest two live contracts become the 1st and 2nd months, and the dynamic weighting process repeats. This weighting methodology is intentionally relatively simple and linear to enable easier reasoning about the likely behaviour of the resulting reference price from various futures contract situations such as contango and backwardation, and specifically super-contango observed in early 2020 due to extreme volatility in the front month expiring WTI contracts resulting in negative futures prices.

The formula for the reference price is:

\\[
price = \begin{cases}
\frac{d_{1} \ - \ X}{d_{1} \ - \ d_{0}} \cdot P_1 \ + \ \frac{\ X \ - d_{0}}{d_{1} \ - \ d_{0}} \cdot P_2 & \ \mbox{if } \ \ \ X \leq d_1 \\ \\
\newline
\frac{d_{2} \ - \ X}{d_{2} \ - \ d_{1}} \cdot P_2 \ + \ \frac{X \ - \ d_{1}}{d_{2} \ - \ d_{1}} \cdot P_3 & \ \mbox{if } \ \ \ 0 \lt d_1 \lt X \\
\end{cases}
\\]

With the inputs below:

| \\(X\\) | Number of days prior to expiration to achieve zero weight in in the expiring contract (default of 5 days) |
| \\(d_{0}\\) | Days since the prior month contract expired |
| \\(d_{1}\\) | Days remaining for the current front month contact |
| \\(d_{2}\\) | Days remaining for the current 2nd month contract |
| \\(P_{0}\\) | Orderbook mid-price of the current front month contract |
| \\(P_{1}\\) | Orderbook mid-price of the current 2nd month contract |
| \\(P_{2}\\) | Orderbook mid-price of the current 3rd month contract |

There are implications for fee reclamation with this approach, given that futures markets close, these Synths will use the next price fee reclamation mechanism found here [SIP-52](https://sips.synthetix.io/sips/sip-52). This requires that during market closures the Chainlink aggregator contract published a stable price. Due to the continuous time aspect of the calculation the reference price will continually update even during market closures. This requires the node operators to subscribe to a market closure data feed to ensure the published price on-chain does not deviate outside a pre-defined range (likely 5bps) during market closures, which would trigger a next price update and cause all orders to fill at a stale price. There is a further implication for circuit breakers and other out of cycle market closures as these events would not be covered by the market closure data feed, in the case of a circuit breaker or other unscheduled market closure the data providers would continue to publish stale prices requiring these markets to be closed manually via the protocolDAO.

## Rationale
This method was chosen over other more strictly enforced constant-maturity methods, such as cubic spline best-fit regressions of the futures curve given the added complexity of these methods and the marginal difference in accuracy of the reference price. The goal of this SIP is to enable broader understandability, adoption and redundancy for a variety of assets for which price discovery is predominantly or solely centered around futures contract trading. By providing a straightforward methodology we can construct reference prices for a range of assets that can be published by Chainlink Oracles onto Ethereum bridging TradFi and DeFI. Some potential assets that this methodology can support are Corn, Wheat, Soybeans, Coffee, Sugar, Platinum, Palladium and other more exotic but liquid markets.

## Test Cases
The logic of these reference prices is implemented at the data provider level, with Chainlink node operators consuming this data and publishing it into aggregator contracts. In order to ensure the reliability of this data multiple data providers will be selected to feed the node operators all of which connect directly to raw data from the futures markets.

## Implementation
The implementations must be completed before any SIP is given status "Implemented", but it need not be completed before the SIP is "Approved". While there is merit to the approach of reaching consensus on the specification and rationale before writing code, the principle of "rough consensus and running code" is still useful when it comes to resolving many discussions of API details.

## Configurable Values (Via SCCP)
The primary configurable variable in this SIP is the number of days to expiry defined as X in the formula above.

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
