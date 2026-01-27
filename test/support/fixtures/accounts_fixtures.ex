defmodule Yunaos.AccountsFixtures do
  def unique_user_email, do: "user#{System.unique_integer()}@example.com"
  def unique_user_identifier, do: "user_#{System.unique_integer([:positive])}"
  def valid_user_password, do: "hello_world!"

  def valid_user_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      name: "Test User",
      identifier: unique_user_identifier(),
      email: unique_user_email(),
      password: valid_user_password()
    })
  end

  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> valid_user_attributes()
      |> Yunaos.Accounts.register_user()

    user
  end

  def extract_user_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end
end
