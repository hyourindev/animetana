defmodule Yunaos.Jikan.CollectionStrategy do
  @moduledoc """
  Jikan Data Collection Strategy - Complete MAL Database Ingestion

  Defines all 29 collection jobs across 6 phases, their dependencies,
  API endpoints, and estimated request volumes.

  ## Phases

  1. **Foundational Taxonomies** - Genres, studios, people, magazines (dependencies for everything else)
  2. **Complete Content Catalog** - Every anime, manga, and character (basic records)
  3. **Complete Content Enrichment** - Full anime details, characters, staff, relations, episodes, statistics, pictures, moreinfo
  4. **Complete Manga Enrichment** - Full manga details, characters, relations, statistics, pictures, moreinfo
  5. **Deep Character & People Data** - Full bios, voice actor mappings, filmographies, pictures
  6. **Complete Universe Data** - Reviews, recommendations, news

  ## Rate Limiting

  Jikan enforces 3 req/sec burst, 60 req/min sustained (~1 req/sec effective).
  All jobs must respect this global rate limit.
  """

  # ---------------------------------------------------------------------------
  # Phase 1: Foundational Taxonomies
  # ---------------------------------------------------------------------------

  @phase_1_jobs [
    %{
      id: :genres,
      phase: 1,
      name: "Genre System",
      description: "Fetch all anime and manga genres with MAL IDs",
      endpoints: [
        "GET /genres/anime",
        "GET /genres/manga"
      ],
      target_table: :genres,
      estimated_requests: 2,
      dependencies: []
    },
    %{
      id: :studios,
      phase: 1,
      name: "Producer/Studio Universe",
      description: "Fetch every studio, producer, and licensor via full pagination",
      endpoints: [
        "GET /producers?page={n}"
      ],
      target_table: :studios,
      estimated_requests: 120,
      estimated_records: 3_000,
      dependencies: []
    },
    %{
      id: :people_basic,
      phase: 1,
      name: "People Database",
      description: "Fetch every person (voice actors, directors, writers, composers) via full pagination",
      endpoints: [
        "GET /people?page={n}"
      ],
      target_table: :people,
      estimated_requests: 4_000,
      estimated_records: 100_000,
      dependencies: []
    },
    %{
      id: :magazines,
      phase: 1,
      name: "Magazine Database",
      description: "Fetch every manga magazine/publisher via full pagination",
      endpoints: [
        "GET /magazines?page={n}"
      ],
      target_table: :magazines,
      estimated_requests: 50,
      estimated_records: 1_500,
      dependencies: []
    }
  ]

  # ---------------------------------------------------------------------------
  # Phase 2: Complete Content Catalog
  # ---------------------------------------------------------------------------

  @phase_2_jobs [
    %{
      id: :anime_catalog,
      phase: 2,
      name: "Every Anime Ever",
      description: "Paginate through entire anime database, storing basic info (mal_id, title, type, status, year, genres)",
      endpoints: [
        "GET /anime?page={n}"
      ],
      target_table: :anime,
      estimated_requests: 3_000,
      estimated_records: 50_000,
      dependencies: [:genres, :studios]
    },
    %{
      id: :manga_catalog,
      phase: 2,
      name: "Every Manga Ever",
      description: "Paginate through entire manga database, storing basic info (mal_id, title, type, status, chapters, volumes)",
      endpoints: [
        "GET /manga?page={n}"
      ],
      target_table: :manga,
      estimated_requests: 3_000,
      estimated_records: 50_000,
      dependencies: [:genres]
    },
    %{
      id: :characters_basic,
      phase: 2,
      name: "Every Character Ever",
      description: "Paginate through entire character database, storing basic info with MAL IDs",
      endpoints: [
        "GET /characters?page={n}"
      ],
      target_table: :characters,
      estimated_requests: 4_000,
      estimated_records: 100_000,
      dependencies: []
    }
  ]

  # ---------------------------------------------------------------------------
  # Phase 3: Complete Content Enrichment (Anime)
  # ---------------------------------------------------------------------------

  @phase_3_jobs [
    %{
      id: :anime_full_details,
      phase: 3,
      name: "Full Anime Details",
      description: "Fetch complete metadata, synopsis, statistics, and dates for every anime",
      endpoints: [
        "GET /anime/{id}/full"
      ],
      target_table: :anime,
      estimated_requests: 50_000,
      estimated_hours: 14,
      dependencies: [:anime_catalog]
    },
    %{
      id: :anime_characters,
      phase: 3,
      name: "All Anime Characters",
      description: "Fetch character roles and voice actors for every anime. Maps anime <-> characters <-> voice actors",
      endpoints: [
        "GET /anime/{id}/characters"
      ],
      target_tables: [:anime_characters, :character_voice_actors],
      estimated_requests: 50_000,
      estimated_hours: 14,
      dependencies: [:anime_catalog, :characters_basic, :people_basic]
    },
    %{
      id: :anime_staff,
      phase: 3,
      name: "All Anime Staff",
      description: "Fetch directors, writers, composers, and all staff credits for every anime",
      endpoints: [
        "GET /anime/{id}/staff"
      ],
      target_table: :anime_staff,
      estimated_requests: 50_000,
      estimated_hours: 14,
      dependencies: [:anime_catalog, :people_basic]
    },
    %{
      id: :anime_relations,
      phase: 3,
      name: "All Anime Relations",
      description: "Fetch sequels, prequels, adaptations, and spin-offs for every anime",
      endpoints: [
        "GET /anime/{id}/relations"
      ],
      target_tables: [:anime_relations, :anime_manga_relations],
      estimated_requests: 50_000,
      estimated_hours: 14,
      dependencies: [:anime_catalog, :manga_catalog]
    },
    %{
      id: :anime_episodes,
      phase: 3,
      name: "Complete Episode Data",
      description: "Fetch all episode titles, air dates, and synopses for TV/OVA/ONA anime (skip movies)",
      endpoints: [
        "GET /anime/{id}/episodes"
      ],
      target_table: :episodes,
      estimated_requests: 30_000,
      estimated_hours: 8,
      dependencies: [:anime_catalog],
      filter: "type IN ('tv', 'ova', 'ona')"
    },
    %{
      id: :anime_statistics,
      phase: 3,
      name: "Anime Score Distribution",
      description: "Fetch score distribution (1-10 vote breakdown with counts and percentages) for every anime",
      endpoints: [
        "GET /anime/{id}/statistics"
      ],
      target_table: :score_distributions,
      estimated_requests: 50_000,
      estimated_hours: 14,
      dependencies: [:anime_catalog]
    },
    %{
      id: :anime_pictures,
      phase: 3,
      name: "Anime Picture Galleries",
      description: "Fetch all gallery images (JPG and WebP variants at multiple resolutions) for every anime",
      endpoints: [
        "GET /anime/{id}/pictures"
      ],
      target_table: :pictures,
      estimated_requests: 50_000,
      estimated_hours: 14,
      dependencies: [:anime_catalog]
    },
    %{
      id: :anime_moreinfo,
      phase: 3,
      name: "Anime More Info",
      description: "Fetch additional info text (viewing order, notes) for every anime",
      endpoints: [
        "GET /anime/{id}/moreinfo"
      ],
      target_table: :anime,
      estimated_requests: 50_000,
      estimated_hours: 14,
      dependencies: [:anime_catalog]
    }
  ]

  # ---------------------------------------------------------------------------
  # Phase 4: Complete Manga Enrichment
  # ---------------------------------------------------------------------------

  @phase_4_jobs [
    %{
      id: :manga_full_details,
      phase: 4,
      name: "Full Manga Details",
      description: "Fetch complete metadata, synopsis, and publication info for every manga",
      endpoints: [
        "GET /manga/{id}/full"
      ],
      target_table: :manga,
      estimated_requests: 50_000,
      estimated_hours: 14,
      dependencies: [:manga_catalog]
    },
    %{
      id: :manga_characters,
      phase: 4,
      name: "All Manga Characters",
      description: "Fetch character appearances for every manga",
      endpoints: [
        "GET /manga/{id}/characters"
      ],
      target_table: :manga_characters,
      estimated_requests: 50_000,
      estimated_hours: 14,
      dependencies: [:manga_catalog, :characters_basic]
    },
    %{
      id: :manga_relations,
      phase: 4,
      name: "All Manga Relations",
      description: "Fetch related manga and anime adaptations for every manga",
      endpoints: [
        "GET /manga/{id}/relations"
      ],
      target_tables: [:manga_relations, :anime_manga_relations],
      estimated_requests: 50_000,
      estimated_hours: 14,
      dependencies: [:manga_catalog, :anime_catalog]
    },
    %{
      id: :manga_statistics,
      phase: 4,
      name: "Manga Score Distribution",
      description: "Fetch score distribution (1-10 vote breakdown with counts and percentages) for every manga",
      endpoints: [
        "GET /manga/{id}/statistics"
      ],
      target_table: :score_distributions,
      estimated_requests: 50_000,
      estimated_hours: 14,
      dependencies: [:manga_catalog]
    },
    %{
      id: :manga_pictures,
      phase: 4,
      name: "Manga Picture Galleries",
      description: "Fetch all gallery images (JPG and WebP variants at multiple resolutions) for every manga",
      endpoints: [
        "GET /manga/{id}/pictures"
      ],
      target_table: :pictures,
      estimated_requests: 50_000,
      estimated_hours: 14,
      dependencies: [:manga_catalog]
    },
    %{
      id: :manga_moreinfo,
      phase: 4,
      name: "Manga More Info",
      description: "Fetch additional info text for every manga",
      endpoints: [
        "GET /manga/{id}/moreinfo"
      ],
      target_table: :manga,
      estimated_requests: 50_000,
      estimated_hours: 14,
      dependencies: [:manga_catalog]
    }
  ]

  # ---------------------------------------------------------------------------
  # Phase 5: Deep Character & People Data
  # ---------------------------------------------------------------------------

  @phase_5_jobs [
    %{
      id: :characters_full,
      phase: 5,
      name: "Complete Character Details",
      description: "Fetch full character bios, images, and favorites count for every character",
      endpoints: [
        "GET /characters/{id}/full"
      ],
      target_table: :characters,
      estimated_requests: 100_000,
      estimated_hours: 28,
      dependencies: [:characters_basic]
    },
    %{
      id: :people_full,
      phase: 5,
      name: "Complete People Details",
      description: "Fetch full person bios, birthdays, and images for every person",
      endpoints: [
        "GET /people/{id}/full"
      ],
      target_table: :people,
      estimated_requests: 100_000,
      estimated_hours: 28,
      dependencies: [:people_basic]
    },
    %{
      id: :character_voices,
      phase: 5,
      name: "Character Voice Actor Mapping",
      description: "Fetch all voice actors across different anime for every character. Maps character <-> voice actors <-> languages <-> anime",
      endpoints: [
        "GET /characters/{id}/voices"
      ],
      target_table: :character_voice_actors,
      estimated_requests: 100_000,
      estimated_hours: 28,
      dependencies: [:characters_basic, :people_basic, :anime_catalog]
    },
    %{
      id: :people_works,
      phase: 5,
      name: "People Anime/Manga History",
      description: "Fetch complete filmography for every person (all anime and manga they worked on)",
      endpoints: [
        "GET /people/{id}/anime",
        "GET /people/{id}/manga"
      ],
      target_tables: [:anime_staff, :manga_staff],
      estimated_requests: 200_000,
      estimated_hours: 56,
      dependencies: [:people_basic, :anime_catalog, :manga_catalog]
    },
    %{
      id: :character_pictures,
      phase: 5,
      name: "Character Picture Galleries",
      description: "Fetch all gallery images for every character",
      endpoints: [
        "GET /characters/{id}/pictures"
      ],
      target_table: :pictures,
      estimated_requests: 100_000,
      estimated_hours: 28,
      dependencies: [:characters_basic]
    },
    %{
      id: :people_pictures,
      phase: 5,
      name: "People Picture Galleries",
      description: "Fetch all gallery images for every person",
      endpoints: [
        "GET /people/{id}/pictures"
      ],
      target_table: :pictures,
      estimated_requests: 100_000,
      estimated_hours: 28,
      dependencies: [:people_basic]
    }
  ]

  # ---------------------------------------------------------------------------
  # Phase 6: Complete Universe Data
  # ---------------------------------------------------------------------------

  @phase_6_jobs [
    %{
      id: :reviews,
      phase: 6,
      name: "All Reviews Ever",
      description: "Paginate through all anime and manga reviews on MAL",
      endpoints: [
        "GET /reviews/anime?page={n}",
        "GET /reviews/manga?page={n}"
      ],
      estimated_requests: 10_000,
      dependencies: [:anime_catalog, :manga_catalog]
    },
    %{
      id: :recommendations,
      phase: 6,
      name: "All Recommendations Ever",
      description: "Paginate through all anime and manga recommendations on MAL",
      endpoints: [
        "GET /recommendations/anime?page={n}",
        "GET /recommendations/manga?page={n}"
      ],
      estimated_requests: 10_000,
      dependencies: [:anime_catalog, :manga_catalog]
    },
    %{
      id: :news,
      phase: 6,
      name: "Complete News Archive",
      description: "Fetch all news articles for every anime and manga",
      endpoints: [
        "GET /anime/{id}/news",
        "GET /manga/{id}/news"
      ],
      estimated_requests: 100_000,
      dependencies: [:anime_catalog, :manga_catalog]
    }
  ]

  # ---------------------------------------------------------------------------
  # Public API
  # ---------------------------------------------------------------------------

  @doc "Returns all jobs across all phases in execution order."
  def all_jobs do
    @phase_1_jobs ++ @phase_2_jobs ++ @phase_3_jobs ++ @phase_4_jobs ++ @phase_5_jobs ++ @phase_6_jobs
  end

  @doc "Returns jobs for a specific phase (1-6)."
  def jobs_for_phase(1), do: @phase_1_jobs
  def jobs_for_phase(2), do: @phase_2_jobs
  def jobs_for_phase(3), do: @phase_3_jobs
  def jobs_for_phase(4), do: @phase_4_jobs
  def jobs_for_phase(5), do: @phase_5_jobs
  def jobs_for_phase(6), do: @phase_6_jobs

  @doc "Returns a single job by its ID."
  def get_job(job_id) do
    Enum.find(all_jobs(), fn job -> job.id == job_id end)
  end

  @doc "Returns the total estimated API requests across all jobs."
  def total_estimated_requests do
    all_jobs()
    |> Enum.map(& &1.estimated_requests)
    |> Enum.sum()
  end

  @doc "Returns jobs that are ready to run given a set of completed job IDs."
  def runnable_jobs(completed_job_ids) do
    completed = MapSet.new(completed_job_ids)

    all_jobs()
    |> Enum.filter(fn job ->
      job.id not in completed and
        Enum.all?(job.dependencies, &(&1 in completed))
    end)
  end

  @doc """
  Returns a summary of the collection strategy.

  ## Final Database State

  - Every anime ever on MAL with complete details, pictures, and score distributions
  - Every manga ever on MAL with complete details, pictures, and score distributions
  - Every character with full bios, relationships, and picture galleries
  - Every person with complete filmography and picture galleries
  - Complete relationship graph between all entities
  - All episodes, reviews, news, recommendations
  - All magazines with manga relationships
  """
  def summary do
    jobs = all_jobs()

    phase_totals =
      jobs
      |> Enum.group_by(& &1.phase)
      |> Enum.sort_by(&elem(&1, 0))
      |> Enum.map(fn {phase, phase_jobs} ->
        total = phase_jobs |> Enum.map(& &1.estimated_requests) |> Enum.sum()
        {phase, length(phase_jobs), total}
      end)

    %{
      total_jobs: length(jobs),
      total_phases: 6,
      total_estimated_requests: total_estimated_requests(),
      estimated_hours: div(total_estimated_requests(), 3_600),
      phase_summary: phase_totals
    }
  end
end
