---
eip: draft-arachnid-eip-lifecycle
title: Revised EIP lifecycle
author: Nick Johnson <nick@ethereum.org>
discussions-to:
status: Draft
type: Meta
created: 2018-03-28
---

## Simple Summary
This EIP specifies a new process for the lifecycle of EIPs, focusing on the acceptance and approval of drafts.

## Motivation
The process for the EIP lifecycle defined in [EIP-1](eip-1.html) is ambiguous, failing to clearly specify when draft EIPs should be merged by editors, and what the process is for progressing a draft EIP, particularly an ERC, from draft to final status. This EIP proposes to revise the process by providing more concrete criteria and a simpler process for draft acceptance.

## Specification

The following text from the EIP1 "Work Flow" section is deleted:

> Once the champion has asked the Ethereum community whether an idea has any chance of acceptance a draft EIP should be presented as a [pull request]. This gives the author a chance to continuously edit the draft EIP for proper formatting and quality. This also allows for further public comment and the author of the EIP to address concerns about the proposal.
>
> If the EIP collaborators approve, the EIP editor will assign the EIP a number (generally the issue or PR number related to the EIP), label it as Standards Track, Informational, or Meta, give it status “Draft”, and add it to the git repository. The EIP editor will not unreasonably deny an EIP. Reasons for denying EIP status include duplication of effort, being technically unsound, not providing proper motivation or addressing backwards compatibility, or not in keeping with the Ethereum philosophy.
>
> Standards Track EIPs consist of three parts, a design document, implementation, and finally if warranted an update to the [formal specification]. The EIP should be reviewed and accepted before an implementation is begun, unless an implementation will aid people in studying the EIP. Standards Track EIPs must be implemented in at least three viable Ethereum clients before it can be considered Final.
>
> For an EIP to be accepted it must meet certain minimum criteria. It must be a clear and complete description of the proposed enhancement. The enhancement must represent a net improvement. The proposed implementation, if applicable, must be solid and must not complicate the protocol unduly.
>
> Once an EIP has been accepted, the implementations must be completed. When the implementation is complete and accepted by the community, the status will be changed to “Final”.
>
> An EIP can also be assigned status “Deferred”. The EIP author or editor can assign the EIP this status when no progress is being made on the EIP. Once an EIP is deferred, the EIP editor can re-assign it to draft status.

In its place, the following text is inserted:

> Anyone may submit a draft EIP as a pull request to the EIPs repository. Drafts should be placed in the 'drafts' directory and named in the format `eip-draft-*author*-*title*.md`, where *author* is the Github user or organisation name from which the pull request is sent, and *title* is a short hyphen-separated title for the EIP draft.
>
> Drafts must be formatted as described in this EIP; a template is available in [eip-X.md](https://github.com/ethereum/EIPs/blob/master/eip-X.md). All required headers must be present and filled in correctly. For a draft, the `eip` field must match the filename, without the 'eip-' prefix or '.md' suffix (eg, for `eip-draft-vitalik-foo.md`, the `eip` field should read `draft-vitalik-foo`). Drafts must contain a `discussions-to` header, specifying the URL to a venue where collaborators can discuss the draft. This may be a Github issue in the EIPs repository, or any other venue as the author sees fit.
>
> An automated process will check all pull requests; if the request passes the format checks and contains only additions or edits to drafts owned by the submitter, it will be automatically merged. No editorial control is exercised over the content of an EIP draft.
>
> Standards track EIPs of type 'Core' are updated from 'Draft' to 'Accepted' status when a core devs meeting has accepted the draft and the participants have announced their intention to implement the EIP for inclusion in a future hard fork. At that point, an EIP number is assigned by the editors and the EIP is moved to the EIPS directory and renamed accordingly. One a Core EIP has been implemented in at least three clients, and all pass a common set of test suites, the status of the EIP is updated to 'Final'. An EIP can also be assigned status “Deferred”. The EIP author or editor can assign the EIP this status when no progress is being made on the EIP.
>
> Standards track, non-core EIPs remain in Draft status until at least one implementation has been completed and referenced in the Implementations section of the draft. At that point, the draft's author may apply to the EIP editor, by way of a pull request, to assign a number to the EIP and update its status to 'Final', moving it to the EIPs directory and renaming it accordingly.
>
> Non-standards track EIPs may be transitioned to 'Accepted' or 'Final' status when the author requests it, and at the discretion of the editors.
>
> For an EIP to be accepted it must meet certain minimum criteria. It must be a clear and complete description of the proposed enhancement. The enhancement must represent a net improvement. The proposed implementation, if applicable, must be solid and must not complicate the protocol unduly. The EIP editor will not unreasonably deny an EIP. Reasons for denying EIP status include duplication of effort, being technically unsound, not providing proper motivation, or failing to address backwards compatibility.
>
> Once an EIP is marked Final, edits are not permitted unless they correct errata; no substantive changes may be made. Anyone wishing to amend a Final EIP must submit a new EIP instead.

## Rationale
This proposal serves to describe more clearly the present process for acceptance and implementation of Core EIPs, while also proposing a more concrete process for non-core EIPs. This serves to alleviate EIP editor workload in cases where manual approval is not necessary, and ensures that outstanding pull requests will all represent work required by the editors, making it easier to identify what actions are required, and making the approval process more transparent to users.

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
