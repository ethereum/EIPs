# Troubleshooting Guide for EIPs

This guide covers common issues encountered when working with EIPs and their solutions.

## Validation Issues

### Missing Required Fields

**Error**: `Missing required field: author`

**Solution**: Ensure all required preamble fields are present:
- `eip`
- `title`
- `description`
- `author`
- `discussions-to`
- `status`
- `type`
- `created`

### Invalid Date Format

**Error**: `Invalid date format: 2024/01/15`

**Solution**: Dates must be in ISO 8601 format (yyyy-mm-dd). Use `2024-01-15` instead of `2024/01/15`.

### Invalid EIP References

**Error**: `proposals must be referenced with the form EIP-N`

**Solution**: Always use the form `EIP-N` (not `EIPN` or `EIP N`) when referencing EIPs in your document.

### Invalid Links

**Error**: `Link validation failed: broken-link.md`

**Solution**: 
- External links must be absolute URLs (https://...)
- Relative links must point to valid files in the repository
- Check that all file paths are correct

## Installation Issues

### eipw Not Found

**Error**: `command not found: eipw`

**Solution**:
1. Install Rust and Cargo if not already installed
2. Install eipw: `cargo install eipw`
3. Add `~/.cargo/bin` to your PATH environment variable

### Ruby Version Issues

**Error**: `undefined method 'exists' for File:Class`

**Solution**: Use Ruby 3.1.4 exactly. Later versions are not supported. Use a version manager like rbenv or rvm.

### Jekyll Build Failures

**Error**: `Jekyll build failed`

**Solution**:
1. Ensure you're using Ruby 3.1.4
2. Run `bundle install` to install dependencies
3. Clear Jekyll cache: `bundle exec jekyll clean`
4. Try building again: `bundle exec jekyll build`

## Common Markdown Issues

### Invalid Section Order

**Error**: `Section 'Rationale' appears before 'Specification'`

**Solution**: Sections must appear in this order:
1. Abstract
2. Motivation (optional)
3. Specification
4. Rationale
5. Backwards Compatibility (optional)
6. Test Cases (optional)
7. Reference Implementation (optional)
8. Security Considerations
9. Copyright

### Title Length Issues

**Error**: `Title exceeds 44 characters`

**Solution**: Keep the title under 44 characters and avoid repeating the EIP number.

### Invalid Author Format

**Error**: `Invalid author format`

**Solution**: Use one of these formats:
- `FirstName LastName (@GitHubUsername)`
- `FirstName LastName <email@example.com>`
- `FirstName (@GitHubUsername) and SecondName (@GitHubUsername)`

## Submission Issues

### PR Fails CI Checks

**Error**: Various CI check failures

**Solution**:
1. Run `eipw` locally before submitting
2. Check spelling: add words to `.codespell-whitelist` if needed
3. Ensure markdown linting passes
4. Verify all links are valid

### EIP Number Assignment

**Question**: How do I get an EIP number?

**Solution**: EIP numbers are assigned by editors when your PR is merged. Use `eip-draft_<short-title>.md` as the filename initially.

## Getting Help

If you encounter issues not covered here:
1. Check [EIP-1](https://eips.ethereum.org/EIPS/eip-1) for the full process
2. Ask on [Ethereum Magicians](https://ethereum-magicians.org/)
3. Open an issue in the repository
4. Contact EIP editors

