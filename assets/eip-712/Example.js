const ethUtil = require('ethereumjs-util');
const abi = require('ethereumjs-abi');
const chai = require('chai');

const typedData = {
    types: {
        EIP712Domain: [
            { name: 'name', type: 'string' },
            { name: 'version', type: 'string' },
            { name: 'chainId', type: 'uint256' },
            { name: 'httpOrigin', type: 'string' },
            { name: 'verifyingContract', type: 'address' }
        ],
        Person: [
            { name: 'name', type: 'string' },
            { name: 'wallet', type: 'address' }
        ],
        Mail: [
            { name: 'from', type: 'Person' },
            { name: 'to', type: 'Person' },
            { name: 'contents', type: 'string' }
        ]
    },
    primaryType: 'Mail',
    domain: {
        name: 'Ether Mail',
        version: '1',
        chainId: 1,
        httpOrigin: 'https://ether-mail.eth',
        verifyingContract: '0xCcCCccccCCCCcCCCCCCcCcCccCcCCCcCcccccccC'
    },
    message: {
        from: {
            name: 'Cow',
            wallet: '0xCD2a3d9F938E13CD947Ec05AbC7FE734Df8DD826'
        },
        to: {
            name: 'Bob',
            wallet: '0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB'
        },
        contents: 'Hello, Bob!'
    }
};

const types = typedData.types;

// Recursively finds all the dependencies of a type
function dependencies(primaryType, found = []) {
    if (found.includes(primaryType)) {
        return found;
    }
    if (types[primaryType] === undefined) {
        return found;
    }
    found.push(primaryType);
    for (let field of types[primaryType]) {
        for (let dep of dependencies(field.type, found)) {
            if (!found.includes(dep)) {
                found.push(dep)
            }
        }
    }
    return found;
}

function encodeType(primaryType) {
    
    // Get dependencies primary first, then alphabetical
    let deps = dependencies(primaryType);
    deps = deps.filter(t => t != primaryType);
    deps = [primaryType].concat(deps.sort());
    
    // Format as a string with fields
    let result = "";
    for (let type of deps) {
        result += `${type}(${types[type].map(
            ({name, type}) => `${type} ${name}`
        ).join(',')})`
    }
    return result;
}

function typeHash(primaryType) {
    return ethUtil.sha3(encodeType(primaryType));
}

function encodeData(primaryType, data) {
    let encTypes = []
    let encValues = []
    
    // Add typehash
    encTypes.push('bytes32');
    encValues.push(typeHash(primaryType))
    
    // Add field contents
    for (let field of types[primaryType]) {
        let value = data[field.name];
        if (field.type == 'string' || field.type == 'bytes') {
            encTypes.push('bytes32');
            value = ethUtil.sha3(value);
            encValues.push(value);
        } else if (types[field.type] !== undefined) {
            encTypes.push('bytes32');
            value = ethUtil.sha3(encodeData(field.type, value));
            encValues.push(value);
        } else if (field.type.lastIndexOf(']') === field.type.length - 1) {
            throw "TODO: Arrays currently unimplemented in encodeData";
        } else {
            encTypes.push(field.type);
            encValues.push(value);
        }
    }
    
    return abi.rawEncode(encTypes, encValues);
}

function structHash(primaryType, data) {
    return ethUtil.sha3(encodeData(primaryType, data));
}

function signHash() {
    return ethUtil.sha3(Buffer.concat([
        Buffer.from('1901', 'hex'),
        structHash('EIP712Domain', typedData.domain),
        structHash(typedData.primaryType, typedData.message)
    ]));
}

const privateKey = ethUtil.sha3('cow');
const address = ethUtil.privateToAddress(privateKey);
const sig = ethUtil.ecsign(signHash(), privateKey);

chai.expect(encodeType('Mail')).to.equal('Mail(Person from,Person to,string contents)Person(string name,address wallet)')
chai.expect(ethUtil.bufferToHex(typeHash('Mail'))).to.equal( '0xa0cedeb2dc280ba39b857546d74f5549c3a1d7bdc2dd96bf881f76108e23dac2');
chai.expect(ethUtil.bufferToHex(encodeData(typedData.primaryType, typedData.message))).to.equal( '0xa0cedeb2dc280ba39b857546d74f5549c3a1d7bdc2dd96bf881f76108e23dac2fc71e5fa27ff56c350aa531bc129ebdf613b772b6604664f5d8dbe21b85eb0c8cd54f074a4af31b4411ff6a60c9719dbd559c221c8ac3492d9d872b041d703d1b5aadf3154a261abdd9086fc627b61efca26ae5702701d05cd2305f7c52a2fc8');
chai.expect(ethUtil.bufferToHex(structHash(typedData.primaryType, typedData.message)) ).to.equal( '0xc52c0ee5d84264471806290a3f2c4cecfc5490626bf912d01f240d7a274b371e');
chai.expect(ethUtil.bufferToHex(structHash('EIP712Domain', typedData.domain)) === '0x0b72c8f1f2c3bf8bcca4c3cc24cd47275f9261a5b0bcf7b9bd803419b303a1a9');
chai.expect(ethUtil.bufferToHex(signHash()) ).to.equal( '0xa5f5fa6b05af38f2e9d2889ac36f5a4ba31e20646781d23739de458d86d6593e');
chai.expect(ethUtil.bufferToHex(address)).to.equal('0xcd2a3d9f938e13cd947ec05abc7fe734df8dd826');
chai.expect(sig.v ).to.equal( 27);
chai.expect(ethUtil.bufferToHex(sig.r) ).to.equal( '0x24040eda35064d96c51f3308b5fae290edae563327348886a366ed604e0c0480');
chai.expect(ethUtil.bufferToHex(sig.s) ).to.equal( '0x42bbabf2fae4b00598596a99d577dde56ff9d013e861f611cfe7b0728e1cd057');
