"""The editor step: Claude picks, ranks and writes the brief from the fetched items."""

from __future__ import annotations

import json

MODEL = "claude-opus-5-5"

SOURCE_IDS = {"type": "array", "items": {"type": "string"}}

STORY = {
    "type": "object",
    "properties": {
        "headline": {"type": "string"},
        "summary": {"type": "string"},
        "category": {"type": "string", "enum": ["general", "ai", "tech", "design", "sports", "science", "culture"]},
        "highlight": {"type": "boolean"},
        "coverage": {"type": "integer"},
        "why": {"type": "string"},
        "context": {"type": "string"},
        "item_ids": SOURCE_IDS,
        "photo_ids": SOURCE_IDS,
    },
    "required": ["headline", "summary", "category", "highlight", "coverage", "why", "context", "item_ids",
                 "photo_ids"],
    "additionalProperties": False,
}

ONGOING = {
    "type": "object",
    "properties": {
        "id": {"type": "string"},
        "title": {"type": "string"},
        "update": {"type": "string"},
        "context": {"type": "string"},
        "item_ids": SOURCE_IDS,
        "photo_ids": SOURCE_IDS,
    },
    "required": ["id", "title", "update", "context", "item_ids", "photo_ids"],
    "additionalProperties": False,
}

EVENT = {
    "type": "object",
    "properties": {
        "title": {"type": "string"},
        "when": {"type": "string"},
        "where": {"type": "string"},
        "scope": {"type": "string", "enum": ["vilnius", "global"]},
        "item_ids": SOURCE_IDS,
    },
    "required": ["title", "when", "where", "scope", "item_ids"],
    "additionalProperties": False,
}

FACT = {
    "type": "object",
    "properties": {"text": {"type": "string"}, "item_ids": SOURCE_IDS},
    "required": ["text", "item_ids"],
    "additionalProperties": False,
}

SCHEMA = {
    "type": "object",
    "properties": {
        "fact": FACT,
        "lead_section": {"type": "string", "enum": ["lithuania", "world"]},
        "widget_headline": {"type": "string"},
        "heads_up": {"type": "array", "items": {"type": "string"}},
        "lithuania": {"type": "array", "items": STORY},
        "world": {"type": "array", "items": STORY},
        "interesting": {"type": "array", "items": STORY},
        "events": {"type": "array", "items": EVENT},
        "ongoing": {"type": "array", "items": ONGOING},
        "quiet_ongoing": {"type": "array", "items": {"type": "string"}},
    },
    "required": ["fact", "lead_section", "widget_headline", "heads_up", "lithuania", "world", "interesting", "events",
                 "ongoing", "quiet_ongoing"],
    "additionalProperties": False,
}

