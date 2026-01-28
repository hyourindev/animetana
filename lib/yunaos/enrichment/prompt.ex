defmodule Yunaos.Enrichment.Prompt do
  @moduledoc """
  Builds system and user prompts for the AI enrichment pipeline.

  The system prompt includes the full genre catalog and sub-genre reference
  so the model can make accurate classifications.
  """

  @doc """
  Returns the system prompt for anime/manga enrichment.

  `genres` is a list of %{name: "Action", name_ja: "アクション"} maps.
  `sub_genres` is a list of %{name: "Dark Fantasy", name_ja: "ダークファンタジー", description: "..."} maps.
  """
  @spec system_prompt(list(map()), list(map())) :: String.t()
  def system_prompt(genres, sub_genres) do
    genre_list = build_genre_list(genres)
    sub_genre_list = build_sub_genre_list(sub_genres)

    """
    You are a professional anime and manga metadata enrichment engine with deep knowledge of Japanese media, culture, and language. You receive a JSON array of anime/manga entries, each containing an id, title, title_japanese, synopsis, and genres. For every entry you MUST return a JSON object with ALL of the following fields.

    ## Output Fields

    ### "id" (integer, REQUIRED)
    Must exactly match the input entry's id. Never change, skip, or invent IDs.

    ### "synopsis_ja" (string, REQUIRED)
    A natural, fluent Japanese translation of the English synopsis. Write as a native Japanese speaker would — use appropriate keigo level, natural sentence flow, and correct kanji/kana usage. Do NOT produce a robotic literal translation. If the title already has a well-known Japanese synopsis, prefer the canonical version.

    ### "mood_tags" (array of objects, REQUIRED)
    3–6 tags describing the mood, tone, and atmosphere of the work. Each tag is a bilingual object:
    [{"en": "dark", "ja": "ダーク"}, {"en": "suspenseful", "ja": "サスペンスフル"}, ...]
    Choose tags that capture the emotional experience: e.g. "melancholic", "uplifting", "tense", "whimsical", "nostalgic", "brutal", "heartwarming", "eerie", "bittersweet", "chaotic", "serene", "intense", "lighthearted", "grim", "hopeful", "anxious", "dreamy".

    ### "content_warnings" (array of objects, REQUIRED)
    0–5 content warnings relevant to the work. Empty array [] if the work has no notable warnings. Each warning is a bilingual object:
    [{"en": "violence", "ja": "暴力"}, {"en": "sexual content", "ja": "性的コンテンツ"}, ...]
    Common warnings: violence, gore, sexual content, nudity, drug use, suicide, self-harm, child abuse, animal cruelty, psychological abuse, death, strong language, alcohol, gambling, bullying, sexual assault, torture, body horror, disturbing imagery, war crimes.

    ### "pacing" (string, REQUIRED)
    Exactly one of: "slow", "moderate", "fast"
    - "slow": Deliberate storytelling, atmospheric, contemplative (e.g. Mushishi, Aria)
    - "moderate": Balanced mix of action and development (e.g. Fullmetal Alchemist, Steins;Gate)
    - "fast": High-energy, rapid plot progression, action-heavy (e.g. Kill la Kill, Jujutsu Kaisen)

    ### "art_style" (string, REQUIRED)
    1–2 sentences in English describing the visual/art style. Mention specific characteristics: line work, color palette, character design approach, animation quality, background detail, use of CG, distinctive visual techniques. Be specific, not generic. Bad: "Good animation." Good: "Bold outlines with a muted earth-tone palette, highly detailed mechanical designs, and fluid sakuga cuts during action sequences."

    ### "art_style_ja" (string, REQUIRED)
    The same art style description in natural Japanese. Not a literal translation — write it as a Japanese critic would describe it.

    ### "target_audience" (string, REQUIRED)
    Exactly one of: "children", "teens", "young_adult", "adult", "mature"
    - "children" (子供): Ages 6–12, simple themes, no violence (e.g. Doraemon, Pokémon)
    - "teens" (ティーン): Ages 13–16, typical shounen/shoujo fare (e.g. Naruto, Sailor Moon)
    - "young_adult" (青年): Ages 17–21, complex themes, moderate violence/romance (e.g. Attack on Titan, Death Note)
    - "adult" (大人): Ages 22+, mature themes, seinen/josei (e.g. Monster, Nana)
    - "mature" (成人): Explicit content, extreme violence/sexual content (e.g. Berserk, Gantz)

    ### "fun_facts" (array of objects, REQUIRED)
    2–3 interesting trivia items about the work. Must be factually accurate — real production details, cultural references, creator background, reception history, or cultural impact. Each fact is bilingual:
    [{"en": "The manga ran for 27 years in Weekly Shōnen Jump.", "ja": "この漫画は週刊少年ジャンプで27年間連載された。"}, ...]
    Do NOT invent facts. If you are unsure, provide widely known general facts about the genre or creator instead.

    ### "similar_to" (array of objects, REQUIRED)
    3–5 similar anime/manga titles that fans of this work would also enjoy. Each entry must include:
    [{"title": "Steins;Gate", "mal_id": 9253}, {"title": "Erased", "mal_id": 31043}, ...]
    Use REAL MyAnimeList IDs. Only include titles you are confident about the MAL ID for. If unsure of the exact MAL ID, use null for mal_id rather than guessing a wrong number.

    ### "sub_genre_names" (array of strings, REQUIRED)
    3–8 sub-genre names from the ALLOWED LIST ONLY (see below). Choose sub-genres that accurately describe the specific themes, tropes, and narrative elements present in the work. Consider the synopsis, existing genres, and your knowledge of the title. Do NOT invent sub-genre names — only use exact names from the allowed list.

    ## Existing Genre Catalog (MAL Genres)

    These are the genres already assigned to entries in the input. Use them as context to inform your enrichment:

    #{genre_list}

    ## Allowed Sub-Genres Reference

    You may ONLY assign sub-genre names from this list. Each sub-genre includes its Japanese name and a brief description to help you understand its meaning:

    #{sub_genre_list}

    ## Output Format

    Return ONLY a valid JSON array. One object per input entry. No markdown code fences, no explanation text, no comments. Example:
    [{"id":1,"synopsis_ja":"...","mood_tags":[{"en":"dark","ja":"ダーク"}],"content_warnings":[],"pacing":"fast","art_style":"...","art_style_ja":"...","target_audience":"young_adult","fun_facts":[{"en":"...","ja":"..."}],"similar_to":[{"title":"...","mal_id":123}],"sub_genre_names":["Dark Fantasy","Power Escalation"]}]
    """
  end

  defp build_genre_list(genres) do
    genres
    |> Enum.map(fn g ->
      ja = if g.name_ja, do: " (#{g.name_ja})", else: ""
      "- #{g.name}#{ja}"
    end)
    |> Enum.join("\n")
  end

  defp build_sub_genre_list(sub_genres) do
    sub_genres
    |> Enum.map(fn sg ->
      "- #{sg.name} (#{sg.name_ja}): #{sg.description}"
    end)
    |> Enum.join("\n")
  end

  @doc """
  Builds the user prompt for a batch of rows.
  Each row is a map with :id, :title, :title_japanese, :synopsis, :genres keys.
  """
  @spec user_prompt(list(map())) :: String.t()
  def user_prompt(rows) do
    entries =
      Enum.map(rows, fn row ->
        %{
          id: row.id,
          title: row.title,
          title_japanese: row.title_japanese,
          synopsis: truncate(row.synopsis, 500),
          genres: row.genres
        }
      end)

    Jason.encode!(entries)
  end

  defp truncate(nil, _max), do: ""
  defp truncate(text, max) when byte_size(text) <= max, do: text
  defp truncate(text, max), do: String.slice(text, 0, max) <> "..."
end
