#!myenv/bin/python
import argparse
import ast
import subprocess
from common import falcon_compact, q
from encoding import decompress
from falcon import HEAD_LEN, SALT_LEN, PublicKey, SecretKey
from falcon_epervier import EpervierPublicKey, EpervierSecretKey
from falcon_recovery import RecoveryModePublicKey, RecoveryModeSecretKey
from polyntt.poly import Poly
from shake import SHAKE
from keccak_prng import KeccakPRNG
from keccak import KeccakHash
from eth_abi import encode


def generate_keys(n, version):
    # private key
    if version == 'ethfalcon' or version == 'falcon':
        SK = SecretKey
    elif version == 'falconrec':
        SK = RecoveryModeSecretKey
    elif version == 'epervier':
        SK = EpervierSecretKey
    else:
        print("This version does not exist.")
        return

    sk = SK(n)

    if version == 'ethfalcon' or version == 'falcon':
        pk = PublicKey(n, sk.h)
    elif version == 'falconrec':
        pk = RecoveryModePublicKey(n, sk.pk)
    elif version == 'epervier':
        pk = EpervierPublicKey(n, sk.pk)

    return sk, pk


def save_pk(pk, filename, version):
    with open(filename, "w") as f:
        f.write("# public key\n")
        f.write("n = {}\n".format(pk.n))
        f.write("pk = {}\n".format(pk.pk))
        f.write("version = {}\n".format(version))


def save_sk(sk, filename, version):
    with open(filename, "w") as f:
        f.write("# private key\n")
        f.write("n = {}\n".format(sk.n))
        f.write("f = {}\n".format(sk.f))
        f.write("g = {}\n".format(sk.g))
        f.write("F = {}\n".format(sk.F))
        f.write("G = {}\n".format(sk.G))
        f.write("version = {}\n".format(version))


def save_signature(sig, filename):
    with open(filename, "w") as f:
        f.write(sig.hex())


def load_pk(filename):
    with open(filename, "r") as f:
        data = f.read()
    variables = dict(line.split("=")
                     # first line is a comment
                     for line in data.splitlines()[1:])
    n = int(variables["n "])
    pk = ast.literal_eval(variables["pk "])
    version = variables["version "].lstrip()
    if version == 'ethfalcon' or version == 'falcon':
        return [PublicKey(n, pk), version]
    elif version == 'falconrec':
        return [RecoveryModePublicKey(n, pk), version]
    elif version == 'epervier':
        return [EpervierPublicKey(n, pk), version]
    else:
        print("This version is not supported.")
        return


def load_sk(filename):
    with open(filename, "r") as f:
        data = f.read()
    variables = dict(line.split("=")
                     # first line is a comment
                     for line in data.splitlines()[1:])
    n = int(variables["n "])
    f = ast.literal_eval(variables["f "])
    g = ast.literal_eval(variables["g "])
    F = ast.literal_eval(variables["F "])
    G = ast.literal_eval(variables["G "])
    version = variables["version "].lstrip()
    if version == 'ethfalcon' or version == 'falcon':
        return [SecretKey(n, polys=[f, g, F, G]), version]
    elif version == 'falconrec':
        return [RecoveryModeSecretKey(n, polys=[f, g, F, G]), version]
    elif version == 'epervier':
        return [EpervierSecretKey(n, polys=[f, g, F, G]), version]
    else:
        print("This version is not supported.")
        return


def load_signature(filename):
    with open(filename, "r") as f:
        signature = f.read()
    return bytes.fromhex(signature)


def signature(sk, data, version):
    # De-randomization of urandom as RFC 6979 page 10-11.
    deterministic_bytes = SHAKE()
    # v = 0x00 32 times in the case of a hash function with output 256 bits.
    # WARNING: this is probably not secure as it is implemented.
    deterministic_bytes.update(bytes(
        [0x01]*32
    ))
    # separator
    deterministic_bytes.update(bytes([0x00]))
    # secret key encoded
    deterministic_bytes.update(b''.join(x.to_bytes(2, 'big') for x in sk.h))
    # data TODO consider h(M) instead here.
    # if H does not output 32 bytes, change V above.
    deterministic_bytes.update(data)

    return sk.sign(
        data,
        randombytes=deterministic_bytes.read,
        xof=SHAKE if version == 'falcon' or version == 'epervier' else KeccakPRNG
    )


