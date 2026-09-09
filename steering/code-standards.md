---
inclusion: always
description: Universal coding standards, error handling, typing, and testing rules
---

# Code Standards & Quality Guidelines

## Purpose
Establishes baseline coding, style, typing, and testing practices across supported languages.

## 1. Type Safety & Clarity
- **Static Typing**: Where supported (TypeScript, Python typing/mypy, Go, Rust), all public interfaces, function parameters, and return values MUST be explicitly typed.
- **Avoid `any`**: Avoid escape hatches (such as `any` in TypeScript or `# type: ignore` in Python) unless strictly necessary with a documented explanation.
- **Descriptive Naming**: Variables, functions, and types MUST have clear, intent-revealing names. Avoid single-letter variables except for standard loop indices.

## 2. Error Handling
- **Explicit Failure Handling**: Never silently catch and discard exceptions or errors (e.g., empty `catch` blocks or `except: pass`).
- **Fail Fast**: Validate inputs and invariants at function boundaries early.
- **Contextual Errors**: Wrap errors with relevant context before bubbling them up.

## 3. Testing Standards
- **Unit Testing**: Every new feature, utility, or bug fix SHOULD be accompanied by corresponding unit tests.
- **Deterministic Tests**: Tests MUST NOT depend on external network services, unpredictable timeframes, or non-deterministic state unless specifically tagged as integration/e2e tests.
- **Regression Tests**: When fixing a bug, write a failing test first that reproduces the bug, then apply the fix.

## 4. Git & Commit Standards
- **Commit Messages**: Follow Conventional Commits format (`feat:`, `fix:`, `refactor:`, `docs:`, `chore:`, `test:`).
- **Atomic Commits**: Keep commits small and logically separated.
- **Signed Commits**: Enable GPG/SSH commit signing wherever required by team policies.
