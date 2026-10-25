# Daily Brief

A short personal news brief, written every morning: Lithuania, World, Ongoing stories, and Interesting (AI, tech, design, sports, events in Vilnius).

## How it works

1. **Fetch**: `generator/fetch.py` reads ~22 RSS feeds (LRT, 15min, Delfi, BBC, Guardian, Al Jazeera, Reuters and AP via Google News, TechCrunch, Dezeen…) and the bilietai.lt event listing. Sources live in `generator/sources.py`.
2. **Edit**: Claude groups duplicates, ranks stories by how many outlets cover them, and writes the brief as JSON. Yesterday's ongoing stories are passed in, so it only reports what changed. The editor rules and format live in `generator/editor.py`.
3. **Save**: `docs/brief.json` (latest) and `docs/archive/YYYY-MM-DD.json`. `docs/index.html` displays it; the iPhone app will read the same JSON.

## Who runs it

- **Daily (default): a Claude Code routine** on the Claude plan, every day at 09:00 Vilnius time (10:00 in summer). It runs `main.py --dry-run`, writes `out/draft.json` from `out/editor-task.md`, runs `main.py --articles out/draft.json` and rewrites the summaries from the full articles in `out/articles.md`, publishes with `main.py --from-draft out/draft.json` (which rejects a malformed draft), and pushes `docs/` to `main`. It runs in the "Daily brief" cloud environment, whose network allowlist must include every feed, article, event and weather domain. Manage it at claude.ai/code/routines.
- **Backup: "Brief via API (manual backup)"** in GitHub Actions writes the brief through the paid API (`ANTHROPIC_API_KEY` secret).
- **Notify** runs on every new `docs/brief.json` and sends an ntfy notification if `NTFY_TOPIC` is set.

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

The routine uses the Claude plan's usage, not API credit. A manual API run costs about $0.20–0.30 on Claude Opus 5.5.
