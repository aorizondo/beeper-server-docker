# beeper-server-docker

Run **Beeper Server** — the headless edition of [Beeper](https://www.beeper.com) — 24/7 in **one
container**, together with **bbctl** self-hosted bridges and the **Beeper CLI**. It gives AI agents and
automations a single API, MCP server and event stream for all your chats (WhatsApp, Telegram, Signal,
Instagram, Messenger…). Beeper Desktop does not need to be open, and you don't run Matrix servers or
databases.

```
            Beeper cloud (your account, homeserver, cloud bridges)
                ▲                         ▲
   outbound     │                         │  outbound
┌───────────────┴─────────────────────────┴──────────────┐
│ container                                              │
│  beeper-server   ← client: sees every account, E2EE    │
│  bbctl bridges   ← e.g. sh-whatsapp: extra numbers     │
│  beeper CLI      ← beeper-setup: login, verify, link   │
└───────────────┬────────────────────────────────────────┘
                │ :23373  Client API /v1 · MCP /v0/mcp · events /v1/ws
        your agent / app (same private network)
```

| Inside the image | What it does |
| --- | --- |
| `beeper-server` | Beeper client without a UI. It sees every account in your Beeper account and exposes the Client API (`/v1`), an MCP server (`/v0/mcp`) and a WebSocket of events (`/v1/ws`) on port 23373. |
| `bbctl` | Runs the **self-hosted bridges** listed in `BRIDGES`, for example `sh-whatsapp`. Per Beeper, *"accounts bridged with self-hosting are free and do not count against your account limits"*: use them for extra numbers. |
| `beeper` (CLI) | Login, device verification, account linking and status, wrapped by `beeper-setup`. |

Beeper Server and the bridges both connect **out** to Beeper. The container needs no inbound port,
domain or TLS certificate to work.

## Requirements

- A Beeper account, and another device already signed in to it (Beeper Desktop or the phone app), to
  verify the new device.
- An x86_64 Linux host with Docker. Plan for 0.5–1 GB of RAM: measured at about 200 MB idle, 360 MB
  with five accounts, and peaks of about 500 MB while a new account syncs its history.

## Quick start (Docker Compose)

```sh
git clone https://github.com/aorizondo/beeper-server-docker && cd beeper-server-docker
docker compose up -d --build
docker exec -it beeper beeper-setup login you@example.com      # code by email, then verify the device
docker exec -it beeper beeper-setup status
```

Accounts already connected to your Beeper account through Beeper's cloud bridges show up by
themselves. Optional:

```sh
docker exec -it beeper beeper-setup bridges you@example.com              # sign bbctl in; BRIDGES start by themselves
docker exec -it beeper beeper-setup pair sh-whatsapp +15551234567        # link a number with a pairing code
docker exec -it beeper beeper-setup link                                 # cloud/on-device bridges (QR or login steps)
```

Step-by-step guide with what each step shows: [docs/SETUP.md](docs/SETUP.md).

## Deploy on a panel (Easypanel, Coolify, Dokploy…)

1. **Source:** an app from this Git repository (`main`, `Dockerfile`), or the image you build from it.
2. **Volume:** one at `/data`. It holds everything: the server database and encryption keys, and the
   CLI and bbctl logins.
3. **Environment:** `BRIDGES=sh-whatsapp`, or leave it empty.
4. **Resources:** a memory limit of 1 GB, and an init process if the panel offers one (Easypanel: *tini*).
5. **No domain and no published port.** Other services on the panel's network reach it as
   `http://<service-host>:23373`. Hostnames with `_` are rejected by some HTTP clients, so prefer the
   alias with `-`.
6. Open the service's **console** and run `beeper-setup login you@example.com` and the other steps.

## `beeper-setup`

| Command | Step |
| --- | --- |
| `beeper-setup login <email>` | 1. Sign Beeper Server in (emailed code) and verify it as a trusted device (emoji comparison) |
| `beeper-setup bridges <email>` | 2. Sign bbctl in; the bridges in `BRIDGES` start within a minute |
| `beeper-setup pair <bridge> <+phone>` | 3. Link a WhatsApp number on a self-hosted bridge with a pairing code ([how it works](docs/BRIDGE-BOT.md)) |
| `beeper-setup link [bridge]` | 3. Link an account on a cloud or on-device bridge (QR or login steps in the terminal) |
| `beeper-setup status` | Server state, verification, bridges and connected accounts |

## Using it from agents and apps

[docs/USING.md](docs/USING.md) covers:
- MCP tools (search, list and send messages…);
- the Client API;
- live events (`message.upserted`);
- forwarding events to webhooks with `beeper watch --webhook`;
- waking an [opencode-apex](https://github.com/aorizondo/opencode-apex) agent with a relay.

## Security and terms

- **Whoever has the API token can read and send in all your chats.** Keep port 23373 on a private
  network. Never put it behind a public domain without an extra auth layer.
- `/data` holds your encryption keys and logins: back it up and protect it like a password store.
- Beeper's terms: personal use. Automating at scale can get accounts suspended, and WhatsApp's own
  terms apply to bridged numbers.
- Beeper Server is not documented on developers.beeper.com yet: its behaviour may change between versions.

## Updating

Versions and checksums are pinned in the `ARG`s of the [Dockerfile](Dockerfile). The comment above
each one says where to read the new values. Rebuild, and the volume keeps every login.

## Image

GitHub Actions builds `ghcr.io/aorizondo/beeper-server`. It is **private**: Beeper Server, bbctl and
the CLI are Beeper's software, so this repository ships only the recipe that downloads and verifies them.
Build your own image from this repo, or fork it and let the workflow publish to your account.

## Troubleshooting

[docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md): verification that never shows up, bbctl login
hanging, self-hosted bridges missing from `accounts add`, pairing codes expiring, noisy logs.

## License

The files in this repository are under the [MIT license](LICENSE). Beeper Server, bbctl, the Beeper CLI
and the bridges they download are covered by their own licenses and terms.
