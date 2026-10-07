# AGENTS.md

Public repository: Karing routing rules shared with every user. `groups.json` is the one source of truth for the shared groups, in match order; `source/<slug>.json` are sing-box rule-set sources (`"version": 2`); CI and `scripts/build.sh` compile them to `srs/*.srs` and generate `karing/rules.zip` (two files only) and `karing/preset.json`. The install page `docs/index.html` is hand-written and served by GitHub Pages from `main:/docs`; the build does not generate it.

- Build: `scripts/build.sh` (outputs into the repo; `scripts/build.sh <dir>` into another directory). Test: `scripts/test.sh` (offline; compares a fresh build with the committed outputs).
- sing-box is pinned to **1.13.0** (the CI tarball is checked by sha256). Do not use `sing-box run`.
- Never add personal matchers: the forbidden list lives in `scripts/test.sh`, and the test fails when one appears anywhere in the repo.
- No secrets: this repository is public. No UUID, key, short id, token, subscription URL, personal IP or personal domain.
- Group actions are only `block`, `direct`, `currentSelected`. A group with `"srs": true` needs `source/<slug>.json`.
- Commit format: `<subject> (Refs ArtemMakaryev/focus-vpn#170)`.
- Documentation is in English; the one exception is the install site `docs/index.html` (https://artemmakaryev.github.io/karing-rules/), which stays Russian for its users (the owner, 2026-10-07, focus-agents#652).
