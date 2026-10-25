"""Build today's brief: fetch sources, have an editor write it, save it as JSON.

    python generator/main.py                         # full run via the Claude API (needs ANTHROPIC_API_KEY)
    python generator/main.py --dry-run               # fetch only; writes out/editor-task.md for a Claude session
    python generator/main.py --from-draft out/draft.json   # check and publish a draft written from that task
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from datetime import datetime, timezone
from pathlib import Path
from zoneinfo import ZoneInfo

from editor import SCHEMA, SYSTEM, build_prompt, validate, write_brief
from fetch import fetch_all, fetch_events_text
from sources import EVENTS_URL, FEEDS

ROOT = Path(__file__).resolve().parent.parent
DOCS = ROOT / "docs"
OUT = ROOT / "out"
VILNIUS = ZoneInfo("Europe/Vilnius")
MAX_SOURCES = 3


def outlet_key(name: str) -> str:
    """'15min.lt', '15min' and 'AP News', 'AP' count as the same outlet."""
    return re.sub(r"\.(lt|com|co\.uk)$|\s+news$", "", name.strip().lower())


def resolve_sources(ids: list[str], items: list[dict]) -> list[dict]:
    candidates = []
    for raw in ids:
        key = raw.strip("[] ")
        if key == "events":
            candidates.append({"name": "bilietai.lt", "url": EVENTS_URL})
        elif key.isdigit() and int(key) < len(items):
            item = items[int(key)]
            if item["link"]:
                candidates.append({"name": item["source"], "url": item["link"]})

    # Direct article links first; Google News redirect links only as a fallback.
    candidates.sort(key=lambda s: "news.google.com" in s["url"])
    sources, seen = [], set()
    for source in candidates:
        if outlet_key(source["name"]) not in seen:
            seen.add(outlet_key(source["name"]))
            sources.append(source)
    return sources[:MAX_SOURCES]


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


def save(brief: dict) -> None:
    text = json.dumps(brief, ensure_ascii=False, indent=2)
    (DOCS / "brief.json").write_text(text)
    archive = DOCS / "archive" / f"{brief['date']}.json"
    archive.parent.mkdir(parents=True, exist_ok=True)
    archive.write_text(text)
    print(f"Saved docs/brief.json and {archive.relative_to(ROOT)}")


def publish_draft(path: Path) -> int:
    """Check a draft written by a Claude session and publish it."""
    try:
        draft = json.loads(path.read_text())
    except (OSError, ValueError) as exc:
        print(f"Draft is not readable JSON: {exc}")
        return 1
    errors = validate(draft, SCHEMA)
    if not errors and not (draft["lithuania"] and draft["world"]):
        errors = ["lithuania and world must not be empty"]
    if errors:
        print("Draft does not match the format:")
        for error in errors[:20]:
            print(f"  - {error}")
        return 1
    run = json.loads((OUT / "run.json").read_text())
    brief = finish(draft, run["items"], datetime.fromisoformat(run["fetched_at"]), run["problems"])
    save(brief)
    return 0


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--dry-run", action="store_true", help="fetch only and write the editor task")
    parser.add_argument("--from-draft", type=Path, help="check and publish a draft brief")
    args = parser.parse_args()

    if args.from_draft:
        return publish_draft(args.from_draft)

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
        OUT.mkdir(exist_ok=True)
        run = {
            "fetched_at": now.isoformat(),
            "problems": problems,
            "items": [{"source": i["source"], "link": i["link"]} for i in items],
        }
        (OUT / "run.json").write_text(json.dumps(run, ensure_ascii=False))
        task = OUT / "editor-task.md"
        task.write_text(
            "# Daily brief editor task\n\n"
            f"## Instructions\n\n{SYSTEM}\n\n"
            "## Output\n\nWrite out/draft.json: one JSON object that matches this JSON Schema exactly "
            "(item ids are the numbers in square brackets, as strings, e.g. \"12\"; use \"events\" for the ticket listing).\n\n"
            f"```json\n{json.dumps(SCHEMA, indent=2)}\n```\n\n"
            f"## Today's material\n\n{prompt}\n"
        )
        print(f"Editor task saved to {task.relative_to(ROOT)} ({len(task.read_text())} chars)")
        return 0

    save(finish(write_brief(prompt), items, now, problems))
    return 0


if __name__ == "__main__":
    sys.exit(main())
