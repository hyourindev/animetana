defmodule YunaosWeb.PageController do
  use YunaosWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
