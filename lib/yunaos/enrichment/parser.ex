defmodule Yunaos.Enrichment.Parser do
  @moduledoc """
  Parses and validates the JSON response from Gemini,
  mapping it to database-ready update maps.
  """

  require Logger

  @valid_pacing ~w(slow moderate fast)
  @valid_audience ~w(children teens young_adult adult mature)

  @doc """
  Parses the raw JSON string from Gemini into a list of enrichment maps.

  `sub_genre_lookup` is a map of %{"Name" => id} for resolving sub_genre_names to IDs.

  Returns `{:ok, [enrichment_map]}` or `{:error, reason}`.
  """
  @spec parse(String.t(), map()) :: {:ok, list(map())} | {:error, term()}
  def parse(raw_json, sub_genre_lookup) do
    # Strip markdown code fences if the model wraps them
    cleaned =
      raw_json
      |> String.trim()
      |> strip_code_fences()

    case Jason.decode(cleaned) do
      {:ok, items} when is_list(items) ->
        parsed = Enum.map(items, &parse_item(&1, sub_genre_lookup))
        {:ok, parsed}

      {:ok, item} when is_map(item) ->
        {:ok, [parse_item(item, sub_genre_lookup)]}

      {:error, reason} ->
        Logger.error("Failed to parse Gemini response: #{inspect(reason)}")
        {:error, {:json_parse, reason}}
    end
  end

  defp strip_code_fences(text) do
    text
    |> String.replace(~r/\A```(?:json)?\s*\n?/, "")
    |> String.replace(~r/\n?```\s*\z/, "")
  end

  defp parse_item(item, sub_genre_lookup) when is_map(item) do
    sub_genre_ids =
      item
      |> Map.get("sub_genre_names", [])
      |> Enum.map(&Map.get(sub_genre_lookup, &1))
      |> Enum.reject(&is_nil/1)

    %{
      id: item["id"],
      synopsis_ja: safe_string(item["synopsis_ja"]),
      mood_tags: safe_json_array(item["mood_tags"]),
      content_warnings: safe_json_array(item["content_warnings"]),
      pacing: safe_enum(item["pacing"], @valid_pacing),
      art_style: safe_string(item["art_style"]),
      art_style_ja: safe_string(item["art_style_ja"]),
      target_audience: safe_enum(item["target_audience"], @valid_audience),
      fun_facts: safe_json_array(item["fun_facts"]),
      similar_to: safe_json_array(item["similar_to"]),
      sub_genre_ids: sub_genre_ids
    }
  end

  defp parse_item(other, _lookup) do
    Logger.warning("Skipping non-map item in response: #{inspect(other)}")
    nil
  end

  defp safe_string(val) when is_binary(val), do: val
  defp safe_string(_), do: nil

  defp safe_enum(val, valid) when is_binary(val) do
    if val in valid, do: val, else: nil
  end

  defp safe_enum(_, _), do: nil

  defp safe_json_array(val) when is_list(val), do: val
  defp safe_json_array(_), do: nil
end
