# Migration Guide for New EIPs

This guide helps new contributors create their first EIP.

## Step-by-Step Process

### 1. Discuss Your Idea

Before writing an EIP, discuss your idea:
- [Ethereum Magicians](https://ethereum-magicians.org/)
- [Ethereum Research](https://ethresear.ch/)

This ensures your proposal is well-thought-out and addresses real needs.

### 2. Read EIP-1

Thoroughly read [EIP-1](https://eips.ethereum.org/EIPS/eip-1) to understand:
- The EIP process
- Required sections
- Validation requirements
- Status progression

### 3. Create Your EIP

1. Copy `eip-template.md`
2. Rename to `eip-draft_your-title.md` (e.g., `eip-draft_simple-ssz-container.md`)
3. Fill in all required fields in the preamble
4. Complete all required sections:
   - Abstract
   - Specification
   - Rationale
   - Security Considerations
   - Copyright

### 4. Validate Locally

Before submitting, validate your EIP:

```sh
# Validate single file
./scripts/validate-eip.sh EIPS/eip-draft_your-title.md

# Validate all files
./scripts/validate-eip.sh
```

### 5. Submit Pull Request

1. Push your branch to your fork
2. Open a pull request to the repository
3. Include a clear description of your EIP
4. Wait for editor feedback

### 6. EIP Number Assignment

- An EIP number will be assigned by editors when your PR is merged
- The filename will be updated from `eip-draft_*` to `eip-####.md`

## Common Mistakes to Avoid

- ❌ Don't use "EIP N" in the title
- ❌ Don't forget required sections
- ❌ Don't skip security considerations
- ❌ Don't use external links for assets (save as PDFs in assets folder)
- ❌ Don't submit without validating first

## Resources

- [EIP-1](https://eips.ethereum.org/EIPS/eip-1): The EIP process
- [TROUBLESHOOTING.md](./TROUBLESHOOTING.md): Common issues and solutions
- [CONTRIBUTING.md](../.github/CONTRIBUTING.md): Contributing guidelines

## Next Steps

After your EIP is merged:
1. Participate in discussions on Ethereum Magicians
2. Address feedback and concerns
3. Work towards Review status
4. Eventually aim for Final status

