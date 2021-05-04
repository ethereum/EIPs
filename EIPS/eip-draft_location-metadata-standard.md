---
eip: <to be assigned>
title: Location Metadata Standard in ERC-721 Tokens
author:
Ricardo Chacon (@RicardoChacon)
Isabella Costanza (@isabellacostanza)
Gabriela Garro (@gabygarro)
James Jose (@jamesjosegdsey)
David Mendes (@de-mendes)
discussions-to: https://ethereum-magicians.org/t/request-for-feedback-standardizing-location-metadata-and-other-metadata-in-erc-721-tokens/5985
status: Draft
type: Informational
created: 2021-05-04
requires: 721
---

## Simple Summary

Standard for location metadata in the ERC-721 tokens. Tokens wishing to include physical location metadata should follow the same standard.

## Abstract

This standard specifies how location metadata should be represented in an ERC-721 token. It serves as an extension of the ERC-721 Metadata Standard as it adds a "location" field to the JSON schema. This location metadata can be represented with either the physical address, geolocation coordinates or both for maximum clarity. 

## Motivation

This standard will promote composability and cohesiveness of tokens across across platforms and systems. Use cases which rely on location metadata or that would benefit from implementing it often find themselves in the position of structuring this data in whichever way serves their specific purpose. However, representing location data is not a trivial endeavor and too many implementations exist since each one is use case specific, even though they are mostly similar. Therefore, we have leveraged existing ISO and geolocation standards to develop a metadata structure that can be applied globally.

Moreover, inconsistent data formats present a rather challenging situation if an user wants to make use of this data, as it can be computationally expensive and slow to clean it up. This standard provides a solution by setting a standard which will cover the need of having location metadata and also give the community a framework which will prove tremendously useful at the application layer.

One example where consistent location data structures are crucial is in supply chain management. As business partners try to coordinate their inventory to eliminate the potential for stockouts or spoilage, they need to understand the location of tokenized inputs. Tracking these inputs on one interface is only possible if all tokens are using the same standards for recording location. 

## Specification

This EIP extends the implemenation of the Asset Metadata JSON in the ERC-721 tokens; as such, the only technical requirement is to write the JSON file as follows:

```json
{
  "title": "Asset Metadata",
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
    "location": {
      "type": "object",
      "name": {
        "type": "string",
        "description": "Identifies the place where the asset represented by this NFT is located."
      },
      "geolocation": {
        "type": "object",
        "latitude": {
          "type": "string",
          "description": "Estimates the geographic position of the asset to which this NFT represents. This value is a representation of the latitude using ISO 6709."
        },
        "longitude": {
          "type": "string",
          "description": "Estimates the geographic position of the asset to which this NFT represents. This value is a representation of the longitude using ISO 6709."
        },
        "altitude": {
          "type": "string",
          "description": "Estimates the geographic position of the asset to which this NFT represents. This value is a representation of the altitude using ISO 6709."
        },
        "crsid": {
          "type": "string",
          "description": "Identifies the coordinate reference system (CRS or SRID) being used. Default is WGS84."
        }
      },
      "address": {
        "type": "object",
        "country": {
          "type": "string",
          "description": "Identifies the country where the asset represented by this NFT is located."
        },
        "state": {
          "type": "string",
          "description": "Identifies the state, province or region within the country specified."
        },
        "city": {
          "type": "string",
          "description": "Identifies the city or locality within the state specified."
        },
        "postal_address": {
          "type": "string",
          "description": "Provides a mean of physically locating the asset to which this NFT represents."
        },
        "postal_code": {
          "type": "string",
          "description": "Provides a mean of physically locating the asset to which this NFT represents."
        }
      }
    }
  }
}
```
### <ins>Validations</ins>

