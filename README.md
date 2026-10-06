# karing-rules

Готовые правила маршрутизации для [Karing](https://karing.app/): российские сайты идут напрямую, заблокированные и зарубежные сервисы — через ваш сервер, реклама и вредоносные адреса блокируются. Наборы правил обновляются с GitHub сами.

*English version below.*

## Быстрая установка

1. **Сначала добавьте подписку на свой сервер** в Karing (импорт правил её не удаляет, но порядок «сначала сервер, потом правила» самый безопасный).
2. **Откройте страницу установки на устройстве с Karing:** <https://artemmakaryev.github.io/karing-rules/> и нажмите «Установить правила в Karing».
3. Подтвердите импорт в Karing. Если кнопка не сработала, откройте в браузере эту ссылку (GitHub не делает `karing://`-ссылки кликабельными, поэтому она дана текстом):

   ```
   karing://restore-backup?url=https%3A%2F%2Fraw.githubusercontent.com%2FArtemMakaryev%2Fkaring-rules%2Fmain%2Fkaring%2Frules.zip
   ```

### Что нужно знать

- Импорт **заменяет ваши текущие группы маршрутизации** (Diversion Rules). Подписка на сервер при этом сохраняется: в архиве только два файла с правилами.
- После импорта Karing **включает TUN** (`tun.enable = true`) — это его обычный VPN-режим.
- Выбранный узел не задаётся правилами: выберите его в Karing сами.
- Если выбранный узел недоступен, наборы правил не скачиваются: Karing тянет их через выбранный узел. В таком случае включите прямую загрузку наборов (Rule Set Direct Download) для `raw.githubusercontent.com`.

### Как приходят обновления

- Наборы правил из `srs/` Karing перекачивает примерно раз в 24 часа (или сразу: Настройки → Очистить кэш / Clear Cache). Ссылки на них не меняются, поэтому повторный импорт не нужен.
- Новая группа или смена действия у группы (напрямую / через прокси / блок) попадает на устройство **только повторной установкой** `rules.zip` по ссылке выше.

### Что делают группы

Группы проверяются сверху вниз, срабатывает первая подходящая (список — в [`groups.json`](groups.json)).

| Порядок | Группы | Действие |
|---|---|---|
| 1–3 | 🛑 Adblock, 🍃 AdblockPlus, 🛑 malware | блокируются реклама, трекеры, вредоносные и фишинговые адреса |
| 4–7 | 🍏 Apple-Direct, 🧠 Apple-VPS, 🌐 Apps-VPS, 🍎 Apple | сервисы Apple напрямую; часть (музыка, ТВ, геолокация, новости) и некоторые приложения — через сервер |
| 8–17 | Google Gemini, Google, TikTok, Instagram, Netflix, Discord, WhatsApp, Telegram, Claude, OpenAI | через выбранный узел |
| 18 | 🌏 GFW | заблокированное в РФ — через выбранный узел |
| 19 | 🇷🇺 Russia | **напрямую**: `geosite:ru`, `geoip:ru` и `srs/russia.srs` (домены `.ru`, `.рф`, `.su` и российские сервисы вне этих зон) |
| — | всё остальное | через выбранный узел |

🇷🇺 Russia стоит **после** 🌏 GFW: заблокированное в РФ российское имя должно идти через прокси, а не напрямую.

Список российских сервисов вне зон `.ru`/`.рф`/`.su` в `source/russia.json` взят из клиентского шаблона автора (`templates/client/base.json`, правила `local-dns`: `domain_suffix` строки 51–56 и 78–161, `domain_keyword` строки 60–73; личные и корпоративные записи не переносились).

## Как править правила (для владельца)

1. Измените `source/<slug>.json` (формат sing-box rule-set, `"version": 2`) или `groups.json`, сделайте commit и push (подойдёт и веб-редактор GitHub).
2. GitHub Actions пересоберёт `srs/` и `karing/` и закоммитит результат от имени бота.
3. Содержимое групп с файлом в `source/` меняется без повторной установки; новая группа или смена действия требует новой установки `rules.zip`.

Локально: `scripts/build.sh` собирает, `scripts/test.sh` проверяет (нужен sing-box 1.13.0, `jq`, `python3`).

---

# English

Ready-made routing rules for [Karing](https://karing.app/): Russian sites go direct, blocked and foreign services go through your own server, ads and malware are blocked. The rule sets update from GitHub on their own.

## Quick install

1. **Add your server subscription to Karing first.** The rules zip contains only two files and keeps your subscription, but "server first, rules second" is the safest order.
2. **Open the install page on the device that runs Karing:** <https://artemmakaryev.github.io/karing-rules/> and press the install button.
3. Confirm the import in Karing. GitHub does not render `karing://` links, so the raw link is given as text:

   ```
   karing://restore-backup?url=https%3A%2F%2Fraw.githubusercontent.com%2FArtemMakaryev%2Fkaring-rules%2Fmain%2Fkaring%2Frules.zip
   ```

### Warnings

- The restore **replaces your existing routing groups** (Diversion Rules); the subscription is kept.
- The restore **turns TUN on** (Karing's normal VPN mode).
- The selected node is not part of the rules; pick it in Karing yourself.
- Rule sets are downloaded through the selected node, so a dead node stalls refresh; enable Rule Set Direct Download for `raw.githubusercontent.com` if that happens.

### How updates arrive

- Karing re-downloads the rule sets in `srs/` about every 24 h, or at once via Settings → Clear Cache. The URLs never change, so no re-import is needed.
- A **new group or a changed action** (direct / proxy / block) reaches a device only by installing `rules.zip` again.

### What the groups do

First match wins, top to bottom (see [`groups.json`](groups.json)): ads and malware blocked; Apple direct (a few Apple services via the server); Google, TikTok, Instagram, Netflix, Discord, WhatsApp, Telegram, Claude, OpenAI and everything blocked in Russia via the selected node; then **Russia direct** (`geosite:ru`, `geoip:ru` and `srs/russia.srs`); everything else via the selected node. Russia sits after GFW so that a name blocked in Russia still goes through the proxy.

### Editing the rules (owner)

Edit `source/<slug>.json` (sing-box rule-set source, `"version": 2`) or `groups.json`, push, and CI rebuilds `srs/` and `karing/` and commits them back. Locally: `scripts/build.sh` builds and `scripts/test.sh` checks (sing-box 1.13.0, `jq`, `python3`).
