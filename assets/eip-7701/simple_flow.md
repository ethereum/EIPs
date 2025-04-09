```plantuml
title EIP-7701 Simple Transaction Flow

actor "User"
skinparam participantFontColor automatic
participant "Ethereum" #darkgreen
participant "AA_ENTRY_POINT" #darkgreen
participant "Sender Contract:\nValidation Code Section" as SCVCS #darkorchid
participant "Sender Contract:\nExecution Code Section" as SCECS #purple
participant "Target Contract:\nExecution Code Section" as TCECS #darkred

"User" -> "Ethereum": Submit AA transaction
note right of "Ethereum": execute\nAA transaction\nstate transition
"Ethereum" -> "AA_ENTRY_POINT":
|||
group Validation Phase
|||
"AA_ENTRY_POINT"->SCVCS: Validate AA Transaction\n""senderValidationData""
return valid: true
|||
end
|||

group Execution Phase
"AA_ENTRY_POINT"->SCECS: Execute AA Transaction\n""senderExecutionData""
|||
SCECS->TCECS: AA Transaction\nExecution Body
|||
end
|||
```
