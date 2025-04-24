```plantuml
title EIP-7701 Simple Transaction Flow With Non-EOF Legacy Proxy

actor "User"
skinparam participantFontColor automatic
participant "Ethereum" #darkgreen
participant "AA_ENTRY_POINT" #darkgreen
participant "Sender Contract Proxy\nLegacy non-EOF code" as SCPL #orangered
participant "Sender Contract Implementation:\nValidation Code Section" as SCVCS #darkorchid
participant "Sender Contract Implementation:\nExecution Code Section" as SCECS #purple
participant "Target Contract:\nExecution Code Section" as TCECS #darkred

"User" -> "Ethereum": Submit AA transaction
note right of "Ethereum": execute\nAA transaction\nstate transition
"Ethereum" -> "AA_ENTRY_POINT":
|||
group Validation Phase
|||
note right of "Ethereum": ""current_entry_point_role := role_sender_validation""
|||
"AA_ENTRY_POINT"->SCPL: Validate AA Transaction\n""senderValidationData""
|||
SCPL->SCVCS: ""DELEGATECALL""
note over SCVCS: ""current_entry_point_role_fulfilled := true""
return valid: true
SCPL-->"AA_ENTRY_POINT":valid: true
|||
end
|||
group Execution Phase
|||
note right of "Ethereum": ""current_entry_point_role := role_sender_execution""
|||
"AA_ENTRY_POINT"->SCPL: Execute AA Transaction\n""senderExecutionData""
|||
SCPL->SCECS: ""DELEGATECALL""
note over SCECS: ""current_entry_point_role_fulfilled := true""
SCECS->TCECS: AA Transaction\nExecution Body
|||
end
|||
```
