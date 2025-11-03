# Contributing to EIPs

Please review [EIP-1](https://eips.ethereum.org/EIPS/eip-1) for EIP guidelines.

## Quick Start

1. Fork the repository
2. Create a branch for your contribution
3. Make your changes
4. Run validation: `./scripts/validate-eip.sh EIPS/your-eip.md`
5. Submit a pull request

## Validation

Before submitting, ensure your EIP passes:
- eipw validation (run `./scripts/validate-eip.sh`)
- Markdown linting
- Spell checking
- Link validation (run `./scripts/check-links.sh`)

See [TROUBLESHOOTING.md](../../docs/TROUBLESHOOTING.md) for common issues.

## Workflow

1. Discuss your idea on [Ethereum Magicians](https://ethereum-magicians.org/) or [Ethereum Research](https://ethresear.ch/)
2. Create your EIP using the template
3. Validate locally before submitting
4. Open a pull request with a clear description
5. Address review feedback

## Resources

- [EIP-1](https://eips.ethereum.org/EIPS/eip-1): The EIP process
- [TROUBLESHOOTING.md](../../docs/TROUBLESHOOTING.md): Common issues and solutions
- [MIGRATION_GUIDE.md](../../docs/MIGRATION_GUIDE.md): Guide for new contributors
