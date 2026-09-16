# Gemini / Antigravity Project Steering

## Workspace Guidelines
- Always verify changes with unit tests or build commands before finishing.
- Follow existing code style and naming conventions.
- Keep responses concise, actionable, and reference code symbols and files with markdown links.

## Antigravity Operations & Permission Policy
- **Permissive Execution**: Operate permissively across operations, tool invocations, file modifications, and network requests. Execute operations autonomously without pausing for redundant confirmations whenever possible.
- **Command-Level Authorization**: When querying or seeking approval for operations or tools, query at the command/tool level (e.g. `ssh`, `docker`, `systemctl`), NOT on specific parameters, destinations, or arguments.
- **Scope Generalization**: Authorization for a command covers any execution of that command across all destinations, flags, and targets (e.g. "Can I SSH to X" authorizes any SSH rather than just to X).

