```plantuml
title EIP-7701 Complete Transaction Flow

actor "User"
skinparam participantFontColor automatic
participant "Ethereum" #darkgreen
participant "AA_ENTRY_POINT" #darkgreen
participant "Deployer Contract:\nDeployer Code Section" as DCDCS #darkslateblue
participant "Sender Contract:\nValidation Code Section" as SCVCS #darkorchid
participant "Sender Contract:\nExecution Code Section" as SCECS #purple
participant "Paymaster Contract:\nPaymaster Validation Code Section" as PCPVCS #olivedrab
participant "Paymaster Contract:\nPaymaster PostOp Code Section" as PCPPCS #olive
participant "Target Contract:\nExecution Code Section" as TCECS #darkred

"User" -> "Ethereum": Submit AA transaction
note right of "Ethereum": execute\nAA transaction\nstate transition
"Ethereum" -> "AA_ENTRY_POINT": 
|||

group Validation Phase
|||
opt Sender Deployment
"AA_ENTRY_POINT"->DCDCS: Deploy AA Transaction Sender\n""deployerData""
DCDCS -> SCVCS: Deploy Sender Contract\n""CREATE2""
DCDCS-->"AA_ENTRY_POINT":deployed: true
|||
end
|||
"AA_ENTRY_POINT"->SCVCS: Validate AA Transaction\n""senderValidationData""
return valid: true
|||

opt Gas Abstraction
"AA_ENTRY_POINT"->PCPVCS: Validate AA Transaction\n""paymasterData""
return valid: true
|||
end
|||
end

group Execution Phase
|||
"AA_ENTRY_POINT"->SCECS: Execute AA Transaction\n""senderExecutionData""
|||
SCECS->TCECS: AA Transaction\nExecution Body
|||
opt PostOp 
"AA_ENTRY_POINT"->PCPPCS: Paymaster PostOp Call
|||
end
|||
end
```
