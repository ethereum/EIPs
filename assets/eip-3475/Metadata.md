# Metadata  standards 


This documentation consists of various JSON schemas (examples or standards) that can be referenced by the reader of this EIP for implementing EIP-3475 bonds storage.

## 1. Description metadata: 

```json 
[
    {
        "title": "defining the title information",
        "_type": "explaining the type of the title information added",
        "description": "little description about the information stored in  the bond",
    }
]
```

Example: adding details in bonds describing the local jurisdiction of the bonds where it's issued:

```json
{
"title": "localisation",
"_type": "string",
"description": "jurisdiction law codes compatibility"
"values": ["fr ", "de", "ch"]
}
```
The 'values' field defined above can also be ISO codes or other hex standard representation.
## 2. Nonce metadata:

- **Information defining the state of the bond** 

```json
[	
	{	
	"title": "maturity",
	"_type": "uint",
	"description": "Lorem ipsum...",
	"values": [0, 0, 0]
	}
]
```


## 3. Class metadata:

```json
[ 
	{	
	"title": "symbol",
	"_type": "string",
	"description": "Lorem ipsum...",
	"values": ["Class symbol 1", "Class symbol 2", "Class symbol 3"],
	},
	{	
	"title": "issuer",
	"_type": "string",
	"description": "Lorem ipsum...",
	"values": ["Issuer name 1", "Issuer name 2", "Issuer name 3"],
	},

	{	
	"title": "issuer_address",
	"_type": "address",
	"description": "Lorem ipsum...",
	"values":["Address 1.", "Address 2", "Address 3"]
	},

	{	
	"title": "class_type",
	"_type": "string",
	"description": "Lorem ipsum...",
	"values": ["Class Type 1", "Class Type 2", "Class Type 3"]
	},

	{	
	"title": "token_address",
	"_type": "address",
	"description": "Lorem ipsum...",
	"values":["Address 1.", "Address 2", "Address 3"]
	},

	{	
	"title": "period",
	"_type": "uint",
	"description": "Lorem ipsum...",
	"values": [0, 0, 0]
	}
]
```
## Examples of other standards: 
    - ISO-20022 standard is the recently adopted standard by banks for communicating  financial operators (Banks, trading intermediaries, underwriters) that also include bond operations. 