def transaction_hash(nonce, to, data, value):
    K = KeccakHash(rate=200-(512 // 8), dsbyte=0x01)
    packed = encode(
        # seem that `to` is considered as uint256
        ["uint256", "uint160", "bytes", "uint256"],
        [nonce, to, data, value]
    )
    K.absorb(packed)
    K.pad()
    return K.squeeze(32)


def print_signature_transaction(sig, pk, tx_hash):
    TX_HASH = "0x" + tx_hash.hex()

    salt = sig[HEAD_LEN:HEAD_LEN + SALT_LEN]
    SALT = "0x"+salt.hex()

    enc_s = sig[HEAD_LEN + SALT_LEN:]
    s2 = decompress(enc_s, pk.sig_bytelen - HEAD_LEN - SALT_LEN, 512)
    s2 = [elt % q for elt in s2]
    s2_compact = falcon_compact(s2)
    S2 = str(s2_compact)
    pk_compact = falcon_compact(Poly(pk.pk, q).ntt())
    PK = str(pk_compact)
    print("TX_HASH = {}".format(TX_HASH))
    print("PK = {}".format(PK))
    print("S2 = {}".format(S2))
    print("SALT = {}".format(SALT))


def verify_signature(pk, data, sig, version):
    if version == 'falcon' or version == 'epervier':
        XOF = SHAKE
    elif version == 'ethfalcon':
        XOF = KeccakPRNG
    else:
        print('NOT IMPLEMENTED YET')
    return pk.verify(data, sig, xof=XOF)


def recover_on_chain(data, sig, contract_address, rpc, version):
    assert version == 'epervier'
    MSG = "0x" + data.hex()

    salt = sig[HEAD_LEN:HEAD_LEN + SALT_LEN]
    SALT = "0x"+salt.hex()

    enc_s = sig[HEAD_LEN + SALT_LEN:-512*3]
    s = decompress(enc_s, 666*2 - HEAD_LEN - SALT_LEN, 512*2)
    mid = len(s)//2
    s = [elt % q for elt in s]
    s1, s2 = s[:mid], s[mid:]
    s1_compact = falcon_compact(s1)
    s2_compact = falcon_compact(s2)
    S1 = str(s1_compact)
    S2 = str(s2_compact)
    s2_inv_ntt = Poly(s2, q).inverse().ntt()
    hint = 1
    for elt in s2_inv_ntt:
        hint = (hint * elt) % q
    HINT = str(hint)

    command = [
        "cast", "call", contract_address,
        "recover(bytes,bytes,uint256[],uint256[],uint256,)", MSG, SALT, S1, S2, HINT, "--rpc-url", rpc
    ]

    result = subprocess.run(
        command,
        capture_output=True,
        text=True
    )
    assert result.stderr == ''
    return result.stdout


def verify_signature_on_chain(pk, data, sig, contract_address, rpc, version):

    MSG = "0x" + data.hex()

    salt = sig[HEAD_LEN:HEAD_LEN + SALT_LEN]
    SALT = "0x"+salt.hex()

    if version == 'epervier':
        # the output of recover_on_chain is a string containing the public key in hexadecimal
        if int(recover_on_chain(data, sig, contract_address, rpc, version), 16) == pk.pk:
            print(
                "\n0x0000000000000000000000000000000000000000000000000000000000000001\n")
    elif version == 'ethfalcon' or version == 'falcon':
        enc_s = sig[HEAD_LEN + SALT_LEN:]
        s2 = decompress(enc_s, 666 - HEAD_LEN - SALT_LEN, 512)
        s2 = [elt % q for elt in s2]
        s2_compact = falcon_compact(s2)
        S2 = str(s2_compact)
        PK = str(falcon_compact(Poly(pk.pk, q).ntt()))
        command = [
            "cast", "call", contract_address,
            "verify(bytes,bytes,uint256[],uint256[])", MSG, SALT, S2, PK, "--rpc-url", rpc
        ]
        result = subprocess.run(
            command,
            capture_output=True,
            text=True
        )
        # assert result.stderr == ''
        print(result.stderr)
        print(result.stdout)
    else:
        print("This version is not implemented.")
        return


def recover_on_chain_with_transaction(data, sig, contract_address, rpc, private_key, version):
    assert version == 'epervier'
    MSG = "0x" + data.hex()

    salt = sig[HEAD_LEN:HEAD_LEN + SALT_LEN]
    SALT = "0x"+salt.hex()

    enc_s = sig[HEAD_LEN + SALT_LEN:-512*3]
    s = decompress(enc_s, 666*2 - HEAD_LEN - SALT_LEN, 512*2)
    mid = len(s)//2
    s = [elt % q for elt in s]
    s1, s2 = s[:mid], s[mid:]
    s1_compact = falcon_compact(s1)
    s2_compact = falcon_compact(s2)
    S1 = str(s1_compact)
    S2 = str(s2_compact)
    s2_inv_ntt = Poly(s2, q).inverse().ntt()
    hint = 1
    for elt in s2_inv_ntt:
        hint = (hint * elt) % q
    HINT = str(hint)

    command = "cast send --private-key {} {} \"recover(bytes,bytes,uint256[],uint256[], uint256)\" {} {} \"{}\" \"{}\" \"{}\" --rpc-url {}".format(
        private_key,
        contract_address,
        MSG,
        SALT,
        S2,
        HINT,
        rpc
    )
    result = subprocess.run(
        command,
        shell=True,
        capture_output=True,
        text=True
    )
    # assert result.stderr == ''
    print(result.stderr)
    print(result.stdout)


def verify_signature_on_chain_with_transaction(pk, data, sig, contract_address, rpc, private_key, version):

    assert version == 'falcon' or version == 'ethfalcon'
    MSG = "0x" + data.hex()

    salt = sig[HEAD_LEN:HEAD_LEN + SALT_LEN]
    SALT = "0x"+salt.hex()

    enc_s = sig[HEAD_LEN + SALT_LEN:]
    s2 = decompress(enc_s, pk.sig_bytelen - HEAD_LEN - SALT_LEN, 512)
    s2 = [elt % q for elt in s2]
    s2_compact = falcon_compact(s2)
    S2 = str(s2_compact)
    pk_compact = falcon_compact(Poly(pk.pk, q).ntt())
    PK = str(pk_compact)

    command = "cast send --private-key {} {} \"verify(bytes,bytes,uint256[],uint256[])\" {} {} \"{}\" \"{}\" --rpc-url {}".format(
        private_key,
        contract_address,
        MSG,
        SALT,
        S2,
        PK,
        rpc
    )
    result = subprocess.run(
        command,
        shell=True,
        capture_output=True,
        text=True
    )
    # assert result.stderr == ''
    print(result.stderr)
    print(result.stdout)


def cli():
    parser = argparse.ArgumentParser(description="CLI for Falcon Signature")
    parser.add_argument("action", choices=[
                        "genkeys", "sign", "sign_tx", "verify", "verifyonchain", "verifyonchainsend", "recoveronchain", "recoveronchainsend"], help="Action to perform")
    parser.add_argument("--version", type=str,
                        help="Version to use (falcon or ethfalcon or epervier)")
    parser.add_argument("--nonce", type=str,
                        help="nonce in hexadecimal to sign the transaction")
    parser.add_argument("--to", type=str,
                        help="Destination in hexadecimal address for the transaction")
    parser.add_argument("--data", type=str,
                        help="Data to be signed in hexadecimal")
    parser.add_argument("--value", type=str,
                        help="Value in hexadecimal for the transaction")
    parser.add_argument("--privkey", type=str,
                        help="Private key file for signing")
    parser.add_argument("--pubkey", type=str,
                        help="Public key file for verification")
    parser.add_argument("--contractaddress", type=str,
                        help="Contract address for on-chain verification")
    parser.add_argument("--rpc", type=str,
                        help="RPC for on-chain verification")
    parser.add_argument("--privatekey", type=str,
                        help="Ethereum ECDSA private key for sending a transaction")
    parser.add_argument("--signature", type=str, help="Signature to verify")

    args = parser.parse_args()

    if args.action == "genkeys":
        if not args.version:
            print("Error: Provide --version")
            return
        n = 512
        priv, pub = generate_keys(n, args.version)
        save_pk(pub, "public_key.pem", args.version)
        save_sk(priv, "private_key.pem", args.version)
        print("Keys generated and saved.")

    elif args.action == "sign":
        if not args.data or not args.privkey:
            print("Error: Provide --data, and --privkey")
            return
        [sk, version] = load_sk(args.privkey)
        sig = signature(sk, bytes.fromhex(args.data), version)
        save_signature(sig, 'sig')

    elif args.action == "sign_tx":
        if not args.data or not args.privkey or not args.nonce or not args.to or not args.value:
            print(
                "Error: Provide --data, --privkey, --nonce, --to and --value")
            return
        tx_hash = transaction_hash(
            int(args.nonce, 16),
            int(args.to, 16),
            bytes.fromhex(args.data),
            int(args.value, 16)
        )
        print(tx_hash)
        [sk, version] = load_sk(args.privkey)
        pk = PublicKey(512, sk.h)
        sig = signature(sk, tx_hash, args.version)
        assert (verify_signature(pk, tx_hash, sig))
        print_signature_transaction(sig, pk, tx_hash, version)

    elif args.action == "verify":
        if not args.data or not args.pubkey or not args.signature:
            print("Error: Provide --data, --pubkey, and --signature")
            return
        [pk, version] = load_pk(args.pubkey)
        sig = load_signature(args.signature)
        if verify_signature(pk, bytes.fromhex(args.data), sig, version):
            print("Signature is valid.")
        else:
            print("Invalid signature.")

    elif args.action == "verifyonchain":
        if not args.data or not args.pubkey or not args.signature or not args.rpc or not args.contractaddress:
            print(
                "Error: Provide --data, --pubkey, --signature, --contractaddress and --rpc")
            return
        [pk, version] = load_pk(args.pubkey)
        sig = load_signature(args.signature)
        verify_signature_on_chain(
            pk, bytes.fromhex(args.data), sig, args.contractaddress, args.rpc, version)

    elif args.action == "verifyonchainsend":
        if not args.data or not args.pubkey or not args.signature or not args.rpc or not args.contractaddress or not args.privatekey:
            print(
                "Error: Provide --data, --pubkey, --signature, --contractaddress, --rpc and --privatekey")
            return
        [pk, version] = load_pk(args.pubkey)
        sig = load_signature(args.signature)
        verify_signature_on_chain_with_transaction(
            pk, bytes.fromhex(args.data), sig, args.contractaddress, args.rpc, args.privatekey, version)

    elif args.action == "recoveronchain":
        if not args.data or not args.pubkey or not args.signature or not args.rpc or not args.contractaddress:
            print(
                "Error: Provide --data, --pubkey, --signature, --contractaddress and --rpc")
            return
        [pk, version] = load_pk(args.pubkey)
        sig = load_signature(args.signature)
        pk_rec = recover_on_chain(
            bytes.fromhex(args.data), sig, args.contractaddress, args.rpc, version)
        print("Public key recovered: {}".format(pk_rec))

    elif args.action == "recoveronchainsend":
        if not args.data or not args.pubkey or not args.signature or not args.rpc or not args.contractaddress or not args.privatekey:
            print(
                "Error: Provide --data, --pubkey, --signature, --contractaddress, --rpc and --privatekey")
            return
        [pk, version] = load_pk(args.pubkey)
        sig = load_signature(args.signature)
        pk_rec = recover_on_chain_with_transaction(
            bytes.fromhex(args.data), sig, args.contractaddress, args.rpc, args.privatekey, version)
        print("Public key recovered: {}".format(pk_rec))


if __name__ == "__main__":
    cli()
