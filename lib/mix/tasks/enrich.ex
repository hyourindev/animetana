defmodule Mix.Tasks.Enrich do
  @moduledoc """
  AI enrichment pipeline for anime and manga records.

  Uses Gemini 3 Flash via Vercel AI Gateway to generate:
  - Japanese synopsis translation
  - Mood tags, content warnings, pacing
  - Art style descriptions
  - Target audience classification
  - Fun facts and similar titles
  - Sub-genre assignments

  ## Usage

      # Enrich all unenriched anime
      mix enrich anime

      # Enrich all unenriched manga
      mix enrich manga

      # Test with a limited number of rows
      mix enrich anime --limit 5

      # Custom batch size
      mix enrich anime --batch-size 10

  ## Requirements

  Set the VERCEL_AI_GATEWAY_TOKEN environment variable:

      export VERCEL_AI_GATEWAY_TOKEN=your_token_here

  ## Resume

  Safe to re-run. Only processes rows where `enriched != true` and `synopsis` is present.
  """

  use Mix.Task

  @shortdoc "Enrich anime/manga with AI-generated metadata"

  @impl Mix.Task
  def run(args) do
    {opts, positional, _} =
      OptionParser.parse(args,
        strict: [limit: :integer, batch_size: :integer, delay: :integer],
        aliases: [l: :limit, b: :batch_size, d: :delay]
      )

    type =
      case positional do
        ["anime"] -> :anime
        ["manga"] -> :manga
        _ ->
          Mix.shell().error("Usage: mix enrich <anime|manga> [--limit N] [--batch-size N]")
          exit({:shutdown, 1})
      end

    # Start the application so Repo and config are available
    Mix.Task.run("app.start")

    pipeline_opts =
      []
      |> maybe_put(:limit, opts[:limit])
      |> maybe_put(:batch_size, opts[:batch_size])
      |> maybe_put(:delay_ms, opts[:delay])

    Yunaos.Enrichment.Pipeline.run(type, pipeline_opts)
    Mix.shell().info("Enrichment complete.")
  end

  defp maybe_put(opts, _key, nil), do: opts
  defp maybe_put(opts, key, value), do: Keyword.put(opts, key, value)
end
