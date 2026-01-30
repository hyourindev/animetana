alias Animetana.Repo

{:ok, result} = Repo.query("SELECT column_name FROM information_schema.columns WHERE table_schema = 'contents' AND table_name = 'anime' ORDER BY ordinal_position")

IO.puts("Columns in contents.anime:")
Enum.each(result.rows, fn [col] -> IO.puts("  #{col}") end)
