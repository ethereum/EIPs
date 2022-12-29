{
  "title": "Package Manifest",
  "description": "EthPM Manifest Specification",
  "type": "object",
  "required": [
    "manifest"
  ],
  "version": "3",
  "not": {
    "required": ["manifest_version"]
  },
  "properties": {
    "manifest": {
      "type": "string",
      "title": "Manifest",
      "description": "EthPM Manifest Version",
      "default": "ethpm/3",
      "enum": ["ethpm/3"]
    },
    "name": {
      "$ref": "#/definitions/PackageName"
    },
    "version": {
      "title": "Package Version",
      "description": "The version of the package that this release is for",
      "type": "string"
    },
    "meta": {
      "$ref": "#/definitions/PackageMeta"
    },
    "sources": {
      "title": "Sources",
      "description": "The source files included in this release",
      "type": "object",
      "patternProperties": {
        ".*": {
		  "$ref": "#/definitions/Source"
		}
	  }
    },
	"compilers": {
	  "title": "Compilers",
	  "description": "The compiler versions used in this release",
	  "type": "array",
	  "items": {
	    "$ref": "#/definitions/CompilerInformation"
	  }
	},
    "contractTypes": {
      "title": "Contract Types",
      "description": "The contract types included in this release",
      "type": "object",
	  "propertyNames": {
		"$ref": "#/definitions/ContractTypeName"
	  },
      "patternProperties": {
        "": {
          "$ref": "#/definitions/ContractType"
        }
      }
    },
    "deployments": {
      "title": "Deployments",
      "description": "The deployed contract instances in this release",
      "type": "object",
      "propertyNames": {
        "$ref": "#/definitions/BlockchainURI"
	  },
      "patternProperties": {
        "": {
          "$ref": "#/definitions/Deployment"
        }
      }
    },
    "buildDependencies": {
      "title": "Build Dependencies",
      "type": "object",
      "propertyNames": {
        "$ref": "#/definitions/PackageName"
	  },
      "patternProperties": {
        "": {
          "$ref": "#/definitions/ContentURI"
        }
      }
    }
  },
  "definitions": {
	"Source": {
	  "title": "Source",
	  "description": "Information about a source file included in this package",
	  "type": "object",
	  "anyOf": [
		{"required": ["content"]},
		{"required": ["urls"]}
	  ],
	  "properties": {
	    "checksum": {
          "$ref": "#/definitions/ChecksumObject"
		},
		"urls": {
		  "title": "URLs",
		  "description": "Array of urls that resolve to the source file",
		  "type": "array",
		  "items": {
			"$ref": "#/definitions/ContentURI"
		  }
		},
		"content": {
		  "title": "Inlined source code",
		  "type": "string"
		},
		"installPath": {
		  "title": "Target file path to install source file",
		  "type": "string",
		  "pattern": "^\\.\\/.*$"
		},
		"type": {
		  "title": "Type",
		  "description": "File type of this source",
		  "type": "string"
		},
		"license": {
		  "title": "License",
		  "description": "The license associated with the source file",
		  "type": "string"
		}
	  }
	},
    "PackageMeta": {
      "title": "Package Meta",
      "description": "Metadata about the package",
      "type": "object",
      "properties": {
        "authors": {
          "title": "Authors",
          "description": "Authors of this package",
          "type": "array",
          "items": {
            "type": "string"
          }
        },
        "license": {
          "title": "License",
          "description": "The license that this package and its source are released under",
          "type": "string"
        },
        "description": {
          "title": "Description",
          "description": "Description of this package",
          "type": "string"
        },
        "keywords": {
          "title": "Keywords",
          "description": "Keywords that apply to this package",
          "type": "array",
          "items": {
            "type": "string"
          }
        },
        "links": {
          "title": "Links",
          "descriptions": "URIs for resources related to this package",
          "type": "object",
          "additionalProperties": {
            "type": "string",
            "format": "uri"
          }
        }
      }
    },
    "PackageName": {
      "title": "Package Name",
      "description": "The name of the package that this release is for",
      "type": "string",
      "pattern": "^[a-z][-a-z0-9]{0,255}$"
    },
    "ContractType": {
      "title": "Contract Type",
      "description": "Data for a contract type included in this package",
      "type": "object",
      "properties":{
        "contractName": {
          "$ref": "#/definitions/ContractTypeName"
        },
        "sourceId": {
          "title": "Source ID",
          "description": "The source ID that corresponds to this contract type",
          "type": "string"
        },
        "deploymentBytecode": {
          "$ref": "#/definitions/BytecodeObject"
        },
        "runtimeBytecode": {
          "$ref": "#/definitions/BytecodeObject"
        },
        "abi": {
          "title": "ABI",
          "description": "The ABI for this contract type",
          "type": "array"
        },
        "devdoc": {
          "title": "Devdoc",
          "description": "The dev-doc for this contract",
          "type": "object"
        },
        "userdoc": {
          "title": "Userdoc",
          "description": "The user-doc for this contract",
          "type": "object"
        }
      }
    },
    "ContractInstance": {
      "title": "Contract Instance",
      "description": "Data for a deployed instance of a contract",
      "type": "object",
      "required": [
        "contractType",
        "address"
      ],
      "properties": {
        "contractType": {
          "anyOf": [
            {"$ref": "#/definitions/ContractTypeName"},
            {"$ref": "#/definitions/NestedContractTypeName"}
          ]
        },
        "address": {
          "$ref": "#/definitions/Address"
        },
        "transaction": {
          "$ref": "#/definitions/TransactionHash"
        },
        "block": {
          "$ref": "#/definitions/BlockHash"
        },
        "runtimeBytecode": {
          "$ref": "#/definitions/BytecodeObject"
        },
        "linkDependencies": {
          "title": "Link Dependencies",
          "description": "The values for the link references found within this contract instances runtime bytecode",
          "type": "array",
          "items": {
            "$ref": "#/definitions/LinkValue"
          }
        }
      }
    },
    "ContractTypeName": {	
      "title": "Contract Type Name",
      "description": "The name of the contract type",
      "type": "string",
      "pattern": "^(?:[a-z][-a-z0-9]{0,255}\\:)?[a-zA-Z_$][-a-zA-Z0-9_$]{0,255}(?:[-a-zA-Z0-9]{1,256}])?$"
    },
    "ByteString": {
      "title": "Byte String",
      "description": "0x-prefixed hexadecimal string representing bytes",
      "type": "string",
      "pattern": "^0x([0-9a-fA-F]{2})*$"
    },
    "BytecodeObject": {
      "title": "Bytecode Object",
      "type": "object",
      "anyOf": [
        {"required": ["bytecode"]},
        {"required": ["linkDependencies"]}
      ],
      "properties": {
        "bytecode": {
          "$ref": "#/definitions/ByteString"
        },
        "linkReferences": {
          "type": "array",
          "items": {
            "$ref": "#/definitions/LinkReference"
          }
        },
        "linkDependencies": {
          "type": "array",
          "items": {
            "$ref": "#/definitions/LinkValue"
          }
        }
      }
    },
	"ChecksumObject": {
      "title": "Checksum Object",
	  "description": "Checksum information about the contents of a source file",
	  "type": "object",
	  "required": [
		"hash",
		"algorithm"
	  ],
	  "properties": {
		"hash": {
		  "type": "string"
		},
		"algorithm": {
		  "type": "string"
		}
	  }
	},
    "LinkReference": {
      "title": "Link Reference",
      "description": "A defined location in some bytecode which requires linking",
      "type": "object",
      "required": [
        "offsets",
        "length",
        "name"
      ],
      "properties": {
        "offsets": {
          "type": "array",
          "items": {
            "type": "integer",
            "minimum": 0
          }
        },
        "length": {
          "type": "integer",
          "minimum": 1
        },
        "name": {
          "anyOf": [
            {"$ref": "#/definitions/ContractTypeName"},
            {"$ref": "#/definitions/NestedContractTypeName"}
          ]
        }
      }
    },
    "LinkValue": {
      "title": "Link Value",
      "description": "A value for an individual link reference in a contract's bytecode",
      "type": "object",
      "required": [
        "offsets",
        "type",
        "value"
      ],
      "properties": {
        "offsets": {
          "type": "array",
          "items": {
            "type": "integer",
            "minimum": 0
          }
        },
        "type": {
          "description": "The type of link value",
          "type": "string"
        },
        "value": {
          "description": "The value for the link reference"
        }
      },
      "oneOf": [{
        "properties": {
          "type": {
            "enum": ["literal"]
          },
          "value": {
            "$ref": "#/definitions/ByteString"
          }
        }
      }, {
        "properties": {
          "type": {
            "enum": ["reference"]
          },
          "value": {
            "anyOf": [
              {"$ref": "#/definitions/ContractInstanceName"},
              {"$ref": "#/definitions/NestedContractInstanceName"}
            ]
          }
        }
      }]
    },
    "ContractInstanceName": {
      "title": "Contract Instance Name",
      "description": "The name of the deployed contract instance",
      "type": "string",
      "pattern": "^[a-zA-Z_$][-a-zA-Z0-9_$]{0,255}(?:[-a-zA-Z0-9]{1,256})?$"
    },
    "Deployment": {
      "title": "Deployment",
      "type": "object",
      "propertyNames": {
        "$ref": "#/definitions/ContractInstanceName"
      },
      "patternProperties": {
        "": {
          "$ref": "#/definitions/ContractInstance"
        }
      }
    },
    "NestedContractTypeName": {
      "title": "Nested Contract Type Name",
      "description": "Name of a nested contract type from somewhere down the dependency tree",
      "type": "string",
      "pattern": "^(?:[a-z][-a-z0-9]{0,255}\\:)+[a-zA-Z_$][-a-zA-Z0-9_$]{0,255}(?:[-a-zA-Z0-9]{1,256})?$"
	},
    "NestedContractInstanceName": {
      "title": "Nested Contract Instance Name",
      "description": "Name of a nested contract instance from somewhere down the dependency tree",
      "type": "string",
      "pattern": "^(?:[a-z][-a-z0-9]{0,255}\\:)+[a-zA-Z_$][-a-zA-Z0-9_$]{0,255}(?:[-a-zA-Z0-9]{1,256})?$"
    },
    "CompilerInformation": {
      "title": "Compiler Information",
      "description": "Information about the software that was used to compile a contract type or deployment",
      "type": "object",
      "required": [
        "name",
        "version"
      ],
      "properties": {
        "name": {
          "description": "The name of the compiler",
          "type": "string"
        },
        "version": {
          "description": "The version string for the compiler",
          "type": "string"
        },
        "settings": {
          "description": "The settings used for compilation",
          "type": "object"
        },
        "contractTypes": {
          "description": "The contract types that targeted this compiler.",
          "type": "array",
          "items": {
            "$ref": "#/definitions/ContractTypeName"
          }
        }
      }
    },
    "Address": {
      "title": "Address",
      "description": "A 0x-prefixed Ethereum address",
      "allOf": [
        { "$ref": "#/definitions/ByteString" },
        { "minLength": 42, "maxLength": 42 }
      ]
    },
    "TransactionHash": {
      "title": "Transaction Hash",
      "description": "A 0x-prefixed Ethereum transaction hash",
      "allOf": [
        { "$ref": "#/definitions/ByteString" },
        { "minLength": 66, "maxLength": 66 }
      ]
    },
    "BlockHash": {
      "title": "Block Hash",
      "description": "An Ethereum block hash",
      "allOf": [
        { "$ref": "#/definitions/ByteString" },
        { "minLength": 66, "maxLength": 66 }
      ]
    },
    "ContentURI": {
      "title": "Content URI",
      "description": "An content addressable URI",
      "type": "string",
      "format": "uri"
    },
	"BlockchainURI": {
      "title": "Blockchain URI",
      "description": "An BIP122 URI",
      "type": "string",
      "pattern": "^blockchain\\://[0-9a-fA-F]{64}\\/block\\/[0-9a-fA-F]{64}$"
	}
  },
  "dependencies": {
    "name": ["version"],
    "version": ["name"]
  }
}
