# Yunaos

## Prerequisites

- Elixir >= 1.15
- Docker & Docker Compose

## Getting Started

Start the infrastructure (Postgres + MinIO):

```bash
docker compose up -d
```

Install dependencies:

```bash
mix deps.get
```

Create the database and run migrations:

```bash
mix ecto.create
mix ecto.migrate
```

Start the server:

```bash
mix phx.server
```

Or inside IEx:

```bash
iex -S mix phx.server
```

Visit [localhost:4000](http://localhost:4000).

## Development Tools

- Live Dashboard: [localhost:4000/dev/dashboard](http://localhost:4000/dev/dashboard)
- Mailbox (dev emails): [localhost:4000/dev/mailbox](http://localhost:4000/dev/mailbox)
- MinIO Console: [localhost:9001](http://localhost:9001) (minioadmin / minioadmin)

## Jikan Data Collection

Populates the database with anime, manga, characters, and people data from the [Jikan API](https://jikan.moe/) (unofficial MyAnimeList API). The process runs ~1.1M API requests at ~1 req/sec, taking roughly 12-13 days to complete. It survives app restarts — progress is persisted to the database.

### Start collection

```bash
mix jikan.collect
```

Starts (or resumes) the collection process and stays in the foreground, printing progress every 30 seconds. Safe to Ctrl+C and restart later — it picks up where it left off.

### Check status

From a separate terminal (does not affect the running collection):

```bash
mix jikan.collect --status
```

Shows completed, skipped, running, failed, and pending job counts with per-job details.

### Retry failed jobs

```bash
mix jikan.collect --retry
```

Resets all failed jobs and starts collection again.

### IEx commands

From a running IEx session (`iex -S mix`):

```elixir
# Start or resume collection
Yunaos.Jikan.Orchestrator.start_collection()

# Check current status
Yunaos.Jikan.Orchestrator.status()

# Skip a stuck job (allows downstream jobs to proceed)
Yunaos.Jikan.Orchestrator.skip_job(:anime_episodes)

# Re-run skipped jobs later
Yunaos.Jikan.Orchestrator.retry_skipped()

# Reset failed jobs for retry
Yunaos.Jikan.Orchestrator.retry_failed()
```

### Collection phases

Jobs run one at a time in dependency order across 6 phases:

1. **Taxonomy** — genres, studios, people, magazines
2. **Catalogs** — anime, manga, characters (paginated search)
3. **Anime enrichment** — full details, characters, staff, relations, episodes, statistics, pictures, moreinfo
4. **Manga enrichment** — full details, characters, relations, statistics, pictures, moreinfo
5. **Character & people enrichment** — full profiles, voices, works, pictures
6. **Community** — reviews, recommendations, news

If a job crashes, partial work is preserved (all writes are upserts) and downstream jobs continue. Use `skip_job/1` to manually skip a problematic job, and `retry_skipped/0` to come back to it later.

## Running Tests

```bash
mix test
```
