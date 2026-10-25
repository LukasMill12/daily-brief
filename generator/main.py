"""Build today's brief: fetch sources, let the editor write it, save it as JSON.

    python generator/main.py            # full run (needs ANTHROPIC_API_KEY)
    python generator/main.py --dry-run  # fetch only, save the editor prompt to out/prompt.txt
"""

from __future__ import annotations

import argparse
import json
import sys
from datetime import datetime, timezone
from pathlib import Path
from zoneinfo import ZoneInfo

from editor import build_prompt, write_brief
from fetch import fetch_all, fetch_events_text
from sources import EVENTS_URL, FEEDS

ROOT = Path(__file__).resolve().parent.parent
DOCS = ROOT / "docs"
VILNIUS = ZoneInfo("Europe/Vilnius")


def resolve_sources(ids: list[str], items: list[dict]) -> list[dict]:
    sources, seen = [], set()
    for raw in ids:
        key = raw.strip("[] ")
        if key == "events":
            name, url = "bilietai.lt", EVENTS_URL
        elif key.isdigit() and int(key) < len(items):
            item = items[int(key)]
            name, url = item["source"], item["link"]
        else:
            continue
        if url and url not in seen:
            seen.add(url)
            sources.append({"name": name, "url": url})
    return sources


def finish(draft: dict, items: list[dict], now: datetime, problems: list[str]) -> dict:
    for section in ("lithuania", "world", "interesting", "events", "ongoing"):
        for entry in draft[section]:
            entry["sources"] = resolve_sources(entry.pop("item_ids"), items)
    return {
        "date": now.astimezone(VILNIUS).date().isoformat(),
        "generated_at": now.isoformat(timespec="seconds"),
        **draft,
        "stats": {"items_read": len(items), "feeds": len(FEEDS), "feed_problems": problems},
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--dry-run", action="store_true", help="fetch only and save the prompt")
    args = parser.parse_args()

    now = datetime.now(timezone.utc)
    items, problems = fetch_all(FEEDS, now)
    events_text = fetch_events_text(EVENTS_URL)
    print(f"Fetched {len(items)} items from {len(FEEDS)} feeds; events page: {len(events_text)} chars")
    for problem in problems:
        print(f"  ! {problem}")

    latest = DOCS / "brief.json"
    previous = json.loads(latest.read_text()) if latest.exists() else None

    date_label = now.astimezone(VILNIUS).strftime("%A, %d %B %Y")
    prompt = build_prompt(date_label, items, events_text, previous)

    if args.dry_run:
        out = ROOT / "out" / "prompt.txt"
        out.parent.mkdir(exist_ok=True)
        out.write_text(prompt)
        print(f"Prompt saved to {out} ({len(prompt)} chars)")
        return 0

    brief = finish(write_brief(prompt), items, now, problems)
    text = json.dumps(brief, ensure_ascii=False, indent=2)
    latest.write_text(text)
    archive = DOCS / "archive" / f"{brief['date']}.json"
    archive.parent.mkdir(parents=True, exist_ok=True)
    archive.write_text(text)
    print(f"Saved {latest} and {archive}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
