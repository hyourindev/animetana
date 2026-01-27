defmodule Yunaos.Jikan.CollectionStrategyTest do
  use ExUnit.Case, async: true

  alias Yunaos.Jikan.CollectionStrategy

  # ---------------------------------------------------------------------------
  # all_jobs/0
  # ---------------------------------------------------------------------------

  describe "all_jobs/0" do
    test "returns a non-empty list of jobs" do
      jobs = CollectionStrategy.all_jobs()
      assert is_list(jobs)
      assert length(jobs) > 0
    end

    test "every job has required keys" do
      required_keys = [:id, :phase, :name, :description, :endpoints, :estimated_requests, :dependencies]

      for job <- CollectionStrategy.all_jobs() do
        for key <- required_keys do
          assert Map.has_key?(job, key),
            "Job #{inspect(job.id)} is missing required key #{inspect(key)}"
        end
      end
    end

    test "every job id is an atom" do
      for job <- CollectionStrategy.all_jobs() do
        assert is_atom(job.id), "Job id #{inspect(job.id)} should be an atom"
      end
    end

    test "every job phase is an integer between 1 and 6" do
      for job <- CollectionStrategy.all_jobs() do
        assert job.phase in 1..6,
          "Job #{inspect(job.id)} has invalid phase #{inspect(job.phase)}"
      end
    end

    test "every job has a non-empty name and description" do
      for job <- CollectionStrategy.all_jobs() do
        assert is_binary(job.name) and byte_size(job.name) > 0,
          "Job #{inspect(job.id)} has invalid name"
        assert is_binary(job.description) and byte_size(job.description) > 0,
          "Job #{inspect(job.id)} has invalid description"
      end
    end

    test "every job has at least one endpoint" do
      for job <- CollectionStrategy.all_jobs() do
        assert is_list(job.endpoints) and length(job.endpoints) > 0,
          "Job #{inspect(job.id)} must have at least one endpoint"
      end
    end

    test "every job has a positive estimated_requests" do
      for job <- CollectionStrategy.all_jobs() do
        assert is_integer(job.estimated_requests) and job.estimated_requests > 0,
          "Job #{inspect(job.id)} must have positive estimated_requests"
      end
    end

    test "every job has a list of dependencies" do
      for job <- CollectionStrategy.all_jobs() do
        assert is_list(job.dependencies),
          "Job #{inspect(job.id)} dependencies must be a list"
      end
    end
  end

  # ---------------------------------------------------------------------------
  # No duplicate IDs
  # ---------------------------------------------------------------------------

  describe "job ID uniqueness" do
    test "no duplicate job IDs exist" do
      ids = Enum.map(CollectionStrategy.all_jobs(), & &1.id)
      unique_ids = Enum.uniq(ids)

      duplicates = ids -- unique_ids

      assert duplicates == [],
        "Found duplicate job IDs: #{inspect(duplicates)}"
    end
  end

  # ---------------------------------------------------------------------------
  # Dependency integrity
  # ---------------------------------------------------------------------------

  describe "dependency integrity" do
    test "all dependency references point to valid job IDs" do
      valid_ids = MapSet.new(CollectionStrategy.all_jobs(), & &1.id)

      for job <- CollectionStrategy.all_jobs(), dep <- job.dependencies do
        assert MapSet.member?(valid_ids, dep),
          "Job #{inspect(job.id)} depends on #{inspect(dep)} which does not exist"
      end
    end

    test "no job depends on itself" do
      for job <- CollectionStrategy.all_jobs() do
        refute job.id in job.dependencies,
          "Job #{inspect(job.id)} has a self-dependency"
      end
    end

    test "dependencies only reference jobs from earlier or same phases" do
      job_phases = Map.new(CollectionStrategy.all_jobs(), fn job -> {job.id, job.phase} end)

      for job <- CollectionStrategy.all_jobs(), dep <- job.dependencies do
        dep_phase = Map.get(job_phases, dep)

        assert dep_phase <= job.phase,
          "Job #{inspect(job.id)} (phase #{job.phase}) depends on " <>
            "#{inspect(dep)} (phase #{dep_phase}) which is in a later phase"
      end
    end
  end

  # ---------------------------------------------------------------------------
  # jobs_for_phase/1
  # ---------------------------------------------------------------------------

  describe "jobs_for_phase/1" do
    test "returns jobs for each phase 1 through 6" do
      for phase <- 1..6 do
        jobs = CollectionStrategy.jobs_for_phase(phase)
        assert is_list(jobs), "Phase #{phase} should return a list"
        assert length(jobs) > 0, "Phase #{phase} should have at least one job"

        for job <- jobs do
          assert job.phase == phase,
            "Job #{inspect(job.id)} returned for phase #{phase} but has phase #{job.phase}"
        end
      end
    end

    test "phase 1 jobs have no dependencies" do
      for job <- CollectionStrategy.jobs_for_phase(1) do
        assert job.dependencies == [],
          "Phase 1 job #{inspect(job.id)} should have no dependencies, got: #{inspect(job.dependencies)}"
      end
    end

    test "phase jobs are subsets of all_jobs" do
      all_ids = MapSet.new(CollectionStrategy.all_jobs(), & &1.id)

      for phase <- 1..6 do
        phase_ids = MapSet.new(CollectionStrategy.jobs_for_phase(phase), & &1.id)

        assert MapSet.subset?(phase_ids, all_ids),
          "Phase #{phase} contains IDs not in all_jobs"
      end
    end

    test "all phases together cover all jobs" do
      all_ids = MapSet.new(CollectionStrategy.all_jobs(), & &1.id)

      combined_ids =
        1..6
        |> Enum.flat_map(&CollectionStrategy.jobs_for_phase/1)
        |> MapSet.new(& &1.id)

      assert MapSet.equal?(all_ids, combined_ids),
        "Combining all phases should produce the same set as all_jobs/0"
    end

    test "phase numbers are sequential with no gaps" do
      phases =
        CollectionStrategy.all_jobs()
        |> Enum.map(& &1.phase)
        |> Enum.uniq()
        |> Enum.sort()

      assert phases == Enum.to_list(1..length(phases)),
        "Phase numbers should be sequential starting from 1, got: #{inspect(phases)}"
    end
  end

  # ---------------------------------------------------------------------------
  # get_job/1
  # ---------------------------------------------------------------------------

  describe "get_job/1" do
    test "finds a job by its ID" do
      job = CollectionStrategy.get_job(:genres)
      assert job != nil
      assert job.id == :genres
      assert job.phase == 1
    end

    test "returns nil for an unknown job ID" do
      assert CollectionStrategy.get_job(:nonexistent_job) == nil
    end

    test "can find every job from all_jobs by its ID" do
      for job <- CollectionStrategy.all_jobs() do
        found = CollectionStrategy.get_job(job.id)
        assert found != nil, "Could not find job #{inspect(job.id)} by ID"
        assert found.id == job.id
      end
    end
  end

  # ---------------------------------------------------------------------------
  # total_estimated_requests/0
  # ---------------------------------------------------------------------------

  describe "total_estimated_requests/0" do
    test "returns a positive integer" do
      total = CollectionStrategy.total_estimated_requests()
      assert is_integer(total)
      assert total > 0
    end

    test "equals the sum of all individual job estimated_requests" do
      manual_sum =
        CollectionStrategy.all_jobs()
        |> Enum.map(& &1.estimated_requests)
        |> Enum.sum()

      assert CollectionStrategy.total_estimated_requests() == manual_sum
    end
  end

  # ---------------------------------------------------------------------------
  # runnable_jobs/1
  # ---------------------------------------------------------------------------

  describe "runnable_jobs/1" do
    test "with empty completed set, returns only jobs with no dependencies" do
      runnable = CollectionStrategy.runnable_jobs([])

      for job <- runnable do
        assert job.dependencies == [],
          "Runnable job #{inspect(job.id)} has unsatisfied dependencies: #{inspect(job.dependencies)}"
      end

      # All phase 1 jobs should be runnable (they have no deps)
      phase_1_ids = MapSet.new(CollectionStrategy.jobs_for_phase(1), & &1.id)
      runnable_ids = MapSet.new(runnable, & &1.id)

      assert MapSet.subset?(phase_1_ids, runnable_ids),
        "All phase 1 jobs should be runnable with no completions"

      # characters_basic from phase 2 also has no dependencies
      assert MapSet.member?(runnable_ids, :characters_basic),
        "characters_basic (phase 2, no deps) should also be runnable"
    end

    test "excludes already-completed jobs" do
      completed = [:genres]
      runnable = CollectionStrategy.runnable_jobs(completed)
      runnable_ids = MapSet.new(runnable, & &1.id)

      refute MapSet.member?(runnable_ids, :genres),
        "Completed job :genres should not appear in runnable jobs"
    end

    test "with phase 1 completed, returns phase 2 jobs whose deps are satisfied" do
      phase_1_ids = Enum.map(CollectionStrategy.jobs_for_phase(1), & &1.id)
      runnable = CollectionStrategy.runnable_jobs(phase_1_ids)
      runnable_ids = MapSet.new(runnable, & &1.id)

      # anime_catalog depends on [:genres, :studios] -- both in phase 1
      assert MapSet.member?(runnable_ids, :anime_catalog),
        "anime_catalog should be runnable after phase 1 completion"

      # manga_catalog depends on [:genres] -- in phase 1
      assert MapSet.member?(runnable_ids, :manga_catalog),
        "manga_catalog should be runnable after phase 1 completion"
    end

    test "jobs with partially satisfied dependencies are not runnable" do
      # anime_characters depends on [:anime_catalog, :characters_basic, :people_basic]
      # Only completing anime_catalog should NOT make it runnable
      runnable = CollectionStrategy.runnable_jobs([:anime_catalog])
      runnable_ids = MapSet.new(runnable, & &1.id)

      refute MapSet.member?(runnable_ids, :anime_characters),
        "anime_characters should not be runnable with only :anime_catalog completed"
    end

    test "with all jobs completed, returns an empty list" do
      all_ids = Enum.map(CollectionStrategy.all_jobs(), & &1.id)
      runnable = CollectionStrategy.runnable_jobs(all_ids)

      assert runnable == [],
        "No jobs should be runnable when all are completed"
    end

    test "accepts MapSet-compatible input" do
      # The function converts the input to a MapSet, so lists should work
      runnable_from_list = CollectionStrategy.runnable_jobs([:genres])
      assert is_list(runnable_from_list)
    end
  end

  # ---------------------------------------------------------------------------
  # summary/0
  # ---------------------------------------------------------------------------

  describe "summary/0" do
    test "returns expected structure" do
      summary = CollectionStrategy.summary()

      assert is_map(summary)
      assert Map.has_key?(summary, :total_jobs)
      assert Map.has_key?(summary, :total_phases)
      assert Map.has_key?(summary, :total_estimated_requests)
      assert Map.has_key?(summary, :estimated_hours)
      assert Map.has_key?(summary, :phase_summary)
    end

    test "total_jobs matches length of all_jobs" do
      summary = CollectionStrategy.summary()
      assert summary.total_jobs == length(CollectionStrategy.all_jobs())
    end

    test "total_phases is 6" do
      assert CollectionStrategy.summary().total_phases == 6
    end

    test "total_estimated_requests matches the dedicated function" do
      summary = CollectionStrategy.summary()
      assert summary.total_estimated_requests == CollectionStrategy.total_estimated_requests()
    end

    test "estimated_hours is derived from total requests" do
      summary = CollectionStrategy.summary()
      expected_hours = div(CollectionStrategy.total_estimated_requests(), 3_600)
      assert summary.estimated_hours == expected_hours
    end

    test "phase_summary has one entry per phase" do
      summary = CollectionStrategy.summary()
      assert length(summary.phase_summary) == 6
    end

    test "phase_summary entries are {phase, job_count, request_count} tuples" do
      for {phase, job_count, request_count} <- CollectionStrategy.summary().phase_summary do
        assert phase in 1..6
        assert is_integer(job_count) and job_count > 0
        assert is_integer(request_count) and request_count > 0
      end
    end

    test "phase_summary job counts sum to total_jobs" do
      summary = CollectionStrategy.summary()

      total_from_phases =
        summary.phase_summary
        |> Enum.map(fn {_phase, count, _requests} -> count end)
        |> Enum.sum()

      assert total_from_phases == summary.total_jobs
    end

    test "phase_summary request counts sum to total_estimated_requests" do
      summary = CollectionStrategy.summary()

      total_from_phases =
        summary.phase_summary
        |> Enum.map(fn {_phase, _count, requests} -> requests end)
        |> Enum.sum()

      assert total_from_phases == summary.total_estimated_requests
    end
  end
end
