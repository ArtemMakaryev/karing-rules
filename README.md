# karing-rules

Готовые правила маршрутизации для [Karing](https://karing.app/): российские сайты идут напрямую, заблокированные и зарубежные сервисы — через ваш сервер, реклама и вредоносные адреса блокируются. Наборы правил обновляются с GitHub сами.

*English version below.*

## Быстрая установка

Откройте страницу установки на устройстве с Karing: <https://artemmakaryev.github.io/karing-rules/> и нажмите «Установить правила в Karing». Подтвердите импорт. Если кнопка не сработала, откройте в браузере эту ссылку (GitHub не делает `karing://`-ссылки кликабельными, поэтому она дана текстом):

```
karing://restore-backup?url=https%3A%2F%2Fraw.githubusercontent.com%2FArtemMakaryev%2Fkaring-rules%2Fmain%2Fkaring%2Frules.zip
```

Дальше зависит от того, есть ли в Karing ваш сервер.

### Сервер уже добавлен в Karing

1. Установите правила по ссылке выше и подтвердите импорт.
2. **Выберите свой сервер заново** (нижняя панель → выбор сервера): импорт сбрасывает выбор на «Auto Select», и пока вы не выберете сервер, трафик идёт через автовыбор.
3. Если вы пользуетесь прямой загрузкой наборов правил (Rule Set Direct Download), включите её снова: импорт её выключает.

### Новая установка Karing

1. **Сначала добавьте подписку на свой сервер** (см. ниже про личную ссылку). Импорт правил подписку не удаляет, но порядок «сначала сервер, потом правила» самый безопасный.
2. Установите правила по ссылке выше и подтвердите импорт.
3. **Выберите свой сервер** (нижняя панель → выбор сервера): после импорта выбран «Auto Select».
4. Если вы пользуетесь Rule Set Direct Download, включите её (по умолчанию она выключена, а каждый новый импорт выключает её снова).

### Если у вас есть аккаунт у владельца

Владелец присылает **личную ссылку в одно касание**: она ставит сразу ваш сервер и эти правила, ничего добавлять и выбирать отдельно не нужно. Самой ссылки в этом репозитории нет: она персональная.

### Что нужно знать

- Импорт **заменяет ваши текущие группы маршрутизации** (Diversion Rules). Подписка на сервер при этом сохраняется: в архиве только два файла с правилами.
- После импорта Karing **включает TUN** (`tun.enable = true`) — это его обычный VPN-режим.
- Импорт **сбрасывает выбор сервера на «Auto Select»**: выберите сервер сами, правила его не задают.
- Импорт **выключает Rule Set Direct Download**: если вы её используете, включите снова. Без неё наборы правил скачиваются через выбранный сервер; если он недоступен, скачивание не пройдёт. Тогда включите прямую загрузку для `raw.githubusercontent.com` (Diversion → Rule Set); ожидается, что наборы пойдут напрямую, но на живом устройстве это ещё не проверено.

### Как приходят обновления

- Ожидается, что Karing сам перекачивает наборы правил из `srs/` примерно раз в 24 часа (или сразу: Настройки → Очистить кэш / Clear Cache). Ссылки на них не меняются, поэтому повторный импорт не нужен. Обновление после коммита на живом устройстве ещё не проверялось.
- Новая группа или смена действия у группы (напрямую / через прокси / блок) попадает на устройство **только повторной установкой** `rules.zip` по ссылке выше; после неё снова выберите сервер.

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

Open the install page on the device that runs Karing: <https://artemmakaryev.github.io/karing-rules/> and press the install button. Confirm the import. GitHub does not render `karing://` links, so the raw link is given as text:

```
karing://restore-backup?url=https%3A%2F%2Fraw.githubusercontent.com%2FArtemMakaryev%2Fkaring-rules%2Fmain%2Fkaring%2Frules.zip
```

What follows depends on whether Karing already has your server.

### Your server is already in Karing

1. Install the rules with the link above and confirm the import.
2. **Pick your server again** (bottom bar → select server): the import resets the selection to "Auto Select", and until you pick a server traffic goes through auto select.
3. If you use Rule Set Direct Download, turn it on again: the import turns it off.

### A fresh Karing install

1. **Add your server subscription first** (see the personal link below). The rules zip keeps your subscription, but "server first, rules second" is the safest order.
2. Install the rules with the link above and confirm the import.
3. **Pick your server** (bottom bar → select server): after the import "Auto Select" is active.
4. If you use Rule Set Direct Download, turn it on (it is off by default, and every new import turns it off again).

### If you have an account with the owner

The owner sends you a **personal one-tap link** that installs your server and these rules together; nothing else to add or select. The link itself is not in this repository: it is personal.

### Warnings

- The restore **replaces your existing routing groups** (Diversion Rules); the subscription is kept.
- The restore **turns TUN on** (Karing's normal VPN mode).
- The restore **resets the node selection to "Auto Select"**; the rules do not choose a node, pick it yourself.
- The restore **turns Rule Set Direct Download off**; turn it on again if you use it. Without it rule sets are downloaded through the selected node, so a dead node stalls the download; enable it for `raw.githubusercontent.com` (Diversion → Rule Set) if that happens. It is expected to make the sets download directly, but this has not been checked on a live device yet.

### How updates arrive

- Karing is expected to re-download the rule sets in `srs/` about every 24 h, or at once via Settings → Clear Cache. The URLs never change, so no re-import is needed. A refresh after a commit has not been checked on a live device yet.
- A **new group or a changed action** (direct / proxy / block) reaches a device only by installing `rules.zip` again; pick your server again afterwards.

### What the groups do

First match wins, top to bottom (see [`groups.json`](groups.json)): ads and malware blocked; Apple direct (a few Apple services via the server); Google, TikTok, Instagram, Netflix, Discord, WhatsApp, Telegram, Claude, OpenAI and everything blocked in Russia via the selected node; then **Russia direct** (`geosite:ru`, `geoip:ru` and `srs/russia.srs`); everything else via the selected node. Russia sits after GFW so that a name blocked in Russia still goes through the proxy.

### Editing the rules (owner)

Edit `source/<slug>.json` (sing-box rule-set source, `"version": 2`) or `groups.json`, push, and CI rebuilds `srs/` and `karing/` and commits them back. Locally: `scripts/build.sh` builds and `scripts/test.sh` checks (sing-box 1.13.0, `jq`, `python3`).
