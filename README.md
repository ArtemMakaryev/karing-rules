# karing-rules

Ready-made routing rules for [Karing](https://karing.app/): Russian sites go direct, blocked and foreign services go through your server, and ads and malicious addresses are blocked. The rule sets update from GitHub on their own.

## Quick install

Open the install page on the device that runs Karing: <https://artemmakaryev.github.io/karing-rules/> (the page is in Russian) and press «Установить правила в Karing» ("Install the rules in Karing"). Confirm the import. If the button did not work, open this link in the browser (GitHub does not make `karing://` links clickable, so it is given as text):

```
karing://restore-backup?url=https%3A%2F%2Fraw.githubusercontent.com%2FArtemMakaryev%2Fkaring-rules%2Fmain%2Fkaring%2Frules.zip
```

What follows depends on whether Karing already has your server.

### The server is already added in Karing

1. Install the rules with the link above and confirm the import.
2. **Select your server again** (bottom bar → server selection): the import resets the selection to "Auto Select", and until you select a server, traffic goes through auto select.
3. If you use direct download of rule sets (Rule Set Direct Download), turn it on again: the import turns it off.

### A new Karing install

1. **First add the subscription to your server** (see the personal link below). Importing the rules does not delete the subscription, but the order "server first, then rules" is the safest.
2. Install the rules with the link above and confirm the import.
3. **Select your server** (bottom bar → server selection): after the import "Auto Select" is selected.
4. If you use Rule Set Direct Download, turn it on (it is off by default, and every new import turns it off again).

### If you have an account with the owner

The owner sends you a **personal one-tap link**: it installs your server and these rules together, and there is nothing to add or select separately. The link itself is not in this repository: it is personal.

### What you need to know

- The import **replaces your current routing groups** (Diversion Rules). The subscription to the server is kept: the archive has only two rule files.
- After the import Karing **turns TUN on** (`tun.enable = true`); this is its usual VPN mode.
- The import **resets the server selection to "Auto Select"**: select the server yourself, the rules do not set it.
- The import **turns off Rule Set Direct Download**: if you use it, turn it on again. Without it, rule sets are downloaded through the selected server; if it is unavailable, the download fails. In that case turn on direct download for `raw.githubusercontent.com` (Diversion → Rule Set); the rule sets are expected to go direct, but this has not been checked on a live device yet.

### How updates arrive

- Karing is expected to re-download the rule sets from `srs/` by itself about once every 24 hours (or at once: Settings → Clear Cache). Their links do not change, so a repeated import is not needed. An update after a commit has not been checked on a live device yet.
- A new group, or a change of a group's action (direct / through the proxy / block), reaches the device **only by installing** `rules.zip` again with the link above; after that, select the server again.

### What the groups do

Groups are checked from top to bottom, and the first match applies (the list is in [`groups.json`](groups.json)).

| Order | Groups | Action |
|---|---|---|
| 1–3 | 🛑 Adblock, 🍃 AdblockPlus, 🛑 malware | ads, trackers, and malicious and phishing addresses are blocked |
| 4–7 | 🍏 Apple-Direct, 🧠 Apple-VPS, 🌐 Apps-VPS, 🍎 Apple | Apple services go direct; some (music, TV, geolocation, news) and some apps go through the server |
| 8–17 | Google Gemini, Google, TikTok, Instagram, Netflix, Discord, WhatsApp, Telegram, Claude, OpenAI | through the selected node |
| 18 | 🌏 GFW | what is blocked in Russia: through the selected node |
| 19 | 🇷🇺 Russia | **direct**: `geosite:ru`, `geoip:ru` and `srs/russia.srs` (domains in `.ru`, `.рф`, `.su` and Russian services outside these zones) |
| — | everything else | through the selected node |

🇷🇺 Russia comes **after** 🌏 GFW: a Russian name that is blocked in Russia must go through the proxy, not direct.

The list of Russian services outside the `.ru`/`.рф`/`.su` zones in `source/russia.json` is taken from the author's client template (`templates/client/base.json`, the `local-dns` rules: `domain_suffix` lines 51–56 and 78–161, `domain_keyword` lines 60–73; personal and corporate entries were not carried over).

## How to edit the rules (for the owner)

1. Change `source/<slug>.json` (sing-box rule-set format, `"version": 2`) or `groups.json`, then commit and push (the GitHub web editor works too).
2. GitHub Actions rebuilds `srs/` and `karing/` and commits the result as the bot.
3. The contents of groups that have a file in `source/` change without a new install; a new group or a change of action requires a new install of `rules.zip`.

Locally: `scripts/build.sh` builds, `scripts/test.sh` checks (needs sing-box 1.13.0, `jq`, `python3`).
