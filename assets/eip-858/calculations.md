| Variable           | Symbol       | Value         | Unit          | Source |
| -------------------|--------------|---------------|---------------|--------|
| Network Hashrate   |H<sub>N</sub> | 296000        | GH/s          | https://etherscan.io/chart/hashrate |
| GPU Hashrate       |H<sub>M</sub> | 31.2          | MH/s          | https://www.legitreviews.com/geforce-gtx-1070-ethereum-mining-small-tweaks-great-hashrate-low-power_195451 |
| GPU Power          |P<sub>M</sub> | 110.6         | W             | https://www.reddit.com/r/ethereum/comments/7vewys/10000_tons_co2_per_day_and_climbing_eip_858/dtrswyz/ |


## Network Power Consumption (P<sub>N</sub>)

A baseline value for network power consumption can be found by multiplying the total network hashrate with a "best case" value for the power/hashrate ratio that a miner can achieve.

> P<sub>N</sub> = H<sub>N</sub> x P<sub>M</sub> / H<sub>M</sub>
>
> P<sub>N</sub> = 296000 (GH/s) x 110.6 (W) x 1000 (MH/GH) / ( 31.2 (MH/s) x 10^6 (W/MW) )
>
> P<sub>N</sub> = 1049 MW

As a side note, people often confuse power (W) and energy (power x time, eg. Wh). For instance, assuming an average daily P<sub>Nd</sub> of 1049 MW we can calculate that days Energy consumption by multiplying by the number of hours in a day.

> E<sub>Nd</sub> = P<sub>Nd</sub> x T<sub>d</sub>
>
> E<sub>Nd</sub> = 1049 (MW) x 24 (h/d) / 1000 (GW/MW)
>
> E<sub>Nd</sub> = 19.7 GWh
