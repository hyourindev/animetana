defmodule Animetana.Accounts.UserNotifier do
  import Swoosh.Email

  alias Animetana.Mailer

  defp deliver(recipient, subject, body) do
    email =
      new()
      |> to(recipient)
      |> from({"Animetana", "noreply@Animetana.com"})
      |> subject(subject)
      |> text_body(body)

    with {:ok, _metadata} <- Mailer.deliver(email) do
      {:ok, email}
    end
  end

  def deliver_confirmation_instructions(user, url) do
    deliver(user.email, "Confirm your Animetana account", """
    Hi #{user.name},

    You can confirm your account by visiting the URL below:

    #{url}

    If you didn't create an account with us, please ignore this.
    """)
  end

  def deliver_reset_password_instructions(user, url) do
    deliver(user.email, "Reset your Animetana password", """
    Hi #{user.name},

    You can reset your password by visiting the URL below:

    #{url}

    If you didn't request this change, please ignore this.
    """)
  end

  def deliver_update_email_instructions(user, url) do
    deliver(user.email, "Update your Animetana email", """
    Hi #{user.name},

    You can confirm your email change by visiting the URL below:

    #{url}

    If you didn't request this change, please ignore this.
    """)
  end
end
