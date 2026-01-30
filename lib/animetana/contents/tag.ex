defmodule Animetana.Contents.Tag do
  @moduledoc """
  Schema for tags in the contents.tags table.
  Tags have replaced genres and include themes, settings, cast, demographics, etc.
  """
  use Ecto.Schema

  @type t :: %__MODULE__{}

  @primary_key {:id, :id, autogenerate: true}
  @schema_prefix "contents"

  schema "tags" do
    field :anilist_id, :integer

    # Names (trilingual)
    field :name_en, :string
    field :name_ja, :string
    field :name_romaji, :string

    # Descriptions
    field :description_en, :string
    field :description_ja, :string

    # Category
    field :category, :string

    # Flags
    field :is_general_spoiler, :boolean, default: false
    field :is_adult, :boolean, default: false

    timestamps(type: :naive_datetime)
  end

  @doc """
  Returns the display name based on locale.
  """
  def display_name(%__MODULE__{} = tag, locale) when locale in ["ja", :ja] do
    tag.name_ja || tag.name_romaji || tag.name_en || "Unknown"
  end

  def display_name(%__MODULE__{} = tag, _locale) do
    tag.name_en || tag.name_romaji || tag.name_ja || "Unknown"
  end

  @doc """
  Returns all valid tag categories.
  """
  def categories do
    ~w(theme setting cast demographic technical sexual_content other)
  end

  @doc """
  Groups tags by their category.
  """
  def group_by_category(tags) do
    Enum.group_by(tags, & &1.category)
  end
end
