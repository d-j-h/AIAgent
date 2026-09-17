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
  - `hyphu/cloudflare`: Cloudflare API token and `hadho.me` zone ID for automated DNS-01 ACME challenge resolution and DNS management.
  - `maid2clean`: Maid2Clean cleaner portal credentials (`PORTAL_USERNAME`, `PORTAL_PASSWORD`) & webhook/poll settings.
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

## CloudWatch Monitoring & Alarms (MiniStack & Gatus Integration)
- **Monitoring Web UI**: `https://secrets.hadho.me/resources/monitoring`
  - StackPort exposes the CloudWatch `monitoring` service console displaying all active Metric Alarms, states (`OK`, `ALARM`, `INSUFFICIENT_DATA`), and Dashboards.
- **Bridge Service (`gatus-cloudwatch-bridge`)**:
  - Runs as an ECS task in cluster `hyphu-development` on MiniStack (`taskDefinition: gatus-cloudwatch-bridge:1`).
  - Source directory: `/home/coder/.gemini/antigravity/scratch/gatus-cloudwatch-bridge/` (mounted to `/app` in container).
  - Polls Gatus API (`http://172.17.0.1:18080/api/v1/endpoints/statuses`) every 30 seconds.
- **CloudWatch Metric Architecture**:
  - **Namespace**: `Gatus`
  - **Metrics**:
    - `UptimeStatus`: 1.0 (UP / healthy) or 0.0 (DOWN / failed).
    - `LatencyMs`: Endpoint response time in milliseconds.
    - `HTTPStatus`: Target HTTP response code (e.g. 200, 401, 502).
  - **Dimensions**: `Endpoint`, `Group` (e.g. `ministack`, `previews`).
- **Metric Alarms**:
  - Naming convention: `Gatus-{group}-{endpoint}-Health`.
  - Trigger condition: `UptimeStatus < 1.0` for 1 evaluation period (60s).
  - Alarm state is synchronized dynamically in real-time, providing immediate visual feedback in the StackPort Monitoring UI and alerting on service degradation.
- **Dashboards**:
  - `Gatus-Overview`: Preconfigured CloudWatch dashboard tracking core infrastructure availability and latency metrics.

## CloudWatch Logs Ingestion & Container Shipping (`cloudwatch-log-shipper`)
- **Logs Web UI**: `https://secrets.hadho.me/resources/logs`
  - StackPort provides a full CloudWatch Logs browser with real-time log event streaming, timestamp filtering, and text/regex search across all groups and streams.
- **Log Shipper Service (`cloudwatch-log-shipper`)**:
  - Runs as an ECS task on MiniStack (`cluster: hyphu-development`, `taskDefinition: cloudwatch-log-shipper:1`).
  - Source directory: `/home/coder/.gemini/antigravity/scratch/cloudwatch-log-shipper/`.
  - Mounts `/var/run/docker.sock` to tail stdout/stderr from all running Docker containers.
- **Log Group Hierarchy**:
  - Docker Containers: `/docker/{container_name}` (e.g. `/docker/matrix-ai-bot`, `/docker/gatus`, `/docker/stackport`, `/docker/bind-primary`, `/docker/ministack`, etc.).
  - System Logs: `/system/{service_name}` (e.g. `/system/netbox-dns-sync`, `/system/netbox-dhcp-sync`).
  - Custom Ingestion: Arbitrary custom namespaces (e.g. `/custom/{app}`).
- **HTTP Ingestion API (Port 8090)**:
  - Accessible locally from containers at `http://172.17.0.1:8090` and from host/LAN at `http://10.0.10.181:8090`.
  - Health check: `GET http://10.0.10.181:8090/health`
  - Single log ingestion:
    ```bash
    curl -X POST http://10.0.10.181:8090/log \
      -H "Content-Type: application/json" \
      -d '{"group": "/my-app", "stream": "node-1", "message": "Transaction processed"}'
    ```
  - Batch log ingestion:
    ```bash
    curl -X POST http://10.0.10.181:8090/logs \
      -H "Content-Type: application/json" \
      -d '{"group": "/my-app", "stream": "node-1", "events": [{"timestamp": 1789127000000, "message": "event 1"}]}'
    ```
