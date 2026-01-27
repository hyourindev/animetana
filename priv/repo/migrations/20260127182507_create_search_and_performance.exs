defmodule Yunaos.Repo.Migrations.CreateSearchAndPerformance do
  use Ecto.Migration

  def change do
    # ── Full-text search indexes ──
    create index(:anime, [:search_vector], using: "GIN")
    create index(:manga, [:search_vector], using: "GIN")

    # ── Trigram indexes for fuzzy title matching ──
    execute(
      "CREATE INDEX idx_anime_title_trgm ON anime USING gin(title gin_trgm_ops)",
      "DROP INDEX IF EXISTS idx_anime_title_trgm"
    )

    execute(
      "CREATE INDEX idx_anime_title_en_trgm ON anime USING gin(title_english gin_trgm_ops)",
      "DROP INDEX IF EXISTS idx_anime_title_en_trgm"
    )

    execute(
      "CREATE INDEX idx_manga_title_trgm ON manga USING gin(title gin_trgm_ops)",
      "DROP INDEX IF EXISTS idx_manga_title_trgm"
    )

    execute(
      "CREATE INDEX idx_manga_title_en_trgm ON manga USING gin(title_english gin_trgm_ops)",
      "DROP INDEX IF EXISTS idx_manga_title_en_trgm"
    )

    # ── Content classification indexes ──
    create index(:anime, [:type, :status])
    create index(:anime, [:season_year, :season])
    create index(:anime, [:start_date])
    create index(:manga, [:type, :status])

    # ── Rating and popularity indexes ──
    execute(
      "CREATE INDEX idx_anime_mal_score ON anime(mal_score DESC NULLS LAST)",
      "DROP INDEX IF EXISTS idx_anime_mal_score"
    )

    create index(:anime, [:average_rating])
    create index(:anime, [:mal_popularity])

    execute(
      "CREATE INDEX idx_manga_mal_score ON manga(mal_score DESC NULLS LAST)",
      "DROP INDEX IF EXISTS idx_manga_mal_score"
    )

    create index(:manga, [:average_rating])

    # ── User list score index ──
    execute(
      "CREATE INDEX idx_user_anime_lists_score ON user_anime_lists(user_id, score DESC)",
      "DROP INDEX IF EXISTS idx_user_anime_lists_score"
    )

    # ── External ID indexes for API sync ──
    execute(
      "CREATE INDEX idx_people_mal_id ON people(mal_id) WHERE mal_id IS NOT NULL",
      "DROP INDEX IF EXISTS idx_people_mal_id"
    )

    execute(
      "CREATE INDEX idx_characters_mal_id ON characters(mal_id) WHERE mal_id IS NOT NULL",
      "DROP INDEX IF EXISTS idx_characters_mal_id"
    )

    # ── Search vector update functions and triggers ──
    execute(
      """
      CREATE OR REPLACE FUNCTION update_anime_search_vector() RETURNS trigger AS $$
      BEGIN
          NEW.search_vector :=
              setweight(to_tsvector('english', COALESCE(NEW.title, '')), 'A') ||
              setweight(to_tsvector('english', COALESCE(NEW.title_english, '')), 'A') ||
              setweight(to_tsvector('english', COALESCE(NEW.title_romaji, '')), 'B') ||
              setweight(to_tsvector('english', COALESCE(array_to_string(NEW.title_synonyms, ' '), '')), 'B') ||
              setweight(to_tsvector('english', COALESCE(NEW.synopsis, '')), 'C');
          RETURN NEW;
      END;
      $$ LANGUAGE plpgsql
      """,
      "DROP FUNCTION IF EXISTS update_anime_search_vector()"
    )

    execute(
      """
      CREATE OR REPLACE FUNCTION update_manga_search_vector() RETURNS trigger AS $$
      BEGIN
          NEW.search_vector :=
              setweight(to_tsvector('english', COALESCE(NEW.title, '')), 'A') ||
              setweight(to_tsvector('english', COALESCE(NEW.title_english, '')), 'A') ||
              setweight(to_tsvector('english', COALESCE(NEW.title_romaji, '')), 'B') ||
              setweight(to_tsvector('english', COALESCE(array_to_string(NEW.title_synonyms, ' '), '')), 'B') ||
              setweight(to_tsvector('english', COALESCE(NEW.synopsis, '')), 'C');
          RETURN NEW;
      END;
      $$ LANGUAGE plpgsql
      """,
      "DROP FUNCTION IF EXISTS update_manga_search_vector()"
    )

    # ── Triggers for automatic search vector updates ──
    execute(
      """
      CREATE TRIGGER anime_search_vector_update_trigger
          BEFORE INSERT OR UPDATE ON anime
          FOR EACH ROW EXECUTE FUNCTION update_anime_search_vector()
      """,
      "DROP TRIGGER IF EXISTS anime_search_vector_update_trigger ON anime"
    )

    execute(
      """
      CREATE TRIGGER manga_search_vector_update_trigger
          BEFORE INSERT OR UPDATE ON manga
          FOR EACH ROW EXECUTE FUNCTION update_manga_search_vector()
      """,
      "DROP TRIGGER IF EXISTS manga_search_vector_update_trigger ON manga"
    )

    # ── View for anime with aggregated stats ──
    execute(
      """
      CREATE VIEW anime_with_stats AS
      SELECT
          a.*,
          COALESCE(stats.watching_count, 0) as stat_watching_count,
          COALESCE(stats.completed_count, 0) as stat_completed_count,
          COALESCE(stats.plan_to_watch_count, 0) as stat_plan_to_watch_count,
          COALESCE(stats.dropped_count, 0) as dropped_count,
          COALESCE(stats.on_hold_count, 0) as on_hold_count,
          COALESCE(stats.total_members, 0) as total_members,
          COALESCE(stats.average_user_score, 0) as average_user_score
      FROM anime a
      LEFT JOIN (
          SELECT
              anime_id,
              COUNT(CASE WHEN status = 'watching' THEN 1 END) as watching_count,
              COUNT(CASE WHEN status = 'completed' THEN 1 END) as completed_count,
              COUNT(CASE WHEN status = 'plan_to_watch' THEN 1 END) as plan_to_watch_count,
              COUNT(CASE WHEN status = 'dropped' THEN 1 END) as dropped_count,
              COUNT(CASE WHEN status = 'on_hold' THEN 1 END) as on_hold_count,
              COUNT(*) as total_members,
              AVG(CASE WHEN score > 0 THEN score END) as average_user_score
          FROM user_anime_lists
          GROUP BY anime_id
      ) stats ON a.id = stats.anime_id
      """,
      "DROP VIEW IF EXISTS anime_with_stats"
    )
  end
end
