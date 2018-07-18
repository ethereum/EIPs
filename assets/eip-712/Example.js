const ethUtil = require('ethereumjs-util');
const abi = require('ethereumjs-abi');
const chai = require('chai');

const typedData = {
    types: {
        EIP712Domain: [
            { name: 'name', type: 'string' },
            { name: 'version', type: 'string' },
            { name: 'chainId', type: 'uint256' },
            { name: 'verifyingContract', type: 'address' },
        ],
        Person: [
            { name: 'name', type: 'string' },
            { name: 'wallet', type: 'address' }
        ],
        Mail: [
            { name: 'from', type: 'Person' },
            { name: 'to', type: 'Person[]' },
            { name: 'contents', type: 'string' }
        ],
    },
    primaryType: 'Mail',
    domain: {
        name: 'Ether Mail',
        version: '1',
        chainId: 1,
        verifyingContract: '0xCcCCccccCCCCcCCCCCCcCcCccCcCCCcCcccccccC',
    },
    message: {
        from: {
            name: 'Cow',
            wallet: '0xCD2a3d9F938E13CD947Ec05AbC7FE734Df8DD826',
        },
        to: [{
            name: 'Bob',
            wallet: '0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB',
        }],
        contents: 'Hello, Bob!',
    },
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
                found.push(dep);
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
    let result = '';
    for (let type of deps) {
        result += `${type}(${types[type].map(({ name, type }) => `${type} ${name}`).join(',')})`;
    }
    return result;
}

function typeHash(primaryType) {
    return ethUtil.sha3(encodeType(primaryType));
}

function encodeData(primaryType, data) {
    let encTypes = [];
    let encValues = [];

    // Add typehash
    encTypes.push('bytes32');
    encValues.push(typeHash(primaryType));

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
            encTypes.push('bytes32');
            const parsedType = field.type.slice(0, field.type.lastIndexOf('['));
            value = ethUtil.sha3(value.map(item => encodeData(parsedType, item)).join(''));
            encValues.push(value);
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
    return ethUtil.sha3(
        Buffer.concat([
            Buffer.from('1901', 'hex'),
            structHash('EIP712Domain', typedData.domain),
            structHash(typedData.primaryType, typedData.message),
        ]),
    );
}

const privateKey = ethUtil.sha3('cow');
const address = ethUtil.privateToAddress(privateKey);
const sig = ethUtil.ecsign(signHash(), privateKey);

const expect = chai.expect;
expect(encodeType('Mail')).to.equal('Mail(Person from,Person[] to,string contents)Person(string name,address wallet)');
expect(ethUtil.bufferToHex(typeHash('Mail'))).to.equal(
    '0xdd57d9596af52b430ced3d5b52d4e3d5dccfdf3e0572db1dcf526baad311fbd1',
);
expect(ethUtil.bufferToHex(encodeData(typedData.primaryType, typedData.message))).to.equal(
    '0xdd57d9596af52b430ced3d5b52d4e3d5dccfdf3e0572db1dcf526baad311fbd1fc71e5fa27ff56c350aa531bc129ebdf613b772b6604664f5d8dbe21b85eb0c872ea07cf404427eb52aed74d9998e238434f046d95c4ff7802d628628bf77a16b5aadf3154a261abdd9086fc627b61efca26ae5702701d05cd2305f7c52a2fc8',
);
expect(ethUtil.bufferToHex(structHash(typedData.primaryType, typedData.message))).to.equal(
    '0x74d81a21341d4ee3434cd75927bce467aeba1fa381760f07f95d9daee6f21e2b',
);
expect(ethUtil.bufferToHex(structHash('EIP712Domain', typedData.domain))).to.equal(
    '0xf2cee375fa42b42143804025fc449deafd50cc031ca257e0b194a650a912090f',
);
expect(ethUtil.bufferToHex(signHash())).to.equal('0x89f2c3d1cb4d1aa3e9c41f664a590fe73bfccdf8be1f8e03b79f5c099a0bd090');
expect(ethUtil.bufferToHex(address)).to.equal('0xcd2a3d9f938e13cd947ec05abc7fe734df8dd826');
expect(sig.v).to.equal(28);
expect(ethUtil.bufferToHex(sig.r)).to.equal('0x62c03af2a2efc2fc5023a11f6b1fffc01d27aad85bfc88dd2ba9aee8cb8b2cec');
expect(ethUtil.bufferToHex(sig.s)).to.equal('0x450d8ce8999ccc65327e40dc3d96286b7d118ba087b7ce40fbdb8de4f6bc0c0d');
