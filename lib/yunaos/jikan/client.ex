defmodule Yunaos.Jikan.Client do
  @moduledoc """
  HTTP client for the Jikan API v4 with rate limiting and error handling.

  Jikan enforces rate limits of 3 requests/second (burst) and 60 requests/minute
  (sustained). This client handles 429 responses by reading the `Retry-After`
  header and sleeping before retrying, and uses `Req`'s built-in transient retry
  for other recoverable errors.

  ## Usage

      # Single resource
      {:ok, body} = Yunaos.Jikan.Client.get("/anime/1")

      # With query params
      {:ok, body} = Yunaos.Jikan.Client.get("/anime", q: "Naruto", limit: 10)

      # All pages collected into a list
      {:ok, all_data} = Yunaos.Jikan.Client.get_paginated("/anime", q: "Naruto")

      # Stream pages for memory-efficient processing
      Yunaos.Jikan.Client.get_all_pages("/anime", [q: "Naruto"], fn page_data, page_number ->
        Enum.each(page_data, &process_item/1)
      end)
  """

  require Logger

  @base_url "https://api.jikan.moe/v4"
  @max_retries 3
  @retry_delay_ms 1_500
  @rate_limit_sleep_ms 1_100

  # ---------------------------------------------------------------------------
  # Public API
  # ---------------------------------------------------------------------------

  @doc """
  Performs a GET request against the Jikan v4 API.

  Returns `{:ok, body}` on success, where `body` is the decoded JSON map.
  Returns `{:ok, :not_modified}` for 304 responses.
  Returns `{:error, :not_found}` for 404 responses.
  Returns `{:error, {status, body}}` for other non-success statuses.
  Returns `{:error, exception}` for transport-level failures.
  """
  @spec get(String.t(), keyword()) :: {:ok, map() | :not_modified} | {:error, term()}
  def get(path, params \\ []) do
    url = build_url(path)

    case do_get(url, params, @max_retries) do
      {:ok, %Req.Response{status: 200, body: body}} ->
        {:ok, body}

      {:ok, %Req.Response{status: 304}} ->
        {:ok, :not_modified}

      {:ok, %Req.Response{status: 404}} ->
        {:error, :not_found}

      {:ok, %Req.Response{status: status, body: body}} ->
        {:error, {status, body}}

      {:error, exception} ->
        {:error, exception}
    end
  end

  @doc """
  Fetches all pages of a paginated endpoint and returns the collected data.

  This is tail-recursive and collects results with a reverse/concat strategy so
  it does not build up call stack frames. Each page is fetched with a sleep of
  #{@rate_limit_sleep_ms}ms between requests to respect Jikan rate limits.

  Returns `{:ok, all_data}` on success or `{:error, reason}` on the first failure.
  """
  @spec get_paginated(String.t(), keyword()) :: {:ok, list()} | {:error, term()}
  def get_paginated(path, params \\ []) do
    do_get_paginated(path, params, _page = 1, _acc = [])
  end

  @doc """
  Streams through all pages of a paginated endpoint, invoking `callback` for
  each page rather than accumulating all data in memory.

  The callback receives `(page_data, page_number)` where `page_data` is the
  list from the `"data"` key and `page_number` is the 1-based page index.

  The callback's return value is collected into a list so callers can accumulate
  a reduced result if desired.

  Returns `{:ok, [callback_results]}` on success or `{:error, reason}` on the
  first failure.

  ## Example

      {:ok, counts} =
        Yunaos.Jikan.Client.get_all_pages("/anime", [q: "Naruto"], fn data, _page ->
          length(data)
        end)

      total = Enum.sum(counts)
  """
  @spec get_all_pages(String.t(), keyword(), (list(), pos_integer() -> term())) ::
          {:ok, list()} | {:error, term()}
  def get_all_pages(path, params \\ [], callback) do
    do_get_all_pages(path, params, callback, _page = 1, _acc = [])
  end

  # ---------------------------------------------------------------------------
  # Private helpers
  # ---------------------------------------------------------------------------

  defp build_url(path), do: @base_url <> path

  # Performs the HTTP GET with manual 429 retry handling on top of Req's
  # built-in transient retry for network errors.
  defp do_get(url, params, retries_left) do
    result =
      Req.get(url,
        params: params,
        retry: :transient,
        retry_delay: &retry_delay/1,
        max_retries: @max_retries
      )

    case result do
      {:ok, %Req.Response{status: 429} = response} when retries_left > 0 ->
        delay = get_retry_after(response.headers)

        Logger.warning(
          "Jikan rate limited (429). Retrying in #{delay}ms " <>
            "(#{retries_left - 1} retries remaining)"
        )

        Process.sleep(delay)
        do_get(url, params, retries_left - 1)

      {:ok, %Req.Response{status: 429}} = final ->
        Logger.error("Jikan rate limited (429). No retries remaining.")
        final

      other ->
        other
    end
  end

  # Tail-recursive paginator that collects all data.
  # We prepend each page's data (reversed) to the accumulator and do a final
  # Enum.reverse at the end, giving us O(n) concatenation instead of O(n^2)
  # from repeated `acc ++ data`.
  defp do_get_paginated(path, params, page, acc) do
    case get(path, Keyword.put(params, :page, page)) do
      {:ok, %{"data" => data, "pagination" => %{"has_next_page" => true}}} ->
        Process.sleep(@rate_limit_sleep_ms)
        do_get_paginated(path, params, page + 1, prepend_reversed(data, acc))

      {:ok, %{"data" => data, "pagination" => %{"has_next_page" => false}}} ->
        {:ok, finalize(data, acc)}

      # Some endpoints return data without pagination info (single-page results).
      {:ok, %{"data" => data}} ->
        {:ok, finalize(data, acc)}

      {:error, _} = error ->
        error
    end
  end

  # Tail-recursive page streamer that invokes a callback per page.
  defp do_get_all_pages(path, params, callback, page, acc) do
    case get(path, Keyword.put(params, :page, page)) do
      {:ok, %{"data" => data, "pagination" => %{"has_next_page" => true}}} ->
        result = callback.(data, page)
        Process.sleep(@rate_limit_sleep_ms)
        do_get_all_pages(path, params, callback, page + 1, [result | acc])

      {:ok, %{"data" => data, "pagination" => %{"has_next_page" => false}}} ->
        result = callback.(data, page)
        {:ok, Enum.reverse([result | acc])}

      {:ok, %{"data" => data}} ->
        result = callback.(data, page)
        {:ok, Enum.reverse([result | acc])}

      {:error, _} = error ->
        error
    end
  end

  # Prepends items from `data` (in reverse order) onto `acc` so that a final
  # Enum.reverse produces the correct overall ordering.
  defp prepend_reversed(data, acc) do
    Enum.reduce(data, acc, fn item, a -> [item | a] end)
  end

  defp finalize(data, acc) do
    acc
    |> prepend_reversed(data)
    |> Enum.reverse()
  end

  # Calculates retry delay with linear backoff.
  defp retry_delay(retry_count) do
    @retry_delay_ms * retry_count
  end

  # Extracts the Retry-After header value (in seconds) and converts to
  # milliseconds. Falls back to 2000ms when the header is absent.
  defp get_retry_after(headers) do
    case Map.get(headers, "retry-after") do
      [value | _] -> parse_retry_after(value)
      _ -> 2_000
    end
  end

  defp parse_retry_after(value) when is_binary(value) do
    case Integer.parse(value) do
      {seconds, _} -> seconds * 1_000
      :error -> 2_000
    end
  end

  defp parse_retry_after(_), do: 2_000
end
