### Title

      EIP: 6
      Title: Renaming Suicide Variable
      Author: Hudson Jameson <hudson@hudsonjameson.com>
      Status: Draft
      Type: Standards Track
      Created: 2015-11-22

### Abstract
The solution proposed in this EIP is to charge the name of the `SUICIDE` variable in Ethereum programming languages with `SELFDESTRUCT`.

### Motivation
Mental health is a very real issue for many people and small notions can make a difference. Those dealing with loss or depression would benefit from not seeing the word suicide in our a programming languages. By some estimates, 350 million people worldwide suffer from depression. The semantics of Ethereum's programming languages need to be reviewed often if we wish to grow our ecosystem to all types of developers.

An Ethereum security audit commissioned by DEVolution, GmbH and [performed by Least Authority](https://github.com/LeastAuthority/ethereum-analyses/blob/master/README.md) recommended the following:
> Replace the instruction name "suicide" with a less connotative word like "self-destruct", "destroy", "terminate", or "close", especially since that is a term describing the natural conclusion of a contract.

The primary reason for us to change the term suicide is to show that people matter more than code and Ethereum is a mature enough of a project to recognize the need for a change. Suicide is a heavy subject and we should make every effort possible to not affect those in our development community who suffer from depression or who have recently lost someone to suicide. Ethereum is a young platform and it will cause less headaches if we implement this change early on in it's life.

### Implementation
The languages that would require the replacement of the `SUICIDE` variable include Solidity, LLL, Serpent, and Mutan. The formal Ethereum specification in the yellow paper has a `SUICIDE` opcode that may be able to be replaced with `SELFDESTRUCT`. If it is prohibitively difficult to change the opcode specification defined in the Ethereum yellow paper, it could be aliased by programming languages using that specification. A backwards compatible alias could be used for all other instances in the Ethereum ecosystem that may require that `SUICIDE` to be present in the codebase, such as the EVM (Ethereum Virtual Machine).