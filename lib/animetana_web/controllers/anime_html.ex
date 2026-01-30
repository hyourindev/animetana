defmodule AnimetanaWeb.AnimeHTML do
  use AnimetanaWeb, :html

  alias Animetana.Contents
  alias Animetana.Contents.Anime
  alias Animetana.Accounts.UserAnimeList

  embed_templates "anime_html/*"

  def display_title(anime, locale), do: Anime.display_title(anime, locale)
  def display_synopsis(anime, locale), do: Anime.display_synopsis(anime, locale)
  def format_status(status, locale), do: Contents.format_status(status, locale)
  def format_type(format, locale), do: Contents.format_type(format, locale)
  def format_source(source, locale), do: Contents.format_source(source, locale)
  def format_season(season, year, locale), do: Contents.format_season(season, year, locale)

  # User list status helpers
  def list_status_text(status, locale), do: UserAnimeList.format_status(status, locale)

  def list_status_color(:watching), do: "bg-green-500"
  def list_status_color(:completed), do: "bg-blue-500"
  def list_status_color(:on_hold), do: "bg-yellow-500"
  def list_status_color(:dropped), do: "bg-red-500"
  def list_status_color(:plan_to_watch), do: "bg-purple-500"
  def list_status_color(_), do: "bg-neutral-500"

  def list_status_options do
    [
      {"Watching", "watching", "bg-green-500"},
      {"Completed", "completed", "bg-blue-500"},
      {"On Hold", "on_hold", "bg-yellow-500"},
      {"Dropped", "dropped", "bg-red-500"},
      {"Plan to Watch", "plan_to_watch", "bg-purple-500"}
    ]
  end

  def format_progress(nil, _total), do: "- / ?"
  def format_progress(progress, nil), do: "#{progress} / ?"
  def format_progress(progress, total), do: "#{progress} / #{total}"

  def format_score(nil), do: "-"
  def format_score(score), do: Decimal.round(score, 2) |> Decimal.to_string()

  def format_number(nil), do: "-"
  def format_number(num) when is_integer(num) do
    num
    |> Integer.to_string()
    |> String.reverse()
    |> String.replace(~r/(\d{3})(?=\d)/, "\\1,")
    |> String.reverse()
  end
  def format_number(num), do: to_string(num)

  def format_date(nil), do: "-"
  def format_date(%Date{} = date), do: Calendar.strftime(date, "%b %d, %Y")

  def format_duration(nil), do: "-"
  def format_duration(minutes) when minutes < 60, do: "#{minutes} min"
  def format_duration(minutes) do
    hours = div(minutes, 60)
    mins = rem(minutes, 60)
    if mins == 0, do: "#{hours} hr", else: "#{hours} hr #{mins} min"
  end

  def status_color(status) do
    case status do
      "releasing" -> "bg-green-500"
      "finished" -> "bg-blue-500"
      "not_yet_released" -> "bg-yellow-500"
      "cancelled" -> "bg-red-500"
      "hiatus" -> "bg-orange-500"
      _ -> "bg-neutral-500"
    end
  end

  def country_name("JP"), do: "Japan"
  def country_name("CN"), do: "China"
  def country_name("KR"), do: "South Korea"
  def country_name("TW"), do: "Taiwan"
  def country_name(code), do: code

  def format_category(nil), do: "Other"
  def format_category("theme"), do: "Themes"
  def format_category("setting"), do: "Setting"
  def format_category("cast"), do: "Cast"
  def format_category("demographic"), do: "Demographic"
  def format_category("technical"), do: "Technical"
  def format_category("sexual_content"), do: "Mature"
  def format_category("other"), do: "Other"
  def format_category(cat), do: String.capitalize(cat)

  def has_selected_tags?(params) do
    genres = params["genres"]
    is_list(genres) and genres != []
  end

  def build_page_url(params, page) do
    params
    |> Map.put("page", page)
    |> Enum.flat_map(fn
      {key, values} when is_list(values) ->
        Enum.map(values, fn v -> {"#{key}[]", v} end)
      {key, value} ->
        [{key, value}]
    end)
    |> URI.encode_query()
    |> then(&("?" <> &1))
  end
end
