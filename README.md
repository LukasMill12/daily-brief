# Daily Brief

A short personal news brief, written every morning: Lithuania, World, Ongoing stories, and Interesting (AI, tech, design, sports, events in Vilnius).

## How it works

1. **Fetch**: `generator/fetch.py` reads ~22 RSS feeds (LRT, 15min, Delfi, BBC, Guardian, Al Jazeera, Reuters and AP via Google News, TechCrunch, Dezeen…) and the bilietai.lt event listing. Sources live in `generator/sources.py`.
2. **Edit**: `generator/editor.py` sends the ~500 headlines to Claude, which groups duplicates, ranks stories by how many outlets cover them, and writes the brief as structured JSON. Yesterday's ongoing stories are passed in, so it only reports what changed.
3. **Save**: `docs/brief.json` (latest) and `docs/archive/YYYY-MM-DD.json`. `docs/index.html` displays it; the iPhone app will read the same JSON.
4. **Schedule**: `.github/workflows/daily.yml` runs every day at 07:00 Vilnius time (08:00 in summer).

## One-time setup

1. Create a GitHub repository and push this folder to it.
2. Repository **Settings → Secrets and variables → Actions**, add `ANTHROPIC_API_KEY` (from console.anthropic.com).
3. **Settings → Pages**: source "Deploy from a branch", branch `main`, folder `/docs`.
4. **Actions → Daily brief → Run workflow** to make the first brief now.
5. Optional phone notification before the app exists: install the ntfy app, subscribe to a long random topic name, and add it as the `NTFY_TOPIC` secret.

## Running locally

Needs Python 3.10+.

```bash
pip install -r requirements.txt
python generator/main.py --dry-run   # fetch only, writes the Claude prompt to out/prompt.txt
python generator/main.py             # full run, needs ANTHROPIC_API_KEY
```

## Cost

Roughly 40k input and a few thousand output tokens per day on Claude Opus 5.5, about $0.20–0.30 a day.
