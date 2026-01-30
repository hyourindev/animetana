defmodule Animetana.Contents.Anime do
  @moduledoc """
  Schema for anime entries in the contents.anime table.
  """
  use Ecto.Schema

  @type t :: %__MODULE__{}

  @primary_key {:id, :id, autogenerate: true}
  @schema_prefix "contents"

  schema "anime" do
    # External IDs
    field :mal_id, :integer
    field :anilist_id, :integer
    field :kitsu_id, :integer

    # Titles
    field :title_en, :string
    field :title_ja, :string
    field :title_romaji, :string
    field :title_synonyms, {:array, :string}, default: []

    # Descriptions
    field :synopsis_en, :string
    field :synopsis_ja, :string
    field :synopsis_html, :string
    field :background_en, :string
    field :background_ja, :string

    # Format & Status (stored as strings, cast from enums)
    field :format, :string
    field :status, :string
    field :source, :string

    # Season & Timing
    field :season, :string
    field :season_year, :integer
    field :broadcast_day, :string
    field :broadcast_time, :time

    # Episodes & Duration
    field :episodes, :integer
    field :duration, :integer

    # Dates
    field :start_date, :date
    field :end_date, :date

    # Next Airing
    field :next_airing_episode, :integer
    field :next_airing_at, :naive_datetime

    # Country & Licensing
    field :country_of_origin, :string, default: "JP"
    field :is_licensed, :boolean, default: true
    field :is_adult, :boolean, default: false
    field :hashtag, :string

    # Images
    field :cover_image_extra_large, :string
    field :cover_image_large, :string
    field :cover_image_medium, :string
    field :cover_image_color, :string
    field :banner_image, :string

    # Trailer
    field :trailer_id, :string
    field :trailer_site, :string
    field :trailer_thumbnail, :string

    # External Links
    field :external_links, {:array, :map}, default: []
    field :streaming_links, {:array, :map}, default: []

    # Site URLs
    field :anilist_url, :string
    field :mal_url, :string

    # Scores - English community (db columns still named yunaos_*)
    field :score_en, :decimal, source: :yunaos_score_en
    field :scored_by_en, :integer, source: :yunaos_scored_by_en
    field :rank_en, :integer, source: :yunaos_rank_en
    field :popularity_en, :integer, source: :yunaos_popularity_en
    field :favorites_en, :integer, source: :yunaos_favorites_en
    field :trending_en, :integer, source: :yunaos_trending_en

    # Scores - Japanese community (db columns still named yunaos_*)
    field :score_ja, :decimal, source: :yunaos_score_ja
    field :scored_by_ja, :integer, source: :yunaos_scored_by_ja
    field :rank_ja, :integer, source: :yunaos_rank_ja
    field :popularity_ja, :integer, source: :yunaos_popularity_ja
    field :favorites_ja, :integer, source: :yunaos_favorites_ja
    field :trending_ja, :integer, source: :yunaos_trending_ja

    # Aggregated Stats
    field :average_rating, :decimal
    field :rating_count, :integer
    field :members_count, :integer
    field :favorites_count, :integer

    # Algorithm Scores
    field :quality_score, :decimal
    field :engagement_score, :decimal
    field :trending_score, :decimal

    # Metadata
    field :last_synced_at, :naive_datetime
    field :deleted_at, :naive_datetime

    timestamps(type: :naive_datetime)
  end

  @doc """
  Returns the display title based on locale.
  Falls back to romaji -> english -> japanese if preferred is nil.
  """
  def display_title(%__MODULE__{} = anime, locale) when locale in ["ja", :ja] do
    anime.title_ja || anime.title_romaji || anime.title_en || "Unknown"
  end

  def display_title(%__MODULE__{} = anime, _locale) do
    anime.title_en || anime.title_romaji || anime.title_ja || "Unknown"
  end

  @doc """
  Returns the display synopsis based on locale.
  """
  def display_synopsis(%__MODULE__{} = anime, locale) when locale in ["ja", :ja] do
    anime.synopsis_ja || anime.synopsis_en
  end

  def display_synopsis(%__MODULE__{} = anime, _locale) do
    anime.synopsis_en || anime.synopsis_ja
  end
end
