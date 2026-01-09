Account Abstraction Comparison 


Tempo transactions:
https://docs.tempo.xyz/protocol/transactions/spec-tempo-transaction 

Readthrough of Tempo tx (features and what it does, very concise can be tx type fields).

Include TIP-20 and TIP-403 polcies. We need to explian that these exist is so no onchain code needs to be run for the tx to be validated.

Compare this simple proposal Lets call it "Simple Approach EIP" (https://gist.github.com/gakonst/00117aa2a1cd327f515bc08fb807102e).


Then we will go in to whats missing from the Simple Approach and how to fill the gaps:
ERC20 payments:
- Native AMM can make it so can pay with erc20 for gas, need to have some configuration or agreed standard to know the slots to update so no EVM code needs to run.
- In request state checks (similar to eth_sendRawTrasnactionConditional, can be signed over or not)
- Onchain configs, similar to above but onchain and referenced in request
- Standardize a token (ie TIP20), enables transfer to be done easily because balance slot is known 
- Blocklist token (TIP403), needed so sactioned addresses can be blocked, need an onchain configuration for this

Account keys:
- Key rotation (want to be able to switch key)
- Old smart accounts (need to migrate non-eoa based 4337 smart accounts to this system)
- Eventual EOA deprecation (quantum) (key rotation)

Deployment of new contracts (ie 7702)
- Auth precompile can deploy a la 7702
- 7702 deployments or new smart accounts require different path (simple)

- Migration of smart accounts (non EOA / 7702)
Auth precompile
Don’t allow migration
 