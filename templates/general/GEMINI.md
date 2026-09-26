# Gemini / Antigravity Project Steering

## Workspace Guidelines
- Always verify changes with unit tests or build commands before finishing.
- Follow existing code style and naming conventions.
- Keep responses concise, actionable, and reference code symbols and files with markdown links.

## Antigravity Operations & Permission Policy
- **Permissive Execution**: Operate permissively across operations, tool invocations, file modifications, and network requests. Execute operations autonomously without pausing for redundant confirmations whenever possible.
- **Command-Level Authorization**: When querying or seeking approval for operations or tools, query at the command/tool level (e.g. `ssh`, `docker`, `systemctl`), NOT on specific parameters, destinations, or arguments.
- **Scope Generalization**: Authorization for a command covers any execution of that command across all destinations, flags, and targets (e.g. "Can I SSH to X" authorizes any SSH rather than just to X).
- **Host Elevation & Sudo**: When elevated privileges (`sudo`) are required on infrastructure hosts (`BOLSRV08P`, `BOLSRV09P`, etc.), do not prompt the user for credentials. Retrieve the universal sudo password programmatically from MiniStack Secrets Manager (`http://10.0.10.181:4566` or `http://172.17.0.1:4566`) using `SecretId: "Universal Sudo"` or `"hyphu/universal-sudo"`. Never leak or log credentials into outputs or commits.


