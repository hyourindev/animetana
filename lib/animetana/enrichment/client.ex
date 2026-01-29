defmodule Animetana.Enrichment.Client do
  @moduledoc """
  HTTP client for Vercel AI Gateway with Google Gemini.

  Handles rate limiting, retries, and error handling for AI API calls.
  """

  require Logger

  @default_config [
    gateway_url: "https://ai-gateway.vercel.sh/v1/chat/completions",
    model: "google/gemini-2.0-flash",
    request_delay_ms: 1000,
    max_retries: 3,
    request_timeout: 60_000
  ]

  def config do
    app_config = Application.get_env(:animetana, :enrichment, [])
    Keyword.merge(@default_config, app_config)
  end

  @doc """
  Sends a chat completion request to Vercel AI Gateway.

  Returns {:ok, content} or {:error, reason}
  """
  def chat_completion(messages, opts \\ []) do
    cfg = config()
    retries = Keyword.get(opts, :retries, cfg[:max_retries])

    do_request(messages, cfg, retries)
  end

  defp do_request(messages, cfg, retries) do
    url = cfg[:gateway_url]
    token = cfg[:gateway_token] |> to_string() |> String.trim()

    unless token != "" do
      raise "VERCEL_AI_GATEWAY_TOKEN not configured. Set it in environment or config."
    end

    body = Jason.encode!(%{
      "model" => cfg[:model],
      "messages" => messages,
      "temperature" => 0.2,
      "max_tokens" => 8192
    })

    headers = [
      {"content-type", "application/json"},
      {"authorization", "Bearer #{token}"}
    ]

    case Req.post(url, body: body, headers: headers, receive_timeout: cfg[:request_timeout]) do
      {:ok, %{status: 200, body: %{"choices" => [%{"message" => %{"content" => content}} | _]}}} ->
        {:ok, content}

      {:ok, %{status: 429, headers: resp_headers}} ->
        retry_after = get_retry_after(resp_headers)
        Logger.warning("[Enrichment.Client] Rate limited, waiting #{retry_after}s...")
        Process.sleep(retry_after * 1000)
        do_request(messages, cfg, retries)

      {:ok, %{status: status}} when status >= 500 and retries > 0 ->
        Logger.warning("[Enrichment.Client] Server error #{status}, retrying...")
        Process.sleep(2000)
        do_request(messages, cfg, retries - 1)

      {:ok, %{status: status, body: body}} ->
        {:error, {:http_error, status, body}}

      {:error, reason} when retries > 0 ->
        Logger.warning("[Enrichment.Client] Request failed: #{inspect(reason)}, retrying...")
        Process.sleep(2000)
        do_request(messages, cfg, retries - 1)

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp get_retry_after(headers) do
    case Enum.find(headers, fn {k, _} -> String.downcase(to_string(k)) == "retry-after" end) do
      {_, value} -> String.to_integer(to_string(value))
      nil -> 60
    end
  end
end
