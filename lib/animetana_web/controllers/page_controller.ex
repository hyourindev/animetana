defmodule AnimetanaWeb.PageController do
  use AnimetanaWeb, :controller

  alias Animetana.Contents

  def home(conn, _params) do
    seasonal_anime = Contents.list_seasonal_anime(4, limit: 20)

    render(conn, :home, seasonal_anime: seasonal_anime)
  end
end
