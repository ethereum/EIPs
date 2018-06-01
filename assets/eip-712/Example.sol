pragma solidity ^0.4.24;

contract Example {
    
    struct EIP712Domain {
        string  name;
        string  version;
        uint256 chainId;
        string  httpOrigin;
        address verifyingContract;
    }

    struct Person {
        string name;
        address wallet;
    }

    struct Mail {
        Person from;
        Person to;
        string contents;
    }

    bytes32 constant EIP712DOMAIN_TYPEHASH = keccak256(
        "EIP712Domain(string name,string version,uint256 chainId,string httpOrigin,address verifyingContract)"
    );

    bytes32 constant PERSON_TYPEHASH = keccak256(
        "Person(string name,address wallet)"
    );

    bytes32 constant MAIL_TYPEHASH = keccak256(
        "Mail(Person from,Person to,string contents)Person(string name,address wallet)"
    );

    bytes32 DOMAIN_SEPARATOR;

    constructor () public {
        DOMAIN_SEPARATOR = hash(EIP712Domain({
            name: "Ether Mail",
            version: '1',
            chainId: 1,
            httpOrigin: "https://ether-mail.eth",
            // verifyingContract: this
            verifyingContract: 0xCcCCccccCCCCcCCCCCCcCcCccCcCCCcCcccccccC
        }));
    }

    function hash(EIP712Domain eip712Domain) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(
            EIP712DOMAIN_TYPEHASH,
            keccak256(bytes(eip712Domain.name)),
            keccak256(bytes(eip712Domain.version)),
            eip712Domain.chainId, 
            keccak256(bytes(eip712Domain.httpOrigin)),
            bytes32(eip712Domain.verifyingContract)
        ));
    }

    function hash(Person person) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(
            PERSON_TYPEHASH,
            keccak256(bytes(person.name)),
            bytes32(person.wallet)
        ));
    }

    function hash(Mail mail) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(
            MAIL_TYPEHASH,
            hash(mail.from),
            hash(mail.to),
            keccak256(bytes(mail.contents))
        ));
    }

    function verify(Mail mail, uint8 v, bytes32 r, bytes32 s) internal view returns (bool) {
        bytes32 digest = keccak256(abi.encodePacked(
          "\x19\x01",
          DOMAIN_SEPARATOR,
          hash(mail)
        ));
        return ecrecover(digest, v, r, s) == mail.from.wallet;
    }
    
    function test() public view returns (bool) {
        // Example signed message
        Mail memory mail = Mail({
            from: Person({
               name: "Cow",
               wallet: 0xCD2a3d9F938E13CD947Ec05AbC7FE734Df8DD826
            }),
            to: Person({
                name: "Bob",
                wallet: 0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB
            }),
            contents: "Hello, Bob!"
        });
        uint8 v = 27;
        bytes32 r = 0x24040eda35064d96c51f3308b5fae290edae563327348886a366ed604e0c0480;
        bytes32 s = 0x42bbabf2fae4b00598596a99d577dde56ff9d013e861f611cfe7b0728e1cd057;
        
        assert(DOMAIN_SEPARATOR == 0x0b72c8f1f2c3bf8bcca4c3cc24cd47275f9261a5b0bcf7b9bd803419b303a1a9);
        assert(hash(mail) == 0xc52c0ee5d84264471806290a3f2c4cecfc5490626bf912d01f240d7a274b371e);
        assert(verify(mail, v, r, s));
        return true;
    }
}
