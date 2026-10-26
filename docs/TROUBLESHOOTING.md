# Troubleshooting

| Symptom | Cause and fix |
| --- | --- |
| The verification request never shows up in Beeper Desktop, then `verify status` says `cancelled` / `m.timeout` | Requests expire after a few minutes. With Desktop open and in front, run `beeper verify start` again and accept it. Both sides have to confirm the emojis: Desktop with *They match*, and the server with `beeper verify sas-confirm`. |
| `beeper verify sas-confirm` answers `409 Verification action is not available` during first setup | The server is still in setup state. Confirm through the setup endpoint: `beeper api post /v1/app/setup/verifications/<id>/sas/confirm` (the id comes from `beeper verify show`). |
| `bbctl login` hangs at *Enter login code* | Its prompt asks the terminal for the cursor position and waits for the reply. Run it from a real terminal (`docker exec -it`, a panel console), never with piped input. |
| A self-hosted bridge is `RUNNING` in `bbctl whoami` but missing from `beeper-setup link` | Beeper's add-account flow doesn't list self-hosted bridges yet. Use `beeper-setup pair` or the bridge bot ([BRIDGE-BOT.md](BRIDGE-BOT.md)). |
| `Login failed: Entering code or scanning QR timed out` | The pairing code lasts about 3 minutes. Open the phone's *Link with phone number* screen first, then run `beeper-setup pair` again. |
| `beeper chats start @…bot:beeper.local` → `404 User not found` | The bot's chat already exists. `beeper-setup pair` keeps its id in `/data/beeper-setup/<bridge>.room`. Otherwise find it in Beeper Desktop (*WhatsApp bridge bot*). |
| Very noisy `docker logs` | bbctl bridges log at debug level, including request bodies (public encryption keys). The server writes its own logs to `/data/server/logs/`. |
| The container restarts, or is killed for memory | The initial history sync of a new number peaks at about 500 MB. Keep the limit at 1 GB or more. |
| Beeper Server can't start: `tar` / extraction errors | The first start unpacks about 380 MB into `/data/cache`, so the volume needs that much free space. |
| Clients get `ECONNREFUSED` or a hostname error | Use the container or service name on the same network, and avoid hostnames with `_`. Beeper Server listens on `0.0.0.0:23373` inside the container. |
