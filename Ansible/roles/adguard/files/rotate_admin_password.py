#!/usr/bin/env python3
"""Rotate the AdGuard Home admin password in /opt/AdGuardHome/AdGuardHome.yaml.

Reads the username and the new password from environment variables, replaces
the user's bcrypt hash, writes back, and verifies the stored hash against the
input password before exiting 0.

Run by the `adguard` Ansible role's rotate-password task — not intended for
direct use.
"""
import os
import sys

import bcrypt
import yaml

CONFIG = "/opt/AdGuardHome/AdGuardHome.yaml"


def main() -> int:
    username = os.environ["ADGUARD_USER"]
    password = os.environ["ADGUARD_PW"].encode()

    with open(CONFIG) as f:
        cfg = yaml.safe_load(f)

    user = next((u for u in cfg.get("users") or [] if u.get("name") == username), None)
    if user is None:
        print(f"FAIL: user '{username}' not in {CONFIG}", file=sys.stderr)
        return 1

    user["password"] = bcrypt.hashpw(password, bcrypt.gensalt()).decode()

    with open(CONFIG, "w") as f:
        yaml.safe_dump(cfg, f, default_flow_style=False, sort_keys=False)

    with open(CONFIG) as f:
        cfg = yaml.safe_load(f)
    user = next(u for u in cfg["users"] if u["name"] == username)
    if not bcrypt.checkpw(password, user["password"].encode()):
        print("FAIL: post-write verify did not match", file=sys.stderr)
        return 2

    print("rotated and verified")
    return 0


if __name__ == "__main__":
    sys.exit(main())
