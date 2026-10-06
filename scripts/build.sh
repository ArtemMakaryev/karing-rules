#!/bin/sh
# Build srs/*.srs and karing/* from source/*.json and groups.json.
# usage: scripts/build.sh [out-root]   (default: the repository root)
# SING_BOX overrides the binary; it must be exactly 1.13.0 (see AGENTS.md).
set -eu

ROOT=$(cd "$(dirname "$0")/.." && pwd)
OUT=${1:-$ROOT}
SING_BOX=${SING_BOX:-sing-box}
WANT_VERSION=1.13.0
MAX_SRS_BYTES=3145728

have=$("$SING_BOX" version | sed -n '1s/^sing-box version //p')
[ "$have" = "$WANT_VERSION" ] || { echo "build: sing-box $WANT_VERSION required, found '$have'" >&2; exit 1; }

# groups.json and source/ must agree on which groups carry a repo-owned rule set.
want=$(jq -r '.[] | select(.srs == true) | .slug' "$ROOT/groups.json" | sort)
have_src=$(cd "$ROOT/source" && ls *.json | sed 's/\.json$//' | sort)
[ "$want" = "$have_src" ] || { echo "build: groups.json srs:true slugs differ from source/*.json" >&2; echo "$want" >&2; echo "--" >&2; echo "$have_src" >&2; exit 1; }

mkdir -p "$OUT/srs" "$OUT/karing"
rm -f "$OUT"/srs/*.srs

for src in "$ROOT"/source/*.json; do
  slug=$(basename "$src" .json)
  dst="$OUT/srs/$slug.srs"
  "$SING_BOX" rule-set compile "$src" -o "$dst"
  magic=$(head -c 4 "$dst" | od -An -tx1 | tr -d ' \n')
  case "$magic" in
    53525301|53525302) ;;
    *) echo "build: $slug.srs has header $magic, want 53525301 or 53525302" >&2; exit 1 ;;
  esac
  size=$(wc -c < "$dst" | tr -d ' ')
  [ "$size" -lt "$MAX_SRS_BYTES" ] || { echo "build: $slug.srs is $size bytes, limit $MAX_SRS_BYTES" >&2; exit 1; }
done

python3 "$ROOT/scripts/gen_karing.py" "$ROOT" "$OUT"
echo "build: ok ($(ls "$OUT"/srs/*.srs | wc -l | tr -d ' ') rule sets, karing/rules.zip)"
