---
name: ai-agent-steering
description: >-
  Provides access to the team's centralized AI steering guidelines, coding standards,
  and behavioral directives from the AIAgent repository. Use to review active steering
  rules, enforce project conventions, or pull updates from github.com/d-j-h/AIAgent.
---

# AI Agent Steering Guidelines & Procedures

This skill integrates the team's official steering rules and conventions into all AI agent workflows.

## Core Rules & Guardrails
When developing, refactoring, or reviewing code:
1. **Verification First**: Always run automated tests, linting, or build checks before marking a task complete.
2. **Surgical Diffs**: Modify only lines directly relevant to the user request. Do not reformat unrelated files or remove existing docstrings/comments.
3. **No Phantom Packages**: Never introduce third-party libraries without checking project dependencies and licenses.
4. **Zero Hardcoded Secrets**: Ensure keys, tokens, and credentials are never placed in code or commits.

## Steering Document Index
Refer to these steering files for specific domains:
- **Core Principles**: [`~/git/AIAgent/steering/core-principles.md`](file:///home/coder/git/AIAgent/steering/core-principles.md)
- **Code Standards & Commits**: [`~/git/AIAgent/steering/code-standards.md`](file:///home/coder/git/AIAgent/steering/code-standards.md)
- **Agent Behavior**: [`~/git/AIAgent/steering/agent-behavior.md`](file:///home/coder/git/AIAgent/steering/agent-behavior.md)
- **Architecture & Security**: [`~/git/AIAgent/steering/architecture-and-security.md`](file:///home/coder/git/AIAgent/steering/architecture-and-security.md)
- **Infrastructure & Services**: [`~/git/AIAgent/steering/infrastructure-and-services.md`](file:///home/coder/git/AIAgent/steering/infrastructure-and-services.md)

## Updating Steering Rules
To pull the latest steering changes and re-link configurations:
```bash
~/git/AIAgent/scripts/sync-and-update.sh
```
