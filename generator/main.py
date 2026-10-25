"""Build today's brief: fetch sources, have an editor write it, save it as JSON.

    python generator/main.py                               # full run via the Claude API (needs ANTHROPIC_API_KEY)
    python generator/main.py --dry-run                     # fetch only; writes out/editor-task.md for a Claude session
    python generator/main.py --articles out/draft.json     # fetch the chosen stories' articles into out/articles.md
    python generator/main.py --from-draft out/draft.json   # check and publish a draft written from that task
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timezone
from pathlib import Path
from zoneinfo import ZoneInfo

from editor import SCHEMA, SYSTEM, build_prompt, validate, write_brief
from fetch import fetch_all, fetch_article_text, fetch_events_text, fetch_weather
from sources import EVENT_SOURCES, FEEDS, WEATHER_URL

ROOT = Path(__file__).resolve().parent.parent
DOCS = ROOT / "docs"
OUT = ROOT / "out"
VILNIUS = ZoneInfo("Europe/Vilnius")
MAX_SOURCES = 3
ARTICLES_PER_STORY = 2
EVENTS_BY_ID = {e["id"]: e for e in EVENT_SOURCES}


def outlet_key(name: str) -> str:
    """'15min.lt', '15min' and 'AP News', 'AP' count as the same outlet."""
    return re.sub(r"\.(lt|com|co\.uk)$|\s+news$", "", name.strip().lower())


def candidate_sources(ids: list[str], items: list[dict]) -> list[dict]:
    """One source per outlet, direct article links before Google News redirect links."""
    candidates = []
    for raw in ids:
        key = raw.strip("[] ")
        if key == "events":  # older drafts cited the ticket listing this way
            key = "ev1"
        if key in EVENTS_BY_ID:
            candidates.append({"name": EVENTS_BY_ID[key]["name"], "url": EVENTS_BY_ID[key]["url"]})
        elif key.isdigit() and int(key) < len(items) and items[int(key)]["link"]:
            item = items[int(key)]
            candidates.append({"name": item["source"], "url": item["link"]})

    candidates.sort(key=lambda s: "news.google.com" in s["url"])
    sources, seen = [], set()
    for source in candidates:
        if outlet_key(source["name"]) not in seen:
            seen.add(outlet_key(source["name"]))
            sources.append(source)
    return sources


def finish(draft: dict, items: list[dict], now: datetime, problems: list[str], weather: dict | None) -> dict:
    for section in ("lithuania", "world", "interesting", "events", "ongoing"):
        for entry in draft[section]:
            entry["sources"] = candidate_sources(entry.pop("item_ids"), items)[:MAX_SOURCES]
    return {
        "date": now.astimezone(VILNIUS).date().isoformat(),
        "generated_at": now.isoformat(timespec="seconds"),
        "weather": weather,
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


def load_draft(path: Path) -> tuple[dict | None, list[str]]:
    try:
        draft = json.loads(path.read_text())
    except (OSError, ValueError) as exc:
        return None, [f"not readable JSON: {exc}"]
    errors = validate(draft, SCHEMA)
    if not errors and not (draft["lithuania"] and draft["world"]):
        errors = ["lithuania and world must not be empty"]
    return draft, errors


def fetch_articles(path: Path) -> int:
    """Write out/articles.md: the article text behind each story the draft picked."""
    draft, errors = load_draft(path)
    if errors:
        print("Draft does not match the format:", *errors[:20], sep="\n  - ")
        return 1
    items = json.loads((OUT / "run.json").read_text())["items"]
    stories = [(section, s["headline"] if "headline" in s else s["title"], s["item_ids"])
               for section in ("lithuania", "world", "interesting", "ongoing") for s in draft[section]]

    def read(story):
        section, headline, ids = story
        direct = [s for s in candidate_sources(ids, items) if "news.google.com" not in s["url"]]
        texts = []
        for source in direct[:ARTICLES_PER_STORY]:
            try:
                text = fetch_article_text(source["url"])
            except Exception as exc:
                text = f"(could not open: {type(exc).__name__})"
            texts.append(f"**{source['name']}** {source['url']}\n{text or '(no article text found)'}")
        return f"## [{section}] {headline}\n\n" + ("\n\n".join(texts) or "(no direct article link)")

    with ThreadPoolExecutor(max_workers=6) as pool:
        sections = list(pool.map(read, stories))
    out = OUT / "articles.md"
    out.write_text(
        "# Articles behind today's picks\n\n"
        "Use these to make each summary accurate and specific: correct anything the headline got wrong and add "
        "the key facts, numbers and why it matters. Keep summaries to one or two sentences and keep the language "
        "rules. Change a pick only if its article shows it is wrong or trivial.\n\n" + "\n\n".join(sections) + "\n"
    )
    print(f"Articles for {len(stories)} stories saved to {out.relative_to(ROOT)} ({len(out.read_text())} chars)")
    return 0


def publish_draft(path: Path) -> int:
    """Check a draft written by a Claude session and publish it."""
    draft, errors = load_draft(path)
    if errors:
        print("Draft does not match the format:", *errors[:20], sep="\n  - ")
        return 1
    run = json.loads((OUT / "run.json").read_text())
    save(finish(draft, run["items"], datetime.fromisoformat(run["fetched_at"]), run["problems"], run["weather"]))
    return 0


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--dry-run", action="store_true", help="fetch only and write the editor task")
    parser.add_argument("--articles", type=Path, help="fetch the articles behind a draft's picks")
    parser.add_argument("--from-draft", type=Path, help="check and publish a draft brief")
    args = parser.parse_args()

    if args.articles:
        return fetch_articles(args.articles)
    if args.from_draft:
        return publish_draft(args.from_draft)

    now = datetime.now(timezone.utc)
    items, problems = fetch_all(FEEDS, now)
    events = [{**e, "text": fetch_events_text(e["url"])} for e in EVENT_SOURCES]
    weather, weather_error = fetch_weather(WEATHER_URL)
    print(f"Fetched {len(items)} items from {len(FEEDS)} feeds; "
          f"event listings: {[len(e['text']) for e in events]} chars; weather: {weather['text'] if weather else 'unavailable'}")
    problems += [f"{e['name']} ({e['about'].split(',')[0]}): unavailable" for e in events if not e["text"]]
    if weather_error:
        problems.append(f"weather: {weather_error}")
    for problem in problems:
        print(f"  ! {problem}")

    latest = DOCS / "brief.json"
    previous = json.loads(latest.read_text()) if latest.exists() else None
    date_label = now.astimezone(VILNIUS).strftime("%A, %d %B %Y")
    prompt = build_prompt(date_label, items, events, previous, weather)

    if args.dry_run:
        OUT.mkdir(exist_ok=True)
        run = {
            "fetched_at": now.isoformat(),
            "problems": problems,
            "weather": weather,
            "items": [{"source": i["source"], "link": i["link"]} for i in items],
        }
        (OUT / "run.json").write_text(json.dumps(run, ensure_ascii=False))
        task = OUT / "editor-task.md"
        task.write_text(
            "# Daily brief editor task\n\n"
            f"## Instructions\n\n{SYSTEM}\n\n"
            "## Output\n\nWrite out/draft.json: one JSON object that matches this JSON Schema exactly "
            "(item ids are the numbers in square brackets, as strings, e.g. \"12\"; event listings use their id, e.g. \"ev1\").\n\n"
            f"```json\n{json.dumps(SCHEMA, indent=2)}\n```\n\n"
            f"## Today's material\n\n{prompt}\n"
        )
        print(f"Editor task saved to {task.relative_to(ROOT)} ({len(task.read_text())} chars)")
        return 0

    save(finish(write_brief(prompt), items, now, problems, weather))
    return 0


if __name__ == "__main__":
    sys.exit(main())
