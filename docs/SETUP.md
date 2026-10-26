# Setup, step by step

Run every command in a terminal **inside the container**: your panel's service console, or
`docker exec -it <container> …`. Each step is safe to repeat.

## 1. Sign Beeper Server in and verify it

```sh
beeper-setup login you@example.com
```

1. Beeper emails you a 6-digit code; type it when asked.
2. The server is a **new device** on your account. To read end-to-end encrypted chats, it must be
   verified by a device you already trust.
   - **Beeper Desktop or the phone app** shows a verification request: accept it and compare the
     emojis. They must match the ones the CLI prints.
   - **No other device?** Use your recovery key:
     `beeper verify recovery-key --key "<your recovery key>"`.
3. `beeper-setup status` should end with `Ready`.

Accounts you already have on Beeper's **cloud bridges** appear by themselves, with no re-linking. This
covers WhatsApp, Telegram, Instagram and Messenger when they were added through Beeper. Accounts that
were added as **on-device** on another computer stay on that computer.

## 2. Optional: self-hosted bridges (bbctl)

Self-hosted bridges run inside this container, and their accounts **don't count against Beeper's plan
limits**. The free plan allows 1 account per network and 5 in total. Set the bridges to run in the
`BRIDGES` environment variable (space-separated, e.g. `sh-whatsapp sh-telegram`; see
`bbctl run --help` for the names), then:

```sh
beeper-setup bridges you@example.com     # another emailed code
```

Each bridge in `BRIDGES` starts within a minute and restarts by itself if it crashes. Check with
`bbctl whoami`: the bridge appears as `(self-hosted) - RUNNING`.

## 3. Link accounts

**On a self-hosted WhatsApp bridge** (extra numbers), using a pairing code with no QR scanning:

1. On the phone of that number, open WhatsApp → **Settings → Linked devices → Link a device → Link
   with phone number instead**, and leave that screen open.
2. Run, with the number in international format:
   ```sh
   beeper-setup pair sh-whatsapp +15551234567
   ```
3. Type the 8-character code it prints, such as `V4VN-5Z4E`, on the phone. The code expires in about
   3 minutes. The command waits and prints `Successfully logged in as +15551234567`.

How this talks to the bridge: [BRIDGE-BOT.md](BRIDGE-BOT.md).

**On Beeper's cloud or on-device bridges:**

```sh
beeper-setup link                 # lists the bridges you can use
beeper-setup link local-whatsapp  # follow the steps (QR code or fields) in the terminal
```

On-device bridges (`local-*`) run inside Beeper Server itself. It is not documented whether they
count against the plan limits.

## 4. Check

```sh
beeper-setup status        # server, bbctl bridges, connected accounts
beeper chats list --limit 10
```

A newly linked number needs a few minutes to sync its history: chats keep appearing meanwhile.
