---
inclusion: always
description: System architecture guidelines and security requirements
---

# Architecture & Security Guidelines

## Purpose
Guarantees architectural cohesion, modularity, and strict adherence to security best practices.

## 1. Architectural Patterns
- **Separation of Concerns**: Decouple domain logic from I/O, UI, and external third-party SDKs.
- **Dependency Inversion**: Rely on abstractions/interfaces rather than concrete implementations for external dependencies.
- **Single Source of Truth**: Avoid duplicate state management across application layers.

## 2. Security Guardrails
- **Input Sanitization**: Treat all external inputs (HTTP requests, file inputs, environment variables) as untrusted. Validate schemas rigorously.
- **Principle of Least Privilege**: Run processes, containers, and services with the minimal permissions necessary.
- **Safe Command Execution**: Prevent shell injection by avoiding string concatenation for shell commands; use argument arrays and proper escaping.
- **Dependency Auditing**: Keep dependencies current, verify checksums/lockfiles, and address security advisories promptly.
- **Centralized Secrets Management**:
  - MiniStack AWS Secrets Manager (`http://172.17.0.1:4566` / `https://secrets.hadho.me/`) is the canonical secrets store for the entire infrastructure.
  - Plaintext credentials must never be committed to source repositories, dotfiles, or unencrypted persistent files.
  - All bot tokens, API keys, database credentials, and service passwords must be synced to and retrieved from AWS Secrets Manager under the `hyphu/<service>` namespace.

