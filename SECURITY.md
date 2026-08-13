# Security Policy

RoundForge coordinates multiplayer game state, so server-authority mistakes can become gameplay exploits even when they are not traditional security vulnerabilities.

## Supported versions

RoundForge is currently pre-release. Security fixes are applied to the latest development line.

## Reporting a vulnerability

Please do not publish an exploit or sensitive reproduction in a public issue before the maintainer has had a reasonable chance to investigate it.

Report privately to the repository maintainer through an available private GitHub contact channel. If no private channel is available, open a minimal public issue that states a security-sensitive problem exists without publishing exploit details.

Useful reports include:

- affected component
- impact
- reproduction conditions
- whether a client can forge server state
- whether the issue survives round reset/rejoin
- suggested mitigation if known

## Security model

RoundForge treats clients as untrusted. Clients may request actions, but authoritative decisions such as participant membership, match state, voting results, winners, timers, and eliminations must be validated on the server.
