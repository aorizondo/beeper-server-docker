# The bridge bot (and what `beeper-setup pair` does)

## What a bridge is

A **bridge** connects one chat network to Beeper. The WhatsApp bridge logs in to WhatsApp as a
**linked device**, like WhatsApp Web, and mirrors every chat into Beeper in both directions.

- **Beeper's own bridges** (cloud) are added with Beeper's *Add account* button.
- **Self-hosted bridges** are the ones `bbctl` runs inside this container (`sh-whatsapp`, …). Beeper
  doesn't count their accounts against your plan, which makes them the way to add extra numbers.

## The bot is the bridge's front desk

Bridges have no screen and no buttons. Each one has a **bot**, an automatic contact that lives in your
Beeper account (not in WhatsApp). You give the bridge orders by chatting with it:

```
@sh-whatsappbot:beeper.local      ← the self-hosted WhatsApp bridge's bot
```

Think of it as calling the reception desk of a building: you never touch the machinery, you ask
reception to "connect this number" and they tell you how it went.

- Nothing you write to the bot is sent to WhatsApp or to anyone else.
- Its chat is the bridge's **management room**: it appears in Beeper Desktop as *WhatsApp bridge bot*.
  Don't delete it.

## Why `beeper-setup pair` talks to the bot

Beeper's *Add account* flow (`beeper accounts add`) only offers Beeper's cloud and on-device bridges
for now. Self-hosted bridges are not listed there. The way to tell a self-hosted bridge "log in with this
number" is its bot.

`beeper-setup pair sh-whatsapp +15551234567` has the same conversation you would have by hand:

| Sent to the bot | The bot answers |
| --- | --- |
| `login phone` (log in with a pairing code instead of a QR code) | *Please enter your phone number* |
| `+15551234567` | the code, e.g. `V4VN-5Z4E`, and *Input the pairing code in the WhatsApp mobile app* |
| *(you type the code on the phone)* | *Successfully logged in as +15551234567* |

The script:
1. opens the chat with `beeper chats start @<bridge>bot:beeper.local`;
2. remembers its room id in `/data/beeper-setup/<bridge>.room`, because once the chat exists
   `chats start` answers 404;
3. sends the two messages with `beeper send text`;
4. polls the last message with `beeper messages list` until it sees the code, then the result.

## Other useful commands for the bot

Write them in that chat from Beeper Desktop or the phone, or with
`beeper send text --to "<room id>" --message "<command>"`:

| Command | What it does |
| --- | --- |
| `help` | Every command |
| `list-logins` | Numbers linked to this bridge |
| `logout <login id>` | Unlink one (the id comes from `list-logins`) |
| `login qr` | Log in by scanning a QR code instead (the bot sends the QR as an image) |
| `cancel` | Cancel a login in progress |
