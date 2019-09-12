---
eip: <to be assigne>
title: Precompiled versioning
author: Antoine Rondelet (@AntoineRondelet)
discussions-to: <URL>
status: Draft
type: Standards Track
category: Core
requires: [eip-1109](https://eips.ethereum.org/EIPS/eip-1109)
created: 2019-09-12
---

<!--You can leave these HTML comments in your merged EIP and delete the visible duplicate text guides, they will not appear and may be helpful to refer to if you edit it again. This is the suggested template for new EIPs. Note that an EIP number will be assigned by an editor. When opening a pull request to submit your EIP, please use an abbreviated title in the filename, `eip-draft_title_abbrev.md`. The title should be 44 characters or less.-->

Note that an EIP number will be assigned by an editor. When opening a pull request to submit your EIP, please use an abbreviated title in the filename, `eip-draft_title_abbrev.md`.

The title should be 44 characters or less.

## Simple Summary
<!--"If you can't explain it simply, you don't understand it well enough." Provide a simplified and layman-accessible explanation of the EIP.-->
Introduces a `chainID` number to differentiate between "mainnet preconpiled contracts" and "fork specific precompiled". This allows forks to extend mainnet's execution environment at will.

## Abstract
<!--A short (~200 word) description of the technical issue being addressed.-->
This EIP follows and extends [eip-1109](https://eips.ethereum.org/EIPS/eip-1109) and aims to introduce a `chainID` argument to the `PRECOMPILEDCALL` OPCODE. Adding such argument would enable forks to be able to define their custom precompiled contracts and extend the execution environment, while keeping it straigthforward to pull new changes made on mainnet and merge them to keep clients in sync with the latest development. As a general note, keeping clients easy to update (with mainnet) should be highly regarded as it helps gathering "forks" and mainnet communities. Making it easy to update a code base should encourage "fork developers" to do frequently which is good from a security standpoint (new fixes and patches can then be quickly introduced in forks).

## Motivation
<!--The motivation is critical for EIPs that want to change the Ethereum protocol. It should clearly explain why the existing protocol specification is inadequate to address the problem that the EIP solves. EIP submissions without sufficient motivation may be rejected outright.-->
As of today, the only way for a fork of Ethereum to define custom precompiled contracts, if to follow the standard approach and introduce a new list:
```golang
var PrecompiledContractsCustom = map[common.Address]PrecompiledContract{
    common.BytesToAddress([]byte{1}): &ecrecover{},
    common.BytesToAddress([]byte{2}): &sha256hash{},
    common.BytesToAddress([]byte{3}): &ripemd160hash{},
    common.BytesToAddress([]byte{4}): &dataCopy{},
    common.BytesToAddress([]byte{5}): &bigModExp{},
    common.BytesToAddress([]byte{6}): &bn256AddIstanbul{},
    common.BytesToAddress([]byte{7}): &bn256ScalarMulIstanbul{},
    common.BytesToAddress([]byte{8}): &bn256PairingIstanbul{},
    common.BytesToAddress([]byte{9}): &blake2F{},
    common.BytesToAddress([]byte{10}): &customPrecomp1{},
    common.BytesToAddress([]byte{11}): &customPrecomp2{},
    common.BytesToAddress([]byte{12}): &customPrecomp3{},
}
```

However, following such approach is not desirable since any new precompiled added to Ethereum will lead to an address collision for the fork willing to fetch new updates from mainnet clients. Following the example above, the only way for a fork client to merge mainnet new precompiled is to either:
1. Add them at address `13` onward, but then custom precompiled contracts get mixed with the one of "mainnet" and we see that repeating this process a few times can lead to some chaos in the precompiled addressing.
2. Follow the addressing used on mainnet, and then add the mainnet precompiled after address `9`, and move the custom precompiled after the newly added precompiled. However, doing so would break all deployed smart contracts (on the fork) calling the fork's precompiled. This is not desired at all.

While an eip like [eip-1352](https://github.com/ethereum/EIPs/blob/master/EIPS/eip-1352.md), which proposed to specify restricted address range for precompiles, could solve the problem aforementioned, we propose here to extend [eip-1109](https://eips.ethereum.org/EIPS/eip-1109) by adding an extra argument - `chainID` - to the `PRECOMPILEDCALL` opcode. This extra argument will enable to execute the precompiled at the given address as implemented on the fork client, and thus would allow to have an EVM with different set of precompiled contracts: the one from mainnet, and the one from the fork.


## Specification
<!--The technical specification should describe the syntax and semantics of any new feature. The specification should be detailed enough to allow competing, interoperable implementations for any of the current Ethereum platforms (go-ethereum, parity, cpp-ethereum, ethereumj, ethereumjs, and [others](https://github.com/ethereum/wiki/wiki/Clients)).-->
This proposal is an extension of [eip-1109](https://eips.ethereum.org/EIPS/eip-1109). As a consequence, we follow the specification introduced in this initial EIP, and will only list changes we would like to make.

As opposed to EIP-1109, the OPCODE `PRECOMPILEDCALL` takes 6 words from the stack as input.
The first input stack value is `mu_s[0] = The chainID specifying in which precompiled address range is the called precompiled defined`.
The value of `chainID` is `0` for mainnet, and can be set to be `=/= 0` for any fork.

The remaining input stack values follow [eip-1109](https://eips.ethereum.org/EIPS/eip-1109).

Like in [eip-1109](https://eips.ethereum.org/EIPS/eip-1109), a `PRECOMPILEDCALL` to a regular address or regular smart contract, is considered a call to an "undefined smart contract", so the VM MUST not execute it and the opcode must return 0x0. Moreover, the VM MUST not execute it and the opcode must return 0x0 if the precompiled is not defined on the fork.


## Rationale
<!--The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion.-->
I few proposal inspired this one. First, [eip-1352](https://github.com/ethereum/EIPs/blob/master/EIPS/eip-1352.md) proposes an alternative approach relying on a static allocation of a range of addresses. This solution has the advantage to be trivial to implement. On the other hand it fails to provide a nice level of abstraction, which is what this proposal aims to address. Likewise, [eip-1109](https://eips.ethereum.org/EIPS/eip-1109) and [eip-1702](https://eips.ethereum.org/EIPS/eip-1702) inspired this proposal.

## Backwards Compatibility
<!--All EIPs that introduce backwards incompatibilities must include a section describing these incompatibilities and their severity. The EIP must explain how the author proposes to deal with these incompatibilities. EIP submissions without a sufficient backwards compatibility treatise may be rejected outright.-->
This EIP requires a hardfork to be able to extend the set of OPCODES. However, it is backwards compatible since no currently deployed smart contracts will be broken if this EIP was to be introduced and implemented.

## Test Cases
<!--Test cases for an implementation are mandatory for EIPs that are affecting consensus changes. Other EIPs can choose to include links to test cases if applicable.-->
Same as in [eip-1702](https://eips.ethereum.org/EIPS/eip-1109), with:
- Call to undefined precompiled for different `chainID` values.
- Call to precompiled defined for certain `chainID` but not for all.

## Implementation
<!--The implementations must be completed before any EIP is given status "Final", but it need not be completed before the EIP is accepted. While there is merit to the approach of reaching consensus on the specification and rationale before writing code, the principle of "rough consensus and running code" is still useful when it comes to resolving many discussions of API details.-->
In order to support this new OPCODE and illustrate the point made above, we propose an incomplete code snippet:
- In `core/vm/instructions.go` (see: [here](https://github.com/ethereum/go-ethereum/blob/master/core/vm/instructions.go)), add a function for the new OPCODE:
```golang
func opPrecompiledCall(pc *uint64, interpreter *EVMInterpreter, contract *Contract, memory *Memory, stack *Stack) ([]byte, error) {
    // Pop gas. The actual gas is in interpreter.evm.callGasTemp.
    interpreter.intPool.put(stack.pop())
    gas := interpreter.evm.callGasTemp
    // Pop other call parameters.
    // We also retrieve the `chainID`
    chainID, addr, inOffset, inSize, retOffset, retSize := stack.pop(), stack.pop(), stack.pop(), stack.pop(), stack.pop()
    toAddr := common.BigToAddress(addr)
    // Get arguments from the memory.
    args := memory.Get(inOffset.Int64(), inSize.Int64())

    // We call interpreter.evm.PrecompiledCall() which has an extra argument `chainID`
    ret, returnGas, err := interpreter.evm.PrecompiledCall(contract, toAddr, args, gas, chainID)
    if err != nil {
        stack.push(interpreter.intPool.getZero())
    } else {
        stack.push(interpreter.intPool.get().SetUint64(1))
    }
    if err == nil || err == errExecutionReverted {
        memory.Set(retOffset.Uint64(), retSize.Uint64(), ret)
    }
    contract.Gas += returnGas

    interpreter.intPool.put(chainID, addr, inOffset, inSize, retOffset, retSize)
    return ret, nil
}
```

- In `core/vm/evm.go` (see: [here](https://github.com/ethereum/go-ethereum/blob/master/core/vm/evm.go)) add:
```golang
func (evm *EVM) PrecompiledCall(caller ContractRef, addr common.Address, input []byte, gas uint64, chainID uint) (ret []byte, leftOverGas uint64, err error) {
    if evm.vmConfig.NoRecursion && evm.depth > 0 {
        return nil, gas, nil
    }
    // Fail if we're trying to execute above the call depth limit
    if evm.depth > int(params.CallCreateDepth) {
        return nil, gas, ErrDepth
    }

    var (
        to       = AccountRef(addr)
        snapshot = evm.StateDB.Snapshot()
    )
    // Initialise a new contract and set the code that is to be used by the EVM.
    // The contract is a scoped environment for this execution context only.
    contract := NewContract(caller, to, new(big.Int), gas)
    contract.SetCallCode(&addr, evm.StateDB.GetCodeHash(addr), evm.StateDB.GetCode(addr))

    // We do an AddBalance of zero here, just in order to trigger a touch.
    // This doesn't matter on Mainnet, where all empties are gone at the time of Byzantium,
    // but is the correct thing to do and matters on other networks, in tests, and potential
    // future scenarios
    evm.StateDB.AddBalance(addr, bigZero)

    // When an error was returned by the EVM or when setting the creation code
    // above we revert to the snapshot and consume any gas remaining. Additionally
    // when we're in Homestead this also counts for code storage gas errors.
    ret, err = runPrecompiled(evm, contract, input, true, chainID)
    if err != nil {
        evm.StateDB.RevertToSnapshot(snapshot)
        if err != errExecutionReverted {
            contract.UseGas(contract.Gas)
        }
    }
    return ret, contract.Gas, err
}
```

and
```golang
// run runs the given contract and takes care of running precompiles with a fallback to the byte code interpreter.
func runPrecompiled(evm *EVM, contract *Contract, input []byte, readOnly bool, chainID uint) ([]byte, error) {
    if (chainID == 0) {
        if (contract.CodeAddr != nil) {
            precompiles := PrecompiledContractsHomestead
            if evm.ChainConfig().IsByzantium(evm.BlockNumber) {
                precompiles = PrecompiledContractsByzantium
            }
            if p := precompiles[*contract.CodeAddr]; p != nil {
                return RunPrecompiledContract(p, input, contract)
            }
        }
    }

    // Here, chainID =/= 0, so we execute a fork's precompiled
    precompiles := PrecompiledContractsCustomToTheFork
    if p := precompiles[*contract.CodeAddr]; p != nil {
        return RunCustomPrecompiledContract(p, input, contract)
    }

    return nil, ErrNoCompatibleInterpreter
}
```

- Then, we introduce a file `custom_contracts.go` in the [package "vm"](https://github.com/ethereum/go-ethereum/tree/master/core/vm), in which custom precompiled are implemented and where the `PrecompiledContractsCustomToTheFork` slice is defined pointing to the fork's precompiled addresses.

**Important Note**: The code proposed above has only been added as an illustration matter and has not been tested. It may be flawed in several ways but aims to illustrate the proposal.

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
