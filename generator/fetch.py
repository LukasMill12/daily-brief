"""Download feeds and the events page, and turn them into plain records."""

from __future__ import annotations

import html
import json
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
    for position, item in enumerate(items, 1):
        item["rank"] = position if feed.get("ranked") else None
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


def fetch_events_text(url: str, max_chars: int = 7000) -> str:
    """A listing page's visible text: event name, venue and date on separate lines."""
    try:
        page = download(url).decode("utf-8", errors="ignore")
    except Exception:
        return ""
    page = re.sub(r"<script.*?</script>|<style.*?</style>", "", page, flags=re.S)
    lines = [l.strip() for l in html.unescape(re.sub(r"<[^>]+>", "\n", page)).split("\n")]
    return "\n".join(l for l in lines if l)[:max_chars]


def fetch_article_text(url: str, max_chars: int = 3000) -> str:
    """The body paragraphs of a news article, without menus and footers where possible."""
    page = download(url).decode("utf-8", errors="ignore")
    page = re.sub(r"<script.*?</script>|<style.*?</style>|<nav.*?</nav>|<footer.*?</footer>", "", page, flags=re.S)
    article = re.search(r"<article[^>]*>(.*?)</article>", page, re.S)
    body = article.group(1) if article and len(article.group(1)) > 2000 else page
    paragraphs = [clean(p) for p in re.findall(r"<p[^>]*>(.*?)</p>", body, re.S)]
    # Real sentences only: menus and captions are short or have no full stop.
    text = " ".join(p for p in paragraphs if len(p) > 60 and "." in p)
    return text[:max_chars]


WMO_LT = [  # (highest code, description) — WMO weather codes as used by Open-Meteo
    (0, "giedra"), (2, "nedidelis debesuotumas"), (3, "debesuota"), (48, "rūkas"),
    (57, "dulksna"), (67, "lietus"), (77, "sniegas"), (82, "protarpiais lyja"),
    (86, "snygis"), (99, "perkūnija"),
]


def fetch_weather(url: str) -> tuple[dict | None, str | None]:
    """Today's Vilnius forecast with a short Lithuanian summary line, or the reason it failed."""
    try:
        data = json.loads(download(url))
    except Exception as exc:
        return None, f"{type(exc).__name__}: {exc}"
    daily = data["daily"]
    code = daily["weather_code"][0]
    rainy_hours = [t[11:16] for t, p in zip(data["hourly"]["time"], data["hourly"]["precipitation_probability"])
                   if p is not None and p >= 50 and "07:00" <= t[11:16] <= "22:00"]
    weather = {
        "min": round(daily["temperature_2m_min"][0]),
        "max": round(daily["temperature_2m_max"][0]),
        "precipitation_mm": daily["precipitation_sum"][0],
        "wind_max_kmh": round(daily["wind_speed_10m_max"][0]),
        "code": code,
        "rain_from": rainy_hours[0] if rainy_hours else None,
    }
    text = next(desc for top, desc in WMO_LT if code <= top)
    line = f"Vilniuje {weather['min']}…{weather['max']} °C, {text}"
    if weather["rain_from"]:
        line += f", krituliai nuo {weather['rain_from']}"
    if weather["wind_max_kmh"] >= 40:
        line += f", vėjas iki {weather['wind_max_kmh']} km/h"
    weather["text"] = line + "."
    return weather, None
