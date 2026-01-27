defmodule Yunaos.JikanFixtures do
  @moduledoc "Sample Jikan API responses for testing workers."

  def genre_anime_response do
    %{
      "data" => [
        %{
          "mal_id" => 1,
          "name" => "Action",
          "url" => "https://myanimelist.net/anime/genre/1/Action",
          "count" => 4872
        },
        %{
          "mal_id" => 2,
          "name" => "Adventure",
          "url" => "https://myanimelist.net/anime/genre/2/Adventure",
          "count" => 4512
        }
      ]
    }
  end

  def genre_manga_response do
    %{
      "data" => [
        %{
          "mal_id" => 1,
          "name" => "Action",
          "url" => "https://myanimelist.net/manga/genre/1/Action",
          "count" => 10_035
        },
        %{
          "mal_id" => 25,
          "name" => "Shoujo",
          "url" => "https://myanimelist.net/manga/genre/25/Shoujo",
          "count" => 3000
        }
      ]
    }
  end

  def producers_page_response do
    %{
      "data" => [
        %{
          "mal_id" => 1,
          "url" => "https://myanimelist.net/anime/producer/1",
          "titles" => [
            %{"type" => "Default", "title" => "Studio Pierrot"},
            %{"type" => "Japanese", "title" => "ぴえろ"}
          ],
          "images" => %{
            "jpg" => %{"image_url" => "https://cdn.myanimelist.net/images/company/1.png"}
          },
          "favorites" => 100,
          "established" => "1979-05-01T00:00:00+00:00",
          "about" => "Studio Pierrot Co.",
          "count" => 326
        }
      ],
      "pagination" => %{"has_next_page" => false, "last_visible_page" => 1}
    }
  end

  def producers_multi_response do
    %{
      "data" => [
        %{
          "mal_id" => 1,
          "url" => "https://myanimelist.net/anime/producer/1",
          "titles" => [
            %{"type" => "Default", "title" => "Studio Pierrot"},
            %{"type" => "Japanese", "title" => "ぴえろ"}
          ],
          "images" => %{
            "jpg" => %{"image_url" => "https://cdn.myanimelist.net/images/company/1.png"}
          },
          "favorites" => 100,
          "established" => "1979-05-01T00:00:00+00:00",
          "about" => "Studio Pierrot Co.",
          "count" => 326
        },
        %{
          "mal_id" => 2,
          "url" => "https://myanimelist.net/anime/producer/2",
          "titles" => [
            %{"type" => "Default", "title" => "Kyoto Animation"}
          ],
          "images" => %{
            "jpg" => %{"image_url" => "https://cdn.myanimelist.net/images/company/2.png"}
          },
          "favorites" => 200,
          "established" => "1981-07-12T00:00:00+00:00",
          "about" => "Kyoto Animation Co., Ltd.",
          "count" => 150
        },
        %{
          "mal_id" => 3,
          "url" => "https://myanimelist.net/anime/producer/3",
          "titles" => [
            %{"type" => "Japanese", "title" => "無名スタジオ"}
          ],
          "images" => %{"jpg" => %{"image_url" => nil}},
          "favorites" => 0,
          "established" => nil,
          "about" => nil,
          "count" => 5
        }
      ],
      "pagination" => %{"has_next_page" => false, "last_visible_page" => 1}
    }
  end

  def people_page_response do
    %{
      "data" => [
        %{
          "mal_id" => 1,
          "url" => "https://myanimelist.net/people/1/Tomokazu_Seki",
          "website_url" => nil,
          "images" => %{
            "jpg" => %{
              "image_url" => "https://cdn.myanimelist.net/images/voiceactors/1/85360.jpg"
            }
          },
          "name" => "Seki, Tomokazu",
          "given_name" => "智一",
          "family_name" => "関",
          "alternate_names" => ["Seki Mondoya", "門戸 開"],
          "birthday" => "1972-09-08T00:00:00+00:00",
          "favorites" => 6243,
          "about" => "Hometown: Tokyo"
        }
      ],
      "pagination" => %{"has_next_page" => false, "last_visible_page" => 1}
    }
  end

  def people_multi_response do
    %{
      "data" => [
        %{
          "mal_id" => 1,
          "url" => "https://myanimelist.net/people/1/Tomokazu_Seki",
          "website_url" => nil,
          "images" => %{
            "jpg" => %{
              "image_url" => "https://cdn.myanimelist.net/images/voiceactors/1/85360.jpg"
            }
          },
          "name" => "Seki, Tomokazu",
          "given_name" => "智一",
          "family_name" => "関",
          "alternate_names" => ["Seki Mondoya", "門戸 開"],
          "birthday" => "1972-09-08T00:00:00+00:00",
          "favorites" => 6243,
          "about" => "Hometown: Tokyo"
        },
        %{
          "mal_id" => 2,
          "url" => "https://myanimelist.net/people/2/Kana_Hanazawa",
          "website_url" => "https://www.hanazawakana.com",
          "images" => %{
            "jpg" => %{
              "image_url" => "https://cdn.myanimelist.net/images/voiceactors/2/12345.jpg"
            }
          },
          "name" => "Hanazawa, Kana",
          "given_name" => "花澤",
          "family_name" => "香菜",
          "alternate_names" => [],
          "birthday" => "1989-02-25T00:00:00+00:00",
          "favorites" => 15_000,
          "about" => "Birthplace: Tokyo, Japan"
        },
        %{
          "mal_id" => 3,
          "url" => "https://myanimelist.net/people/3/Unknown",
          "website_url" => nil,
          "images" => %{"jpg" => %{"image_url" => nil}},
          "name" => "Unknown Person",
          "given_name" => nil,
          "family_name" => nil,
          "alternate_names" => nil,
          "birthday" => nil,
          "favorites" => nil,
          "about" => nil
        }
      ],
      "pagination" => %{"has_next_page" => false, "last_visible_page" => 1}
    }
  end

  def magazines_page_response do
    %{
      "data" => [
        %{
          "mal_id" => 1,
          "name" => "Big Comic Original",
          "url" => "https://myanimelist.net/manga/magazine/1/Big_Comic_Original",
          "count" => 101
        }
      ],
      "pagination" => %{"has_next_page" => false, "last_visible_page" => 1}
    }
  end

  def magazines_multi_response do
    %{
      "data" => [
        %{
          "mal_id" => 1,
          "name" => "Big Comic Original",
          "url" => "https://myanimelist.net/manga/magazine/1/Big_Comic_Original",
          "count" => 101
        },
        %{
          "mal_id" => 2,
          "name" => "Weekly Shounen Jump",
          "url" => "https://myanimelist.net/manga/magazine/2/Weekly_Shounen_Jump",
          "count" => 500
        },
        %{
          "mal_id" => 3,
          "name" => "Monthly Shounen Magazine",
          "url" => "https://myanimelist.net/manga/magazine/3/Monthly_Shounen_Magazine",
          "count" => 200
        }
      ],
      "pagination" => %{"has_next_page" => false, "last_visible_page" => 1}
    }
  end
end
