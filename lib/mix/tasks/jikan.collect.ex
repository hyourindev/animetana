defmodule Mix.Tasks.Jikan.Collect do
  @moduledoc """
  Starts the Jikan data collection process.

  ## Usage

      mix jikan.collect          # Start/resume collection (stays in foreground)
      mix jikan.collect --status # Query DB for job status (no collection started)
      mix jikan.collect --retry  # Reset failed jobs and start collection
  """

  use Mix.Task

  @shortdoc "Runs the Jikan data collection"

  @impl Mix.Task
  def run(args) do
    if "--status" in args do
      # Status-only: start just the repo, don't start the full app
      {:ok, _} = Application.ensure_all_started(:postgrex)
      {:ok, _} = Application.ensure_all_started(:ecto_sql)
      _ = Yunaos.Repo.start_link()

      print_db_status()
    else
      # Full app start for collection
      Mix.Task.run("app.start")

      if "--retry" in args do
        retry_and_start()
      else
        start_and_monitor()
      end
    end
  end

  defp start_and_monitor do
    case Yunaos.Jikan.Orchestrator.start_collection() do
      :ok ->
        IO.puts("Collection started. Monitoring progress...\n")
        monitor_loop()

      {:error, :already_running} ->
        IO.puts("Collection is already running.\n")
        monitor_loop()
    end
  end

  defp retry_and_start do
    case Yunaos.Jikan.Orchestrator.retry_failed() do
      {:ok, 0} ->
        IO.puts("No failed jobs to retry.")
        start_and_monitor()

      {:ok, count} ->
        IO.puts("Reset #{count} failed job(s). Starting collection...\n")
        start_and_monitor()

      {:error, :collection_running} ->
        IO.puts("Cannot retry while collection is running.\n")
        monitor_loop()
    end
  end

  defp monitor_loop do
    Process.sleep(30_000)
    status = Yunaos.Jikan.Orchestrator.status()

    IO.puts(
      "[#{status.status}] #{status.completed_count}/#{status.total_jobs} jobs completed | " <>
        "current: #{status.current_job || "none"} | failed: #{status.failed_count}"
    )

    if status.status == :running do
      monitor_loop()
    else
      IO.puts("\nCollection finished.")

      if status.failed_count > 0 do
        IO.puts("Failed jobs: #{inspect(status.failed_jobs)}")
        IO.puts("\nTo retry: mix jikan.collect --retry")
      end
    end
  end

  # Query the DB directly for status without starting the orchestrator
  defp print_db_status do
    import Ecto.Query

    total = length(Yunaos.Jikan.CollectionStrategy.all_jobs())

    rows =
      from(j in "jikan_job_runs",
        select: %{
          job_id: j.job_id,
          status: j.status,
          started_at: j.started_at,
          completed_at: j.completed_at,
          error_message: j.error_message
        },
        order_by: j.id
      )
      |> Yunaos.Repo.all()

    completed = Enum.count(rows, &(&1.status == "completed"))
    skipped = Enum.count(rows, &(&1.status == "skipped"))
    running = Enum.count(rows, &(&1.status == "running"))
    failed = Enum.count(rows, &(&1.status == "failed"))
    pending = total - completed - skipped - running - failed

    IO.puts("""
    Completed:  #{completed}/#{total}
    Skipped:    #{skipped}
    Running:    #{running}
    Failed:     #{failed}
    Pending:    #{pending}
    """)

    if rows != [] do
      IO.puts("Job details:")

      Enum.each(rows, fn row ->
        icon =
          case row.status do
            "completed" -> "[OK]"
            "skipped" -> "[--]"
            "running" -> "[..]"
            "failed" -> "[!!]"
            _ -> "[  ]"
          end

        extra =
          case row.status do
            "failed" -> " -- #{row.error_message}"
            "skipped" -> " (skipped, use retry_skipped to re-run)"
            "completed" when row.error_message != nil -> " (partial: #{row.error_message})"
            _ -> ""
          end

        IO.puts("  #{icon} #{row.job_id}#{extra}")
      end)
    end
  end
end
