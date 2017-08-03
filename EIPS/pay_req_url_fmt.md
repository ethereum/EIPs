## Preamble

    EIP: <to be assigned>
    Title: URL Format for Payment Requests
    Author: Daniel A. Nagy <daniel@ethereum.org>
    Type: Standard Track
    Category: ERC
    Status: Draft
    Created: 2017-08-01
    Requires: #20, #137

## Simple Summary
A standard way of representing payment requests in Ethers and ERC #20 tokens as URLs.

## Abstract
URLs embedded in QR-codes, hyperlinks in web-pages, emails or chat messages provide for robust cross-application signaling between very loosely coupled applications. A standardized URL format for payment requests allows for instant invocation of the user's preferred wallet application (even if it is a webapp or a swarm đapp), with the correct parameterization of the payment transaction only to be confirmed by the (authenticated) user.

## Motivation
The convenience of representing payment requests by standard URLs has been a major factor in the wide adoption of Bitcoin. Bringing a similarly convenient mechanism to Ethereum would speed up its acceptance as a payment platform among end-users. In particular, URLs embedded in broadcast Intents are the preferred way of launching applications on the Android operating system and work across practically all applications. Desktop web browsers have a standardized way of defining protocol handlers for URLs with specific protocol specifications. Other desktop applications typically launch the web browser upon encountering a URL. Thus, payment request URLs could be delivered through a very broad, ever growing selection of channels.

Note that this is different from ERC #67, which is a URL format for representing arbitrary transactions and as such is more general and low-level. This ERC deals specifically with the important special case of payment requests.

## Specification

### Syntax
Payment request URLs contain "ethpay" in their schema (protocol) part and are constructed as follows:

    request                 = "ethpay" ":" beneficiary_address [ "/" token_contract_address ] [ "?" parameters ]
    beneficiary_address     = ethereum_address
    token_contract_address  = ethereum_address
    ethereum_address        = 40*40HEXDIG / ENS_NAME
    parameters              = parameter *( "&" parameter )
    parameter               = key "=" value

At present, the only `key` defined is `amount` and the corresponding `value` is a decimal number. Thus:

    key                     = "amount"
    value                   = *DIGIT [ "." 1*DIGIT ]

For the syntax of ENS_NAME, please consult ERC #137 defining Ethereum Name Service.

### Semantics
If `token_contract_address` is missing, then the payment is requested in the native token of the blockchain, which is Ether in our case. The only mandatory field `beneficiary_address` denotes the address of the account to be credited with the requested token.

Thus, if `token_contract_address` is missing, the target address of the transaction is `beneficiary_address`, otherwise it is `token_contract_address`, with the appropriate transaction data, as defined in ERC #20 indicating the transfer of the given amount of tokens.

If using ENS names instead of hexadecimal addresses, the resolution is up to the payer, at any time between receiving the URL and sending the transaction. Hexadecimal addresses always take precedence over ENS names, i. e. even if there exists a matching ENS name consisting of 40 hexadecimal digits, it should never be resolved. Instead, the hexadecimal address should be used directly.

The amount is to be interpreted in the decimal definition of the token, NOT the atomic unit. In case of Ether, it needs to be multiplied by 10^18 to get the integer amount in Wei. For other tokens, the decimal value should be read from the token contract before conversion.

Note that the indicated amount is only a suggestion and the user is free to change it. With no indicated amount, the user should be prompted to enter the amount to be paid. In case of multiple suggestions, the user should have the option of choosing one or enter their own.

## Rationale
The proposed format is chosen to resemble `bitcoin:` URLs as closely as possible, as both users and application programmers are already familiar with that format. In particular, this motivated the omission of the unit, which is often used in Ethereum ecosystem. Handling different orders of magnitude is delegated to the application, just like in the case of `bitcoin:`. Additional parameters may be added, if popular use cases requiring them emerge in practice.
