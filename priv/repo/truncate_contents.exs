alias Yunaos.Repo

# Truncate all contents tables
Repo.query!("TRUNCATE TABLE contents.anime, contents.manga, contents.genres, contents.characters, contents.people, contents.studios, contents.tags, contents.demographics CASCADE")

IO.puts("All contents tables cleared!")
