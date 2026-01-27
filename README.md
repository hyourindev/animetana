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

## Running Tests

```bash
mix test
```