SYSTEM = """You are the editor of a short, personal daily news brief for one reader who lives in Vilnius, Lithuania. It is read on a phone in 3-5 minutes. Write plainly and neutrally.

Language: write the lithuania section, heads_up, and Vilnius events in Lithuanian (natural, correct Lithuanian with proper diacritics). Write everything else (world, interesting, ongoing, global events) in English, translating Lithuanian-language items where needed.

You get today's raw headlines from many outlets, some in Lithuanian and some in English. Each item has an id like [12]. Pick and write the brief from these items only. Never add facts that are not in the items, and cite the ids each entry is based on.

How to choose stories
- Importance comes from coverage: a story carried by many different outlets or feeds, or with a large Google News cluster ("cluster: N outlets"), is big news. Group items that report the same story and count the distinct outlets; put that number in `coverage`.
- Second signal: "front page #N" means the item is Nth on an importance-ordered front page (BBC Top Stories or a Google News section). A story near the top of several front pages is big news even when the cluster count is capped at 5.
- The biggest stories always come first and are never pushed out by the reader's interests.
- Drop soft content: horoscopes, recipes, celebrity gossip, lifestyle filler, advertorials.
- Yesterday's brief is listed for reference. Don't repeat a story from it unless there is a real new development today (new numbers, a decision, an outcome); if you do include it, the headline and summary must lead with what is new. Prefer fresh stories of similar weight.

Sections
- lithuania: exactly 3 of the most important Lithuanian stories, ranked. Lithuanian outlets give the same event very different headlines, so translate first and group by the underlying event (same people, place, decision or number), not by wording. Cluster counts on lithuania items are the strongest signal here; add matching items from other outlets to the count. Prefer national news (government, Seimas, security, economy, major incidents) over local crime, accidents and celebrity stories. A story carried by only one outlet makes the cut only if nothing better covered is left.
- world: 3 or 4 of the most important world stories, ranked.
- interesting: 2 or 3 picks from AI, tech, design and sports (science or culture if something stands out). Prefer substance over hype; mix categories when possible.
- events: 1 or 2 Vilnius events plus 1 or 2 global events, so both kinds appear every day. Vilnius events (scope "vilnius") must come from one of the event listings, take place in Vilnius in the next 7 days, and cite that listing's id (e.g. "ev1") as their only item id. Mix kinds when possible (a concert, an exhibition or a festival). Global events (scope "global") are notable dated happenings in the coming days from the news, e.g. an election tomorrow, a summit, a court ruling, a launch or a big match tonight; there is almost always one. Don't repeat the top story as an event.
- ongoing: long-running stories (wars, conflicts, multi-week crises). Include one only if something new happened in the last 24 hours, and write only what changed, in one or two sentences, without retelling the background. Reuse the id of a previously tracked story when it continues; make a short kebab-case id for a new one. List previously tracked stories that had no real news today in `quiet_ongoing` (titles only).
- lead_section: "lithuania" or "world", whichever section's first story is the single most important story of the day. The app shows that story as a large lead paragraph.
- widget_headline: a 2–3 word label for the lead story, at most 22 characters, in the lead story's language, no final period. It sits alone on a small curved line on the home screen widget, so the reader must understand what happened from these words alone. Read the story and write the label fresh: name the core subject and what happened (e.g. "Skola brangsta", "Brazil decides", "Kaunas sky closed", "Biudžetas be liberalų"). Never use the first words of the headline, a truncated phrase, or a label that only makes sense with more context.
- fact: one fact of the day in English, one or two sentences, citing the id it comes from. Take it from the "on this day" list ([d0], [d1], …; start with the year, e.g. "In 1977, …") or from a surprising, verifiable detail in today's items. It must make a well-read adult think "huh, I didn't know that": consequential, strange or revealing, ideally connected to something in today's news. Never trivia-quiz material, records, celebrity birthdays, cute animal facts or anything cheesy, and never anything that isn't stated in the material. Rewrite it in your own plain words.
- context (on every lithuania, world, interesting and ongoing entry), in the entry's language. First decide what kind of story it is:
  * Part of a longer story (a war, a long political crisis, a court saga, an election race, a long-running dispute): tell the backstory from the very beginning in plain words, as to someone who never followed it: when and how it started, why, and the two or three key turns that led to today. Two to four short sentences, in time order, e.g. "It began in February 2022, when Russia invaded Ukraine… Since then…". Every ongoing entry is this kind.
  * Self-contained (an accident, an award, a single announcement or deal): at most one short, plain sentence that makes it understandable (who someone is, what something means), or an empty string if it explains itself.
  Interesting entries are always the short kind. Examples of the long kind: a president urging cuts to the budget deficit (how the deficit and the budget fight arose), someone crossing the border into Russia (why that border is so tense), an election, a politician's latest court case, a strike after an attack. Example of the short kind: a former president leaving hospital ("He was admitted on 26 September after a sudden illness and had surgery."), an award, a company's IPO.
  Never repeat the summary or update. For the history you may use well-established background knowledge (widely known, undisputed dates and facts); anything about the last few weeks must come from the material.
- heads_up: at most 2 short practical notes that affect daily life in Lithuania (clock change, strikes, severe weather warnings, transport disruption), only if the items mention them. Usually empty. The daily forecast is shown separately, so don't repeat ordinary weather here.

Rules
- Every story appears once. If a story belongs to an ongoing event, it goes in ongoing, not in lithuania or world.
- headline: short and factual, no clickbait. summary: one or two sentences, the key facts and numbers.
- why: a few words on why it was picked, in the entry's language, e.g. "Covered by 9 outlets" or "Apie tai rašė 5 portalai".
- highlight: true for stories about AI, tech, design or sports, in any section.
- category: "general" for anything outside the reader's topics.
- item_ids: cite every item that reports this story itself (all outlets, including Google News items), the main news report first, so the reader gets several sources and the full articles can be looked up. Leave out pieces that only touch the story from another angle: celebrity, lifestyle, opinion or reaction pieces.
- photo_ids: up to 2 ids of items marked {photo} whose photo would show this story: its event, place or the people at its centre, as judged from that item's headline and outlet. Never pick photos from celebrity, lifestyle or unrelated pieces, and prefer the main news report's photo. An empty list is better than a photo that doesn't fit."""


