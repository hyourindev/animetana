defmodule AnimetanaWeb.Layouts do
  @moduledoc """
  This module holds layouts and related functionality
  used by your application.
  """
  use AnimetanaWeb, :html

  # Embed all files in layouts/* within this module.
  # The default root.html.heex file contains the HTML
  # skeleton of your application, namely HTML headers
  # and other static content.
  embed_templates "layouts/*"

  @doc """
  Renders your app layout.

  This function is typically invoked from every template,
  and it often contains your application menu, sidebar,
  or similar.

  ## Examples

      <Layouts.app flash={@flash}>
        <h1>Content</h1>
      </Layouts.app>

  """
  attr :flash, :map, required: true, doc: "the map of flash messages"

  attr :current_scope, :map,
    default: nil,
    doc: "the current [scope](https://hexdocs.pm/phoenix/scopes.html)"

  slot :inner_block, required: true

  def app(assigns) do
    ~H"""
    <header class="flex items-center justify-between px-4 sm:px-6 lg:px-8 py-4 border-b border-neutral-200 dark:border-neutral-800">
      <div class="flex-1">
        <a href="/" class="flex w-fit items-center gap-2">
          <img src={~p"/images/logo.svg"} width="36" />
          <span class="text-sm font-semibold">v{Application.spec(:phoenix, :vsn)}</span>
        </a>
      </div>
      <div class="flex-none">
        <ul class="flex px-1 space-x-4 items-center">
          <li>
            <a href="https://phoenixframework.org/" class="text-sm hover:underline">Website</a>
          </li>
          <li>
            <a href="https://github.com/phoenixframework/phoenix" class="text-sm hover:underline">GitHub</a>
          </li>
          <li>
            <.theme_toggle />
          </li>
          <li>
            <a href="https://hexdocs.pm/phoenix/overview.html" class="px-4 py-2 bg-neutral-900 dark:bg-neutral-100 text-white dark:text-black text-sm font-medium rounded hover:opacity-80 transition">
              Get Started <span aria-hidden="true">&rarr;</span>
            </a>
          </li>
        </ul>
      </div>
    </header>

    <main class="px-4 py-20 sm:px-6 lg:px-8">
      <div class="mx-auto max-w-2xl space-y-4">
        {render_slot(@inner_block)}
      </div>
    </main>

    <.flash_group flash={@flash} />
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />

      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={show(".phx-client-error #client-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={show(".phx-server-error #server-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end

  @doc """
  Renders the main navigation bar.
  """
  attr :locale, :string, required: true
  attr :current_user, :map, default: nil

  def navbar(assigns) do
    ~H"""
    <header class="border-b border-neutral-200 dark:border-neutral-800">
      <nav class="max-w-7xl mx-auto px-4 py-4 flex justify-between items-center">
        <div class="flex items-center gap-6">
          <a href={~p"/#{@locale}/"} class="text-xl font-bold tracking-tight">Animetana</a>

          <%!-- Main Navigation Links --%>
          <div class="hidden md:flex items-center gap-4">
            <.link href={~p"/#{@locale}/anime"} class="text-sm hover:text-neutral-600 dark:hover:text-neutral-300 transition">
              {gettext("Anime")}
            </.link>
          </div>
        </div>

        <div class="flex items-center gap-6">
          <!-- Language Switcher -->
          <div class="flex gap-2 text-sm">
            <a href={~p"/en/"} class={"hover:underline #{if @locale == "en", do: "font-bold", else: "text-neutral-500"}"}>EN</a>
            <span class="text-neutral-300 dark:text-neutral-700">|</span>
            <a href={~p"/ja/"} class={"hover:underline #{if @locale == "ja", do: "font-bold", else: "text-neutral-500"}"}>JA</a>
          </div>

          <!-- Theme Toggle -->
          <button
            onclick="toggleTheme()"
            class="p-2 hover:bg-neutral-100 dark:hover:bg-neutral-800 rounded transition"
            aria-label="Toggle theme"
          >
            <svg class="w-5 h-5 hidden dark:block" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 3v1m0 16v1m9-9h-1M4 12H3m15.364 6.364l-.707-.707M6.343 6.343l-.707-.707m12.728 0l-.707.707M6.343 17.657l-.707.707M16 12a4 4 0 11-8 0 4 4 0 018 0z" />
            </svg>
            <svg class="w-5 h-5 block dark:hidden" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20.354 15.354A9 9 0 018.646 3.646 9.003 9.003 0 0012 21a9.003 9.003 0 008.354-5.646z" />
            </svg>
          </button>

          <!-- Auth -->
          <%= if @current_user do %>
            <div class="relative" id="user-menu">
              <button
                type="button"
                onclick="document.getElementById('user-dropdown').classList.toggle('hidden')"
                class="flex items-center gap-2 p-1 rounded-full hover:bg-neutral-100 dark:hover:bg-neutral-800 transition"
              >
                <div class="w-8 h-8 rounded-full bg-neutral-300 dark:bg-neutral-700 overflow-hidden flex items-center justify-center">
                  <%= if @current_user.avatar_url do %>
                    <img src={@current_user.avatar_url} alt={@current_user.name} class="w-full h-full object-cover" />
                  <% else %>
                    <span class="text-sm font-medium text-neutral-600 dark:text-neutral-300">
                      {String.first(@current_user.name) |> String.upcase()}
                    </span>
                  <% end %>
                </div>
                <svg class="w-4 h-4 text-neutral-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
                </svg>
              </button>

              <div
                id="user-dropdown"
                class="hidden absolute right-0 mt-2 w-56 bg-white dark:bg-neutral-900 border border-neutral-200 dark:border-neutral-800 rounded-lg shadow-lg py-1 z-50"
              >
                <div class="px-4 py-3 border-b border-neutral-200 dark:border-neutral-800">
                  <p class="text-sm font-medium truncate">{@current_user.name}</p>
                  <p class="text-xs text-neutral-500 truncate">@{@current_user.identifier}</p>
                </div>

                <div class="py-1">
                  <.link
                    navigate={~p"/#{@locale}/users/#{@current_user.identifier}"}
                    class="flex items-center gap-3 px-4 py-2 text-sm hover:bg-neutral-100 dark:hover:bg-neutral-800 transition"
                  >
                    <svg class="w-4 h-4 text-neutral-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
                    </svg>
                    {gettext("Profile")}
                  </.link>
                  <.link
                    navigate={~p"/#{@locale}/settings"}
                    class="flex items-center gap-3 px-4 py-2 text-sm hover:bg-neutral-100 dark:hover:bg-neutral-800 transition"
                  >
                    <svg class="w-4 h-4 text-neutral-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z" />
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                    </svg>
                    {gettext("Settings")}
                  </.link>
                </div>

                <div class="border-t border-neutral-200 dark:border-neutral-800 py-1">
                  <.link
                    href={~p"/#{@locale}/users/log_out"}
                    method="delete"
                    class="flex items-center gap-3 px-4 py-2 text-sm text-red-600 dark:text-red-400 hover:bg-neutral-100 dark:hover:bg-neutral-800 transition"
                  >
                    <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1" />
                    </svg>
                    {gettext("Log out")}
                  </.link>
                </div>
              </div>
            </div>
          <% else %>
            <.link href={~p"/#{@locale}/users/log_in"} class="text-sm hover:underline">
              {gettext("Log in")}
            </.link>
            <.link href={~p"/#{@locale}/users/register"} class="text-sm font-medium hover:underline">
              {gettext("Register")}
            </.link>
          <% end %>
        </div>
      </nav>
    </header>

    <script>
      // Close dropdown when clicking outside
      document.addEventListener('click', function(event) {
        const dropdown = document.getElementById('user-dropdown');
        const menu = document.getElementById('user-menu');
        if (dropdown && menu && !menu.contains(event.target)) {
          dropdown.classList.add('hidden');
        }
      });
    </script>
    """
  end

  @doc """
  Provides dark vs light theme toggle based on themes defined in app.css.

  See <head> in root.html.heex which applies the theme before page load.
  """
  def theme_toggle(assigns) do
    ~H"""
    <div class="relative flex flex-row items-center border border-neutral-300 dark:border-neutral-700 bg-neutral-100 dark:bg-neutral-800 rounded-full">
      <button
        class="flex p-2 cursor-pointer hover:bg-neutral-200 dark:hover:bg-neutral-700 rounded-full transition"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="system"
      >
        <.icon name="hero-computer-desktop-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer hover:bg-neutral-200 dark:hover:bg-neutral-700 rounded-full transition"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="light"
      >
        <.icon name="hero-sun-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer hover:bg-neutral-200 dark:hover:bg-neutral-700 rounded-full transition"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="dark"
      >
        <.icon name="hero-moon-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>
    </div>
    """
  end
end
