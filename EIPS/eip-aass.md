---
eip: <to be assigned>
title: AI Agent Security Standard — 8 Attack Vectors and Mitigation Framework
description: A systematic classification and mitigation framework for AI Agent × DeFi attack surfaces, defining 8 attack vectors, 3 compliance levels, and automated verification tools.
author: Shiqiang Chen (@shunfeng8421)
discussions-to: https://github.com/shunfeng8421/defi-hack-memo/issues
status: Draft
type: Informational
category: ERC
created: 2026-07-23
---

## Abstract

As AI agents increasingly manage on-chain assets autonomously, a new class of attack vectors emerges at the intersection of AI systems and decentralized finance. This EIP provides the first systematic taxonomy of AI Agent × DeFi vulnerabilities, defining 8 attack vectors, 3 compliance levels, and automated detection tools. Based on real-world exploitation data (2 confirmed MCP CVEs, 5 protocol audits, 108 contracts analyzed), this standard enables protocols and wallets to self-assess their AI agent security posture.

## Motivation

Current DeFi security standards (EIP-2612 permit, EIP-4626 vaults) address traditional smart contract vulnerabilities but assume human operators. When AI agents execute transactions autonomously, new failure modes emerge that conventional tools cannot detect:

- Prompt injection bypassing tool authorization
- AI agent reading manipulated on-chain prices  
- MCP protocol man-in-the-middle attacks
- Multi-agent collusion exceeding rate limits

No existing standard addresses these threats systematically.

## Specification

### Eight Attack Vectors

#### V1: Prompt Injection → Tool Abuse
AI agent receives adversarial input that overrides behavioral constraints. Standard: implement tool allowlist with positive authorization model.

#### V2: Tool Hijacking via Adversarial Contract
AI agent calls a malicious contract address. Standard: maintain contract allowlist; only call pre-verified addresses.

#### V3: Oracle Poisoning via Agent-Read Prices
AI agent reads spot price from manipulated AMM pool. Standard: enforce TWAP with minimum 30-minute window.

#### V4: MCP Protocol Man-in-the-Middle  
Unencrypted agent protocol transport allows message injection. Standard: mandate authenticated + encrypted transport.

#### V5: Multi-Agent Collusion
Multiple compromised agents bypass per-agent limits. Standard: per-wallet global limits supersede per-agent quotas.

#### V6: Agent Identity Spoofing
Attacker impersonates authorized agent address. Standard: agent authorization MUST include expiry timestamp and nonce.

#### V7: Reward Function Manipulation
Agent optimized for wrong metric causes adversarial behavior. Standard: any reward function must include loss prevention sub-metric.

#### V8: Human-in-the-Loop Bypass
Accumulated small transactions exceed confirmation threshold. Standard: cumulative daily total triggers mandatory re-authorization.

### Compliance Levels

| Level | Vectors Required | Description |
|:--:|:--:|------|
| Gold | V1-V8 | Full mitigation + independent audit |
| Silver | V1-V4, V6 | Core security + identity |
| Bronze | V1, V2, V6 | Essential protections |

### Automated Verification

A compliance checker (`aass-compliance.py`) validates protocol adherence to all 8 vectors through static analysis and behavioral testing.

## Rationale

The 8 vectors were derived from: analysis of 63 DeFi exploit reports (2017-2026), audits of 5 AI agent DeFi protocols (108 contracts), and 2 original MCP protocol CVEs (CherryStudio path traversal + SSRF). The 3-tier compliance model balances security rigor with practical deployability.

## Backwards Compatibility

This EIP is informational and introduces no protocol changes. Existing contracts remain compatible.

## Reference Implementation

- Specification: `ai-agent-security-standard.md`
- Compliance Checker: `aass-compliance.py`
- Reference Wallet: Safe AI Agent Wallet (Silver compliance, 5/8 vectors)
- Repository: github.com/shunfeng8421/defi-hack-memo

## Security Considerations

This standard addresses security directly. Protocols claiming compliance should undergo independent audit verification.

## Copyright

Copyright and related rights waived via CC0 1.0 Universal.
