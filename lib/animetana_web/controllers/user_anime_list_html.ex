defmodule AnimetanaWeb.UserAnimeListHTML do
  use AnimetanaWeb, :html

  alias Animetana.Accounts.UserAnimeList
  alias Animetana.Contents.Anime

  embed_templates "user_anime_list_html/*"

  def display_title(anime, locale), do: Anime.display_title(anime, locale)

  def format_status(status), do: UserAnimeList.format_status(status)
  def format_status(status, locale), do: UserAnimeList.format_status(status, locale)

  def format_score(nil), do: "-"
  def format_score(score), do: to_string(score)

  def format_progress(nil, _total), do: "-"
  def format_progress(progress, nil), do: "#{progress} / ?"
  def format_progress(progress, total), do: "#{progress} / #{total}"

  def format_date(nil), do: "-"
  def format_date(%Date{} = date), do: Calendar.strftime(date, "%b %d, %Y")

  def status_color(:watching), do: "bg-green-500"
  def status_color(:completed), do: "bg-blue-500"
  def status_color(:on_hold), do: "bg-yellow-500"
  def status_color(:dropped), do: "bg-red-500"
  def status_color(:plan_to_watch), do: "bg-purple-500"
  def status_color(_), do: "bg-neutral-500"

  def status_text_color(:watching), do: "text-green-500"
  def status_text_color(:completed), do: "text-blue-500"
  def status_text_color(:on_hold), do: "text-yellow-500"
  def status_text_color(:dropped), do: "text-red-500"
  def status_text_color(:plan_to_watch), do: "text-purple-500"
  def status_text_color(_), do: "text-neutral-500"

  def status_options do
    [
      {"Watching", "watching"},
      {"Completed", "completed"},
      {"On Hold", "on_hold"},
      {"Dropped", "dropped"},
      {"Plan to Watch", "plan_to_watch"}
    ]
  end

  def score_options do
    [
      {"-", ""},
      {"10 - Masterpiece", "10"},
      {"9 - Great", "9"},
      {"8 - Very Good", "8"},
      {"7 - Good", "7"},
      {"6 - Fine", "6"},
      {"5 - Average", "5"},
      {"4 - Bad", "4"},
      {"3 - Very Bad", "3"},
      {"2 - Horrible", "2"},
      {"1 - Appalling", "1"}
    ]
  end

end