- **Caddy Edge Proxy Log Streaming**:
  - Edge Caddy on `BOLVM01P` (`10.0.10.205`) streams JSON access and operational logs over TCP to `10.0.10.181:8092`.
  - Configured via Caddy Admin API (`http://10.0.10.205:2019`):
    - Logger: `logging.logs.caddy_edge` (`writer: {output: "net", address: "10.0.10.181:8092"}`).
    - Server access logger: `apps.http.servers.srv0.logs.default_logger_name: "caddy_edge"`.
  - Log Groups:
    - `/caddy/access`: Streams segregated by requested hostname (e.g. `secrets.hadho.me`, `dev.hadho.me`, `sec.hadho.me`, preview hosts).
    - `/caddy/server`: Stream `caddy-edge` for operational, TLS, and reverse proxy events.
  - **Dynamic Secrets Ingestion**:
    - Pre-launch fetcher `/data/docker/caddy/fetch-secrets.sh` (mode `0700`) retrieves `hyphu/cloudflare` from MiniStack Secrets Manager (`http://10.0.10.181:4566`).
    - Writes `CLOUDFLARE_API_TOKEN` and `CLOUDFLARE_ZONE_ID` to runtime file `/data/docker/caddy/.env.secrets` (mode `0600`).
    - Consumed by `docker-compose.yml` via `services.caddy.env_file: [ .env.secrets ]`, eliminating plaintext credentials from compose manifests.

## Plane Project & Documentation Management (`doc.hadho.me`)
- **Web UI & Ingress**: `https://doc.hadho.me/`
  - Ingress route: Cloudflare -> Edge Caddy (`10.0.10.205`) -> Authelia SSO (`sec.hadho.me`) -> Plane upstream (`http://BOLSRV09P.srv.hadho.me:8095`).
  - Auth policy: Web UI protected by Authelia SSO (`sec.hadho.me`); API requests with `X-Api-Key` or `Authorization` headers bypass Authelia forward-auth.
- **Runtime & Deployment Architecture**:
  - Primary host: `BOLSRV09P` (`10.0.10.181`).
  - Orchestration: MiniStack ECS cluster `plane-cluster` (task definition `plane-app`).
  - Container: `makeplane/plane-aio-community:v1.4.2` (`plane-aio`), exposing port `80` mapped to host port **`8095`**.
- **Supporting Infrastructure & Persistence**:
  - Base directory: `/var/lib/ministack/plane` (on 3.6 TB persistent XFS volume).
  - Infrastructure compose stack: `/var/lib/ministack/plane/docker-compose.infra.yml`:
    - **PostgreSQL 15**: Container `plane-db` on `172.17.0.1:15433` (mount: `/var/lib/ministack/plane/data/postgres`).
    - **Valkey / Redis 7.2**: Container `plane-redis` on `172.17.0.1:6380` (mount: `/var/lib/ministack/plane/data/redis`).
    - **RabbitMQ 3.13**: Container `plane-mq` on `172.17.0.1:5673` (mount: `/var/lib/ministack/plane/data/rabbitmq`).
    - **MinIO Object Storage**: Container `plane-minio` on `172.17.0.1:9002` (mount: `/var/lib/ministack/plane/data/minio`, bucket: `plane-uploads`).
- **Secrets & Configuration**:
  - Infrastructure secrets: Stored in `/var/lib/ministack/plane/.env.infra` (`chmod 600`).
  - Edge TLS & DNS: Managed automatically by Edge Caddy with Cloudflare credentials fetched from MiniStack Secrets Manager (`hyphu/cloudflare`).

## Maid2Clean Job Watcher (`maid2clean-watcher`)
- **Web UI & Endpoints**:
  - Web UI: `http://10.0.10.181:8091/` (port `8090` mapped to host port `8091`).
  - Home Assistant Webhook Target: `http://10.0.10.112:8123/api/webhook/maid2clean_jobs`.
- **Runtime & Deployment Architecture**:
  - Primary host: `BOLSRV09P` (`10.0.10.181`).
  - Orchestration: MiniStack ECS cluster `Maid2Clean` (service `maid2clean-watcher`, task definition `maid2clean-watcher:2`).
  - Container Image: `127.0.0.1:4566/maid2clean:latest` (built on Debian Bookworm).
  - Source Repository: `/home/coder/git/maid2clean-watcher` (remote `git@github.com:d-j-h/maid2clean-watcher.git`).
- **Persistence & Configuration**:
  - State volume: `/var/lib/ministack/scratch/maid2clean/session` -> `/app/session` (persists `seen_jobs.json`, `pending_webhooks.json`, `.session.env`).
  - Secrets Management: Credentials dynamically fetched by `auth.py` from MiniStack AWS Secrets Manager (`maid2clean`), ensuring no plaintext credentials in git or manifests.



