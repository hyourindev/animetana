defmodule AnimetanaWeb.UserProfileHTML do
  use AnimetanaWeb, :html

  alias Animetana.Contents.Anime

  embed_templates "user_profile_html/*"

  def display_title(anime, locale), do: Anime.display_title(anime, locale)
end
