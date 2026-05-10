#!/usr/bin/env python3
"""Rotate the AdGuard Home admin password in /opt/AdGuardHome/AdGuardHome.yaml.

Reads username and new password from environment variables, replaces the user's
bcrypt hash, writes back, and verifies the hash matches the new password.

Run by the `adguard` Ansible role's rotate-password task — not intended for
direct use.
"""
import os
import sys

import yaml

try:
    from passlib.hash import bcrypt as _bcrypt

    def _hash(pw: str) -> str:
        return _bcrypt.hash(pw)

    def _verify(pw: str, h: str) -> bool:
        return _bcrypt.verify(pw, h)

except ImportError:
    import bcrypt as _b

    def _hash(pw: str) -> str:
        return _b.hashpw(pw.encode(), _b.gensalt()).decode()

    def _verify(pw: str, h: str) -> bool:
        return _b.checkpw(pw.encode(), h.encode())


CONFIG = "/opt/AdGuardHome/AdGuardHome.yaml"


def main() -> int:
    username = os.environ["ADGUARD_USER"]
    password = os.environ["ADGUARD_PW"]

    with open(CONFIG) as f:
        cfg = yaml.safe_load(f)

    users = cfg.get("users") or []
    user = next((u for u in users if u.get("name") == username), None)
    if user is None:
        print(f"FAIL: user '{username}' not in {CONFIG}", file=sys.stderr)
        return 1

    user["password"] = _hash(password)

    with open(CONFIG, "w") as f:
        yaml.safe_dump(cfg, f, default_flow_style=False, sort_keys=False)

    with open(CONFIG) as f:
        cfg = yaml.safe_load(f)
    user = next(u for u in cfg["users"] if u["name"] == username)
    if not _verify(password, user["password"]):
        print("FAIL: post-write verify did not match", file=sys.stderr)
        return 2

    print("rotated and verified")
    return 0


if __name__ == "__main__":
    sys.exit(main())
