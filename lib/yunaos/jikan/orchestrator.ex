defmodule Yunaos.Jikan.Orchestrator do
  @moduledoc """
  Orchestrates the Jikan data collection process.

  Runs one job at a time in dependency order, persisting completion
  state to the `jikan_job_runs` table so collection survives app restarts.

  ## Usage

      Yunaos.Jikan.Orchestrator.start_collection()  # start or resume
      Yunaos.Jikan.Orchestrator.status()             # current state
      Yunaos.Jikan.Orchestrator.skip_job(:job_id)    # skip a job (can revisit later)
      Yunaos.Jikan.Orchestrator.retry_failed()       # reset failed jobs
      Yunaos.Jikan.Orchestrator.retry_skipped()      # reset skipped jobs for re-run
  """

  use GenServer

  require Logger

  alias Yunaos.Repo
  alias Yunaos.Jikan.{CollectionStrategy, JobRun, WorkerRegistry}

  import Ecto.Query

  # ---------------------------------------------------------------------------
  # Client API
  # ---------------------------------------------------------------------------

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc "Begins the collection process. No-op if already running."
  def start_collection do
    GenServer.call(__MODULE__, :start_collection)
  end

  @doc "Returns current orchestrator status."
  def status do
    GenServer.call(__MODULE__, :status)
  end

  @doc "Resets failed jobs so they can be retried on next start."
  def retry_failed do
    GenServer.call(__MODULE__, :retry_failed)
  end

  @doc "Resets skipped jobs so they will be re-run on next start."
  def retry_skipped do
    GenServer.call(__MODULE__, :retry_skipped)
  end

  @doc """
  Manually skips a job. The job is marked as "skipped" in the DB so
  downstream jobs can proceed. Use `retry_skipped/0` later to re-run them.
  """
  def skip_job(job_id) when is_atom(job_id) do
    GenServer.call(__MODULE__, {:skip_job, job_id})
  end

  # ---------------------------------------------------------------------------
  # Server Callbacks
  # ---------------------------------------------------------------------------

  @impl true
  def init(_opts) do
    completed = load_done_jobs()

    # Reset any "running" jobs left over from a previous crash
    from(j in JobRun, where: j.status == "running")
    |> Repo.update_all(set: [status: "pending"])

    state = %{
      status: :idle,
      completed_jobs: completed,
      failed_jobs: MapSet.new(),
      current_job: nil,
      current_task: nil,
      started_at: nil
    }

    Logger.info(
      "[Orchestrator] Initialized with #{MapSet.size(completed)} done jobs"
    )

    {:ok, state}
  end

  @impl true
  def handle_call(:start_collection, _from, %{status: :running} = state) do
    {:reply, {:error, :already_running}, state}
  end

  def handle_call(:start_collection, _from, state) do
    Logger.info("[Orchestrator] Starting collection run")

    new_state = %{
      state
      | status: :running,
        failed_jobs: MapSet.new(),
        started_at: DateTime.utc_now()
    }

    send(self(), :dispatch_next)
    {:reply, :ok, new_state}
  end

  def handle_call(:status, _from, state) do
    total = length(CollectionStrategy.all_jobs())

    skipped_count =
      from(j in JobRun, where: j.status == "skipped", select: count(j.id))
      |> Repo.one()

    reply = %{
      status: state.status,
      current_job: state.current_job,
      completed_count: MapSet.size(state.completed_jobs),
      failed_count: MapSet.size(state.failed_jobs),
      skipped_count: skipped_count,
      total_jobs: total,
      completed_jobs: state.completed_jobs |> MapSet.to_list() |> Enum.sort(),
      failed_jobs: state.failed_jobs |> MapSet.to_list() |> Enum.sort(),
      started_at: state.started_at
    }

    {:reply, reply, state}
  end

  def handle_call(:retry_failed, _from, %{status: :running} = state) do
    {:reply, {:error, :collection_running}, state}
  end

  def handle_call(:retry_failed, _from, state) do
    failed_ids =
      from(j in JobRun, where: j.status == "failed", select: j.job_id)
      |> Repo.all()

    if failed_ids == [] do
      {:reply, {:ok, 0}, state}
    else
      from(j in JobRun, where: j.status == "failed")
      |> Repo.delete_all()

      Logger.info("[Orchestrator] Reset #{length(failed_ids)} failed jobs for retry")
      {:reply, {:ok, length(failed_ids)}, %{state | failed_jobs: MapSet.new()}}
    end
  end

  def handle_call(:retry_skipped, _from, %{status: :running} = state) do
    {:reply, {:error, :collection_running}, state}
  end

  def handle_call(:retry_skipped, _from, state) do
    skipped =
      from(j in JobRun, where: j.status == "skipped", select: j.job_id)
      |> Repo.all()

    if skipped == [] do
      {:reply, {:ok, 0}, state}
    else
      from(j in JobRun, where: j.status == "skipped")
      |> Repo.delete_all()

      # Remove skipped jobs from the completed set so they become runnable again
      skipped_atoms = Enum.map(skipped, &String.to_existing_atom/1) |> MapSet.new()
      new_completed = MapSet.difference(state.completed_jobs, skipped_atoms)

      Logger.info("[Orchestrator] Reset #{length(skipped)} skipped jobs for re-run")
      {:reply, {:ok, length(skipped)}, %{state | completed_jobs: new_completed}}
    end
  end

  def handle_call({:skip_job, job_id}, _from, state) do
    record_job_skipped(job_id)
    new_completed = MapSet.put(state.completed_jobs, job_id)
    Logger.info("[Orchestrator] Skipped job: #{job_id} (use retry_skipped/0 to re-run later)")
    {:reply, :ok, %{state | completed_jobs: new_completed}}
  end

  @impl true
  def handle_info(:dispatch_next, state) do
    completed_list = MapSet.to_list(state.completed_jobs)

    # Get jobs whose dependencies are all satisfied (completed or skipped)
    runnable = CollectionStrategy.runnable_jobs(completed_list)

    # Filter out jobs that already failed in this run
    runnable = Enum.reject(runnable, fn job -> job.id in state.failed_jobs end)

    case runnable do
      [] ->
        failed_count = MapSet.size(state.failed_jobs)
        completed_count = MapSet.size(state.completed_jobs)

        if failed_count > 0 do
          Logger.warning(
            "[Orchestrator] Collection paused — #{completed_count} done, " <>
              "#{failed_count} failed. Use retry_failed/0 then start_collection/0 to resume."
          )
        else
          Logger.info(
            "[Orchestrator] Collection finished — #{completed_count} jobs done"
          )
        end

        {:noreply, %{state | status: :finished, current_job: nil, current_task: nil}}

      [next_job | _] ->
        job_id = next_job.id

        Logger.info(
          "[Orchestrator] Dispatching job: #{job_id} (Phase #{next_job.phase} — #{next_job.name})"
        )

        record_job_start(job_id)

        task = Task.async(fn -> run_worker(job_id) end)

        {:noreply, %{state | current_job: job_id, current_task: task.ref}}
    end
  end

  # Task completed successfully
  def handle_info({ref, result}, %{current_task: ref} = state) do
    Process.demonitor(ref, [:flush])
    job_id = state.current_job

    case result do
      :ok ->
        handle_job_success(job_id, state)

      {:ok, _} ->
        handle_job_success(job_id, state)

      {:error, reason} ->
        handle_job_failure(job_id, inspect(reason), state)
    end
  end

  # Task crashed — workers are idempotent (upserts), so partial work is saved.
  # Mark as completed with a warning so downstream jobs can proceed.
  # The worker can be re-run later via retry_skipped if needed.
  def handle_info({:DOWN, ref, :process, _pid, reason}, %{current_task: ref} = state) do
    job_id = state.current_job

    Logger.warning(
      "[Orchestrator] Job #{job_id} crashed but partial work is saved (upserts are idempotent): #{inspect(reason)}"
    )

    record_job_complete(job_id, "crashed: #{inspect(reason)}")
    new_completed = MapSet.put(state.completed_jobs, job_id)

    send(self(), :dispatch_next)

    {:noreply,
     %{state | completed_jobs: new_completed, current_job: nil, current_task: nil}}
  end

  def handle_info(_msg, state) do
    {:noreply, state}
  end

  # ---------------------------------------------------------------------------
  # Private
  # ---------------------------------------------------------------------------

  defp handle_job_success(job_id, state) do
    Logger.info("[Orchestrator] Job #{job_id} completed successfully")
    record_job_complete(job_id)
    new_completed = MapSet.put(state.completed_jobs, job_id)

    send(self(), :dispatch_next)

    {:noreply,
     %{state | completed_jobs: new_completed, current_job: nil, current_task: nil}}
  end

  defp handle_job_failure(job_id, reason, state) do
    Logger.error("[Orchestrator] Job #{job_id} failed: #{reason}")
    record_job_failed(job_id, reason)
    new_failed = MapSet.put(state.failed_jobs, job_id)

    send(self(), :dispatch_next)

    {:noreply,
     %{state | failed_jobs: new_failed, current_job: nil, current_task: nil}}
  end

  defp run_worker(job_id) do
    worker = WorkerRegistry.worker_for(job_id)
    worker.run()
  end

  # Load jobs that count as "done" for dependency purposes:
  # both "completed" and "skipped" allow downstream jobs to proceed.
  defp load_done_jobs do
    from(j in JobRun, where: j.status in ["completed", "skipped"], select: j.job_id)
    |> Repo.all()
    |> Enum.map(&String.to_existing_atom/1)
    |> MapSet.new()
  rescue
    _ ->
      Logger.warning("[Orchestrator] Could not load jobs from DB (table may not exist yet)")
      MapSet.new()
  end

  defp record_job_start(job_id) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)
    job_id_str = Atom.to_string(job_id)

    case Repo.get_by(JobRun, job_id: job_id_str) do
      nil ->
        %JobRun{}
        |> JobRun.changeset(%{job_id: job_id_str, status: "running", started_at: now})
        |> Repo.insert!()

      existing ->
        existing
        |> JobRun.changeset(%{status: "running", started_at: now, error_message: nil})
        |> Repo.update!()
    end
  end

  defp record_job_complete(job_id, error_message \\ nil) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)
    job_id_str = Atom.to_string(job_id)

    from(j in JobRun, where: j.job_id == ^job_id_str)
    |> Repo.update_all(
      set: [status: "completed", completed_at: now, error_message: error_message, updated_at: now]
    )
  end

  defp record_job_skipped(job_id) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)
    job_id_str = Atom.to_string(job_id)

    case Repo.get_by(JobRun, job_id: job_id_str) do
      nil ->
        %JobRun{}
        |> JobRun.changeset(%{job_id: job_id_str, status: "skipped", started_at: now, completed_at: now})
        |> Repo.insert!()

      existing ->
        existing
        |> JobRun.changeset(%{status: "skipped", completed_at: now})
        |> Repo.update!()
    end
  end

  defp record_job_failed(job_id, error_message) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)
    job_id_str = Atom.to_string(job_id)

    from(j in JobRun, where: j.job_id == ^job_id_str)
    |> Repo.update_all(
      set: [status: "failed", completed_at: now, error_message: error_message, updated_at: now]
    )
  end
end
