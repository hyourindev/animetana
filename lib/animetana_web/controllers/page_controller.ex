defmodule AnimetanaWeb.PageController do
  use AnimetanaWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
