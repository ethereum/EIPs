# ERC-7007 Reference Implementation

This is a WIP implementation of ERC-7007 based on the discussions in the [EIP-7007 issue thread](https://github.com/ethereum/EIPs/issues/7007).

## Setup
Run `npm install` in the root directory.

## Testing
Try running some of the following tasks:

```shell
npx hardhat help
npx hardhat test
REPORT_GAS=true npx hardhat test
```

## Metadata Standard

```json
{
    "title": "AIGC Metadata",
    "type": "object",
    "properties": {
        "name": {
            "type": "string",
            "description": "Identifies the asset to which this NFT represents"
        },
        "description": {
            "type": "string",
            "description": "Describes the asset to which this NFT represents"
        },
        "image": {
            "type": "string",
            "description": "A URI pointing to a resource with mime type image/* representing the asset to which this NFT represents. Consider making any images at a width between 320 and 1080 pixels and aspect ratio between 1.91:1 and 4:5 inclusive."
        },

        "prompt": {
            "type": "string",
            "description": "Identifies the prompt from which this AIGC NFT generated"
        },
        "seed": {
            "type": "uint256",
            "description": "Identifies the seed from which this AIGC NFT generated"
        },
        "aigc_type": {
            "type": "string",
            "description": "image/video/audio..."
        },
        "aigc_data": {
            "type": "string",
            "description": "A URI pointing to a resource with mime type image/* representing the asset to which this AIGC NFT represents. Consider making any images at a width between 320 and 1080 pixels and aspect ratio between 1.91:1 and 4:5 inclusive."
        }
    }
}
```