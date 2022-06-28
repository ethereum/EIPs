# metadata  standards 


this documentation consist of various example  JSON schemas (examples or standards) that can be referenced by the reader of EIP for implementing EIP-3475 bonds storage.


## 1. Description metadata: 

```json 
[
    {
        "title": "defining the title information",
        "types": "explaining the type of the title information added",
        "description": "little description about the information stored in  the bond",
    }
]
```

example: adding details in bonds describing the local jurisdiction of the bonds where its issued:

```json
{
"title": "localisation",
"types": "string",
"description": "jurisdiction law codes compatibility "
"values": ["fr ", "de", "ch"] // can also be ISO codes 
}
```

## 2. Nonce metadata:

- **Information defining the state of the bond** 

```json
[	
	{	
	"title": "maturity",
	"types": "uint",
	"description": "Lorem ipsum..."
	"values": [0, 0, 0]
	}
]
```


## 3. Class metadata:


```json
[	
	{	
	"title": "symbol",
	"types": "string",
	"description": "Lorem ipsum..."
	"values": ["Class symbol 1", "Class symbol 2", "Class symbol 3"],
	},

	{	
	"title": "issuer",
	"types": "string",
	"description": "Lorem ipsum..."
	"values": ["Issuer name 1", "Issuer name 2", "Issuer name 3"],
	},

	{	
	"title": "issuer_address",
	"types": "address",
	"description": "Lorem ipsum..."
	"values":["Address 1.", "Address 2", "Address 3"]
	},

	{	
	"title": "class_type",
	"types": "string",
	"description": "Lorem ipsum..."
	"values": ["Class Type 1", "Class Type 2", "Class Type 3"]
	},

	{	
	"title": "token_address",
	"types": "address",
	"description": "Lorem ipsum..."
	"values":["Address 1.", "Address 2", "Address 3"]
	},

	{	
	"title": "period",
	"types": "uint",
	"description": "Lorem ipsum..."
	"values": [0, 0, 0]
	}
]
## TODO, defining example schemas for actual fintech standards : 
- ISO-20022 standard is the recent adopted standard by banks for communicating the financial operations. 