TYPES = {"object": dict, "array": list, "string": str, "integer": int, "boolean": bool}


def validate(value, schema: dict, path: str = "brief") -> list[str]:
    """Check a draft against SCHEMA; only the keywords SCHEMA uses are supported."""
    expected = TYPES[schema["type"]]
    if not isinstance(value, expected) or (expected is int and isinstance(value, bool)):
        return [f"{path}: expected {schema['type']}"]
    if "enum" in schema and value not in schema["enum"]:
        return [f"{path}: {value!r} is not one of {schema['enum']}"]
    errors = []
    if expected is dict:
        for key in schema["required"]:
            if key not in value:
                errors.append(f"{path}.{key}: missing")
        for key in value:
            if key not in schema["properties"]:
                errors.append(f"{path}.{key}: unexpected field")
            else:
                errors += validate(value[key], schema["properties"][key], f"{path}.{key}")
    elif expected is list:
        for i, entry in enumerate(value):
            errors += validate(entry, schema["items"], f"{path}[{i}]")
    return errors


def format_items(items: list[dict]) -> str:
    lines = []
    for i, item in enumerate(items):
        published = item["published"].strftime("%a %H:%M UTC") if item["published"] else "?"
        line = f"[{i}] ({item['source']} | {item['section']} | {published}) {item['title']}"
        if item["summary"]:
            line += f" — {item['summary']}"
        if len(item["outlets"]) > 1:
            line += f" {{cluster: {len(item['outlets'])} outlets: {', '.join(item['outlets'][:8])}}}"
        if item.get("rank"):
            line += f" {{front page #{item['rank']} on {item['feed']}}}"
        if item.get("image"):
            line += " {photo}"
        lines.append(line)
    return "\n".join(lines)


def build_prompt(date_label: str, items: list[dict], events: list[dict], previous: dict | None,
                 weather: dict | None, on_this_day: list[dict]) -> str:
    tracked, yesterday = "none yet", "none"
    if previous:
        if previous.get("ongoing"):
            tracked = "\n".join(f"- {o['id']}: {o['title']} (last update: {o['update']})" for o in previous["ongoing"])
        tracked += "".join(f"\n- {t} (quiet last time)" for t in previous.get("quiet_ongoing", []))
        yesterday = "\n".join(f"- [{section}] {s['headline']}"
                              for section in ("lithuania", "world", "interesting") for s in previous.get(section, []))
    listings = "\n\n".join(
        f"[{e['id']}] {e['name']}: {e['about']} (name, venue, date on consecutive lines)\n{e['text'] or 'unavailable today'}"
        for e in events
    )

    anniversaries = "\n".join(f"[d{i}] {e['year']}: {e['text']}" for i, e in enumerate(on_this_day)) or "unavailable today"

    return f"""Today is {date_label} in Vilnius.
Forecast (shown to the reader separately): {weather['text'] if weather else "unavailable"}

<yesterdays_brief>
{yesterday}
</yesterdays_brief>

<previously_tracked_ongoing_stories>
{tracked}
</previously_tracked_ongoing_stories>

<headlines>
{format_items(items)}
</headlines>

<event_listings>
{listings}
</event_listings>

<on_this_day>
Wikipedia's curated anniversaries for today's date:
{anniversaries}
</on_this_day>

Write today's brief."""


def write_brief(prompt: str) -> dict:
    import anthropic  # only needed for a full run, so --dry-run works without the SDK

    client = anthropic.Anthropic()
    with client.beta.messages.stream(
        model=MODEL,
        max_tokens=32000,
        betas=["server-side-fallback-2026-07-01"],
        fallbacks="default",
        output_config={
            "effort": "medium",
            "format": {"type": "json_schema", "schema": SCHEMA},
        },
        system=SYSTEM,
        messages=[{"role": "user", "content": prompt}],
    ) as stream:
        message = stream.get_final_message()

    if message.stop_reason == "refusal":
        raise RuntimeError(f"Editor step was declined: {message.stop_details}")
    if message.stop_reason == "max_tokens":
        raise RuntimeError("Editor step ran out of output tokens")

    text = next(b.text for b in message.content if b.type == "text")
    usage = message.usage
    print(f"Claude usage: {usage.input_tokens} in, {usage.output_tokens} out")
    return json.loads(text)
