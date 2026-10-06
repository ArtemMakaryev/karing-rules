#!/bin/sh
# Offline checks: the committed srs/ and karing/ are current, and the repo is public-safe.
# usage: scripts/test.sh   (needs sing-box 1.13.0, jq, python3)
set -eu

ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
fails=0
fail() { echo "FAIL: $*" >&2; fails=$((fails + 1)); }
ok() { echo "ok:   $*"; }
check() { # check <description> <command...>
  desc=$1; shift
  if "$@" >/dev/null 2>&1; then ok "$desc"; else fail "$desc"; fi
}

RAW=https://raw.githubusercontent.com/ArtemMakaryev/karing-rules/main
ZIP_URL=$RAW/karing/rules.zip
ENC_URL=https%3A%2F%2Fraw.githubusercontent.com%2FArtemMakaryev%2Fkaring-rules%2Fmain%2Fkaring%2Frules.zip
DEEP_LINK="karing://restore-backup?url=$ENC_URL"

# 1. JSON parses
for f in groups.json source/*.json karing/*.json; do
  check "parses: $f" jq -e . "$f"
done

# 2. the committed outputs are what the build produces
"$ROOT/scripts/build.sh" "$TMP/out" >"$TMP/build.log" 2>&1 || { cat "$TMP/build.log" >&2; fail "build.sh into a temp dir"; }
check "srs/ equals a fresh build byte for byte" diff -r "$TMP/out/srs" srs
check "karing/ equals a fresh build byte for byte" diff -r "$TMP/out/karing" karing

# 3. rules.zip lists exactly the two files
zip_names=$(python3 -I -c 'import sys, zipfile; print(" ".join(sorted(zipfile.ZipFile(sys.argv[1]).namelist())))' karing/rules.zip)
[ "$zip_names" = "karing_routing_group.json karing_subscribe_use.json" ] && ok "rules.zip lists exactly the two files" || fail "rules.zip lists '$zip_names'"
python3 -I - <<'PY' && ok "rules.zip contents equal karing/*.json" || fail "rules.zip contents differ from karing/*.json"
import zipfile
z = zipfile.ZipFile("karing/rules.zip")
assert z.testzip() is None
for n in z.namelist():
    assert z.read(n) == open("karing/" + n, "rb").read(), n
PY

# 4. group names and order equal groups.json
jq -r '.[].name' groups.json >"$TMP/want.names"
jq -r '.items[0].groups[].name' karing/karing_routing_group.json >"$TMP/routing.names"
jq -r '.diversion_group[] | select(.diversion_groupid == "custom") | .diversion_name' karing/karing_subscribe_use.json >"$TMP/use.names"
check "routing group names and order equal groups.json" cmp "$TMP/want.names" "$TMP/routing.names"
check "diversion_group names and order equal groups.json" cmp "$TMP/want.names" "$TMP/use.names"
check "the first three groups are block" jq -e '[.[0:3][].action] == ["block","block","block"]' groups.json
check "Russia comes after GFW" jq -e '([.[].slug] | index("russia")) > ([.[].slug] | index("gfw"))' groups.json
check "Russia is the last group (before the fall-through)" jq -e '.[-1].slug == "russia"' groups.json
check "the fall-through is the last diversion_group entry, currentSelected" \
  jq -e '.diversion_group[-1] | .diversion_groupid == "final" and .server_groupid == "currentSelected"' karing/karing_subscribe_use.json
check "slugs are unique" jq -e '([.[].slug] | length) == ([.[].slug] | unique | length)' groups.json

# 5. actions
check "groups.json actions are block|direct|currentSelected" jq -e 'all(.[]; .action | IN("block","direct","currentSelected"))' groups.json
check "diversion_group actions are block|direct|currentSelected" \
  jq -e 'all(.diversion_group[]; .server_groupid | IN("block","direct","currentSelected"))' karing/karing_subscribe_use.json
check "preset.json outbounds are block|direct|currentSelected" jq -e 'all(.rules[]; .outbound | IN("block","direct","currentSelected"))' karing/preset.json
check "routing has no Android package matcher" jq -e 'all(.items[0].groups[]; has("package") | not)' karing/karing_routing_group.json

# 6. rule sets: every URL has its file, every source is registered, every srs has a source
jq -r '.items[0].groups[].rule_set[]?' karing/karing_routing_group.json | sort -u >"$TMP/urls"
missing=0
while IFS= read -r url; do
  case "$url" in
    "$RAW"/srs/*.srs) [ -f "srs/${url#"$RAW"/srs/}" ] || { echo "no file for $url" >&2; missing=1; } ;;
    *) echo "unexpected rule_set URL $url" >&2; missing=1 ;;
  esac
done <"$TMP/urls"
[ "$missing" = 0 ] && ok "every rule_set URL has its file under srs/" || fail "a rule_set URL has no file under srs/"
jq -r '.rule_set_items[].url' karing/karing_routing_group.json | sort >"$TMP/items"
check "rule_set_items equal the group URLs, no duplicates" cmp "$TMP/urls" "$TMP/items"
check "rule_set_items are remote binary with tag == url" \
  jq -e 'all(.rule_set_items[]; .type == "remote" and .format == "binary" and .tag == .url)' karing/karing_routing_group.json
check "every source is version 2" sh -c 'for f in source/*.json; do jq -e ".version == 2" "$f" >/dev/null || exit 1; done'
for f in srs/*.srs; do
  slug=$(basename "$f" .srs)
  [ -f "source/$slug.json" ] || fail "srs/$slug.srs has no source"
done
check "the subscription file carries no nodes" jq -e '.recent == [] and .select_default == ""' karing/karing_subscribe_use.json

# 7. install page, README, workflow
check "docs/index.html has the karing:// link" grep -qF "$DEEP_LINK" docs/index.html
check "docs/index.html has no script, no external src/href" sh -c '! grep -qiE "<script|src=\"?http|<link[^>]*href=\"?http|<iframe" docs/index.html'
check "README has the karing:// link" grep -qF "$DEEP_LINK" README.md
check "README links the install page" grep -qF "https://artemmakaryev.github.io/karing-rules/" README.md
check "workflow actions are pinned by full commit SHA" sh -c '! grep -E "^[[:space:]-]*uses:" .github/workflows/build.yml | grep -vqE "@[0-9a-f]{40}([[:space:]]|$)"'
check "workflow pins the sing-box tarball by sha256" sh -c 'grep -qE "SING_BOX_SHA256: *[0-9a-f]{64}" .github/workflows/build.yml'

# 8. nothing personal, no secrets (the lists are this test's own; it is excluded from the scan)
PERSONAL='tailnet|orca|corp-rt|apps-direct|100\.111\.|192\.168\.31\.|rt\.ru|rostelecom|ktalk|trueconf|bybit|okx|makaryev\.com'
UUID='[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}'
if grep -rIniE "$PERSONAL" . --exclude-dir=.git --exclude=test.sh >"$TMP/personal" 2>&1; then
  cat "$TMP/personal" >&2; fail "a personal matcher is in the repository"
else ok "no personal matcher outside test.sh"; fi
if grep -rIniE "$UUID" . --exclude-dir=.git >"$TMP/uuid" 2>&1; then
  cat "$TMP/uuid" >&2; fail "a UUID is in the repository"
else ok "no UUID anywhere"; fi
# the compiled outputs hold only what the sources hold, so scan the zip text too
python3 -I - "$PERSONAL" <<'PY' && ok "no personal matcher inside rules.zip" || fail "a personal matcher is inside rules.zip"
import re, sys, zipfile
z = zipfile.ZipFile("karing/rules.zip")
bad = [n for n in z.namelist() if re.search(sys.argv[1], z.read(n).decode(), re.I)]
sys.exit(1 if bad else 0)
PY

if [ "$fails" -ne 0 ]; then echo "test: $fails check(s) failed" >&2; exit 1; fi
echo "test: all checks passed"
