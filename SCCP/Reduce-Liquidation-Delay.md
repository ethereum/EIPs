---
sccp: TBD
title: Reduce Liquidation Time Delay
author: Kaleb Keny (@kaleb-keny)
discussions-to: https://discord.gg/mXNj2x
status: Proposed
created: 2020-06-06
---

## Simple Summary
<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the SCCP.-->
Proposing to lower the liquidation delay `liquidationDelay` variable from 2 weeks to 3 days.

## Abstract
<!--A short (~200 word) description of the variable change proposed.-->
The initial parameters set at implementation of [SIP-15](https://sips.synthetix.io/sips/sip-15) gave users a 2 week grace period to raise their c-ratio, before bots and other users are able to liquidate them. The reason behind the grace period is to provide users with an opportunity to fix their c-ratio and avoid the scenario of bad actors manipulating SNX prices temporarily in order to liquidate wallets of minters. However, a long grace period exposes the system to the risk of having to fund an uncollateralized wallet if a sharp decrease in SNX prices persists.
This SCCP proposes to lower the grace period (`liquidationDelay`)  to 3 days, in order to bolster the protection of the system against the threat of undercollateralized wallets.

## Motivation
<!--The motivation is critical for SCCPs that want to update variables within Synthetix. It should clearly explain why the existing variable is not incentive aligned. SCCP submissions without sufficient motivation may be rejected outright.-->

#### SNX-Debt Pool Correlation:
The c-ratio of wallet is comprised of 2 components fundamentally, the debt of a user and the collateral pledged. The price of SNX drives the value of the collateral, while the prices of the individual underlyings of the debt pool drive the debt of a user. Using the price of ETH as a proxy for the debt of a wallet, we find that the correlation coefficient between the price of SNX and the price ETH  around 0.60 historically.
Having that in mind, and the fact that liquidation grace period starts when the c-ratio of wallet reaches a `Liquidation-Collateral-Ratio` of  200%, we can simulate the shocks that would result in a c-ratio of 100%:

| Component | Pre Shock | Price Shock | Post Shock|
| :-------------: | :-------------: | :-------------: |  :-------------: | 
| SNX Collateral | 1,000 | -60%| 400
| Debt | 500 | -20%| 400
| **C-Ratio** | **200%** || **100%**

From the above table, as well as taking into account other idiosyncratic events on the price of SNX (due to its low liquidity relative to ETH), we can deduce that a  price-shock of 30% to 50% could severely increase the risk that a wallet with a c-ratio of 200% becomes under-collateralized. 

#### Probability Inference:
Using a target SNX price shock of 30% to 50%, we can infer the probabilities of such a shock taking place, using the probability  distribution of  returns of SNX inferred from historical prices. As can be expected, the longer the time horizon involved (i.e. the longer the grace period), the higher the volatility that can be expected of returns and therefore the greater the risk that a wallet becoming under uncollateralized.

Modelling the probability distribution (with a Gaussian Mixture Model) we can infer the respective probabilities to different prices shocks across different time horizons:
| Time\Shock | -30% | -40% | -50% |
|:----:|:----:|:----:|:----:|
|  **1D**  |  10% |  5%  |  2%  |
|  **3D**  |  19%  |  12%  |  6%  |
|  **1W**  |  38% |  24% |  14% |
|  **2W**  |  42% |  41% |  40% |

The 10% number in the table for instance refers to the probability of a negative price shock of 30% or more during a 1 day horizon (i.e. in math lingo, it's CDF of the returns random variable evaluated at observation -30%). One important assumption for this model to hold is the stationarity of price returns, which althought acceptable for short-term periods becoming less and less guaranteed for longer time horizons.

The table reveals that there is around 20 times the risk that SNX prices will fall by 50% during a 2-week period, as compared to a 1-day horizon. 
We can also infer from the table above that the proposed decrease in the liquidation grace period from 2-weeks to 3 days will significantly bolster the protection of the system.

#### Disclaimer:
As **justwanttoknowathing - SNX phD** mentioned, past performance doesn't guarantee future results. In other words, this parameter might need to be revisited (relaxed or maybe tightened) if the distribution of returns of SNX varies significantly.


#### Sources:
- [Correlation SNX-ETH](asset/liquidation_delay/snx-eth-corr.png)
- [Jupyter Notebook](asset/liquidation_delay/SNX_RETURNS_PROB.ipynb)
- [SNX Return Probability Distribution](asset/liquidation_delay/returns-plot.png)
- [Data.csv](asset/liquidation_delay/returns.csv)

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
