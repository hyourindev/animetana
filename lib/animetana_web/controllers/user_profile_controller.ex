defmodule AnimetanaWeb.UserProfileController do
  use AnimetanaWeb, :controller

  alias Animetana.Accounts

  def show(conn, %{"identifier" => identifier} = params) do
    user = Accounts.get_user_by_identifier!(identifier)
    current_user = conn.assigns[:current_user]

    if Accounts.can_view_profile?(user, current_user) do
      is_own_profile = current_user && current_user.id == user.id
      can_view_activity = Accounts.can_view_activity?(user, current_user)

      # Get anime list data if activity is visible
      {anime_entries, anime_status_counts} =
        if can_view_activity do
          status_filter = parse_status(params["status"])
          entries = Accounts.list_user_anime(user,
            status: status_filter,
            limit: 20,
            preload_anime: true
          )
          counts = Accounts.count_user_anime_by_status(user)
          {entries, counts}
        else
          {[], %{}}
        end

      render(conn, :show,
        user: user,
        can_view_statistics: Accounts.can_view_statistics?(user, current_user),
        can_view_activity: can_view_activity,
        is_own_profile: is_own_profile,
        anime_entries: anime_entries,
        anime_status_counts: anime_status_counts,
        current_status: parse_status(params["status"])
      )
    else
      conn
      |> put_flash(:error, gettext("This profile is private."))
      |> redirect(to: ~p"/#{conn.assigns.locale}/")
    end
  end

  defp parse_status(nil), do: nil
  defp parse_status("all"), do: nil
  defp parse_status(status) when status in ~w(watching completed on_hold dropped plan_to_watch) do
    String.to_existing_atom(status)
  end
  defp parse_status(_), do: nil
end
