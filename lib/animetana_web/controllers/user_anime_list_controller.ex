defmodule AnimetanaWeb.UserAnimeListController do
  use AnimetanaWeb, :controller

  alias Animetana.Accounts

  @doc """
  Shows a single anime list entry for editing.
  """
  def edit(conn, %{"id" => id}) do
    user = conn.assigns.current_user
    entry = Accounts.get_user_anime_entry_with_anime!(id)

    # Ensure the entry belongs to the current user
    if entry.user_id != user.id do
      conn
      |> put_flash(:error, gettext("You don't have permission to edit this entry."))
      |> redirect(to: ~p"/#{conn.assigns.locale}/users/#{conn.assigns.current_user.identifier}")
    else
      changeset = Accounts.change_anime_entry(entry)
      render(conn, :edit,
        entry: entry,
        changeset: changeset,
        page_title: gettext("Edit List Entry")
      )
    end
  end

  @doc """
  Updates an anime list entry.
  """
  def update(conn, %{"id" => id, "user_anime_list" => entry_params}) do
    user = conn.assigns.current_user
    entry = Accounts.get_user_anime_entry_with_anime!(id)

    if entry.user_id != user.id do
      conn
      |> put_flash(:error, gettext("You don't have permission to edit this entry."))
      |> redirect(to: ~p"/#{conn.assigns.locale}/users/#{conn.assigns.current_user.identifier}")
    else
      case Accounts.update_anime_entry(entry, entry_params) do
        {:ok, _entry} ->
          conn
          |> put_flash(:info, gettext("Entry updated successfully."))
          |> redirect(to: ~p"/#{conn.assigns.locale}/users/#{conn.assigns.current_user.identifier}")

        {:error, %Ecto.Changeset{} = changeset} ->
          render(conn, :edit,
            entry: entry,
            changeset: changeset,
            page_title: gettext("Edit List Entry")
          )
      end
    end
  end

  @doc """
  Adds an anime to the user's list (quick add).
  """
  def create(conn, %{"anime_id" => anime_id, "status" => status}) do
    user = conn.assigns.current_user
    status_atom = String.to_existing_atom(status)

    case Accounts.add_anime_to_list(user, anime_id, status_atom) do
      {:ok, _entry} ->
        conn
        |> put_flash(:info, gettext("Added to your list."))
        |> redirect(to: redirect_back(conn))

      {:error, _changeset} ->
        conn
        |> put_flash(:error, gettext("Failed to add to list."))
        |> redirect(to: redirect_back(conn))
    end
  end

  @doc """
  Updates the status of an anime in the list (quick status change).
  """
  def update_status(conn, %{"id" => id, "status" => status}) do
    user = conn.assigns.current_user
    entry = Accounts.get_user_anime_entry!(id)

    if entry.user_id != user.id do
      conn
      |> put_flash(:error, gettext("You don't have permission to edit this entry."))
      |> redirect(to: redirect_back(conn))
    else
      status_atom = String.to_existing_atom(status)
      case Accounts.update_anime_status(entry, status_atom) do
        {:ok, _entry} ->
          conn
          |> put_flash(:info, gettext("Status updated."))
          |> redirect(to: redirect_back(conn))

        {:error, _changeset} ->
          conn
          |> put_flash(:error, gettext("Failed to update status."))
          |> redirect(to: redirect_back(conn))
      end
    end
  end

  @doc """
  Increments the progress of an anime (+1 episode).
  """
  def increment_progress(conn, %{"id" => id}) do
    user = conn.assigns.current_user
    entry = Accounts.get_user_anime_entry!(id)

    if entry.user_id != user.id do
      conn
      |> put_flash(:error, gettext("You don't have permission to edit this entry."))
      |> redirect(to: redirect_back(conn))
    else
      case Accounts.increment_anime_progress(entry) do
        {:ok, _entry} ->
          conn
          |> put_flash(:info, gettext("Progress updated."))
          |> redirect(to: redirect_back(conn))

        {:error, _changeset} ->
          conn
          |> put_flash(:error, gettext("Failed to update progress."))
          |> redirect(to: redirect_back(conn))
      end
    end
  end

  @doc """
  Updates the score of an anime.
  """
  def update_score(conn, %{"id" => id, "score" => score}) do
    user = conn.assigns.current_user
    entry = Accounts.get_user_anime_entry!(id)

    if entry.user_id != user.id do
      conn
      |> put_flash(:error, gettext("You don't have permission to edit this entry."))
      |> redirect(to: redirect_back(conn))
    else
      score_int = if score == "", do: nil, else: String.to_integer(score)
      case Accounts.update_anime_score(entry, score_int) do
        {:ok, _entry} ->
          conn
          |> put_flash(:info, gettext("Score updated."))
          |> redirect(to: redirect_back(conn))

        {:error, _changeset} ->
          conn
          |> put_flash(:error, gettext("Failed to update score."))
          |> redirect(to: redirect_back(conn))
      end
    end
  end

  @doc """
  Deletes an anime from the user's list.
  """
  def delete(conn, %{"id" => id}) do
    user = conn.assigns.current_user
    entry = Accounts.get_user_anime_entry!(id)

    if entry.user_id != user.id do
      conn
      |> put_flash(:error, gettext("You don't have permission to delete this entry."))
      |> redirect(to: redirect_back(conn))
    else
      case Accounts.delete_anime_entry(entry) do
        {:ok, _entry} ->
          conn
          |> put_flash(:info, gettext("Removed from your list."))
          |> redirect(to: ~p"/#{conn.assigns.locale}/users/#{conn.assigns.current_user.identifier}")

        {:error, _changeset} ->
          conn
          |> put_flash(:error, gettext("Failed to remove from list."))
          |> redirect(to: redirect_back(conn))
      end
    end
  end

  # Helpers

  defp redirect_back(conn) do
    case get_req_header(conn, "referer") do
      [referer | _] ->
        uri = URI.parse(referer)
        path = uri.path || "/"
        if uri.query, do: "#{path}?#{uri.query}", else: path
      _ ->
        ~p"/#{conn.assigns.locale}/users/#{conn.assigns.current_user.identifier}"
    end
  end
end
