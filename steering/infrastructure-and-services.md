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
  - Project directory: `/var/lib/ministack/scratch/matrix-happyloaf`
  - Runs in container `matrix-hh-synapse-1` on network `matrix-happyloaf_default`.
  - Exposed on host port **`8018`** (`0.0.0.0:8018`), federation on **`8458`** (`0.0.0.0:8458`).
  - Reachable from containers via host IP `http://10.0.10.181:8018` or Docker default bridge gateway `http://172.17.0.1:8018`.
- **Application Services & Bridges**:
  - **IRC Bridge (`heisenbridge`)**:
    - Container: `matrix-hh-heisenbridge-1` (`hif1/heisenbridge:latest`).
    - Port: `9898` (connected to `http://synapse:8008`).
    - Config: `/var/lib/ministack/scratch/matrix-happyloaf/heisenbridge/registration.yaml`.
    - User namespace: `@irc_.*:happyloaf.com`.
  - **XMPP Bridge (`matrix-bifrost`) & Server (`prosody`)**:
    - Bifrost container: `matrix-hh-matrix-bifrost-1` (`matrixdotorg/matrix-bifrost:latest`).
    - Prosody container: `matrix-hh-prosody-1` (`prosody/prosody:latest`) acting as the XMPP server with an external component listener on port `5347`.
    - Bifrost appservice port: `5000`, media proxy port: `11111`.
    - Config: `/var/lib/ministack/scratch/matrix-happyloaf/matrix-bifrost/config.yaml`, `registration.yaml`, and `signingkey.jwk` (HS512).
    - Database: PostgreSQL database `bifrost` on `matrix-hh-postgres-1`.
    - User namespace: `@_bifrost_.*:happyloaf.com`, room alias namespace: `#bifrost_.*:happyloaf.com`.
  - **Mautrix Bridges**:
    - Slack (`matrix-hh-mautrix-slack-1`), Discord (`matrix-hh-mautrix-discord-1`), Signal (`matrix-hh-mautrix-signal-1`), WhatsApp (`matrix-hh-mautrix-whatsapp-1`).
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

## Internal DNS & NetBox IPAM Architecture
- **BIND9 Authoritative Nameserver (`bind-primary`)**:
  - Container: `bind-primary` listening on `0.0.0.0:53` on host `BOLSRV09P` (`10.0.10.181`).
  - Authoritative for: `hadho.me`, `srv.hadho.me`, `lan.hadho.me`, `hyphu.hadho.me`, `iot.hadho.me`, `10.0.10.in-addr.arpa`.
  - Authoritative NS records: `ns1.hadho.me` (`10.0.10.181`), `ns2.hadho.me` (`10.0.10.205`).
  - Zone files directory: `/var/lib/ministack/netbox/dns/zones/` (mounted ro in `bind-primary`).
- **NetBox IPAM & Sync Scripts (`/var/lib/ministack/netbox/scripts/`)**:
  - NetBox runs locally on `http://127.0.0.1:8000/api`.
  - NetBox record ID=30: `10.0.10.181/24` with `dns_name: bolsrv09p.srv`.
  - `netbox-dns-sync.py`: Generates zone files from NetBox IPAM and reloads BIND. Runs every 5 min via `happyloaf` user crontab.
  - `netbox-dhcp-sync.py`: Syncs DHCP leases from OPNsense router (`10.0.10.1`) into NetBox IPAM. Runs every 5 min via crontab.
- **Gatus Status Monitoring (`/gatus`)**:
  - Container: `/gatus` (`twinproduction/gatus:latest`) on bridge network, exposing port 18080.
  - Mounts: `/var/lib/ministack/monitoring/config.yaml:/config/config.yaml:ro` and `/var/lib/ministack/monitoring:/data`.
  - Monitored MiniStack endpoints: `http://BOLSRV09P.srv.hadho.me:4566` (API and S3) and `http://BOLSRV09P.srv.hadho.me:8080/api/health` (stackport).
  - Note: Bridge network containers do not resolve internal BIND zones via DHCP nameservers; `/gatus` container requires `ExtraHosts: ["BOLSRV09P.srv.hadho.me:10.0.10.181", "bolsrv09p.srv.hadho.me:10.0.10.181"]` configured in `HostConfig`.

## Central Secrets Store (AWS Secrets Manager & StackPort)
- **Secrets Management UI**: `https://secrets.hadho.me/`
  - Routes via Cloudflare -> Edge Caddy (`10.0.10.205`) -> Authelia SSO (`sec.hadho.me`) -> StackPort upstream (`10.0.10.181:8080`).
  - Underlying container: `/stackport` (`davireis/stackport:latest`) on host `BOLSRV09P`.
  - Config mount: `/var/lib/ministack/stackport/endpoints.json` (mounted to `/data/endpoints.json` in container).
  - Configured endpoint: `bolsrv09p` -> `http://10.0.10.181:4566` (active & default).
  - Required container `HostConfig`: `ExtraHosts: ["bolsrv09p.srv.hadho.me:10.0.10.181", "BOLSRV09P.srv.hadho.me:10.0.10.181"]`.
- **Secrets Manager API Endpoints**:
  - From Docker containers (default bridge gateway): `http://172.17.0.1:4566`
  - From Host / LAN: `http://10.0.10.181:4566`
  - Region: `us-east-1`
- **Naming Convention & Secret Hierarchy**:
  - Standard prefix: `hyphu/<service>` or `hyphu/<domain>/<service>`.
  - Multi-attribute credentials must be stored as JSON strings containing key-value pairs.
- **Active Secrets Inventory**:
  - `hyphu/openrouter`: OpenRouter API key for LLM integrations.
  - `hyphu/netbox`: NetBox superuser API token, secret key, DB credentials.
  - `hyphu/duplicati`: Duplicati web/API management credentials.
  - `hyphu/matrix/ai-bot`: Matrix user password (`@hyphubot:happyloaf.com`) & OpenRouter API key.
  - `hyphu/matrix/github-bot`: Matrix user password (`@githubbot:happyloaf.com`) & GitHub personal access token.
  - `hyphu/monitoring`: Gatus tokens (GitHub token, Home Assistant token, Ntfy token).
  - `hyphu/development/recovery`: Dev recovery tokens.
- **Programmatic Secret Access Pattern (Python / boto3)**:
  ```python
  import json, os, boto3

  # In containers where ECS metadata credential env vars are injected, unset them or supply dummy creds
  os.environ.pop("AWS_CONTAINER_CREDENTIALS_RELATIVE_URI", None)
  os.environ.pop("AWS_CONTAINER_CREDENTIALS_FULL_URI", None)

  sm = boto3.client(
      "secretsmanager",
      endpoint_url="http://172.17.0.1:4566",
      region_name="us-east-1",
      aws_access_key_id="test",
      aws_secret_access_key="test",
  )

  secret = json.loads(sm.get_secret_value(SecretId="hyphu/<service>")["SecretString"])
  ```


