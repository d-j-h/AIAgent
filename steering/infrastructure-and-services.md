---
inclusion: always
description: Infrastructure context, host services, and bot runtime configurations
---

# Infrastructure & Services Knowledge

## Host Environment & MiniStack
- **Primary Host**: `BOLSRV09P`
  - Host LAN IP: `10.0.10.181` (Note: formerly `10.0.10.161`; dynamically assigned/managed).
  - MiniStack endpoint: `http://172.17.0.1:4566` (LocalStack / AWS mock API for ECS, RDS, S3).
  - ECS Cluster: `hyphu-development`
  - Container Scratch Volume: `/var/lib/ministack/scratch`

## Matrix & Synapse Architecture
- **Homeserver**: Synapse (`happyloaf.com`)
  - Runs in container `matrix-hh-synapse-1` on network `matrix-hh_matrix`.
  - Exposed on host port **`8018`** (`0.0.0.0:8018`).
  - Reachable from containers via host IP `http://10.0.10.181:8018` or Docker default bridge gateway `http://172.17.0.1:8018`.
- **Matrix Bots**:
  - **HyphuBot** (`matrix-ai-bot`):
    - User ID: `@hyphubot:happyloaf.com`
    - Container: `matrix-ai-bot` (bridge network)
    - Source / Mounts:
      - `/var/lib/ministack/scratch/matrix/bot` -> `/bot` (contains `.env` configs and `bot_state.json`)
      - `/var/lib/ministack/scratch/matrix/hyphu-repo` -> `/repo` (synced Hyphu repository)
    - Runtime: `python3 -m bot.main`
    - Config file: `/bot/ai.env` (`MATRIX_HOMESERVER=http://10.0.10.181:8018`)
  - **GitHub Reporter** (`matrix-github-reporter`):
    - User ID: `@githubbot:happyloaf.com`
    - Container: `matrix-github-reporter` (bridge network)
    - Mounts: `/var/lib/ministack/scratch/matrix/bot` -> `/bot`
    - Runtime: `python3 -m bot.github_reporter`
    - Config file: `/bot/github.env` (`MATRIX_HOMESERVER=http://10.0.10.181:8018`)
  - **Duplicati Bot** (`matrix-duplicati-bot`):
    - User ID: `@duplicatibot:happyloaf.com`
    - Deployed as an ECS task on MiniStack (`hyphu-development` cluster) with host networking.
    - Config: `/home/coder/.gemini/antigravity/scratch/matrix-duplicati-bot/config.yaml` (`homeserver_url: http://10.0.10.181:8018`).

## Troubleshooting Matrix Bot Connectivity
1. **Symptom**: HyphuBot or GitHub Reporter not responding to messages or commands in Element/Matrix.
2. **Diagnosis**:
   - Inspect container logs via Docker socket for `Connect call failed ('<IP>', 8018)` or `[Errno 113] Host is unreachable`.
   - Verify active host IP (`ip route` / `ip addr` / `10.0.10.181`) and test `/_matrix/client/versions` against port `8018`.
3. **Resolution**:
   - Update `MATRIX_HOMESERVER` in `/var/lib/ministack/scratch/matrix/bot/ai.env` and `/var/lib/ministack/scratch/matrix/bot/github.env`.
   - Recreate the containers with the updated `MATRIX_HOMESERVER` env var (preserving persistent volume mounts).
   - Check logs to ensure `Loaded state` and `Starting Matrix sync loop` appear without connection errors, and verify the `since` token in `bot_state.json` advances.
