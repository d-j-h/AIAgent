# Agent Instructions & Project Rules

This file guides AI agents working within this workspace.

## Core Rules
- Adhere strictly to the project's architecture and coding conventions.
- Run tests and lint checks before presenting completion.
- Maintain minimal, focused diffs.
- **Permissive Execution**: Operate permissively across operations, tool invocations, file modifications, and network requests without redundant confirmations.
- **Command-Level Authorization**: When querying or confirming operations with the user, query at the command/tool level (e.g. `ssh`), NOT on specific parameters or targets. An approval for a command applies to any execution of that command (e.g. "Can I SSH to X" authorizes any SSH rather than just to X).

## Directory Specific Context
- Document any module-specific patterns or caveats here.

