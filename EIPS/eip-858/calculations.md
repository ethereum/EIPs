| Variable           | Symbol       | Value         | Unit          | Source |
| -------------------|--------------|---------------|---------------|--------|
| Network Hashrate   |H<sub>N</sub> | 232001        | GH/s          | https://etherscan.io/chart/hashrate |
| Power/Hashrate     |P<sub>H</sub> | 3.54          | W*s/MH        | http://www.legitreviews.com/geforce-gtx-1070-ethereum-mining-small-tweaks-great-hashrate-low-power_195451, https://www.reddit.com/r/ethereum/comments/7vewys/10000_tons_co2_per_day_and_climbing_eip_858/dtrswyz/ |


## Network Power Consumption (P<sub>N</sub>)

A baseline value for network power consumption can be found by multiplying the total network hashrate with a "best case" value for the power/hashrate ratio that a miner can achieve.

> P<sub>N</sub> = H<sub>N</sub> x P<sub>H</sub>
>
> P<sub>N</sub> = 232001 (GH/s) x 3.54 (W*s/MH) x 1000 (MH/GH) / 10^6 (W/MW)
>
> P<sub>N</sub> = 821 MW

As a side note, people often confuse power (W) and energy (power x time, eg. Wh). For instance, assuming an average daily P<sub>Nd</sub> of 821 MW we can calculate that days Energy consumption by multiplying by the number of hours in a day.

> E<sub>Nd</sub> = P<sub>Nd</sub> x T<sub>d</sub>
>
> E<sub>Nd</sub> = 821 (MW) x 24 (h/d) / 1000 (GW/MW)
>
> E<sub>Nd</sub> = 19.7 GWh



## Network CO2 contribution

Work in progress
