# Shared VPS infrastructure

This repository owns the shared nginx ingress, certificates integration and panel runtime. The lisw.top repository owns Vue/Go source, application tests, database migrations and precompiled release delivery. Changes to public routes, TLS, ports and proxy headers are reviewed here; applications do not rewrite nginx configuration.

| Entry | Owner / upstream |
| --- | --- |
| TCP 443, https://lisw.top | nginx → panel:8081 |
| TCP 8080 | existing Hysteria masquerade site |
| loopback TCP 9443 | existing Xray fallback site |
| UDP 4433 | Hysteria2, unchanged |
| TCP 8443 | Xray VLESS, unchanged |
| loopback TCP 18081 | panel health / local administration |

`nginx/templates/default.conf.template` retains the camouflage sites. `panel.conf.template` adds the panel virtual host. Keep these independently editable fragments together here. A future service adds its own fragment rather than modifying another service's server block.

## Panel runtime

Build only on GitHub Actions or a development machine. The application installer verifies a release, applies ledger-backed migrations, switches `/opt/lisw-panel/current`, and calls `scripts/restart-panel.sh`. Docker recreates the read-only bind mount to follow the new release. It does not compile code. On failure the application installer restores the previous release and recreates the container.

Prerequisites: `/opt/lisw-panel/current` is a verified linux-amd64 release; `/etc/lisw-panel/database.json` is a root-only secret; `${CERT_PATH}/live/${DOMAIN}` contains the existing certificate and key. Do not commit credentials or private keys. Initial transition from the previous systemd runtime requires `systemctl disable --now lisw-panel` before starting the container on loopback port 18081.

Panel runs with no Linux capabilities, a read-only filesystem, 96 MiB memory and 0.30 CPU limit. Its dedicated network uses 172.29.44.0/24; nginx alone receives the trusted address 172.29.44.2. Check for subnet conflicts before moving to another host. This allows per-client login throttling without trusting public forwarding headers. Secure cookies are mandatory in this runtime.

After changing ingress: validate with `docker compose config -q` and the workflow's nginx configuration check, then update nginx only. Application-only deployments recreate panel only and do not restart proxy services. Keep the former systemd unit disabled after transition.

## Certificates

Reuse the existing acme.sh certificate for lisw.top; do not issue a second certificate for panel. Mount the whole certificate directory so renewed files remain visible. Register the absolute `scripts/reload-certificates.sh` path as the acme.sh install certificate reload command. It validates/reloads nginx and restarts Hysteria to load renewed certificates. No port or credential changes are necessary.
