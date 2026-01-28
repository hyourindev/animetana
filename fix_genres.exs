import Ecto.Query

now = DateTime.utc_now() |> DateTime.truncate(:second)

from(j in "jikan_job_runs",
  where: j.job_id in ["genres", "studios", "people_basic", "magazines"]
)
|> Yunaos.Repo.update_all(
  set: [status: "completed", completed_at: now]
)

from(j in "jikan_job_runs",
  where: j.job_id not in ["genres", "studios", "people_basic", "magazines"]
)
|> Yunaos.Repo.delete_all()

rows =
  from(j in "jikan_job_runs",
    select: {j.job_id, j.status},
    order_by: j.id
  )
  |> Yunaos.Repo.all()

Enum.each(rows, fn {id, status} ->
  IO.puts("  #{id}: #{status}")
end)

IO.puts("\nPhase 1 kept. Everything else reset.")