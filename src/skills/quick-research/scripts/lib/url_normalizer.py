"""Internal helper for triage_sources.py. Not a public skill entrypoint."""
from __future__ import annotations

from urllib.parse import urlparse


def host_of(url: str) -> str:
    """Return lowercased host of URL with leading 'www.' stripped.

    Returns empty string if the URL has no parseable host.
    """
    parsed = urlparse(url if "://" in url else f"http://{url}")
    host = (parsed.hostname or "").lower()
    return host.removeprefix("www.")
