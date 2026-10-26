# Changelog

## 0.1.0 — 2026-10-25

- One image with Beeper Server 4.3.229, bbctl v0.15.0 and Beeper CLI 0.6.2, all pinned and checksum-verified.
- `start.sh` supervises the server and the bridges in `BRIDGES`, restarting each one with backoff.
- `beeper-setup` drives the setup: `login`, `bridges`, `pair` (WhatsApp pairing code via the bridge bot), `link` and `status`.
- Docker Compose file, panel deployment notes, and a GitHub Actions workflow that builds a private GHCR image.
