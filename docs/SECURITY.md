# Security baseline

- TLS for all public portal traffic and approved CWMP transport.
- NBI, GenieACS UI, MongoDB and MariaDB remain private and firewall-restricted.
- Secrets are injected through protected environment/configuration outside Git.
- Password hashing uses a modern password-hashing algorithm supported by the chosen Go stack.
- RBAC is enforced in backend middleware and service methods, not only in frontend navigation.
- Tenant context is resolved server-side; fail closed on missing or ambiguous tenant.
- Apply rate limits, request size limits, timeouts and input validation.
- Redact credentials, device parameter secrets, personal data and payment details from logs.
- Audit login, tenant membership changes, device enrollment, remote actions, billing changes and privileged access.
- Protect against SSRF: no user-controlled NBI endpoint, webhook validation and outbound allowlisting.
- Use CSRF protection for cookie-authenticated browser operations and secure cookie settings.
- API keys are stored as hashes and shown only once.
- Backups are encrypted, access-controlled and restore-tested.
- Dependencies and CI workflows are pinned/reviewed; no secrets in CI logs.

## Required release gates
Cross-tenant authorization tests, authentication tests, secret scanning, dependency review, migration review and a documented rollback plan must pass before any production release.
