#!/bin/sh
# Runs Beeper Server and the self-hosted bridges listed in $BRIDGES (e.g. "sh-whatsapp sh-telegram"),
# restarting each one when it exits. Bridges wait until `bbctl login` has been done once.
set -u
mkdir -p /data/server /data/cache

supervise() {   # supervise <name> <command...>: run forever, backoff 2 s → 60 s, reset after a minute up
  name=$1; shift; delay=2
  while :; do
    started=$(date +%s)
    "$@"
    code=$?
    [ $(( $(date +%s) - started )) -gt 60 ] && delay=2
    echo "[$name] exited with $code; restarting in ${delay}s" >&2
    sleep "$delay"
    [ "$delay" -lt 60 ] && delay=$((delay * 2))
  done
}

supervise server beeper-server --host=0.0.0.0 --port=23373 --data-dir=/data/server &

for bridge in ${BRIDGES:-}; do
  (
    until [ -s /data/.config/bbctl/config.json ]; do
      echo "[$bridge] waiting for bbctl to be signed in: run 'beeper-setup bridges <email>' in this container" >&2
      sleep 60
    done
    supervise "$bridge" bbctl run "$bridge"
  ) &
done

wait
