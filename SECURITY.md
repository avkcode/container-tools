# Security Policy

## Supported Versions

We aim to support:
- The latest released minor series (X.Y.x)
- The immediate previous minor series

Security fixes may be backported when feasible. Otherwise, fixes land in the latest release.

## Reporting a Vulnerability

Please do not open a public issue for security reports.

Use GitHub’s private security advisories:
- Navigate to the repository’s “Security” tab
- Click “Report a vulnerability” and follow the prompt

Provide:
- A clear description of the issue and impact
- Steps to reproduce or a proof of concept
- Affected versions/targets, if known
- Any suggested mitigations

We will acknowledge receipt, investigate, and coordinate disclosure and fixes.

## Supply Chain and Scanning

- Trivy scanning is integrated but optional; builds will proceed when Trivy is absent.
- Signing is supported via cosign (images/artifacts) and GPG (tarballs).
- We prefer signed commits and signed tags for traceability.

## Hardening and Best Practices

- Minimal rootfs, no unnecessary packages
- Avoid apt-key; prefer signed-by keyrings
- Clean apt caches in the same layer
- Avoid leaking secrets (no secrets via CLI/env where possible)
