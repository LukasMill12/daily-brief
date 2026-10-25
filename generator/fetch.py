"""Download feeds and the events page, and turn them into plain records."""

from __future__ import annotations

import html
import re
import urllib.request
import xml.etree.ElementTree as ET
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timedelta, timezone
from email.utils import parsedate_to_datetime

USER_AGENT = "Mozilla/5.0 (compatible; daily-brief/1.0)"
MAX_AGE = timedelta(hours=36)
MAX_ITEMS_PER_FEED = 30
SUMMARY_CHARS = 220

ATOM = "{http://www.w3.org/2005/Atom}"


def download(url: str, timeout: int = 25) -> bytes:
    req = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        return resp.read()


def clean(text: str | None) -> str:
    text = html.unescape(re.sub(r"<[^>]+>", " ", text or ""))
    return re.sub(r"\s+", " ", text).strip()


def parse_date(value: str | None) -> datetime | None:
    if not value:
        return None
    value = value.strip()
    try:
        dt = parsedate_to_datetime(value)
    except (TypeError, ValueError):
        try:
            dt = datetime.fromisoformat(value.replace("Z", "+00:00"))
        except ValueError:
            return None
    return dt if dt.tzinfo else dt.replace(tzinfo=timezone.utc)


def google_outlets(description: str) -> list[str]:
    """Google News items list every outlet in the story cluster as <font> tags."""
    raw = html.unescape(description or "")
    outlets = [clean(o) for o in re.findall(r"<font[^>]*>(.*?)</font>", raw, re.S)]
    return list(dict.fromkeys(o for o in outlets if o))  # one outlet can appear twice in a cluster


def parse_feed(data: bytes, feed: dict) -> list[dict]:
    root = ET.fromstring(data)
    is_google = "news.google.com" in feed["url"]
    items = []

    entries = root.iter("item")
    atom_entries = list(root.iter(f"{ATOM}entry"))
    for node in atom_entries or entries:
        if atom_entries:
            title = node.findtext(f"{ATOM}title")
            link_el = node.find(f"{ATOM}link")
            link = link_el.get("href") if link_el is not None else ""
            summary = node.findtext(f"{ATOM}summary") or node.findtext(f"{ATOM}content")
            published = node.findtext(f"{ATOM}published") or node.findtext(f"{ATOM}updated")
            source = feed["name"]
            outlets: list[str] = []
        else:
            title = node.findtext("title")
            link = node.findtext("link")
            summary = node.findtext("description")
            published = node.findtext("pubDate")
            source_el = node.find("source")
            source = source_el.text if is_google and source_el is not None else feed["name"]
            outlets = google_outlets(summary) if is_google else []

        title = clean(title)
        if is_google:
            # "Headline - Outlet" -> "Headline"; the outlet is in `source`.
            title = re.sub(r"\s+-\s+[^-]+$", "", title)
            summary = ""  # the description only repeats the cluster headlines
        if not title:
            continue
        items.append({
            "feed": feed["name"],
            "section": feed["section"],
            "source": clean(source),
            "title": title,
            "summary": clean(summary)[:SUMMARY_CHARS],
            "link": (link or "").strip(),
            "published": parse_date(published),
            "outlets": outlets,
        })
    return items


def fetch_feed(feed: dict, now: datetime) -> tuple[dict, list[dict], str | None]:
    try:
        items = parse_feed(download(feed["url"]), feed)
    except Exception as exc:  # one broken feed must not stop the brief
        return feed, [], f"{type(exc).__name__}: {exc}"
    fresh = [i for i in items if i["published"] is None or now - i["published"] <= MAX_AGE]
    return feed, fresh[:feed.get("limit", MAX_ITEMS_PER_FEED)], None


def fetch_all(feeds: list[dict], now: datetime) -> tuple[list[dict], list[str]]:
    items, problems = [], []
    with ThreadPoolExecutor(max_workers=8) as pool:
        for feed, feed_items, error in pool.map(lambda f: fetch_feed(f, now), feeds):
            if error:
                problems.append(f"{feed['name']}: {error}")
            elif not feed_items:
                problems.append(f"{feed['name']}: no recent items")
            items.extend(feed_items)
    return items, problems


def fetch_events_text(url: str, max_chars: int = 9000) -> str:
    """The ticket site's visible text: event name, venue and date on separate lines."""
    try:
        page = download(url).decode("utf-8", errors="ignore")
    except Exception:
        return ""
    page = re.sub(r"<script.*?</script>|<style.*?</style>", "", page, flags=re.S)
    lines = [l.strip() for l in html.unescape(re.sub(r"<[^>]+>", "\n", page)).split("\n")]
    return "\n".join(l for l in lines if l)[:max_chars]
