defmodule AnimetanaWeb.AnimeController do
  use AnimetanaWeb, :controller

  alias Animetana.Accounts
  alias Animetana.Contents

  def index(conn, params) do
    # Parse filter params
    filters = parse_filters(params)

    # Get search results
    search_results = Contents.search_anime(filters)

    # Get filter options
    filter_options = Contents.search_filter_options()
    years = Contents.available_years()
    tags = Contents.list_tags_grouped(include_adult: filters[:include_adult] || false)

    render(conn, :index,
      results: search_results.results,
      total: search_results.total,
      page: search_results.page,
      per_page: search_results.per_page,
      total_pages: search_results.total_pages,
      filters: filters,
      filter_options: filter_options,
      years: years,
      tags: tags,
      params: params
    )
  end

  def show(conn, %{"id" => id}) do
    anime = Contents.get_anime!(id)

    # Get user's list entry if logged in
    list_entry =
      case conn.assigns[:current_user] do
        nil -> nil
        user -> Accounts.get_user_anime_entry(user.id, anime.id)
      end

    render(conn, :show, anime: anime, list_entry: list_entry)
  end

  defp parse_filters(params) do
    [
      query: params["q"],
      genres: parse_list(params["genres"]),
      exclude_genres: parse_list(params["exclude_genres"]),
      year: params["year"],
      year_from: params["year_from"],
      year_to: params["year_to"],
      season: params["season"],
      format: params["format"],
      status: params["status"],
      country: params["country"],
      source: params["source"],
      episodes_min: params["episodes_min"],
      episodes_max: params["episodes_max"],
      duration_min: params["duration_min"],
      duration_max: params["duration_max"],
      sort: params["sort"] || "popularity_desc",
      page: parse_int(params["page"], 1),
      per_page: parse_int(params["per_page"], 50),
      include_adult: params["adult"] == "true"
    ]
  end

  defp parse_list(nil), do: []
  defp parse_list(list) when is_list(list), do: list
  defp parse_list(str) when is_binary(str), do: String.split(str, ",", trim: true)

  defp parse_int(nil, default), do: default
  defp parse_int("", default), do: default
  defp parse_int(str, default) when is_binary(str) do
    case Integer.parse(str) do
      {num, _} -> num
      :error -> default
    end
  end
  defp parse_int(num, _default) when is_integer(num), do: num
end
