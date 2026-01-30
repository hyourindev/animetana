defmodule Animetana.Contents do
  @moduledoc """
  The Contents context for anime, manga, and related data.
  """

  import Ecto.Query
  alias Animetana.Repo
  alias Animetana.Contents.{Anime, Tag}

  @doc """
  Returns the current season based on the current date.
  """
  def current_season do
    today = Date.utc_today()
    {season_for_month(today.month), today.year}
  end

  defp season_for_month(month) when month in [1, 2, 3], do: "winter"
  defp season_for_month(month) when month in [4, 5, 6], do: "spring"
  defp season_for_month(month) when month in [7, 8, 9], do: "summer"
  defp season_for_month(month) when month in [10, 11, 12], do: "fall"

  @doc """
  Returns the last N seasons including the current one.
  Returns a list of {season, year} tuples in reverse chronological order.
  """
  def last_n_seasons(n \\ 4) do
    {current_season, current_year} = current_season()

    Stream.iterate({current_season, current_year}, &previous_season/1)
    |> Enum.take(n)
  end

  defp previous_season({"winter", year}), do: {"fall", year - 1}
  defp previous_season({"spring", year}), do: {"winter", year}
  defp previous_season({"summer", year}), do: {"spring", year}
  defp previous_season({"fall", year}), do: {"summer", year}

  @doc """
  Returns anime for a specific season.

  ## Options
    * `:limit` - Maximum number of anime to return (default: 20)
    * `:order_by` - Field to order by (default: :animetana_popularity_en)
  """
  def list_anime_by_season(season, year, opts \\ []) do
    limit = Keyword.get(opts, :limit, 20)

    Anime
    |> where([a], a.season == ^season and a.season_year == ^year)
    |> where([a], is_nil(a.deleted_at))
    |> order_by([a], [desc: a.popularity_en, asc: a.id])
    |> limit(^limit)
    |> Repo.all()
  end

  @doc """
  Returns anime grouped by the last N seasons.
  Returns a list of maps with :season, :year, and :anime keys.
  """
  def list_seasonal_anime(num_seasons \\ 4, opts \\ []) do
    limit_per_season = Keyword.get(opts, :limit, 20)

    last_n_seasons(num_seasons)
    |> Enum.map(fn {season, year} ->
      %{
        season: season,
        year: year,
        anime: list_anime_by_season(season, year, limit: limit_per_season)
      }
    end)
  end

  @doc """
  Formats a season for display.
  """
  def format_season(season, year, locale \\ "en")

  def format_season(season, year, locale) when locale in ["ja", :ja] do
    season_ja = %{
      "winter" => "冬",
      "spring" => "春",
      "summer" => "夏",
      "fall" => "秋"
    }
    "#{year}年 #{season_ja[season]}"
  end

  def format_season(season, year, _locale) do
    "#{String.capitalize(season)} #{year}"
  end

  @doc """
  Checks if a season is the current season.
  """
  def current_season?(season, year) do
    {current, current_year} = current_season()
    season == current and year == current_year
  end

  @doc """
  Gets a single anime by ID. Raises if not found.
  """
  def get_anime!(id) do
    Anime
    |> where([a], is_nil(a.deleted_at))
    |> Repo.get!(id)
  end

  @doc """
  Gets a single anime by ID. Returns nil if not found.
  """
  def get_anime(id) do
    Anime
    |> where([a], is_nil(a.deleted_at))
    |> Repo.get(id)
  end

  @doc """
  Formats a status for display.
  """
  def format_status(status, locale \\ "en")

  def format_status(status, locale) when locale in ["ja", :ja] do
    %{
      "releasing" => "放送中",
      "finished" => "完結",
      "not_yet_released" => "未放送",
      "cancelled" => "中止",
      "hiatus" => "休止中",
      "unknown" => "不明"
    }[status] || status
  end

  def format_status(status, _locale) do
    %{
      "releasing" => "Currently Airing",
      "finished" => "Finished",
      "not_yet_released" => "Not Yet Released",
      "cancelled" => "Cancelled",
      "hiatus" => "On Hiatus",
      "unknown" => "Unknown"
    }[status] || status
  end

  @doc """
  Formats a format type for display.
  """
  def format_type(format, locale \\ "en")

  def format_type(format, locale) when locale in ["ja", :ja] do
    %{
      "tv" => "TV",
      "tv_short" => "TVショート",
      "movie" => "劇場版",
      "special" => "スペシャル",
      "ova" => "OVA",
      "ona" => "ONA",
      "music" => "ミュージック",
      "cm" => "CM",
      "pv" => "PV",
      "unknown" => "不明"
    }[format] || format
  end

  def format_type(format, _locale) do
    %{
      "tv" => "TV",
      "tv_short" => "TV Short",
      "movie" => "Movie",
      "special" => "Special",
      "ova" => "OVA",
      "ona" => "ONA",
      "music" => "Music",
      "cm" => "CM",
      "pv" => "PV",
      "unknown" => "Unknown"
    }[format] || format
  end

  @doc """
  Formats a source for display.
  """
  def format_source(source, locale \\ "en")

  def format_source(nil, _locale), do: nil

  def format_source(source, locale) when locale in ["ja", :ja] do
    %{
      "original" => "オリジナル",
      "manga" => "漫画",
      "light_novel" => "ライトノベル",
      "visual_novel" => "ビジュアルノベル",
      "video_game" => "ゲーム",
      "novel" => "小説",
      "doujinshi" => "同人誌",
      "anime" => "アニメ",
      "web_novel" => "Web小説",
      "live_action" => "実写",
      "game" => "ゲーム",
      "comic" => "コミック",
      "multimedia_project" => "メディアミックス",
      "picture_book" => "絵本",
      "other" => "その他"
    }[source] || source
  end

  def format_source(source, _locale) do
    (source || "")
    |> String.replace("_", " ")
    |> String.split(" ")
    |> Enum.map(&String.capitalize/1)
    |> Enum.join(" ")
  end

  ## Tags

  @doc """
  Lists all tags, optionally filtered by category.
  """
  def list_tags(opts \\ []) do
    category = Keyword.get(opts, :category)
    include_adult = Keyword.get(opts, :include_adult, false)

    Tag
    |> then(fn q ->
      if category, do: where(q, [t], t.category == ^category), else: q
    end)
    |> then(fn q ->
      if include_adult, do: q, else: where(q, [t], t.is_adult == false)
    end)
    |> order_by([t], asc: t.name_en)
    |> Repo.all()
  end

  @doc """
  Lists tags grouped by category.
  """
  def list_tags_grouped(opts \\ []) do
    list_tags(opts)
    |> Enum.group_by(& &1.category)
  end

  ## Search

  @doc """
  Returns available filter options for search.
  """
  def search_filter_options do
    %{
      formats: ~w(tv tv_short movie special ova ona music),
      statuses: ~w(releasing finished not_yet_released cancelled hiatus),
      seasons: ~w(winter spring summer fall),
      sources: ~w(original manga light_novel visual_novel video_game novel doujinshi anime web_novel live_action game comic multimedia_project picture_book other),
      countries: ~w(JP CN KR TW),
      sort_options: ~w(score_desc score_asc popularity_desc popularity_asc title_asc title_desc start_date_desc start_date_asc)
    }
  end

  @doc """
  Returns available years for filtering (from current year back to 1940).
  """
  def available_years do
    current_year = Date.utc_today().year
    Enum.to_list(current_year..1940)
  end

  @doc """
  Searches anime with various filters.

  ## Options
    * `:query` - Text search in titles
    * `:genres` - List of tag IDs to include
    * `:exclude_genres` - List of tag IDs to exclude
    * `:year` - Specific year
    * `:year_from` - Year range start
    * `:year_to` - Year range end
    * `:season` - Season (winter, spring, summer, fall)
    * `:format` - Anime format
    * `:status` - Airing status
    * `:country` - Country of origin
    * `:source` - Source material
    * `:episodes_min` - Minimum episodes
    * `:episodes_max` - Maximum episodes
    * `:duration_min` - Minimum duration per episode
    * `:duration_max` - Maximum duration per episode
    * `:sort` - Sort option (default: popularity_desc)
    * `:page` - Page number (default: 1)
    * `:per_page` - Results per page (default: 50)
    * `:include_adult` - Include adult content (default: false)
  """
  def search_anime(opts \\ []) do
    page = Keyword.get(opts, :page, 1)
    per_page = Keyword.get(opts, :per_page, 50)
    offset = (page - 1) * per_page

    query = build_search_query(opts)

    results = query
    |> limit(^per_page)
    |> offset(^offset)
    |> Repo.all()

    total = query
    |> exclude(:order_by)
    |> exclude(:limit)
    |> exclude(:offset)
    |> select([a], count(a.id))
    |> Repo.one()

    %{
      results: results,
      total: total,
      page: page,
      per_page: per_page,
      total_pages: ceil(total / per_page)
    }
  end

  defp build_search_query(opts) do
    include_adult = Keyword.get(opts, :include_adult, false)
    sort = Keyword.get(opts, :sort, "popularity_desc")

    Anime
    |> where([a], is_nil(a.deleted_at))
    |> filter_by_query(Keyword.get(opts, :query))
    |> filter_by_year(Keyword.get(opts, :year))
    |> filter_by_year_range(Keyword.get(opts, :year_from), Keyword.get(opts, :year_to))
    |> filter_by_season(Keyword.get(opts, :season))
    |> filter_by_format(Keyword.get(opts, :format))
    |> filter_by_status(Keyword.get(opts, :status))
    |> filter_by_country(Keyword.get(opts, :country))
    |> filter_by_source(Keyword.get(opts, :source))
    |> filter_by_episodes(Keyword.get(opts, :episodes_min), Keyword.get(opts, :episodes_max))
    |> filter_by_duration(Keyword.get(opts, :duration_min), Keyword.get(opts, :duration_max))
    |> filter_by_tags(Keyword.get(opts, :genres, []))
    |> exclude_tags(Keyword.get(opts, :exclude_genres, []))
    |> filter_adult(include_adult)
    |> apply_sort(sort)
  end

  defp filter_by_query(query, nil), do: query
  defp filter_by_query(query, ""), do: query
  defp filter_by_query(query, search_term) do
    search = "%#{search_term}%"
    where(query, [a],
      ilike(a.title_en, ^search) or
      ilike(a.title_romaji, ^search) or
      ilike(a.title_ja, ^search)
    )
  end

  defp filter_by_year(query, year) do
    case parse_optional_int(year) do
      nil -> query
      year -> where(query, [a], a.season_year == ^year)
    end
  end

  defp filter_by_year_range(query, from, to) do
    from = parse_optional_int(from)
    to = parse_optional_int(to)

    query
    |> then(fn q -> if from, do: where(q, [a], a.season_year >= ^from), else: q end)
    |> then(fn q -> if to, do: where(q, [a], a.season_year <= ^to), else: q end)
  end

  defp filter_by_season(query, nil), do: query
  defp filter_by_season(query, ""), do: query
  defp filter_by_season(query, season) do
    where(query, [a], a.season == ^season)
  end

  defp filter_by_format(query, nil), do: query
  defp filter_by_format(query, ""), do: query
  defp filter_by_format(query, format) do
    where(query, [a], a.format == ^format)
  end

  defp filter_by_status(query, nil), do: query
  defp filter_by_status(query, ""), do: query
  defp filter_by_status(query, status) do
    where(query, [a], a.status == ^status)
  end

  defp filter_by_country(query, nil), do: query
  defp filter_by_country(query, ""), do: query
  defp filter_by_country(query, country) do
    where(query, [a], a.country_of_origin == ^country)
  end

  defp filter_by_source(query, nil), do: query
  defp filter_by_source(query, ""), do: query
  defp filter_by_source(query, source) do
    where(query, [a], a.source == ^source)
  end

  defp filter_by_episodes(query, min, max) do
    min = parse_optional_int(min)
    max = parse_optional_int(max)

    query
    |> then(fn q -> if min, do: where(q, [a], a.episodes >= ^min), else: q end)
    |> then(fn q -> if max, do: where(q, [a], a.episodes <= ^max), else: q end)
  end

  defp filter_by_duration(query, min, max) do
    min = parse_optional_int(min)
    max = parse_optional_int(max)

    query
    |> then(fn q -> if min, do: where(q, [a], a.duration >= ^min), else: q end)
    |> then(fn q -> if max, do: where(q, [a], a.duration <= ^max), else: q end)
  end

  defp parse_optional_int(nil), do: nil
  defp parse_optional_int(""), do: nil
  defp parse_optional_int(val) when is_integer(val), do: val
  defp parse_optional_int(val) when is_binary(val) do
    case Integer.parse(val) do
      {num, _} -> num
      :error -> nil
    end
  end

  defp filter_by_tags(query, []), do: query
  defp filter_by_tags(query, tag_ids) when is_list(tag_ids) do
    tag_ids = Enum.map(tag_ids, fn id ->
      if is_binary(id), do: String.to_integer(id), else: id
    end)

    # Anime must have ALL specified tags
    Enum.reduce(tag_ids, query, fn tag_id, q ->
      where(q, [a],
        fragment(
          "EXISTS (SELECT 1 FROM contents.anime_tags WHERE anime_id = ? AND tag_id = ?)",
          a.id,
          ^tag_id
        )
      )
    end)
  end

  defp exclude_tags(query, []), do: query
  defp exclude_tags(query, tag_ids) when is_list(tag_ids) do
    tag_ids = Enum.map(tag_ids, fn id ->
      if is_binary(id), do: String.to_integer(id), else: id
    end)

    where(query, [a],
      fragment(
        "NOT EXISTS (SELECT 1 FROM contents.anime_tags WHERE anime_id = ? AND tag_id = ANY(?))",
        a.id,
        ^tag_ids
      )
    )
  end

  defp filter_adult(query, true), do: query
  defp filter_adult(query, false) do
    where(query, [a], a.is_adult == false)
  end

  defp apply_sort(query, "score_desc"), do: order_by(query, [a], [desc_nulls_last: a.score_en, asc: a.id])
  defp apply_sort(query, "score_asc"), do: order_by(query, [a], [asc_nulls_last: a.score_en, asc: a.id])
  defp apply_sort(query, "popularity_desc"), do: order_by(query, [a], [asc_nulls_last: a.popularity_en, asc: a.id])
  defp apply_sort(query, "popularity_asc"), do: order_by(query, [a], [desc_nulls_last: a.popularity_en, asc: a.id])
  defp apply_sort(query, "title_asc"), do: order_by(query, [a], [asc: a.title_romaji, asc: a.id])
  defp apply_sort(query, "title_desc"), do: order_by(query, [a], [desc: a.title_romaji, asc: a.id])
  defp apply_sort(query, "start_date_desc"), do: order_by(query, [a], [desc_nulls_last: a.start_date, asc: a.id])
  defp apply_sort(query, "start_date_asc"), do: order_by(query, [a], [asc_nulls_last: a.start_date, asc: a.id])
  defp apply_sort(query, _), do: order_by(query, [a], [asc_nulls_last: a.popularity_en, asc: a.id])
end
