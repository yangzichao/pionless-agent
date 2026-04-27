#!/usr/bin/env python3
"""Rank candidate URLs by source-tier heuristics.

Usage:
    python scripts/triage_sources.py URLS_FILE

Reads one URL per line from URLS_FILE and prints a ranked list with a
heuristic tier label (primary / authoritative_secondary / weak).

This script is a fast first pass only. The authoritative definition of
source tiers lives in `references/source-policy.md`; the host agent
should still apply judgment on edge cases.
"""
from __future__ import annotations

import sys
from pathlib import Path

from lib.url_normalizer import host_of


PRIMARY_SUFFIXES = (".gov", ".edu", ".mil")
PRIMARY_DOMAINS = (
    "arxiv.org",
    "ietf.org",
    "w3.org",
    "iso.org",
    "europa.eu",
)
AUTHORITATIVE_SECONDARY_DOMAINS = (
    "nytimes.com",
    "ft.com",
    "reuters.com",
    "apnews.com",
    "bbc.co.uk",
    "economist.com",
    "wikipedia.org",
)

TIER_ORDER = ("primary", "authoritative_secondary", "weak")


def classify(url: str) -> str:
    host = host_of(url)
    if not host:
        return "weak"
    if any(host.endswith(suffix) for suffix in PRIMARY_SUFFIXES):
        return "primary"
    if any(host == d or host.endswith("." + d) for d in PRIMARY_DOMAINS):
        return "primary"
    if any(host == d or host.endswith("." + d) for d in AUTHORITATIVE_SECONDARY_DOMAINS):
        return "authoritative_secondary"
    return "weak"


def main(argv: list[str]) -> int:
    if len(argv) != 2:
        print("usage: triage_sources.py URLS_FILE", file=sys.stderr)
        return 2

    path = Path(argv[1])
    if not path.exists():
        print(f"error: {path} not found", file=sys.stderr)
        return 1

    urls = [line.strip() for line in path.read_text().splitlines() if line.strip()]
    ranked = sorted(urls, key=lambda u: TIER_ORDER.index(classify(u)))
    for url in ranked:
        print(f"{classify(url):>24}  {url}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
