```plantuml
title EIP-7701 Complete Transaction Flow

actor "User"
skinparam participantFontColor automatic
participant "Ethereum" #darkgreen
participant "AA_ENTRY_POINT" #darkgreen
participant "Deployer Contract" as DC #darkslateblue
participant "Sender Contract" as SC #darkorchid
participant "Paymaster Contract" as PC #olivedrab
participant "Target Contract" as TC #darkred

"User" -> "Ethereum": Submit AA transaction
note right of "Ethereum": execute\nAA transaction\nstate transition
"Ethereum" -> "AA_ENTRY_POINT": 
|||

group Validation Phase
|||
opt Sender Deployment
"AA_ENTRY_POINT"->DC: Deploy AA Transaction Sender\n""deployerData""
note over DC: ""ACCEPTROLE 0xA0""
DC -> SC: Deploy Sender Contract\n""CREATE2""
DC-->"AA_ENTRY_POINT":deployed: true
|||
end
|||
"AA_ENTRY_POINT"->SC: Validate AA Transaction\n""senderValidationData""
note over SC: ""ACCEPTROLE 0xA1""
return valid: true
|||

opt Gas Abstraction
"AA_ENTRY_POINT"->PC: Validate AA Transaction\n""paymasterData""
note over PC: ""ACCEPTROLE 0xA2""
return valid: true
|||
end
|||
end
group Execution Phase
|||
"AA_ENTRY_POINT"->SC: Execute AA Transaction\n""senderExecutionData""
note over SC: ""ACCEPTROLE 0xA3""
|||
SC->TC: AA Transaction\nExecution Body
|||
opt PostOp 
"AA_ENTRY_POINT"->PC: Paymaster PostOp Call
note over PC: ""ACCEPTROLE 0xA4""
|||
end
|||
end
```
