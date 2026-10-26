# Using it from agents and apps

Everything is served by Beeper Server on port **23373**. Clients on the same private network use
`http://<host>:23373`. Every endpoint except `/v1/info` and the OAuth endpoints needs
`Authorization: Bearer <token>`.

## The token

- **Full access token:** `beeper-setup login` stores one in `/data/.beeper/targets/desktop.json`
  (field `accessToken`). It can read and send in every chat. Treat it like a password.
- **Limited token (better):** for other apps, create one through Beeper's OAuth flow (`/oauth/*`, see
  the [Beeper Desktop API docs](https://developers.beeper.com)), so each client gets only what it needs.

## MCP (`/v0/mcp`, streamable HTTP)

| Tools |
| --- |
| `search`, `search_chats`, `get_chat`, `list_messages`, `search_messages`, `get_accounts`, `search_docs` |
| `send_message`, `archive_chat`, `set_chat_reminder`, `clear_chat_reminder`, `focus_app` |

OpenCode example (remote MCP server):

```jsonc
"mcp": { "servers": { "beeper": {
  "type": "remote",
  "url": "http://beeper:23373/v0/mcp",
  "headers": { "Authorization": "Bearer {env:BEEPER_ACCESS_TOKEN}" },
  "oauth": false
} } }
```

Put an **approval rule** on `send_message`: it sends from your real accounts.

## Client API (`/v1`)

The same API as Beeper Desktop: accounts, chats, messages, send, bridges, login sessions. The CLI in
the image is a full client for it:
- `beeper chats list`
- `beeper messages list --chat <id>`
- `beeper send text --to <id> --message …`
- `beeper api get /v1/...`

## Live events (`/v1/ws`)

A WebSocket that pushes `chat.upserted`, `chat.deleted`, `message.upserted` and `message.deleted`.
Subscribe after connecting with `{"type":"subscriptions.set","requestID":"1","chatIDs":["*"]}`.

- **Quick check:** `beeper watch --include-type message.upserted --json`.
- **Forward to a webhook:** `beeper watch --include-type message.upserted --webhook https://… --webhook-secret …`
  posts each event, for example to n8n.
- **Your own messages** come with `isSender: true`. Drop them before waking anyone.

## Waking an agent (opencode-apex)

[opencode-apex](https://github.com/aorizondo/opencode-apex) wakes an OpenCode agent when an outside
program calls its `events.ingest` RPC.

A small relay next to OpenCode:
1. holds the WebSocket open;
2. normalizes each `message.upserted` into `{source: "beeper", type: "message.received", eventID, payload}`;
3. calls `events.ingest`;
4. an apex subscription that filters on the chat id delivers the task to the agent.

The relay design, in any language: the `apex-callbacks` skill shipped with opencode-apex, in its
`references/relays.md`.

Both connections are outbound from the relay: OpenCode and the relay can run anywhere that can reach
port 23373.
