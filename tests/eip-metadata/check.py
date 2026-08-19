#!/usr/bin/env python3
"""Check EIP front matter without changing proposal content."""

from __future__ import annotations

import argparse
import datetime
import pathlib
import sys

REQUIRED = ("eip", "title", "description", "author", "discussions-to", "status", "type", "created")
STATUSES = {"Draft", "Review", "Last Call", "Final", "Stagnant", "Withdrawn", "Living", "Moved"}


def front_matter(path: pathlib.Path) -> tuple[dict[str, str], list[str]]:
    lines = path.read_text(encoding="utf-8").splitlines()
    if not lines or lines[0] != "---":
        return {}, ["front matter does not start with ---"]
    try:
        end = lines.index("---", 1)
    except ValueError:
        return {}, ["front matter has no closing ---"]

    fields: dict[str, str] = {}
    errors: list[str] = []
    for line in lines[1:end]:
        if ":" not in line:
            continue
        key, value = line.split(":", 1)
        key, value = key.strip(), value.strip()
        if key in fields:
            errors.append(f"duplicate field: {key}")
        fields[key] = value
    return fields, errors


def check(path: pathlib.Path) -> list[str]:
    fields, errors = front_matter(path)
    if not fields:
        return errors

    status = fields.get("status")
    if status not in STATUSES:
        errors.append(f"unknown status: {status!r}")
    if status not in {"Moved", "Withdrawn"}:
        errors.extend(f"missing field: {field}" for field in REQUIRED if not fields.get(field))
    if status == "Last Call" and not fields.get("last-call-deadline"):
        errors.append("Last Call requires last-call-deadline")
    if status == "Withdrawn" and not fields.get("withdrawal-reason"):
        errors.append("Withdrawn requires withdrawal-reason")
    if fields.get("type") == "Standards Track" and not fields.get("category"):
        errors.append("Standards Track requires category")
    for field in ("created", "last-call-deadline"):
        if fields.get(field):
            try:
                datetime.date.fromisoformat(fields[field])
            except ValueError:
                errors.append(f"{field} must be an ISO date: {fields[field]!r}")
    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("paths", nargs="+", type=pathlib.Path)
    parser.add_argument("--strict", action="store_true", help="exit non-zero when any issue is found")
    args = parser.parse_args()

    issue_count = 0
    for path in args.paths:
        errors = check(path)
        if errors:
            issue_count += len(errors)
            for error in errors:
                print(f"{path}: {error}")
        elif args.strict:
            print(f"{path}: ok")
    print(f"checked={len(args.paths)} issues={issue_count}")
    return 1 if args.strict and issue_count else 0


if __name__ == "__main__":
    sys.exit(main())