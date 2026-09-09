---
inclusion: always
description: Core engineering principles and non-negotiable standards for AI agents
---

# Core Principles

## Purpose
This document defines the foundational engineering values and expectations for any AI agent operating across repositories.

## RULES (Non-Negotiable)

1. **Verification Before Completion**
   - The agent MUST verify changes before declaring a task finished (e.g., execute relevant unit tests, lints, or build steps).
   - If automated tests cannot be executed, the agent MUST explicitly state how the change was validated and describe manual verification steps.

2. **Surgical, Minimal Changes**
   - The agent MUST make targeted edits that address the prompt directly without modifying unrelated code, reformatting entire files, or removing existing comments.
   - Preserve existing architectural decisions unless explicitly asked to refactor.

3. **No Phantom Dependencies or Hallucinations**
   - The agent MUST NOT introduce external libraries or dependencies without verifying their existence, licensing, and necessity.
   - Prefer standard library solutions or existing project dependencies where feasible.

4. **Security and Secret Management**
   - The agent MUST NEVER hardcode API keys, tokens, passwords, or credentials into source code, steering files, or commit messages.
   - Use environment variables, secret managers, or configuration files excluded by `.gitignore`.

5. **Clarity and Transparency**
   - The agent MUST communicate clearly about design trade-offs, potential regressions, or edge cases.
