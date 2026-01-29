defmodule AnimetanaWeb.Plugs.Locale do
  @moduledoc """
  Plug to handle locale from URL path prefix (/en, /ja).

  Locale detection priority:
  1. URL path prefix (required for all content routes)
  2. For root path redirect: Cloudflare CF-IPCountry header (JP -> ja, else -> en)
  3. Fallback: "en"
  """
  import Plug.Conn

  @locales ~w(en ja)
  @default_locale "en"

  def init(opts), do: opts

  def call(conn, _opts) do
    locale = conn.assigns[:locale] || @default_locale

    Gettext.put_locale(AnimetanaWeb.Gettext, locale)

    conn
    |> assign(:locale, locale)
  end

  @doc """
  Detects the preferred locale based on the user's country.
  Uses Cloudflare CF-IPCountry header (JP = ja, everything else = en).
  """
  def detect_locale_from_ip(conn) do
    case get_req_header(conn, "cf-ipcountry") do
      ["JP" | _] -> "ja"
      _ -> @default_locale
    end
  end

  @doc """
  Returns the list of supported locales.
  """
  def supported_locales, do: @locales

  @doc """
  Returns the default locale.
  """
  def default_locale, do: @default_locale

  @doc """
  Validates a locale string. Returns the locale if valid, default otherwise.
  """
  def validate_locale(locale) when locale in @locales, do: locale
  def validate_locale(_), do: @default_locale
end

defmodule AnimetanaWeb.Plugs.SetLocaleFromPath do
  @moduledoc """
  Plug that extracts locale from the URL path and assigns it to the conn.
  Must be used in a scope that captures :locale as a path parameter.
  """
  import Plug.Conn

  alias AnimetanaWeb.Plugs.Locale

  def init(opts), do: opts

  def call(%{params: %{"locale" => locale}} = conn, _opts) do
    validated_locale = Locale.validate_locale(locale)
    assign(conn, :locale, validated_locale)
  end

  def call(conn, _opts) do
    assign(conn, :locale, Locale.default_locale())
  end
end

defmodule AnimetanaWeb.Plugs.RedirectToLocale do
  @moduledoc """
  Plug that redirects requests without a locale prefix to the appropriate locale.
  Detects locale from Cloudflare CF-IPCountry header.
  """
  import Plug.Conn
  import Phoenix.Controller, only: [redirect: 2]

  alias AnimetanaWeb.Plugs.Locale

  def init(opts), do: opts

  def call(conn, _opts) do
    locale = Locale.detect_locale_from_ip(conn)
    path = conn.request_path
    query = if conn.query_string != "", do: "?#{conn.query_string}", else: ""

    # Redirect to locale-prefixed path
    redirect_path = "/#{locale}#{path}#{query}"

    conn
    |> redirect(to: redirect_path)
    |> halt()
  end
end
