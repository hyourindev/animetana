defmodule Yunaos.Jikan.WorkerRegistry do
  @moduledoc """
  Maps CollectionStrategy job IDs to their corresponding worker modules.
  """

  alias Yunaos.Jikan.Workers

  @job_to_worker %{
    # Phase 1: Foundational Taxonomies
    genres: Workers.GenresWorker,
    studios: Workers.StudiosWorker,
    people_basic: Workers.PeopleWorker,
    magazines: Workers.MagazinesWorker,

    # Phase 2: Complete Content Catalog
    anime_catalog: Workers.AnimeCatalogWorker,
    manga_catalog: Workers.MangaCatalogWorker,
    characters_basic: Workers.CharactersCatalogWorker,

    # Phase 3: Anime Enrichment
    anime_full_details: Workers.AnimeFullWorker,
    anime_characters: Workers.AnimeCharactersWorker,
    anime_staff: Workers.AnimeStaffWorker,
    anime_relations: Workers.AnimeRelationsWorker,
    anime_episodes: Workers.AnimeEpisodesWorker,
    anime_statistics: Workers.AnimeStatisticsWorker,
    anime_pictures: Workers.AnimePicturesWorker,
    anime_moreinfo: Workers.AnimeMoreinfoWorker,

    # Phase 4: Manga Enrichment
    manga_full_details: Workers.MangaFullWorker,
    manga_characters: Workers.MangaCharactersWorker,
    manga_relations: Workers.MangaRelationsWorker,
    manga_statistics: Workers.MangaStatisticsWorker,
    manga_pictures: Workers.MangaPicturesWorker,
    manga_moreinfo: Workers.MangaMoreinfoWorker,

    # Phase 5: Deep Character & People Data
    characters_full: Workers.CharactersFullWorker,
    people_full: Workers.PeopleFullWorker,
    character_voices: Workers.CharacterVoicesWorker,
    people_works: Workers.PeopleWorksWorker,
    character_pictures: Workers.CharacterPicturesWorker,
    people_pictures: Workers.PeoplePicturesWorker,

    # Phase 6: Universe Data (stubs)
    reviews: Workers.ReviewsWorker,
    recommendations: Workers.RecommendationsWorker,
    news: Workers.NewsWorker
  }

  @doc "Returns the worker module for a given job ID atom."
  def worker_for(job_id) when is_atom(job_id) do
    Map.fetch!(@job_to_worker, job_id)
  end

  @doc "Returns all known job IDs."
  def all_job_ids, do: Map.keys(@job_to_worker)
end
