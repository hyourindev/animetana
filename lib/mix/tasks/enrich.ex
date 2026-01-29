defmodule Mix.Tasks.Enrich do
  @moduledoc """
  AI enrichment for anime, manga, and characters.

  ## Usage

      mix enrich stats           # Show stats
      mix enrich anime           # Enrich all anime
      mix enrich anime 100       # Enrich 100 anime
      mix enrich manga           # Enrich all manga
      mix enrich manga 100       # Enrich 100 manga
      mix enrich characters      # Enrich all characters
      mix enrich characters 100  # Enrich 100 characters
      mix enrich full            # Enrich everything
      mix enrich reset anime     # Reset errors for anime
  """

  use Mix.Task

  require Logger

  alias Animetana.Enrichment.Orchestrator

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.start")

    case args do
      ["stats"] ->
        Orchestrator.stats()

      ["anime"] ->
        run_with_result(fn -> Orchestrator.enrich_anime() end)

      ["anime", limit] ->
        run_with_result(fn -> Orchestrator.enrich_anime(limit: parse_int(limit)) end)

      ["manga"] ->
        run_with_result(fn -> Orchestrator.enrich_manga() end)

      ["manga", limit] ->
        run_with_result(fn -> Orchestrator.enrich_manga(limit: parse_int(limit)) end)

      ["characters"] ->
        run_with_result(fn -> Orchestrator.enrich_characters() end)

      ["characters", limit] ->
        run_with_result(fn -> Orchestrator.enrich_characters(limit: parse_int(limit)) end)

      ["full"] ->
        run_with_result(fn -> Orchestrator.full_enrich() end)

      ["full", limit] ->
        run_with_result(fn -> Orchestrator.full_enrich(limit: parse_int(limit)) end)

      ["reset", type] ->
        reset_errors(type)

      _ ->
        print_usage()
    end
  end

  defp parse_int(str), do: String.to_integer(str)

  defp run_with_result(fun) do
    case fun.() do
      {:ok, result} ->
        IO.puts("\n[OK] Done: #{inspect(result)}")

      {:error, reason} ->
        IO.puts("\n[ERROR] #{inspect(reason)}")
    end
  end

  defp reset_errors(type) when type in ["anime", "manga", "characters"] do
    import Ecto.Query

    {count, _} =
      from(t in type, prefix: "contents", where: not is_nil(t.enrichment_error))
      |> Animetana.Repo.update_all(set: [enrichment_error: nil, enrichment_status: 0])

    IO.puts("Reset #{count} entries for #{type}")
  end

  defp reset_errors(_), do: IO.puts("Invalid type. Use: anime, manga, or characters")

  defp print_usage do
    IO.puts("""
    Usage:
      mix enrich stats           # Show enrichment stats
      mix enrich anime           # Enrich all anime
      mix enrich anime 100       # Enrich 100 anime
      mix enrich manga           # Enrich all manga
      mix enrich manga 100       # Enrich 100 manga
      mix enrich characters      # Enrich all characters
      mix enrich characters 100  # Enrich 100 characters
      mix enrich full            # Enrich everything
      mix enrich reset anime     # Reset errors for anime
    """)
  end
end
