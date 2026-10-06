#!/usr/bin/env python3
"""Generate karing/*.json and the deterministic karing/rules.zip from groups.json.

usage: gen_karing.py <repo-root> <out-root>
Reads <repo-root>/groups.json; writes <out-root>/karing/{karing_routing_group.json,
karing_subscribe_use.json,preset.json,rules.zip}. Standard library only.
"""
import json
import os
import sys
import zipfile

RAW = "https://raw.githubusercontent.com/ArtemMakaryev/karing-rules/main"
ACTIONS = {
    "block": ("block", "block_out"),
    "direct": ("direct", "direct_out"),
    "currentSelected": ("currentSelected", ""),
}


def dump(obj):
    return json.dumps(obj, ensure_ascii=False, indent=2) + "\n"


def main():
    root, out = sys.argv[1], sys.argv[2]
    groups = json.load(open(os.path.join(root, "groups.json"), encoding="utf-8"))

    items, diversion, preset, urls = [], [], [], []
    for g in groups:
        if g["action"] not in ACTIONS:
            sys.exit("bad action %r in %s" % (g["action"], g["name"]))
        url = "%s/srs/%s.srs" % (RAW, g["slug"]) if g.get("srs") else None
        item = {"groupid": "custom", "name": g["name"], "type": "", "or": True}
        for key in ("domain_suffix", "ip_cidr", "rule_set_build_in"):
            if g.get(key):
                item[key] = g[key]
        if url:
            item["rule_set"] = [url]
            if url not in urls:
                urls.append(url)
        items.append(item)
        sid, sname = ACTIONS[g["action"]]
        diversion.append({
            "diversion_groupid": "custom",
            "diversion_name": g["name"],
            "server_groupid": sid,
            "server_name": sname,
            "dns_servers": [],
        })
        p = {"name": g["name"], "outbound": g["action"], "switch": True, "or": True}
        p.update({k: v for k, v in item.items() if k in ("rule_set", "rule_set_build_in", "domain_suffix", "ip_cidr")})
        preset.append(p)
    diversion.append({
        "diversion_groupid": "final",
        "diversion_name": "",
        "server_groupid": "currentSelected",
        "server_name": "",
        "dns_servers": [],
    })

    routing = {
        "items": [{"groupid": "custom", "urlOrPath": "", "remark": "Custom", "editAble": True, "groups": items}],
        "rule_set_items": [{"type": "remote", "tag": u, "format": "binary", "url": u} for u in urls],
    }
    # No nodes, no secrets: only the diversion actions; the user's subscription stays (facts Q4).
    use = {
        "disable": [],
        "select_default": "",
        "recent": [],
        "fav": [],
        "geosite": [],
        "geoip": [],
        "acl": [],
        "ruleset_direct_download": [],
        "server_select_search_select": [],
        "add_profile_select": [],
        "diversion_group": diversion,
    }

    kdir = os.path.join(out, "karing")
    os.makedirs(kdir, exist_ok=True)
    files = {
        "karing_routing_group.json": dump(routing),
        "karing_subscribe_use.json": dump(use),
    }
    for name, text in files.items():
        with open(os.path.join(kdir, name), "w", encoding="utf-8") as f:
            f.write(text)
    with open(os.path.join(kdir, "preset.json"), "w", encoding="utf-8") as f:
        f.write(dump({"rules": preset}))

    # Stored (not deflated) with fixed mtime: the bytes do not depend on the zlib build.
    with zipfile.ZipFile(os.path.join(kdir, "rules.zip"), "w", zipfile.ZIP_STORED) as z:
        for name in sorted(files):
            zi = zipfile.ZipInfo(name, date_time=(1980, 1, 1, 0, 0, 0))
            zi.compress_type = zipfile.ZIP_STORED
            zi.create_system = 3
            zi.external_attr = 0o644 << 16
            z.writestr(zi, files[name].encode("utf-8"))


if __name__ == "__main__":
    main()
