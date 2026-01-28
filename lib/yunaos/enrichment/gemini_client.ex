defmodule Yunaos.Enrichment.GeminiClient do
  @moduledoc """
  HTTP client for calling Gemini via the Vercel AI Gateway.
  Uses the OpenAI-compatible chat completions endpoint.
  """

  require Logger

  @max_retries 3

  @doc """
  Sends a chat completion request to Gemini via Vercel AI Gateway.

  Returns `{:ok, content_string}` with the assistant's text response,
  or `{:error, reason}` on failure.
  """
  @spec chat(String.t(), String.t()) :: {:ok, String.t()} | {:error, term()}
  def chat(system_prompt, user_prompt) do
    config = Application.get_env(:yunaos, :enrichment)
    token = config[:gateway_token]
    url = config[:gateway_url]
    model = config[:model]

    unless token do
      raise "VERCEL_AI_GATEWAY_TOKEN not set. Export it as an environment variable."
    end

    body =
      Jason.encode!(%{
        model: model,
        messages: [
          %{role: "system", content: system_prompt},
          %{role: "user", content: user_prompt}
        ],
        temperature: 0.3,
        max_tokens: 16384
      })

    do_request(url, token, body, @max_retries)
  end

  defp do_request(url, token, body, retries_left) do
    result =
      Req.post(url,
        body: body,
        headers: [
          {"authorization", "Bearer #{token}"},
          {"content-type", "application/json"}
        ],
        receive_timeout: 120_000
      )

    case result do
      {:ok, %Req.Response{status: 200, body: resp_body}} ->
        extract_content(resp_body)

      {:ok, %Req.Response{status: 429}} when retries_left > 0 ->
        delay = retry_delay(@max_retries - retries_left + 1)
        Logger.warning("Vercel rate limited (429). Retrying in #{delay}ms (#{retries_left - 1} left)")
        Process.sleep(delay)
        do_request(url, token, body, retries_left - 1)

      {:ok, %Req.Response{status: 429}} ->
        {:error, :rate_limited}

      {:ok, %Req.Response{status: status, body: _resp_body}} when retries_left > 0 and status >= 500 ->
        delay = retry_delay(@max_retries - retries_left + 1)
        Logger.warning("Vercel server error (#{status}). Retrying in #{delay}ms")
        Process.sleep(delay)
        do_request(url, token, body, retries_left - 1)

      {:ok, %Req.Response{status: status, body: resp_body}} ->
        Logger.error("Vercel API error: #{status} — #{inspect(resp_body)}")
        {:error, {status, resp_body}}

      {:error, exception} ->
        if retries_left > 0 do
          delay = retry_delay(@max_retries - retries_left + 1)
          Logger.warning("Network error: #{inspect(exception)}. Retrying in #{delay}ms")
          Process.sleep(delay)
          do_request(url, token, body, retries_left - 1)
        else
          {:error, exception}
        end
    end
  end

  defp extract_content(%{"choices" => [%{"message" => %{"content" => content}} | _]}) do
    {:ok, content}
  end

  defp extract_content(body) do
    Logger.error("Unexpected response shape: #{inspect(body)}")
    {:error, :unexpected_response}
  end

  defp retry_delay(attempt), do: 2_000 * attempt
end
