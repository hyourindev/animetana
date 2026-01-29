defmodule AnimetanaWeb.RedirectController do
  use AnimetanaWeb, :controller

  alias AnimetanaWeb.Plugs.Locale

  @doc """
  Redirects the root path to the appropriate locale-prefixed path.
  Uses Cloudflare CF-IPCountry header to detect Japan (ja) vs rest of world (en).
  """
  def to_locale(conn, _params) do
    locale = Locale.detect_locale_from_ip(conn)
    redirect(conn, to: ~p"/#{locale}/")
  end
end
