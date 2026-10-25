"""Where the brief's raw material comes from.

`section` is only a hint for the editor step; a story can still end up in a
different section (e.g. a world story with a Lithuanian angle).
`ranked` marks feeds ordered by importance (an editor's or Google's front page),
so an item's position there is a second importance signal next to coverage.
"""

GOOGLE = "https://news.google.com/rss"
EN = "hl=en-US&gl=US&ceid=US:en"

FEEDS = [
    # Lithuania
    {"name": "LRT English", "section": "lithuania", "url": "https://www.lrt.lt/en/news-in-english?rss"},
    {"name": "LRT", "section": "lithuania", "url": "https://www.lrt.lt/naujienos/lietuvoje?rss"},
    # Delfi's own feeds stopped updating in Aug 2026, so read it through Google News.
    {"name": "Delfi", "section": "lithuania", "url": f"{GOOGLE}/search?q=site:delfi.lt+when:1d&hl=lt&gl=LT&ceid=LT:lt"},
    {"name": "15min", "section": "lithuania", "url": "https://www.15min.lt/rss"},
    {"name": "Lrytas", "section": "lithuania", "url": "https://www.lrytas.lt/rss"},
    # Google's Lithuania section groups each story with every outlet covering it,
    # which is the best importance signal for Lithuanian news.
    {"name": "Google News Lithuania", "section": "lithuania", "limit": 50, "ranked": True,
     "url": f"{GOOGLE}/headlines/section/topic/NATION?hl=lt&gl=LT&ceid=LT:lt"},
    # World
    {"name": "BBC Top Stories", "section": "world", "limit": 20, "ranked": True, "url": "https://feeds.bbci.co.uk/news/rss.xml"},
    {"name": "Google News Top", "section": "world", "ranked": True, "url": f"{GOOGLE}?{EN}"},
    {"name": "Google News World", "section": "world", "ranked": True, "url": f"{GOOGLE}/headlines/section/topic/WORLD?{EN}"},
    {"name": "BBC", "section": "world", "url": "https://feeds.bbci.co.uk/news/world/rss.xml"},
    {"name": "The Guardian", "section": "world", "url": "https://www.theguardian.com/world/rss"},
    {"name": "Al Jazeera", "section": "world", "url": "https://www.aljazeera.com/xml/rss/all.xml"},
    {"name": "Reuters", "section": "world", "url": f"{GOOGLE}/search?q=site:reuters.com+when:1d&{EN}"},
    {"name": "AP", "section": "world", "url": f"{GOOGLE}/search?q=site:apnews.com+when:1d&{EN}"},
    {"name": "LRT World", "section": "world", "url": "https://www.lrt.lt/naujienos/pasaulyje?rss"},
    # Interesting: AI, tech, design, sports
    {"name": "Google News Tech", "section": "interesting", "ranked": True, "url": f"{GOOGLE}/headlines/section/topic/TECHNOLOGY?{EN}"},
    {"name": "TechCrunch", "section": "interesting", "url": "https://techcrunch.com/feed/"},
    {"name": "The Verge", "section": "interesting", "url": "https://www.theverge.com/rss/index.xml"},
    {"name": "Ars Technica", "section": "interesting", "url": "https://feeds.arstechnica.com/arstechnica/index"},
    {"name": "BBC Tech", "section": "interesting", "url": "https://feeds.bbci.co.uk/news/technology/rss.xml"},
    {"name": "Dezeen", "section": "interesting", "url": "https://www.dezeen.com/feed/"},
    {"name": "Google News Sports", "section": "interesting", "ranked": True, "url": f"{GOOGLE}/headlines/section/topic/SPORTS?{EN}"},
    {"name": "BBC Sport", "section": "interesting", "url": "https://feeds.bbci.co.uk/sport/rss.xml"},
    {"name": "LRT Sport", "section": "interesting", "url": "https://www.lrt.lt/naujienos/sportas?rss"},
]

# Event listings; their page text is handed to the editor as-is. The id is what entries cite.
EVENT_SOURCES = [
    {"id": "ev1", "name": "bilietai.lt", "about": "concerts, theatre and shows (also other cities)",
     "url": "https://www.bilietai.lt/lit/renginiai/miestas/vilnius"},
    {"id": "ev2", "name": "bilietai.lt", "about": "exhibitions, conferences and festivals (also other cities)",
     "url": "https://www.bilietai.lt/lit/renginiai/parodos"},
    {"id": "ev3", "name": "LKL", "about": "Lithuanian basketball league schedule; RYT is Vilnius Rytas",
     "url": "https://www.lkl.lt/tvarkarastis"},
]

# Open-Meteo, free and keyless.
WEATHER_URL = (
    "https://api.open-meteo.com/v1/forecast?latitude=54.687&longitude=25.28"
    "&daily=temperature_2m_max,temperature_2m_min,precipitation_sum,weather_code,wind_speed_10m_max"
    "&hourly=precipitation_probability&timezone=Europe%2FVilnius&forecast_days=1"
)
