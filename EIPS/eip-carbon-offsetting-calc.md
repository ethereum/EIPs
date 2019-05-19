---
eip: <to be assigned>
title: GHG Emissions Offsetting calculation standard for Ethereum transactions
author: Anton Galenovich (galenovich@ipci.io), Sergey Lonshakov (@ensrationis)
discussions-to: https://ethereum-magicians.org/t/ghg-emissions-offsetting-for-ethereum-blockchain-transactions/3296
status: Draft
type: Standard Track
category: ERC
created: 2019-05-19
---

## Simple Summary
Ethereum, other crypto transactions consume substantial amount of fossil fuel combustion-based electricity. The best way to resolve the issue is to calculate transaction or address-induced consumption-based GHG emissions, to buy-out and burn relevant amount of independently verified in the Ethereum Main Net carbon credits.  

## Abstract
EIP for Ethereum requires calculation of a specific transaction-induced GHG emissions by gas consumed and conservative assumptions for energy consumption factor of the mining equipment and grid emission factor for mining the block, which processed the transaction. Once the calculation is broadcasted to the user and the miner, they are presented with an option to select, buy-out and burn relevant amount of Ethereum native tokens representing independently verified and issued in the Ethereum Main Net carbon offset credits.

## Motivation
There are numerous examples of environmental/climate change mitigation project initiators, programs, standards and environmental/climate change community in general rejecting the use of Ethereum and other cryptocurrency ecosystems because of the GHG emissions induced by mining to process the transactions. Responses of blockchain community, Ethereum founders and developers up to date if any have been hollow, non-specific trash talk mainly referring to vague perspectives of PoS introduction. Development and implementation of the EIP resolves the issue entirely for the Ethereum transactions on the basis of the Paris Agreement (PA) principle of  “overall mitigation of global emissions” (OMGE) and should be extended to embrace other cryptocurrencies’ transactions starting with Bitcoin. Existing [DAO IPCI  Dapp](http://dapp.ipci.io) provides for verification, issuance and retirement of carbon offset credits sufficient to perform carbon offsetting in “a manual mode” but does not provide for calculation of crypto transactions’ “carbon footprint” and a self-executing option to offset it.   

## Specification
Calculation Algorithm: Electricity consumed per transaction (MWh) multiplied by Grid Emission Factor (tCO2e*MWh) plus carbon footprint for one Ethereum transaction to burn the carbon credits.
Offsetting Algorithm:
    1. the User may choose the units he would prefer out of those that are placed on the Complier contract, which means that they are born and die on the blockchain
    2. carbon footprint calculated as an option might be divided by 2 to include proposal to the miner to offset half of the transaction footprint
    3. once the units are paid for and burnt the User and relevant Miner receive public report, which includes the addresses of the burning transaction, of the token, of the verification report, and the amount of tCO2e burnt and left to be burnt

**Sources of Data**

Transactions data: http://etherscan.io for Ethereum, e.g. https://www.blockchain.com/explorer for Bitcoin
Calculation based on gas consumed and conservative assumptions for energy consumption factor of the mining equipment and grid emission factor for mining the block, which processed the transaction. Existing examples of calculation results for Energy consumption per transaction: https://digiconomist.net/ethereum-energy-consumption for Ethereum, https://digiconomist.net/bitcoin-energy-consumption for Bitcoin.
Grid emission factor: assessed conservatively as equal to national grid emission factor for P.R. of China. According to “China’s electricity emission intensity…” equals to 0.861 t/MWh.

**Example**

TxHash: 0x8cb77d212b249ba3c455f405ceb07d1b05e36ccb7e59cd53ecd3311b08513a28
Block height: [6063159](https://etherscan.io/block/6063159)
Mined By: 0x829bd824b016326a401d083b33d092293333a830 (f2pool_2)
Energy consumption per transaction: Calculation based on gas consumed and conservative assumptions for energy consumption factor of the mining equipment and grid emission factor for mining the block, which processed the transaction. Or as calculated by https://digiconomist.net = 0,094 MWh

Grid emission factor: 0,861 t/MWh

Calculation: 0,094*0,861 + 0,094*0,861 = 0,161868 tСО2e

For offsetting purposes, the price established by the Complier is used (ex. 20 Euro)

Total price to offset the transaction 0,161868 * 20 = 3,23736 Euro

To include the miner, once half the units are paid for and burnt by the User relevant Miner receives public report, which includes the addresses of the burning transaction, of the token, of the verification report, and the amount of tCO2e burnt and left to be burnt (0,080934 tCO each)
General design for offsetting carbon footprint of individual address.

Calculation Algorithm would be different: Electricity consumed per transaction (MWh) multiplied by Grid Emission Factor (tCO2e*MWh) multiplied by the number of transactions.

**Example**

Address: 0x6CEc6913fF2F8802a0eaA183Fb61C0234AAB5830  
Number of transactions: [327](https://etherscan.io/address/0x6CEc6913fF2F8802a0eaA183Fb61C0234AAB5830 )

Energy consumption per transaction: Calculation based on gas consumed and conservative assumptions for energy consumption factor of the mining equipment and grid emission factor for mining the block, which processed the transaction. Or as calculated by https://digiconomist.net = 0,094 MWh
Grid emission factor: 0,861 t/MWh

For offsetting purposes, number of transactions is increased by one and the result may be divided by 2 to include the miner and the price established by the Complier is used (ex. 20 Euro)

Calculation: 328*0,094*0,861=22,242213 tСО2e

Total price for 26,546352tCO2e = 530,92704 Euro

To include the miner, once half the units are paid for and burnt by the User relevant Miner receives public report, which includes the addresses of the burning transaction, of the token, of the verification report, and the amount of tCO2e burnt and left to be burnt (13,273176 tCO each)

To compare, Bitcoin energy consumption and carbon footprint per transaction calculated by https://digiconomist.net was not 0,094, but 0,803 MWh.

## Rationale
The rationale for specific design is based on careful examination of all alternative options including exotic and unrealistic proposals to transfer mining to renewable sources of energy. The EIP reflects the only feasible, independently verifiable solution for the chain of GHG emission from generation to offsetting within the same semantic space with reasonable and conservative assumptions, where direct access to data required is technically impossible for  the date (energy consumption factor of the mining equipment, grid emission factors).   

## Backwards Compatibility
### Test Cases
Offsetting carbon footprint with Ethereum native tokens representing independently verified and issued in the Ethereum Main Net carbon offset credits has been practically and successfully tested for number of times:
* https://etherscan.io/tx/0xff2ce19aaa46c8debaac2e195eb898f6dd86c0c46befb26baaf66c94cd35fad8
* https://etherscan.io/tx/0xa3c60801f82f74e36c471c135d1f2eb6b92ca1c8aa05b8f58ee283ab21b3cbf7
* https://etherscan.io/tx/0x517efedf6b0eadadf46759b6f9b2d9a64b12fc0bef55b8e124d2319d989d2332
etc.

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