<center>Field</center>|<center>Expected Characterisitics</center>| <center>Examples</center>|<center>Name in JSON schema</center>
-|-|-|-|
Location Name|• String<br>• UTF-8|“Warehouse A”,<br>“Factory 02”,<br>“Factory #2”,<br>“DV’s Restaurant”,<br>“A&B”,<br>“Günter’s”<br>|name
Address|•   String<br>•   UTF-8|“5 Times Square”,<br>“243 E. Main St.”,<br>“101 1/2 Main St”|postal_address
City/Locality|• String<br>• UTF-8|“Paris”, “Cape Town”|city
State/Province|•    String<br>• UTF-8|“Washington”, “Province No 1”, “Beijing”|state
Postal Code|•   String<br>• Latin Alphabet [A-Z], numbers [0-9] and dashes<br>•    Or UTF-8 depending on the region|“10069”<br>“10069-1234”, “D10”|postal_code
Country|•   String<br>• UTF-8|“USA”, “Spain”, “Panama”|country
Latitude|•  String<br>• Decimal Degrees<br>•    From -90 to +90<br>•    Decmials for precision|“-29.23123”,”+80.3122”|latitude
Longitude|• String<br>• Decimal Degrees<br>•    From -180 to +180<br>•  Decimals for precision|"-66.165321","+130.399994"|longitude
Altitude|•  Number<br>• In meters<br>•  Sea level as a reference|"2000","8849"|altitude
Coordinate Reference System Identifier|•    URL<br>• Registry:ID<br>•   Only ID is there's formal definition in the data source<br>•   It's recommended to use a registry authority|“EPSG:4626” “WGS86”|crsid
---

### <ins>Fields Required</ins>

<center>Field</center>|<center>Required</center>
-|-
Location Name|<center>Optional<center/>
Address|<center>Optional<center/>
City/Locality|<center>Optional, needs the Country and State to work properly<center/>
State/Province|<center>Optional, needs the Country to work properly<center/>
Postal Code|<center>Optional<center/>
Country|<center>Optional<center/>
Latitude|<center>Optional<center/>
Longitude|<center>Optional<center/>
Altitude|<center>Optional<center/>
CRSID|<center>Optional, default is assumed to be WGS84<center/>

## Rationale

1.	Geolocation attributes are based on the standard [ISO 6709](https://www.iso.org/standard/39242.html), for further information, please refer to the standard document.
2.	UTF-8 as encoding is used to provide flexibility to the values when written in different languages, also the RFC definition for JSON format specifies:<br>
    * JSON text exchanged between systems that are not part of a closed ecosystem MUST be encoded using UTF-8<br>
    * [RFC 8259](https://tools.ietf.org/html/rfc8259) - The JavaScript Object Notation (JSON) Data Interchange Format.


3.	EPSG is one of the biggest registries for CRS definitions, that’s why the recommendation of use that one, however, as there are several formats allowed by the ISO 6709, depends strictly on the application on how to treat it.
4.	ISO 6709 about decimal degrees: “For computer data interchange of latitude and longitude, this International Standard generally suggests that decimal degrees be used”

## Backwards Compatibility

One of the best aspects of this EIP is that it presents NO backwards incompatibilities. This is because any ERC-721 token that implements the Asset Metadata JSON does it optionally. This means that ERC-721 Tokens which do not have an Asset Metadata JSON will not be impacted. Similarly, any token which does implement it will continue to live regardless of the implementation of this EIP. Nonetheless, any non-compliant token can be made compliant with a simple metadata update with the location field and its corresponding attributes, as detailed in the [Technical Specification Section](#Specification). 

This being said, there is one case where some confusion could arise. It would be when a token's metadata already has a "location" field which does not comply to this EIP. However, this particular case pertains more to the application level and how the NFT's metadata is being used. To conclude, this case does not generate backwards incompatibilities since no minted ERC-721 will be impacted but if a solution (as described earlier) were already to exist, a decision will need to be made as to which standard will be implemented.

## Reference Implementation

```json
{ 
  "name": "My Token",
  "description": "Just a token",
  "image": "https://images.blokchain.ey.com/0b1abca",
  "location": {
    "name": "My store",
    "geolocation": {
      "latitude": "+50.213",
      "longitude": "-30.1322",
      "altitude": "2000",
      "crsid": "WGS84",
    },
    "address": {
      "country": "USA",
      "state": "New York",
      "city": "New York",
      "postal_code": "1312",
      "postal_address": "5 Time Square",
    }
  }
}
```

## Security Considerations

There are no security implications for this proposal. This is because as we've described previously, this location standard exists within the Asset Metadata JSON of an ERC-721 and the only security implications, if any, would come from security implications in the [EIP-721](https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md).

## Disclaimer

This EIP does not promote third party products or services. Because of EY’s role as a public accounting firm, we are required to remain independent in our work from audit clients. This includes avoiding the perception that EY is promoting technology or solutions from any one firm or giving preferential access or information to any one firm. As a result, and in the interest of maximum public transparency, we will only be accepting feedback received through the public forum. Any private messages will be returned with a request that they be published to the full public forum instead. Any private revisions will be replied with the same message.

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).