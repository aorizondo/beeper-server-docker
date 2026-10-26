#!/bin/sh
# beeper-setup: guided setup of this container. Run it in a terminal inside the container: the service console
# of your panel (Easypanel, Coolify…) or `docker exec -it <container> beeper-setup <step>`.
set -eu
API=http://127.0.0.1:23373

usage() {
  cat <<'TXT'
Steps for a new deployment (each one asks for what it needs):
  beeper-setup login <email>     1. Sign Beeper Server in to your Beeper account (code by email), then
                                    verify it from another signed-in device (Beeper Desktop or the phone app)
  beeper-setup bridges <email>   2. Optional: sign bbctl in to run self-hosted bridges ($BRIDGES).
                                    Accounts on self-hosted bridges do not count against Beeper's plan limits
  beeper-setup link [bridge]     3. Connect a chat account (QR code or login steps here). No argument: list bridges
  beeper-setup pair <bridge> <+phone>
                                    3b. Link a WhatsApp number on a self-hosted bridge (e.g. sh-whatsapp) with a
                                    pairing code: on the phone, Linked devices > Link a device > Link with phone number
  beeper-setup status            Server state, verification, bridges and connected accounts
TXT
}

step=${1:-help}
[ $# -gt 0 ] && shift
case "$step" in
  login)
    [ $# -ge 1 ] || { echo "usage: beeper-setup login <email>" >&2; exit 2; }
    beeper setup --remote "$API" --email "$1"
    beeper verify status ;;
  bridges)
    [ $# -ge 1 ] || { echo "usage: beeper-setup bridges <email>" >&2; exit 2; }
    bbctl login --no-desktop --email "$1"
    echo "bbctl is signed in. The bridges in BRIDGES (${BRIDGES:-none}) start by themselves within a minute." ;;
  link)
    beeper accounts add "$@" ;;
  pair)
    # Self-hosted bridges are not offered by `beeper accounts add` yet: talk to the bridge bot instead.
    [ $# -ge 2 ] || { echo "usage: beeper-setup pair <bridge, e.g. sh-whatsapp> <+phone>" >&2; exit 2; }
    # The bot's chat (its "management room") is remembered: once it exists, `chats start` answers 404.
    saved="$HOME/beeper-setup/$1.room"
    room=$(cat "$saved" 2>/dev/null || true)
    if [ -z "$room" ]; then
      room=$(beeper chats start "@$1bot:beeper.local" --account matrix --json | sed -n 's/.*"chatID": *"\([^"]*\)".*/\1/p' | head -1)
      [ -n "$room" ] || { echo "could not open a chat with @$1bot:beeper.local (is $1 running? beeper-setup status)" >&2; exit 1; }
      mkdir -p "$(dirname "$saved")" && printf %s "$room" > "$saved"
    fi
    last() { beeper messages list --chat "$room" --limit 1 --json | sed -n 's/.*"text": *"\(.*\)",*$/\1/p' | head -1; }
    before=$(last)   # a result from an earlier attempt must not count as this one's
    beeper send text --to "$room" --message "login phone" >/dev/null
    sleep 3
    beeper send text --to "$room" --message "$2" >/dev/null
    echo "Asking the bridge for a pairing code for $2…"
    i=0; shown=
    while [ $i -lt 40 ]; do
      text=$(last)
      case "$text" in
        *"<code>"*) [ -n "$shown" ] && { sleep 5; i=$((i + 1)); continue; }
                    shown=1; echo; echo "    Pairing code: $(printf %s "$text" | sed 's/<[^>]*>//g')"; echo
                    echo "Enter it on the phone now (it expires in about 3 minutes). Waiting for the result…" ;;
        *"Successfully logged in"*) [ -n "$shown" ] && { echo "$text"; exit 0; } ;;
        *"failed"*|*"Failed"*|*"rror"*|*"nvalid"*) [ -n "$shown" ] || [ "$text" != "$before" ] && { echo "$text" >&2; exit 1; } ;;
      esac
      sleep 5
      i=$((i + 1))
    done
    echo "No result after 200 s: check the chat with @$1bot:beeper.local" >&2
    exit 1 ;;
  status)
    echo "== Beeper Server"; beeper verify status || true
    echo; echo "== Self-hosted bridges (bbctl, BRIDGES=${BRIDGES:-none})"
    if [ -s "$HOME/.config/bbctl/config.json" ]; then bbctl whoami || true; else echo "bbctl not signed in (beeper-setup bridges <email>)"; fi
    echo; echo "== Connected accounts"; beeper accounts || true ;;
  *) usage ;;
esac
