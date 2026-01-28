# AI Enrichment Schema / AI エンリッチメントスキーマ

This document describes all database changes for the AI enrichment pipeline.
このドキュメントは、AIエンリッチメントパイプラインのすべてのデータベース変更を説明します。

---

## New Tables / 新しいテーブル

### `sub_genres` — サブジャンル

Sub-genres provide granular classification beyond MAL's genre/theme system.
サブジャンルは、MALのジャンル/テーマシステムを超えた詳細な分類を提供します。

| Column / カラム | Type / 型 | Description / 説明 |
|---|---|---|
| `id` | serial PK | Primary key / 主キー |
| `name` | string | English name / 英語名 |
| `name_ja` | string | Japanese name / 日本語名 |
| `description` | text | English description / 英語の説明 |
| `description_ja` | text | Japanese description / 日本語の説明 |
| `inserted_at` | utc_datetime | Created timestamp / 作成日時 |

### `genre_sub_genres` — ジャンル・サブジャンル関連

Many-to-many link between genres and sub-genres. A sub-genre can belong to multiple genres.
ジャンルとサブジャンルの多対多リンク。サブジャンルは複数のジャンルに属することができます。

| Column / カラム | Type / 型 | Description / 説明 |
|---|---|---|
| `genre_id` | references genres | Parent genre / 親ジャンル |
| `sub_genre_id` | references sub_genres | Sub-genre / サブジャンル |

### `anime_sub_genres` — アニメ・サブジャンル関連

| Column / カラム | Type / 型 | Description / 説明 |
|---|---|---|
| `anime_id` | references anime | Anime entry / アニメエントリ |
| `sub_genre_id` | references sub_genres | Sub-genre / サブジャンル |

### `manga_sub_genres` — マンガ・サブジャンル関連

| Column / カラム | Type / 型 | Description / 説明 |
|---|---|---|
| `manga_id` | references manga | Manga entry / マンガエントリ |
| `sub_genre_id` | references sub_genres | Sub-genre / サブジャンル |

---

## Altered Tables / 変更されるテーブル

### `anime` — アニメ (new columns / 新しいカラム)

| Column / カラム | Type / 型 | Description / 説明 |
|---|---|---|
| `synopsis_ja` | text | Japanese synopsis / 日本語のあらすじ |
| `mood_tags` | jsonb | Mood/atmosphere tags / 雰囲気タグ. Format: `[{"en": "dark", "ja": "ダーク"}, ...]` |
| `content_warnings` | jsonb | Content warnings / コンテンツ警告. Format: `[{"en": "violence", "ja": "暴力"}, ...]` |
| `similar_to` | jsonb | Similar titles / 類似作品. Format: `[{"title": "...", "mal_id": ...}, ...]` |
| `pacing` | string | Pacing / ペース. Values: `slow` / `moderate` / `fast` (遅い / 普通 / 速い) |
| `art_style` | text | Art style description (EN) / アートスタイルの説明（英語） |
| `art_style_ja` | text | Art style description (JA) / アートスタイルの説明（日本語） |
| `target_audience` | string | Target audience / 対象視聴者. Values: `children` (子供), `teens` (ティーン), `young_adult` (青年), `adult` (大人), `mature` (成人) |
| `fun_facts` | jsonb | Trivia / 豆知識. Format: `[{"en": "...", "ja": "..."}, ...]` |
| `enriched` | boolean | Whether AI enrichment has been applied / AIエンリッチメント済みかどうか. Default: `false` |

### `manga` — マンガ (new columns / 新しいカラム)

| Column / カラム | Type / 型 | Description / 説明 |
|---|---|---|
| `synopsis_ja` | text | Japanese synopsis / 日本語のあらすじ |
| `mood_tags` | jsonb | Mood/atmosphere tags / 雰囲気タグ. Format: `[{"en": "dark", "ja": "ダーク"}, ...]` |
| `content_warnings` | jsonb | Content warnings / コンテンツ警告. Format: `[{"en": "violence", "ja": "暴力"}, ...]` |
| `similar_to` | jsonb | Similar titles / 類似作品. Format: `[{"title": "...", "mal_id": ...}, ...]` |
| `pacing` | string | Pacing / ペース. Values: `slow` / `moderate` / `fast` (遅い / 普通 / 速い) |
| `art_style` | text | Art style description (EN) / アートスタイルの説明（英語） |
| `art_style_ja` | text | Art style description (JA) / アートスタイルの説明（日本語） |
| `target_audience` | string | Target audience / 対象読者. Values: `children` (子供), `teens` (ティーン), `young_adult` (青年), `adult` (大人), `mature` (成人) |
| `fun_facts` | jsonb | Trivia / 豆知識. Format: `[{"en": "...", "ja": "..."}, ...]` |
| `enriched` | boolean | Whether AI enrichment has been applied / AIエンリッチメント済みかどうか. Default: `false` |

### `characters` — キャラクター (new columns / 新しいカラム)

| Column / カラム | Type / 型 | Description / 説明 |
|---|---|---|
| `role_description` | text | Role in the story (EN) / 物語での役割（英語） |
| `role_description_ja` | text | Role in the story (JA) / 物語での役割（日本語） |
| `personality_tags` | jsonb | Personality traits / 性格タグ. Format: `[{"en": "tsundere", "ja": "ツンデレ"}, ...]` |
| `gender` | string | Gender / 性別. Values: `male` (男性), `female` (女性), `non_binary` (ノンバイナリー), `unknown` (不明) |
| `age` | string | Age / 年齢. Free text: `"17"`, `"unknown"` (不明), `"immortal"` (不死) |
| `height` | string | Height / 身長. e.g. `"170cm"` |
| `weight` | string | Weight / 体重. e.g. `"55kg"` |
| `blood_type` | string | Blood type / 血液型. Values: `A`, `B`, `O`, `AB`, `unknown` |
| `measurements` | string | Body measurements / スリーサイズ. e.g. `"B88/W56/H85"` |
| `enriched` | boolean | AI enrichment applied / AIエンリッチメント済み. Default: `false` |

### `people` — 人物 (new columns / 新しいカラム)

| Column / カラム | Type / 型 | Description / 説明 |
|---|---|---|
| `gender` | string | Gender / 性別 |
| `blood_type` | string | Blood type / 血液型. Values: `A`, `B`, `O`, `AB`, `unknown` (不明) |
| `height` | string | Height / 身長. e.g. `"165cm"` |
| `weight` | string | Weight / 体重. e.g. `"50kg"` |
| `measurements` | string | Body measurements / スリーサイズ. e.g. `"B88/W56/H85"` |
| `hometown` | string | Hometown (EN) / 出身地（英語） |
| `hometown_ja` | string | Hometown (JA) / 出身地（日本語） |
| `social_twitter` | string | Twitter/X handle / Twitterアカウント |
| `social_instagram` | string | Instagram handle / Instagramアカウント |
| `social_youtube` | string | YouTube channel URL / YouTubeチャンネル |
| `social_tiktok` | string | TikTok handle / TikTokアカウント |
| `social_website` | string | Personal website / 個人サイト |
| `notable_works` | jsonb | Key works / 代表作. Format: `[{"title": "...", "title_ja": "...", "role": "..."}, ...]` |
| `enriched` | boolean | AI enrichment applied / AIエンリッチメント済み. Default: `false` |

### `genres` / `themes` / `demographics` — ジャンル / テーマ / デモグラフィック (new columns / 新しいカラム)

| Column / カラム | Type / 型 | Description / 説明 |
|---|---|---|
| `name_ja` | string | Japanese name / 日本語名 |
| `description_ja` | text | Japanese description / 日本語の説明 |

---

## Bilingual Data Format / バイリンガルデータ形式

All JSONB tag fields use a consistent bilingual format:
すべてのJSONBタグフィールドは一貫したバイリンガル形式を使用します：

```json
[
  {"en": "dark", "ja": "ダーク"},
  {"en": "psychological", "ja": "心理的"},
  {"en": "violent", "ja": "暴力的"}
]
```

String fields use `_ja` suffix columns for Japanese:
文字列フィールドは日本語用に `_ja` サフィックスカラムを使用します：

```
name     → "Isekai"
name_ja  → "異世界"
```

### Locale Helper / ロケールヘルパー

```elixir
def l(record, field, :ja), do: Map.get(record, :"#{field}_ja") || Map.get(record, field)
def l(record, field, _), do: Map.get(record, field)

# Usage / 使用例:
l(sub_genre, :name, :ja)  #=> "異世界"
l(sub_genre, :name, :en)  #=> "Isekai"
```

---

## Existing Genres / 既存のジャンル

80 genres from MAL (via Jikan API):
MALからの80ジャンル（Jikan API経由）：

| MAL ID | Name / 名前 | Name (JA) / 日本語名 |
|---|---|---|
| 1 | Action | アクション |
| 2 | Adventure | 冒険 |
| 3 | Racing | レース |
| 4 | Comedy | コメディ |
| 5 | Avant Garde | アヴァンギャルド |
| 6 | Mythology | 神話 |
| 7 | Mystery | ミステリー |
| 8 | Drama | ドラマ |
| 9 | Ecchi | エッチ |
| 10 | Fantasy | ファンタジー |
| 11 | Strategy Game | 戦略ゲーム |
| 12 | Hentai | 変態 |
| 13 | Historical | 歴史 |
| 14 | Horror | ホラー |
| 15 | Kids | キッズ |
| 17 | Martial Arts | 格闘技 |
| 18 | Mecha | メカ |
| 19 | Music | 音楽 |
| 20 | Parody | パロディ |
| 21 | Samurai | 侍 |
| 22 | Romance | 恋愛 |
| 23 | School | 学園 |
| 24 | Sci-Fi | SF |
| 25 | Shoujo | 少女 |
| 26 | Girls Love | 百合 |
| 27 | Shounen | 少年 |
| 28 | Boys Love | ボーイズラブ |
| 29 | Space | 宇宙 |
| 30 | Sports | スポーツ |
| 31 | Super Power | 超能力 |
| 32 | Vampire | 吸血鬼 |
| 35 | Harem | ハーレム |
| 36 | Slice of Life | 日常 |
| 37 | Supernatural | 超自然 |
| 38 | Military | 軍事 |
| 39 | Detective | 探偵 |
| 40 | Psychological | 心理 |
| 41 | Suspense | サスペンス |
| 42 | Seinen | 青年 |
| 43 | Josei | 女性 |
| 44 | Crossdressing | 女装・男装 |
| 45 | Suspense (manga) | サスペンス（マンガ） |
| 46 | Award Winning | 受賞作品 |
| 47 | Gourmet | グルメ |
| 48 | Workplace | 職場 |
| 49 | Erotica | エロティカ |
| 50 | Adult Cast | 大人キャスト |
| 51 | Anthropomorphic | 擬人化 |
| 52 | CGDCT | 可愛い女の子日常系 |
| 53 | Childcare | 育児 |
| 54 | Combat Sports | 格闘スポーツ |
| 55 | Delinquents | 不良 |
| 56 | Educational | 教育 |
| 57 | Gag Humor | ギャグ |
| 58 | Gore | ゴア |
| 59 | High Stakes Game | 頭脳ゲーム |
| 60 | Idols (Female) | アイドル（女性） |
| 61 | Idols (Male) | アイドル（男性） |
| 62 | Isekai | 異世界 |
| 63 | Iyashikei | 癒し系 |
| 64 | Love Polygon | 三角関係 |
| 65 | Magical Sex Shift | 性転換 |
| 66 | Mahou Shoujo | 魔法少女 |
| 67 | Medical | 医療 |
| 68 | Organized Crime | 組織犯罪 |
| 69 | Otaku Culture | オタク文化 |
| 70 | Performing Arts | 舞台芸術 |
| 71 | Pets | ペット |
| 72 | Reincarnation | 転生 |
| 73 | Reverse Harem | 逆ハーレム |
| 74 | Love Status Quo | 恋愛現状維持 |
| 75 | Showbiz | 芸能界 |
| 76 | Survival | サバイバル |
| 77 | Team Sports | チームスポーツ |
| 78 | Time Travel | タイムトラベル |
| 79 | Video Game | ビデオゲーム |
| 80 | Visual Arts | ビジュアルアーツ |
| 81 | Crossdressing | 女装・男装 |
| 82 | Urban Fantasy | 都市ファンタジー |
| 83 | Villainess | 悪役令嬢 |

---

## Sub-Genre Seed / サブジャンルシード

Sub-genres with their parent genre associations.
サブジャンルと親ジャンルの関連。

Target: ~1000 sub-genres across all genres.
目標：全ジャンルで約1000のサブジャンル。

### Action / アクション (mal_id: 1)
| Name | Name (JA) | Description | Description (JA) |
|---|---|---|---|
| Battle Royale | バトルロイヤル | Characters fight in a free-for-all elimination contest | キャラクターが自由参加の殲滅戦で戦う |
| Swordfight | 剣戟 | Combat focused on bladed weapons and swordplay | 刀剣を用いた戦闘が中心 |
| Gun Action | ガンアクション | Firearms and gunfights as primary combat | 銃器と銃撃戦が主要な戦闘手段 |
| Hand-to-Hand Combat | 格闘戦 | Close quarters fighting without weapons | 武器を使わない近接格闘 |
| Aerial Combat | 空中戦 | Dogfights, air battles, flying combat | 空中での戦闘・ドッグファイト |
| Naval Combat | 海戦 | Sea-based warfare and ship battles | 海上での戦争・艦船バトル |
| Assassination | 暗殺 | Stealth kills, hitmen, and covert operations | 暗殺者、ヒットマン、秘密作戦 |
| Tournament Arc | トーナメント | Structured competitive fighting brackets | 構造化された対戦トーナメント |
| Power Escalation | パワーインフレ | Characters progressively become stronger over time | キャラクターが時間とともに強くなっていく |
| Siege Battle | 攻城戦 | Large-scale fortress or territory defense/attack | 大規模な城塞・領地の攻防 |
| Revenge | 復讐 | Protagonist driven by desire for vengeance | 復讐心に駆られた主人公 |
| Berserker | 狂戦士 | Characters entering uncontrollable rage in combat | 戦闘中に制御不能な怒りに入るキャラクター |
| Weapon Master | 武器の達人 | Focus on mastering a specific weapon type | 特定の武器の習得に焦点を当てる |
| Arena Combat | 闘技場 | Fighting in gladiatorial arenas for survival or glory | 生存または栄光のために闘技場で戦う |
| Bodyguard | ボディガード | Protecting a VIP from threats and enemies | VIPを脅威や敵から守る |
| Bounty Hunter | 賞金稼ぎ | Hunting targets for money or reward | 金銭や報酬のために標的を狩る |
| Gang War | 抗争 | Turf battles between rival gangs or factions | ライバルギャングや派閥間の縄張り争い |
| Rescue Mission | 救出作戦 | Action centered on saving captives or hostages | 捕虜や人質を救出するアクション |
| Dual Wielding | 二刀流 | Characters fighting with two weapons simultaneously | 二つの武器を同時に使って戦うキャラクター |
| Chain Battle | 連戦 | Consecutive fights without rest between them | 休みなく続く連続戦闘 |
| Ambush Tactics | 奇襲戦術 | Combat focused on surprise attacks and traps | 奇襲や罠を中心とした戦闘 |
| Last Stand | 最後の抵抗 | Outnumbered heroes making a final desperate stand | 劣勢の英雄たちが最後の抵抗をする |
| Duel | 決闘 | One-on-one formalized combat encounters | 一対一の正式な戦闘 |
| Rampage | 暴走 | Unstoppable destructive force on the loose | 制御不能な破壊力の解放 |
| Guerrilla Action | ゲリラアクション | Hit-and-run tactics against stronger forces | 優勢な敵に対する奇襲戦術 |
| Vehicular Combat | 車両戦闘 | Fights using cars, tanks, or other vehicles | 車、戦車、その他の乗り物を使った戦闘 |
| Underground Fighting | 地下格闘 | Illegal or secret fighting rings | 違法または秘密の格闘リング |
| Superhero Combat | ヒーロー戦闘 | Costumed heroes fighting villains | コスチュームのヒーローが悪役と戦う |
| Wuxia Action | 武侠アクション | Chinese martial arts wire-fu combat | 中国武術のワイヤーアクション |
| Explosive Action | 爆発アクション | Heavy use of explosions and destruction | 爆発と破壊を多用するアクション |

### Adventure / 冒険 (mal_id: 2)
| Name | Name (JA) | Description | Description (JA) |
|---|---|---|---|
| Dungeon Crawl | ダンジョン探索 | Exploring dungeons, labyrinths, and underground environments | ダンジョン・迷宮・地下環境の探索 |
| Village Building | 村づくり | Building and managing settlements from scratch | ゼロからの集落建設と運営 |
| Treasure Hunt | 宝探し | Quests to find legendary items or artifacts | 伝説のアイテムや遺物を探す冒険 |
| World Exploration | 世界探索 | Discovering and mapping unknown lands and cultures | 未知の土地と文化の発見と探索 |
| Shipwreck Survival | 漂流サバイバル | Stranded in unknown territory, must survive | 未知の土地に漂着し、生き延びなければならない |
| Quest Narrative | クエスト物語 | Journey driven by a specific mission or objective | 特定のミッションや目的に導かれた旅 |
| Expedition | 探検 | Organized journey into dangerous or uncharted territory | 危険な未踏の地への組織的な旅 |
| Pirate | 海賊 | Seafaring outlaws and treasure on the high seas | 海の無法者と大海原の冒険 |
| Caravan Journey | 隊商の旅 | Traveling with a group through dangerous lands | 危険な土地を集団で旅する |
| Frontier Settlement | 開拓地 | Pioneers settling untamed wilderness | 未開の荒野を開拓する |
| Spelunking | 洞窟探検 | Exploring natural caves and underground formations | 自然の洞窟と地下の形成物を探索 |
| Desert Crossing | 砂漠横断 | Traversing vast deserts and arid wastelands | 広大な砂漠と乾燥した荒地を横断 |
| Mountain Climbing | 登山 | Scaling dangerous peaks and mountain ranges | 危険な山頂と山脈を登る |
| Jungle Exploration | ジャングル探検 | Adventures in dense tropical forests | 密生した熱帯雨林での冒険 |
| Arctic Expedition | 極地探検 | Journeys through frozen polar landscapes | 凍った極地の風景を旅する |
| Sky Adventure | 空の冒険 | Adventures in the skies, floating islands, airships | 空、浮遊島、飛行船での冒険 |
| Underwater Adventure | 水中冒険 | Exploring oceans, sea floors, and underwater ruins | 海、海底、水中遺跡の探索 |
| Nomadic Life | 遊牧生活 | Wandering without a fixed home | 定住せずに放浪する生活 |
| Lost Civilization | 失われた文明 | Discovering ruins of ancient forgotten cultures | 古代の忘れられた文化の遺跡を発見 |
| Survival Crafting | サバイバルクラフト | Gathering resources and crafting tools to survive | 資源を集め道具を作って生き延びる |
| Monster Taming | モンスターテイム | Capturing and befriending wild creatures | 野生の生き物を捕まえて仲間にする |
| Maze | 迷路 | Navigating complex labyrinths and puzzle environments | 複雑な迷宮やパズル環境を進む |
| Escort Quest | 護衛クエスト | Protecting someone during a dangerous journey | 危険な旅の間、誰かを守る |
| Treasure Map | 宝の地図 | Following cryptic maps to hidden riches | 暗号の地図をたどって隠された財宝へ |
| Guild Adventure | ギルド冒険 | Taking quests from adventurer guilds | 冒険者ギルドからクエストを受ける |
| Dimensional Travel | 次元旅行 | Traveling between parallel worlds or dimensions | 平行世界や異次元を旅する |
| Road Trip | ロードトリップ | Journey along roads with stops and encounters | 道中での立ち寄りや出会いを伴う旅 |
| Colonization | 植民地化 | Settling and developing new lands or planets | 新しい土地や惑星の開拓と開発 |
| Ruin Exploration | 遺跡探索 | Investigating ancient ruins full of traps and secrets | 罠と秘密に満ちた古代遺跡の調査 |
| Sailing | 航海 | Ocean voyages and seafaring adventures | 海洋航海と船旅の冒険 |

### Comedy / コメディ (mal_id: 4)
| Name | Name (JA) | Description | Description (JA) |
|---|---|---|---|
| Slapstick | スラップスティック | Physical humor and exaggerated reactions | 身体を使ったユーモアと大げさなリアクション |
| Absurdist | 不条理 | Surreal, nonsensical humor that defies logic | 論理を超えたシュールでナンセンスなユーモア |
| Romantic Comedy | ラブコメ | Love stories with comedic situations | コメディ要素のある恋愛物語 |
| Dark Comedy | ブラックコメディ | Humor derived from serious or taboo subjects | 深刻な問題やタブーから生まれるユーモア |
| Situational Comedy | シチュエーションコメディ | Humor from everyday situations and misunderstandings | 日常の状況や誤解から生まれるユーモア |
| Deadpan | シュール | Dry, understated humor delivered with a straight face | 無表情で淡々と述べるドライなユーモア |
| Self-Referential | メタコメディ | Breaking the fourth wall, meta-humor | 第四の壁を破るメタ的なユーモア |
| Cringe Comedy | 気まずいコメディ | Humor from awkward and embarrassing situations | 気まずくて恥ずかしい状況から生まれるユーモア |
| Sketch Comedy | スケッチコメディ | Short, standalone comedic segments | 短い独立したコメディセグメント |
| Witty Dialogue | 知的コメディ | Sharp, clever wordplay and verbal humor | 鋭く巧みな言葉遊びと会話のユーモア |
| Fish Out of Water | 場違い | Character placed in an unfamiliar environment for laughs | 笑いのために不慣れな環境に置かれたキャラクター |
| Toilet Humor | 下ネタ | Crude bodily function jokes | 下品な身体機能のジョーク |
| Tsukkomi-Boke | ツッコミ・ボケ | Japanese straight-man/funny-man comedy duo dynamic | 日本の漫才コンビの掛け合い |
| Misunderstanding Comedy | 勘違いコメディ | Humor from characters misinterpreting situations | キャラクターが状況を誤解することから生まれるユーモア |
| Satire | 風刺 | Mocking societal norms, politics, or culture | 社会規範、政治、文化を風刺する |
| Wordplay | 駄洒落 | Puns, double meanings, and linguistic jokes | ダジャレ、二重の意味、言語的なジョーク |
| Reaction Comedy | リアクション芸 | Exaggerated facial expressions and over-the-top reactions | 大げさな表情とオーバーなリアクション |
| Rivalry Comedy | ライバルコメディ | Comedic competition between characters | キャラクター間のコメディ的な競争 |
| Culture Clash | 文化衝突 | Humor from different cultures meeting | 異なる文化の出会いから生まれるユーモア |
| Buddy Comedy | バディコメディ | Two mismatched characters forced together | 不釣り合いな二人が一緒にされるコメディ |
| Parenting Comedy | 子育てコメディ | Comedic struggles of raising children | 子育ての苦労をコメディにした作品 |
| Pet Comedy | ペットコメディ | Humor centered around animal companions | 動物の相棒を中心としたユーモア |
| Workplace Comedy | 職場コメディ | Funny situations in work environments | 職場での面白い状況 |
| Otaku Comedy | オタクコメディ | Humor about anime, manga, and geek culture | アニメ、マンガ、オタク文化に関するユーモア |
| Cosplay Comedy | コスプレコメディ | Humor involving costumes and character impersonation | コスチュームやキャラクターのなりきりに関するユーモア |
| Food Comedy | グルメコメディ | Exaggerated reactions to food and cooking mishaps | 料理への大げさなリアクションや調理の失敗 |
| Sarcastic Protagonist | 皮肉な主人公 | Main character uses sarcasm as primary humor vehicle | 主人公が皮肉をユーモアの主な手段として使う |
| Fourth Wall Break | 第四の壁破壊 | Characters aware they are in a story | キャラクターが物語の中にいることを自覚している |
| Ensemble Comedy | 群像コメディ | Large cast each contributing different humor styles | 大人数のキャストがそれぞれ異なるユーモアスタイルを提供 |
| Impersonation Comedy | モノマネコメディ | Humor from characters imitating others | キャラクターが他者を模倣することから生まれるユーモア |

### Drama / ドラマ (mal_id: 8)
| Name | Name (JA) | Description | Description (JA) |
|---|---|---|---|
| Tragedy | 悲劇 | Stories ending in loss, death, or irreversible consequences | 喪失、死、取り返しのつかない結果で終わる物語 |
| Family Drama | 家族ドラマ | Conflicts and bonds within families | 家族内の葛藤と絆 |
| Coming of Age | 成長物語 | Growing up, self-discovery, transition to adulthood | 成長、自己発見、大人への移行 |
| Political Drama | 政治ドラマ | Power struggles, governance, political intrigue | 権力闘争、統治、政治的陰謀 |
| Social Commentary | 社会派 | Critique of society, class, inequality | 社会、階級、不平等への批評 |
| Melodrama | メロドラマ | Heightened emotions and dramatic plot devices | 高まる感情とドラマチックな展開 |
| Courtroom Drama | 法廷ドラマ | Legal battles and justice system stories | 法廷での戦いと司法制度の物語 |
| War Drama | 戦争ドラマ | Human cost and moral complexity of warfare | 戦争の人的コストと道徳的複雑さ |
| Forbidden Love | 禁断の恋 | Romance that society or circumstances oppose | 社会や状況が反対する恋愛 |
| Redemption | 贖罪 | Characters seeking forgiveness or atonement | 許しや償いを求めるキャラクター |
| Terminal Illness | 不治の病 | Character facing death from disease | 病気で死に直面するキャラクター |
| Disability | 障害 | Characters living with physical or mental disability | 身体的・精神的障害を持つキャラクター |
| Addiction | 依存症 | Substance abuse or behavioral addiction struggles | 薬物乱用や行動依存症との闘い |
| Divorce | 離婚 | Breakup of marriages and its aftermath | 結婚の破綻とその後 |
| Orphan | 孤児 | Growing up without parents | 親なしで育つ |
| Class Struggle | 階級闘争 | Conflict between social classes, rich vs poor | 社会階級間の対立、富裕層vs貧困層 |
| Immigrant Story | 移民物語 | Adjusting to a new country and culture | 新しい国と文化への適応 |
| Bullying | いじめ | Harassment and its psychological effects | ハラスメントとその心理的影響 |
| Grief | 悲嘆 | Processing the death of a loved one | 愛する人の死を受け入れる過程 |
| Betrayal | 裏切り | Trust broken by close friends or allies | 親しい友人や仲間による信頼の崩壊 |
| Sacrifice | 犠牲 | Characters giving up something precious for others | 他者のために大切なものを犠牲にするキャラクター |
| Sibling Conflict | 兄弟の確執 | Rivalry or estrangement between siblings | 兄弟姉妹間の対立や疎遠 |
| Generational Trauma | 世代間トラウマ | Trauma passed down through family generations | 家族の世代を超えて受け継がれるトラウマ |
| Poverty | 貧困 | Struggles of living in extreme poverty | 極度の貧困の中で生きる苦闘 |
| Whistleblower | 内部告発 | Exposing corruption at great personal cost | 大きな個人的犠牲を払って腐敗を暴露する |
| Identity Struggle | アイデンティティの葛藤 | Conflict between duty, desire, and self | 義務、欲望、自己の間の葛藤 |
| Aging | 老い | Dealing with growing old and mortality | 老いと死に対する向き合い |
| Arranged Marriage | 政略結婚 | Marriage decided by others, not by love | 愛ではなく他者によって決められた結婚 |
| Single Parent | シングルペアレント | Challenges of raising children alone | 一人で子供を育てる挑戦 |
| Refugee | 難民 | Fleeing war, persecution, or disaster | 戦争、迫害、災害からの逃避 |

### Fantasy / ファンタジー (mal_id: 10)
| Name | Name (JA) | Description | Description (JA) |
|---|---|---|---|
| Dark Fantasy | ダークファンタジー | Grim, morally grey fantasy worlds | 暗く道徳的にグレーなファンタジー世界 |
| High Fantasy | ハイファンタジー | Epic quests in fully realized fantasy worlds | 完全に構築されたファンタジー世界での壮大な冒険 |
| Low Fantasy | ローファンタジー | Minimal magic in a mostly realistic world | ほぼ現実的な世界に最小限の魔法 |
| Sword and Sorcery | 剣と魔法 | Heroes with blades and magic in fantasy settings | ファンタジー世界での剣と魔法の英雄 |
| Cultivation | 修行 | Characters train to increase supernatural power levels | 超自然的な力を高めるために修行するキャラクター |
| Spirit World | 霊界 | Interaction with ghosts, spirits, or afterlife realms | 幽霊、精霊、あの世との交流 |
| Mythical Creatures | 幻獣 | Dragons, phoenixes, and legendary beasts | 龍、鳳凰、伝説の獣 |
| Magic Academy | 魔法学園 | Schools teaching magic and supernatural arts | 魔法や超自然的な技術を教える学校 |
| Demon Lord | 魔王 | Stories centered around demon kings and their defeat | 魔王とその討伐を中心とした物語 |
| Guild System | ギルド | Adventurer guilds, rankings, and quest boards | 冒険者ギルド、ランキング、クエストボード |
| Fairy Tale | おとぎ話 | Based on or inspired by classic fairy tales | 古典的なおとぎ話に基づく、またはインスピレーションを得た作品 |
| Wuxia | 武侠 | Chinese martial arts fantasy with chivalrous heroes | 侠客が活躍する中国武術ファンタジー |
| Elemental Magic | 属性魔法 | Magic based on fire, water, earth, wind elements | 火、水、土、風の属性に基づく魔法 |
| Necromancy | 死霊術 | Raising and controlling the dead | 死者を蘇らせ操る魔術 |
| Summoning | 召喚術 | Calling forth creatures or spirits to fight | 戦わせるために生物や精霊を呼び出す |
| Enchanted Items | 魔法のアイテム | Powerful magical artifacts central to the plot | プロットの中心となる強力な魔法の遺物 |
| Beast Rider | 騎獣 | Characters riding dragons, griffins, or magical beasts | ドラゴン、グリフォン、魔獣に乗るキャラクター |
| Prophecy | 予言 | Story driven by a foretold destiny | 予言された運命によって導かれる物語 |
| Forbidden Magic | 禁呪 | Magic that is banned or has terrible costs | 禁じられた、または恐ろしい代償を伴う魔法 |
| Familiar | 使い魔 | Magical animal or spirit companion | 魔法の動物や精霊の相棒 |
| Magical Contract | 魔法契約 | Deals with supernatural beings with binding terms | 拘束力のある条件で超自然的な存在と契約 |
| Alchemy | 錬金術 | Transforming substances through mystical chemistry | 神秘的な化学による物質の変換 |
| Rune Magic | ルーン魔法 | Magic through symbols, glyphs, and inscriptions | 記号、図形、碑文による魔法 |
| Blood Magic | 血の魔法 | Magic powered by blood sacrifice | 血の犠牲で力を得る魔法 |
| Shapeshifter | 変身者 | Characters who transform into animals or other forms | 動物や他の姿に変身するキャラクター |
| Enchanted Forest | 魔法の森 | Mystical woodland settings with magical properties | 魔法の性質を持つ神秘的な森の舞台 |
| Floating Islands | 浮遊島 | Worlds with land masses suspended in the sky | 空中に浮かぶ陸地のある世界 |
| Underground Kingdom | 地底王国 | Civilizations beneath the earth's surface | 地表の下にある文明 |
| Magical Warfare | 魔法戦争 | Large-scale conflicts using magic as weapons | 魔法を武器として使う大規模な戦争 |
| Xianxia | 仙侠 | Chinese immortal cultivation fantasy | 中国の仙人修行ファンタジー |
| Gaslamp Fantasy | ガスランプファンタジー | Fantasy in a Victorian or Edwardian setting | ヴィクトリア朝やエドワード朝を舞台にしたファンタジー |
| Mythic Retelling | 神話再話 | Modern reinterpretation of classical myths | 古典的な神話の現代的な再解釈 |
| Pocket Dimension | 異空間 | Small contained worlds within the larger world | 大きな世界の中にある小さな閉じた世界 |
| Anti-Magic | 反魔法 | Settings where magic is suppressed or outlawed | 魔法が抑圧または禁止されている設定 |

### Horror / ホラー (mal_id: 14)
| Name | Name (JA) | Description | Description (JA) |
|---|---|---|---|
| Body Horror | ボディホラー | Grotesque transformations and physical mutation | グロテスクな変身と身体的変異 |
| Cosmic Horror | 宇宙的恐怖 | Lovecraftian, incomprehensible existential dread | ラヴクラフト的な理解不能な存在への恐怖 |
| Psychological Horror | 心理的恐怖 | Terror from the mind, paranoia, unreliable reality | 精神からの恐怖、妄想、信頼できない現実 |
| Slasher | スラッシャー | Killer hunting victims one by one | 殺人鬼が犠牲者を一人ずつ狙う |
| Survival Horror | サバイバルホラー | Limited resources, must escape or endure threats | 限られた資源で脅威から逃げるか耐え抜く |
| Ghost Story | 怪談 | Hauntings, spirits, and supernatural apparitions | 幽霊、心霊、超自然的な出現 |
| Folk Horror | 民俗ホラー | Rural settings, ancient rituals, pagan traditions | 田舎の舞台、古代の儀式、異教の伝統 |
| Zombie | ゾンビ | Undead outbreaks and apocalyptic scenarios | アンデッドの発生と終末的なシナリオ |
| Demonic | 悪魔 | Demons, possession, and exorcism | 悪魔、憑依、悪魔祓い |
| Creepy Atmosphere | 不気味な雰囲気 | Slow burn dread and unsettling ambiance | じわじわと迫る恐怖と不穏な雰囲気 |
| Isolation Horror | 孤立ホラー | Terror from being alone and cut off | 孤立し隔絶されることから生まれる恐怖 |
| Haunted House | 幽霊屋敷 | Cursed buildings and haunted locations | 呪われた建物や心霊スポット |
| Parasitic | 寄生 | Organisms taking over host bodies | 宿主の体を乗っ取る生物 |
| Cannibal | 人喰い | Human consumption as horror element | 食人をホラー要素として |
| Torture | 拷問 | Extreme physical suffering as horror | 極端な肉体的苦痛をホラーとして |
| Stalker | ストーカー | Being followed and watched by a threatening figure | 脅威的な人物に付きまとわれ監視される |
| Cult Horror | カルトホラー | Sinister religious groups and brainwashing | 邪悪な宗教団体と洗脳 |
| Medical Horror | 医療ホラー | Hospitals, experiments, and surgical terror | 病院、実験、外科的恐怖 |
| Doppelganger | ドッペルゲンガー | Encountering an identical copy of oneself | 自分と同一の存在に遭遇する |
| Cursed Object | 呪いのオブジェ | Haunted items that bring misfortune | 不幸をもたらす呪われたアイテム |
| Dream Horror | 夢のホラー | Nightmares that bleed into reality | 現実に侵食する悪夢 |
| Child Horror | 子供ホラー | Creepy or possessed children as horror element | 不気味な、または憑依された子供 |
| Found Footage | ファウンド・フッテージ | Horror told through discovered recordings | 発見された記録映像を通じて語られるホラー |
| Urban Legend | 都市伝説 | Horror based on modern myths and legends | 現代の神話や伝説に基づくホラー |
| School Horror | 学校ホラー | Terrifying events in school settings | 学校を舞台にした恐怖の出来事 |
| Eldritch | 異形 | Unknowable alien entities beyond comprehension | 理解を超えた異質な存在 |
| Infection | 感染 | Spreading disease or corruption transforming people | 人々を変容させる広がる病気や腐敗 |
| Phobia | 恐怖症 | Horror exploiting specific fears like claustrophobia, arachnophobia | 閉所恐怖症、蜘蛛恐怖症など特定の恐怖を利用したホラー |
| Werewolf | 人狼 | Lycanthropy and transformation horror | 人狼と変身ホラー |
| Alien Horror | エイリアンホラー | Extraterrestrial creatures as source of terror | 恐怖の源としての地球外生物 |

### Romance / 恋愛 (mal_id: 22)
| Name | Name (JA) | Description | Description (JA) |
|---|---|---|---|
| Slow Burn | スローバーン | Romance that develops very gradually over time | 時間をかけてゆっくり発展する恋愛 |
| Enemies to Lovers | 敵から恋人へ | Characters who start as antagonists fall in love | 敵対関係から始まり恋に落ちる |
| Childhood Friends | 幼なじみ | Romance between people who grew up together | 一緒に育った人同士の恋愛 |
| Office Romance | オフィスラブ | Love developing in the workplace | 職場で芽生える恋 |
| Age Gap | 年の差 | Significant age difference between partners | パートナー間の大きな年齢差 |
| First Love | 初恋 | Pure, innocent first romantic experience | 純粋で無垢な初めての恋愛体験 |
| Second Chance | 再会の恋 | Former lovers reuniting and rekindling romance | かつての恋人が再会し恋を再燃させる |
| Unrequited Love | 片思い | One-sided romantic feelings | 一方的な恋愛感情 |
| Love Confession | 告白 | Story building toward a pivotal confession | 重要な告白に向けて展開する物語 |
| Long Distance | 遠距離恋愛 | Romance maintained across physical separation | 物理的な距離を超えて維持される恋愛 |
| Fake Relationship | 偽装恋愛 | Pretending to date that becomes real | 偽りの交際が本物になる |
| Contract Marriage | 契約結婚 | Marriage of convenience that develops into love | 便宜上の結婚が愛に発展する |
| Love Triangle | 三角関係 | Three people entangled in romantic feelings | 三人が恋愛感情に巻き込まれる |
| Tsundere Romance | ツンデレ恋愛 | Cold exterior hiding warm romantic feelings | 冷たい外見の裏に温かい恋愛感情を隠す |
| Yandere Romance | ヤンデレ恋愛 | Obsessive, dangerous love | 執着的で危険な愛 |
| Secret Relationship | 秘密の交際 | Couples hiding their romance from others | 他人から恋愛関係を隠すカップル |
| Teacher-Student Romance | 師弟恋愛 | Forbidden romance between mentor and pupil | 師匠と弟子の禁断の恋 |
| Interspecies Romance | 異種間恋愛 | Love between human and non-human characters | 人間と人間以外のキャラクターの恋愛 |
| Master-Servant | 主従恋愛 | Romance developing in a power-imbalanced relationship | 力の不均衡な関係で発展する恋愛 |
| Amnesia Romance | 記憶喪失恋愛 | Romance where one partner has lost memories | 片方が記憶を失った恋愛 |
| Destined Love | 運命の恋 | Lovers fated to be together by supernatural forces | 超自然的な力で結ばれる運命の恋人 |
| Online Romance | ネット恋愛 | Love developing through online communication | オンラインコミュニケーションで発展する恋 |
| Forbidden Romance | 禁じられた恋 | Love that breaks societal rules or taboos | 社会的ルールやタブーを破る恋 |
| Marriage Life | 結婚生活 | Romance focused on married couple dynamics | 夫婦の関係性に焦点を当てた恋愛 |
| Confession Failure | 告白失敗 | Repeated failed attempts to confess feelings | 告白の失敗を繰り返す |
| Cohabitation | 同棲 | Unmarried couple living together | 未婚のカップルが一緒に暮らす |
| Celebrity Romance | 芸能人恋愛 | Romance involving famous public figures | 有名な公人が関わる恋愛 |
| Supernatural Romance | 超自然恋愛 | Romance with ghosts, vampires, or supernatural beings | 幽霊、吸血鬼、超自然的存在との恋愛 |
| Rival to Lover | ライバルから恋人へ | Competitive relationship evolving into love | 競争関係が恋愛に発展する |
| Military Romance | 軍人恋愛 | Romance in wartime or military settings | 戦時中や軍隊での恋愛 |
| Accidental Kiss | 偶然のキス | Unplanned romantic physical contact as plot device | プロットの仕掛けとしての予期しないロマンチックな身体接触 |
| Love Letter | ラブレター | Romance driven by written correspondence | 手紙のやり取りで進む恋愛 |
| Matchmaking | お見合い | Third parties arranging romantic meetings | 第三者がロマンチックな出会いを手配する |

### Sci-Fi / SF (mal_id: 24)
| Name | Name (JA) | Description | Description (JA) |
|---|---|---|---|
| Cyberpunk | サイバーパンク | High tech, low life, dystopian near-future | ハイテク・ローライフ、ディストピアの近未来 |
| Steampunk | スチームパンク | Victorian-era technology with steam-powered machinery | ヴィクトリア朝時代の蒸気機械技術 |
| Post-Apocalyptic | 終末後 | Life after civilization has collapsed | 文明崩壊後の生活 |
| Space Opera | スペースオペラ | Epic adventures across galaxies and star systems | 銀河と星系を舞台にした壮大な冒険 |
| Hard Sci-Fi | ハードSF | Scientifically rigorous and technically detailed | 科学的に厳密で技術的に詳細 |
| Dystopia | ディストピア | Oppressive future societies and totalitarian control | 抑圧的な未来社会と全体主義的な支配 |
| Utopia | ユートピア | Idealized future societies and their hidden costs | 理想化された未来社会とその隠れた代償 |
| Artificial Intelligence | 人工知能 | AI consciousness, robot sentience, machine ethics | AI意識、ロボットの感性、機械倫理 |
| Virtual Reality | 仮想現実 | VR worlds, digital consciousness, simulation | VR世界、デジタル意識、シミュレーション |
| Alien Contact | 異星人接触 | First contact and interaction with extraterrestrial life | 地球外生命体との初接触と交流 |
| Clone / Genetic Engineering | クローン・遺伝子工学 | Genetic modification and human cloning themes | 遺伝子改変と人間クローンのテーマ |
| Mecha Pilot | メカパイロット | Piloting giant robots in combat or exploration | 巨大ロボットを操縦して戦闘や探索 |
| Biopunk | バイオパンク | Biological technology and organic modifications | 生物学的技術と有機的改造 |
| Solarpunk | ソーラーパンク | Optimistic eco-friendly future technology | 楽観的な環境に優しい未来技術 |
| Nanopunk | ナノパンク | Nanotechnology-driven futures | ナノテクノロジーが支配する未来 |
| Dieselpunk | ディーゼルパンク | Retro-futurism inspired by 1920s-1950s aesthetics | 1920〜1950年代の美学に基づくレトロフューチャリズム |
| Atompunk | アトムパンク | Atomic age retro-futurism, 1950s space-age optimism | 原子力時代のレトロフューチャリズム |
| Terraforming | テラフォーミング | Transforming planets to support human life | 人間が住めるよう惑星を改造する |
| Generation Ship | 世代宇宙船 | Multi-generational space voyages | 複数世代にわたる宇宙航海 |
| Mind Upload | 精神アップロード | Transferring consciousness to digital form | 意識をデジタル形式に転送する |
| Transhumanism | トランスヒューマニズム | Enhancing human capabilities beyond natural limits | 人間の能力を自然の限界を超えて強化する |
| Time Loop | タイムループ | Characters trapped repeating the same period | 同じ期間を繰り返すことに囚われたキャラクター |
| Parallel Universe | 平行宇宙 | Multiple coexisting realities | 複数の共存する現実 |
| Megacorporation | 巨大企業 | Corporations more powerful than governments | 政府よりも強力な企業 |
| Surveillance State | 監視国家 | Total information control and privacy elimination | 完全な情報管理とプライバシーの排除 |
| Android / Cyborg | アンドロイド・サイボーグ | Human-like machines or human-machine hybrids | 人間に似た機械や人間と機械のハイブリッド |
| Space Colony | 宇宙植民地 | Human settlements on other planets or in space | 他の惑星や宇宙での人類の居住地 |
| Galactic War | 銀河戦争 | Interstellar military conflicts | 恒星間の軍事紛争 |
| Singularity | シンギュラリティ | Technological singularity and its consequences | 技術的特異点とその結果 |
| Cryogenic | 冷凍保存 | Characters frozen and awakened in the future | 冷凍され未来に目覚めるキャラクター |
| Alien Invasion | 宇宙人侵略 | Extraterrestrial attack on Earth | 地球外生命体による地球への攻撃 |
| Robot Uprising | ロボットの反乱 | Machines rebelling against their creators | 機械が創造者に反抗する |
| Hivemind | 集合意識 | Shared consciousness across multiple beings | 複数の存在間で共有される意識 |
| Wormhole | ワームホール | Travel through spacetime shortcuts | 時空のショートカットを通じた旅行 |
| Lightsaber / Energy Weapons | エネルギー兵器 | Advanced energy-based weaponry | 先進的なエネルギーベースの武器 |
| Kaiju Sci-Fi | 怪獣SF | Giant monsters in a science fiction context | SFの文脈における巨大モンスター |

### Slice of Life / 日常 (mal_id: 36)
| Name | Name (JA) | Description | Description (JA) |
|---|---|---|---|
| Rural Life | 田舎暮らし | Countryside living and agricultural settings | 田舎の生活と農業的な環境 |
| Club Activities | 部活動 | School clubs and extracurricular activities | 学校のクラブと課外活動 |
| Food & Cooking | 料理 | Centered around food preparation and culinary arts | 料理と食文化を中心とした物語 |
| After School | 放課後 | Daily life and hangouts after school hours | 放課後の日常生活とたまり場 |
| Seasonal Events | 季節の行事 | Cultural festivals, holidays, seasonal traditions | 文化祭、祝日、季節の伝統 |
| Neighborhood Stories | 下町物語 | Community life and local interactions | 地域の生活と人々の交流 |
| Retirement Life | 老後の生活 | Stories about elderly characters and late-life experiences | 高齢者キャラクターと晩年の体験の物語 |
| Café / Restaurant | 喫茶店・レストラン | Daily life running or visiting eateries | 飲食店の経営や来店を中心とした日常 |
| Travel Diary | 旅日記 | Leisurely journeys and travel experiences | のんびりとした旅と旅行体験 |
| Mundane Fantasy | 日常系ファンタジー | Magical elements in otherwise normal daily life | 普通の日常の中に魔法の要素がある |
| Apartment Life | アパート生活 | Daily life in shared apartment buildings | 共同アパートでの日常生活 |
| Shopping | お買い物 | Characters enjoying shopping and consumer culture | ショッピングと消費文化を楽しむキャラクター |
| Gardening | ガーデニング | Growing plants and caring for gardens | 植物を育て庭を手入れする |
| Fishing | 釣り | Peaceful fishing as primary activity | 穏やかな釣りが主な活動 |
| Camping | キャンプ | Outdoor camping and nature activities | アウトドアキャンプと自然活動 |
| Bath House | 銭湯 | Stories centered around public baths or hot springs | 銭湯や温泉を中心とした物語 |
| Bookworm | 読書家 | Characters passionate about books and reading | 本と読書に情熱を注ぐキャラクター |
| Arts & Crafts | 手芸 | Handmaking, knitting, pottery, and creative hobbies | 手作り、編み物、陶芸、創造的な趣味 |
| Photography | 写真 | Photography as hobby or profession | 趣味や職業としての写真 |
| Daily Routine | 日課 | Comfort in repetitive everyday patterns | 日常的なパターンの心地よさ |
| Cozy Home | 居心地の良い家 | Warm domestic life and home comfort | 温かい家庭生活と家の心地よさ |
| Friendship Group | 友達グループ | Close friend circles and their daily interactions | 仲良しグループとその日常のやりとり |
| Pen Pal | ペンパル | Relationships maintained through letters | 手紙を通じて維持される関係 |
| Part-Time Job | アルバイト | Working part-time jobs and the experiences that come with them | アルバイトとそこから得られる経験 |
| Moving In | 引越し | Adjusting to a new home or town | 新しい家や町に適応する |
| Rainy Day | 雨の日 | Stories that focus on quiet, indoor moments | 静かな屋内の時間に焦点を当てた物語 |
| Festival Preparation | 祭りの準備 | Building up to a community or school festival | 地域や学校の祭りに向けた準備 |
| Morning Routine | 朝の日課 | Starting the day and morning rituals | 一日の始まりと朝の儀式 |
| Letter Writing | 手紙書き | Exchanging heartfelt letters | 心のこもった手紙のやりとり |
| Sunset Watching | 夕焼け | Contemplative moments watching the sky | 空を眺める瞑想的なひととき |

### Supernatural / 超自然 (mal_id: 37)
| Name | Name (JA) | Description | Description (JA) |
|---|---|---|---|
| Exorcism | 除霊 | Banishing evil spirits and supernatural entities | 悪霊や超自然的な存在の退治 |
| Yokai | 妖怪 | Japanese folklore creatures and spirits | 日本の民話の生き物と精霊 |
| Shinigami | 死神 | Death gods and afterlife mythology | 死神とあの世の神話 |
| Curse | 呪い | Supernatural curses and their consequences | 超自然的な呪いとその結果 |
| Psychic Powers | 超能力 | ESP, telekinesis, telepathy, precognition | 超感覚、念動力、テレパシー、予知能力 |
| Onmyouji | 陰陽師 | Japanese yin-yang masters and spiritual arts | 日本の陰陽道と霊的な術 |
| Medium / Channeler | 霊媒 | Communication with the dead or spirits | 死者や霊との交信 |
| Shapeshifting | 変身 | Characters who can transform their physical form | 物理的な姿を変えることができるキャラクター |
| Immortality | 不死 | Characters who cannot die and the burden of eternal life | 死ぬことができないキャラクターと永遠の命の重荷 |
| Afterlife | 死後の世界 | Stories set in or exploring the world after death | 死後の世界を舞台にした、または探索する物語 |
| Guardian Angel | 守護天使 | Supernatural protector watching over characters | キャラクターを見守る超自然的な守護者 |
| Poltergeist | ポルターガイスト | Mischievous or violent invisible spirit activity | いたずらまたは暴力的な目に見えない霊の活動 |
| Astral Projection | 幽体離脱 | Spirit leaving the body to travel | 体を離れて旅する霊 |
| Kitsune | 狐 | Fox spirits with shapeshifting abilities | 変身能力を持つ狐の精霊 |
| Tengu | 天狗 | Powerful bird-like creatures from Japanese myth | 日本の神話に登場する鳥のような強力な存在 |
| Tanuki | 狸 | Raccoon dog spirits known for trickery | いたずらで知られる狸の精霊 |
| Oni | 鬼 | Japanese ogres and demons | 日本の鬼 |
| Spiritual Awakening | 霊的覚醒 | Character gaining supernatural perception | キャラクターが超自然的な知覚を得る |
| Soul Binding | 魂の契約 | Souls bound to objects, people, or places | 物、人、場所に縛られた魂 |
| Reaper | 死神使い | Characters who collect or guide souls of the dead | 死者の魂を集めたり導いたりするキャラクター |
| Spirit Detective | 霊的探偵 | Investigating supernatural cases | 超自然的な事件を調査する |
| Haunted School | 心霊学校 | Schools with resident ghosts and supernatural events | 幽霊や超自然的な出来事のある学校 |
| Sacred Barrier | 結界 | Protective spiritual barriers and wards | 保護的な霊的結界と守り |
| Divine Punishment | 天罰 | Gods punishing mortals for transgressions | 神が過ちを犯した人間を罰する |
| Spirit Contract | 霊的契約 | Pacts made with supernatural beings | 超自然的な存在との契約 |
| Ayakashi | あやかし | Mysterious supernatural phenomena in Japanese tradition | 日本の伝統における不思議な超自然現象 |
| Possession | 憑依 | Spirits or entities taking over a person's body | 霊や存在が人の体を乗っ取る |
| Holy Power | 聖なる力 | Divine or sacred powers used against evil | 悪に対して使われる神聖な力 |
| Demon Slaying | 退魔 | Hunting and destroying demons | 悪魔を狩り滅ぼす |
| Spiritual Battle | 霊戦 | Combat between supernatural forces | 超自然的な力同士の戦い |

### Mystery / ミステリー (mal_id: 7)
| Name | Name (JA) | Description | Description (JA) |
|---|---|---|---|
| Whodunit | フーダニット | Classic detective puzzle: who committed the crime? | 古典的な探偵パズル：誰が犯罪を犯したか？ |
| Locked Room | 密室 | Impossible crime in a sealed environment | 密閉された環境での不可能な犯罪 |
| Police Procedural | 警察捜査 | Realistic law enforcement investigation process | 現実的な法執行機関の捜査プロセス |
| Cold Case | 未解決事件 | Investigating long-unsolved crimes | 長期間未解決の犯罪を捜査する |
| Conspiracy | 陰謀 | Uncovering hidden plots and secret organizations | 隠された陰謀と秘密組織の解明 |
| Serial Killer | 連続殺人 | Hunting or profiling a repeat murderer | 連続殺人犯の追跡またはプロファイリング |
| Missing Person | 行方不明 | Search for a disappeared individual | 失踪した人物の捜索 |
| Heist | 強盗 | Planning and executing elaborate thefts | 精巧な窃盗の計画と実行 |
| Occult Mystery | オカルトミステリー | Supernatural elements in detective stories | 探偵物語における超自然的な要素 |
| Forensic | 法医学 | Science-based crime solving | 科学に基づく犯罪解決 |
| Private Detective | 私立探偵 | Freelance investigators solving cases | フリーランスの調査員が事件を解決 |
| Amateur Sleuth | 素人探偵 | Non-professional solving mysteries | 非専門家がミステリーを解決 |
| Armchair Detective | 安楽椅子探偵 | Solving crimes through reasoning alone without leaving home | 外出せず推理だけで犯罪を解決 |
| Murder Mystery | 殺人ミステリー | Solving a murder through clues and deduction | 手がかりと推理で殺人を解決 |
| Noir | ノワール | Dark, cynical crime stories with morally grey characters | 道徳的にグレーなキャラクターの暗く冷笑的な犯罪物語 |
| Espionage | スパイ | Spy networks, intelligence gathering, double agents | スパイ網、情報収集、二重スパイ |
| Alibi Cracking | アリバイ崩し | Proving a suspect's alibi is false | 容疑者のアリバイが嘘であることを証明する |
| Dying Message | ダイイングメッセージ | Victim leaves a coded final clue | 被害者が暗号化された最後の手がかりを残す |
| Impossible Crime | 不可能犯罪 | Crimes that seem physically impossible to commit | 物理的に不可能に見える犯罪 |
| Identity Mystery | 正体不明 | Mystery about who someone truly is | 誰かの正体に関するミステリー |
| Amnesia Mystery | 記憶喪失ミステリー | Protagonist must solve a mystery while missing memories | 記憶を失った主人公がミステリーを解決しなければならない |
| Art Theft | 美術品窃盗 | Stealing or recovering valuable artworks | 価値ある芸術作品の窃盗または回収 |
| Cipher / Code Breaking | 暗号解読 | Solving puzzles through cryptography | 暗号学を通じてパズルを解く |
| Historical Mystery | 歴史ミステリー | Solving crimes set in historical periods | 歴史的な時代を舞台にした犯罪解決 |
| Courtroom Mystery | 法廷ミステリー | Mysteries unraveled during legal proceedings | 法的手続き中に解明されるミステリー |
| Kidnapping | 誘拐 | Abduction and rescue mysteries | 誘拐と救出のミステリー |
| Phantom Thief | 怪盗 | Gentleman thieves who leave calling cards | 予告状を残す紳士的な泥棒 |
| Poisoning | 毒殺 | Murder or attempted murder by poison | 毒による殺人または殺人未遂 |
| Inheritance Mystery | 遺産ミステリー | Mysteries surrounding wills and estates | 遺言書や遺産をめぐるミステリー |
| Witness Protection | 証人保護 | Protecting key witnesses from danger | 重要な証人を危険から守る |

### Sports / スポーツ (mal_id: 30)
| Name | Name (JA) | Description | Description (JA) |
|---|---|---|---|
| Baseball | 野球 | Baseball-focused stories | 野球を中心とした物語 |
| Soccer | サッカー | Football/soccer-focused stories | サッカーを中心とした物語 |
| Basketball | バスケットボール | Basketball-focused stories | バスケットボールを中心とした物語 |
| Volleyball | バレーボール | Volleyball-focused stories | バレーボールを中心とした物語 |
| Swimming | 水泳 | Swimming and aquatic sports | 水泳と水上スポーツ |
| Boxing | ボクシング | Boxing and ring combat sports | ボクシングとリング格闘スポーツ |
| Tennis | テニス | Tennis-focused stories | テニスを中心とした物語 |
| Cycling | 自転車 | Cycling and bicycle racing | 自転車競技とロードレース |
| Figure Skating | フィギュアスケート | Ice skating and figure skating stories | アイススケートとフィギュアスケートの物語 |
| Motorsport | モータースポーツ | Car, motorcycle, and other vehicle racing | 車、バイク、その他の乗り物のレース |
| Track and Field | 陸上競技 | Running, jumping, and athletic events | ランニング、ジャンプ、その他の陸上競技 |
| Shogi / Chess | 将棋・チェス | Board game competition stories | ボードゲーム競技の物語 |
| Esports | eスポーツ | Competitive video gaming | 競技的なビデオゲーム |
| Dance | ダンス | Dance competitions and performance | ダンスの競技とパフォーマンス |
| Badminton | バドミントン | Badminton-focused stories | バドミントンを中心とした物語 |
| Rugby | ラグビー | Rugby-focused stories | ラグビーを中心とした物語 |
| American Football | アメフト | American football-focused stories | アメリカンフットボールを中心とした物語 |
| Golf | ゴルフ | Golf-focused stories | ゴルフを中心とした物語 |
| Sumo | 相撲 | Sumo wrestling stories | 相撲の物語 |
| Judo | 柔道 | Judo-focused stories | 柔道を中心とした物語 |
| Kendo | 剣道 | Japanese sword fighting sport | 日本の剣術スポーツ |
| Archery | 弓道 | Archery and kyudo stories | 弓道の物語 |
| Table Tennis | 卓球 | Table tennis / ping pong stories | 卓球の物語 |
| Gymnastics | 体操 | Gymnastics competition stories | 体操競技の物語 |
| Surfing | サーフィン | Surfing and wave riding | サーフィンと波乗り |
| Skiing | スキー | Skiing and winter sports | スキーとウィンタースポーツ |
| Climbing | クライミング | Rock climbing and bouldering | ロッククライミングとボルダリング |
| Karuta | かるた | Competitive Japanese card game | 競技かるた |
| Go | 囲碁 | Go board game competition | 囲碁の競技 |
| Mahjong | 麻雀 | Competitive mahjong stories | 競技麻雀の物語 |
| Wrestling | プロレス | Professional wrestling stories | プロレスの物語 |
| MMA | 総合格闘技 | Mixed martial arts competition | 総合格闘技の競技 |
| Fencing | フェンシング | Fencing competition stories | フェンシング競技の物語 |
| Horse Racing | 競馬 | Horse racing and equestrian sports | 競馬と馬術 |
| Skateboarding | スケートボード | Skateboarding culture and competition | スケートボード文化と競技 |
| Cheerleading | チアリーディング | Cheerleading teams and competitions | チアリーディングチームと競技 |
| Marathon | マラソン | Long distance running stories | 長距離走の物語 |
| Coaching | 指導 | Focus on the coach/mentor rather than the athlete | 選手ではなくコーチ/指導者に焦点 |
| Underdog | 弱小チーム | Weak team rising to challenge strong opponents | 弱いチームが強い相手に挑む |
| Training Montage | 特訓 | Intensive training arcs to improve skills | スキル向上のための集中トレーニング |
| Rivalry Match | ライバル戦 | Key match against a personal rival | 個人的なライバルとの重要な試合 |
| Championship | 大会 | Working toward and competing in a major tournament | 大きな大会に向けて努力し競う |
| Sportsmanship | スポーツマンシップ | Themes of fair play, respect, and honor in competition | フェアプレー、敬意、名誉のテーマ |

### Historical / 歴史 (mal_id: 13)
| Name | Name (JA) | Description | Description (JA) |
|---|---|---|---|
| Sengoku Period | 戦国時代 | Japan's Warring States era (1467-1615) | 日本の戦国時代（1467-1615） |
| Edo Period | 江戸時代 | Tokugawa shogunate era (1603-1868) | 徳川幕府の時代（1603-1868） |
| Meiji Era | 明治時代 | Japan's modernization period (1868-1912) | 日本の近代化期（1868-1912） |
| Taisho Era | 大正時代 | Brief democratic period (1912-1926) | 短い民主主義の時代（1912-1926） |
| World War II | 第二次世界大戦 | Stories set during WWII | 第二次世界大戦中を舞台にした物語 |
| Ancient Civilization | 古代文明 | Egypt, Rome, Greece, Mesopotamia settings | エジプト、ローマ、ギリシャ、メソポタミアが舞台 |
| Medieval Europe | 中世ヨーロッパ | European Middle Ages settings | ヨーロッパの中世が舞台 |
| Chinese Dynasty | 中国王朝 | Historical Chinese imperial settings | 中国の歴史的な王朝が舞台 |
| Viking Age | ヴァイキング時代 | Norse and Scandinavian historical settings | 北欧・スカンジナビアの歴史的な舞台 |
| Revolution | 革命 | Stories centered on historical uprisings | 歴史的な蜂起を中心とした物語 |
| Heian Period | 平安時代 | Japanese court culture (794-1185) | 日本の宮廷文化（794-1185） |
| Kamakura Period | 鎌倉時代 | Rise of the samurai class (1185-1333) | 武士階級の台頭（1185-1333） |
| Showa Era | 昭和時代 | Japan from 1926-1989 including WWII and post-war boom | 昭和時代（1926-1989）戦争と戦後の繁栄 |
| World War I | 第一次世界大戦 | Stories set during WWI | 第一次世界大戦中を舞台にした物語 |
| Cold War Era | 冷戦時代 | Stories set during the Cold War (1947-1991) | 冷戦時代を舞台にした物語（1947-1991） |
| Ancient Japan | 古代日本 | Jomon, Yayoi, and Kofun periods | 縄文、弥生、古墳時代 |
| Korean Dynasty | 朝鮮王朝 | Historical Korean settings (Joseon, Goryeo) | 歴史的な韓国を舞台（朝鮮、高麗） |
| Ottoman Empire | オスマン帝国 | Stories set in the Ottoman period | オスマン帝国時代を舞台にした物語 |
| Renaissance | ルネサンス | European Renaissance period (14th-17th century) | ヨーロッパのルネサンス期（14〜17世紀） |
| Napoleonic Era | ナポレオン時代 | Stories during the Napoleonic Wars | ナポレオン戦争時代の物語 |
| Ancient Greece | 古代ギリシャ | Greek antiquity, city-states, philosophy | ギリシャ古代、都市国家、哲学 |
| Ancient Rome | 古代ローマ | Roman Empire and Republic era | ローマ帝国と共和制時代 |
| Ancient Egypt | 古代エジプト | Pharaohs, pyramids, Nile civilization | ファラオ、ピラミッド、ナイル文明 |
| Crusades | 十字軍 | Holy wars between East and West | 東西間の聖戦 |
| Colonial Era | 植民地時代 | Age of European colonization | ヨーロッパの植民地化の時代 |
| Industrial Revolution | 産業革命 | Stories during mechanization of society | 社会の機械化期の物語 |
| Pirate Age | 大航海時代 | Age of exploration and piracy (15th-18th century) | 探検と海賊の時代（15〜18世紀） |
| Silk Road | シルクロード | Trade route connecting East and West | 東西を結ぶ交易路 |
| Mongolian Empire | モンゴル帝国 | Stories set during Mongol conquest | モンゴル征服時代を舞台にした物語 |
| Bakumatsu | 幕末 | End of Tokugawa shogunate (1853-1868) | 徳川幕府の終焉（1853-1868） |

### Music / 音楽 (mal_id: 19)
| Name | Name (JA) | Description | Description (JA) |
|---|---|---|---|
| Band | バンド | Forming and performing in a music group | 音楽グループの結成と演奏 |
| Classical Music | クラシック音楽 | Orchestra, piano, violin, classical compositions | オーケストラ、ピアノ、バイオリン、クラシック曲 |
| Idol | アイドル | Pop idol training and performances | ポップアイドルのトレーニングとパフォーマンス |
| Rock | ロック | Rock music scene and culture | ロック音楽シーンと文化 |
| DJ / Electronic | DJ・エレクトロニック | Electronic music production and DJ culture | 電子音楽制作とDJ文化 |
| Hip Hop | ヒップホップ | Rap, beatboxing, and hip hop culture | ラップ、ビートボックス、ヒップホップ文化 |
| Musical Theater | ミュージカル | Stage musicals and song-integrated storytelling | 舞台ミュージカルと歌を組み込んだ物語 |
| Jazz | ジャズ | Jazz music scene and improvisation | ジャズ音楽シーンと即興演奏 |
| Folk Music | フォーク | Traditional and folk music performance | 伝統音楽とフォークミュージック |
| Choir | 合唱 | Choral singing and vocal ensembles | 合唱団と声楽アンサンブル |
| Punk | パンク | Punk rock culture and rebellious music | パンクロック文化と反抗的な音楽 |
| Metal | メタル | Heavy metal music scene | ヘビーメタル音楽シーン |
| Enka | 演歌 | Traditional Japanese ballad singing | 日本の伝統的な演歌 |
| Vocaloid | ボーカロイド | Virtual singer and synthesized music | バーチャルシンガーと合成音楽 |
| Music Producer | 音楽プロデューサー | Behind-the-scenes music creation | 音楽制作の舞台裏 |
| Singing Contest | 歌合戦 | Vocal competitions and singing battles | 歌唱コンテストと歌バトル |
| Street Performance | ストリートライブ | Busking and performing in public spaces | 路上ライブと公共の場でのパフォーマンス |
| Marching Band | マーチングバンド | Marching bands and parade performances | マーチングバンドとパレード演奏 |
| Music School | 音楽学校 | Training at a music academy | 音楽学校での訓練 |
| Songwriting | 作曲 | Writing and composing original music | オリジナル曲の作詞作曲 |
| Concert Tour | コンサートツアー | Traveling and performing live shows | 旅をしてライブを行う |
| Underground Music | アンダーグラウンド | Indie and underground music scenes | インディーズとアンダーグラウンド音楽シーン |

### Workplace / 職場 (mal_id: 48)
| Name | Name (JA) | Description | Description (JA) |
|---|---|---|---|
| Corporate | 企業 | Office work and corporate ladder climbing | オフィスワークと出世 |
| Game Development | ゲーム開発 | Making video games as profession | ビデオゲーム開発を職業として |
| Anime Industry | アニメ業界 | Behind the scenes of anime production | アニメ制作の舞台裏 |
| Manga Artist | 漫画家 | Life as a professional manga creator | プロの漫画家としての生活 |
| Healthcare Worker | 医療従事者 | Doctors, nurses, and hospital stories | 医師、看護師、病院の物語 |
| Teacher | 教師 | Teaching profession and school staff stories | 教職と学校スタッフの物語 |
| Military Service | 軍務 | Professional military life and duty | 職業軍人の生活と任務 |
| Firefighter / Rescue | 消防・救助 | Emergency services and rescue operations | 緊急サービスと救助活動 |
| Space Crew | 宇宙乗組員 | Life aboard spacecraft or space stations | 宇宙船や宇宙ステーションでの生活 |
| Chef / Baker | シェフ・パン職人 | Professional cooking and baking | プロの料理とパン作り |
| Journalist | ジャーナリスト | Reporting, investigative journalism | 報道、調査ジャーナリズム |
| Lawyer | 弁護士 | Legal profession and courtroom work | 法律の専門家と法廷での仕事 |
| Programmer | プログラマー | Software development and tech industry | ソフトウェア開発と技術業界 |
| Fashion Designer | ファッションデザイナー | Clothing design and fashion industry | 服飾デザインとファッション業界 |
| Veterinarian | 獣医 | Animal care and veterinary practice | 動物の世話と獣医の仕事 |
| Farmer | 農家 | Agricultural work and farm life | 農作業と農場生活 |
| Innkeeper | 宿屋 | Running an inn, hotel, or guesthouse | 旅館、ホテル、ゲストハウスの経営 |
| Librarian | 図書館員 | Library work and book management | 図書館の仕事と本の管理 |
| Blacksmith | 鍛冶屋 | Forging weapons and armor as profession | 武器や鎧を鍛造する職業 |
| Merchant | 商人 | Trading goods and running businesses | 商品の取引と事業の運営 |
| Adventurer (Profession) | 冒険者（職業） | Adventuring as a paid profession | 有給の職業としての冒険 |
| Scientist | 科学者 | Research and scientific discovery | 研究と科学的発見 |
| Architect | 建築家 | Designing and constructing buildings | 建物の設計と建設 |
| Idol Manager | アイドルマネージャー | Managing entertainment talent | 芸能タレントのマネジメント |
| Assassin (Profession) | 暗殺者（職業） | Contract killing as a job | 仕事としての暗殺 |
| Bounty Hunter (Profession) | 賞金稼ぎ（職業） | Professional bounty hunting | プロの賞金稼ぎ |
| Bartender | バーテンダー | Working in a bar and listening to stories | バーで働き客の話を聞く |
| Detective (Profession) | 探偵（職業） | Professional private investigation | プロの私立探偵 |
| Delivery | 配達 | Delivery and courier work | 配達と宅配の仕事 |

### Isekai / 異世界 (mal_id: 62)
| Name | Name (JA) | Description | Description (JA) |
|---|---|---|---|
| Overpowered Protagonist | 俺TUEEE | Main character starts with or quickly gains overwhelming power | 主人公が最初から圧倒的な力を持つ |
| Slow Life | スローライフ | Relaxed life in another world, avoiding conflict | 異世界でのんびり暮らす、争いを避ける |
| Kingdom Building | 国づくり | Building or reforming a nation in another world | 異世界での国家建設や改革 |
| Game World | ゲーム世界 | Trapped in or reborn in a video game world | ビデオゲームの世界に閉じ込められるか転生する |
| Summoned Hero | 召喚勇者 | Called to another world to be its savior | 別の世界に召喚されて救世主になる |
| Regression | 巻き戻り | Returning to an earlier point in time to redo life | 人生をやり直すために過去に戻る |
| Reverse Isekai | 逆異世界 | Fantasy beings coming to the modern world | ファンタジーの存在が現代世界に来る |
| Death and Restart | 死に戻り | Dying and respawning repeatedly to progress | 死んでリスポーンを繰り返して進む |
| Cheat Skill | チートスキル | Given a broken ability upon arrival in new world | 異世界到着時にチート能力を与えられる |
| Monster Evolution | モンスター進化 | Reborn as a monster, evolving to grow stronger | モンスターに転生し、進化して強くなる |
| Otome Game | 乙女ゲーム | Reborn inside a romance game world | 乙女ゲームの世界に転生する |
| Craft & Build | クラフト＆ビルド | Using modern knowledge to create things in a fantasy world | 現代の知識を使ってファンタジー世界でものづくり |
| Reborn as Object | 物に転生 | Reincarnated as a sword, vending machine, slime, etc. | 剣、自動販売機、スライムなどに転生 |
| Slave Protagonist | 奴隷主人公 | Starting as a slave in the new world | 異世界で奴隷として始まる |
| Dungeon Master | ダンジョンマスター | Managing and building dungeons in another world | 異世界でダンジョンを管理・建設する |
| Harem Isekai | 異世界ハーレム | Isekai with multiple romantic interests | 複数の恋愛対象がいる異世界 |
| Dark Isekai | ダーク異世界 | Grim, brutal isekai with serious consequences | 深刻な結果を伴う残酷な異世界 |
| Comedy Isekai | コメディ異世界 | Lighthearted and funny isekai adventures | 軽快で面白い異世界冒険 |
| Truck-kun | トラック転生 | Transported to another world via truck accident | トラック事故で異世界に転送される |
| Status Window | ステータスウィンドウ | RPG-like status screens and level systems | RPGのようなステータス画面とレベルシステム |
| Modern Knowledge | 現代知識 | Using modern science/technology in a medieval world | 中世の世界で現代の科学/技術を使う |
| Pharmacist Isekai | 異世界薬師 | Making medicines and potions in another world | 異世界で薬やポーションを作る |
| Cooking Isekai | 異世界料理 | Using modern cooking in a fantasy world | ファンタジー世界で現代の料理を使う |
| Reborn as Villain | 悪役転生 | Reincarnated as the story's villain | 物語の悪役に転生する |
| Second Life | セカンドライフ | Living a completely new life after reincarnation | 転生後にまったく新しい人生を生きる |
| Party Kicked Out | パーティー追放 | Hero expelled from party, proves their worth | パーティーから追放された勇者が実力を証明する |
| Tamer Isekai | 異世界テイマー | Taming and collecting monsters in another world | 異世界でモンスターをテイムして集める |
| Merchant Isekai | 異世界商人 | Running a business in a fantasy world | ファンタジー世界で商売を営む |
| Retired Hero | 引退勇者 | Former hero trying to live peacefully | 平和に暮らそうとする元勇者 |
| Skill Gacha | スキルガチャ | Random skill acquisition upon isekai arrival | 異世界到着時にランダムなスキルを取得 |
| Labyrinth Isekai | 迷宮異世界 | Entire world is a dungeon/labyrinth | 世界全体がダンジョン/迷宮 |

### Psychological / 心理 (mal_id: 40)
| Name | Name (JA) | Description | Description (JA) |
|---|---|---|---|
| Mind Games | 心理戦 | Characters outsmarting each other through manipulation | 心理操作でお互いを出し抜くキャラクター |
| Unreliable Narrator | 信頼できない語り手 | Story told through a perspective that may be false | 嘘かもしれない視点から語られる物語 |
| Identity Crisis | アイデンティティの危機 | Characters questioning who they truly are | 自分が本当は誰なのか疑問に思うキャラクター |
| Gaslighting | ガスライティング | Psychological manipulation to make someone doubt reality | 現実を疑わせる心理的操作 |
| Descent into Madness | 狂気への転落 | Gradual mental deterioration of characters | キャラクターの徐々に進む精神崩壊 |
| Moral Dilemma | 道徳的ジレンマ | Impossible choices with no right answer | 正解のない不可能な選択 |
| Stockholm Syndrome | ストックホルム症候群 | Bonding with captors or abusers | 捕獲者や虐待者との絆 |
| Split Personality | 二重人格 | Multiple personalities or dissociative identity | 多重人格や解離性同一性 |
| Paranoia | パラノイア | Extreme distrust and fear of persecution | 極端な不信と迫害への恐怖 |
| Trauma Recovery | トラウマ回復 | Dealing with and healing from past trauma | 過去のトラウマへの対処と回復 |
| Brainwashing | 洗脳 | Systematic mental reprogramming | 体系的な精神の再プログラミング |
| Obsession | 執着 | Unhealthy fixation on a person, goal, or idea | 人、目標、アイデアへの不健全な執着 |
| Social Experiment | 社会実験 | Characters placed in experimental social conditions | 実験的な社会条件に置かれたキャラクター |
| Memory Manipulation | 記憶操作 | Altering, erasing, or implanting memories | 記憶の改変、消去、または埋め込み |
| Deception | 欺瞞 | Characters living lies and maintaining false identities | 嘘の人生を送り偽のアイデンティティを維持するキャラクター |
| Existential Crisis | 存在の危機 | Characters questioning the meaning of existence | 存在の意味を問うキャラクター |
| Claustrophobic | 閉所恐怖 | Psychological tension from confined spaces | 閉じた空間からの心理的緊張 |
| Manipulation | 操作 | Characters controlling others through psychological means | 心理的手段で他者を操るキャラクター |
| Survival Game | サバイバルゲーム | Psychological pressure of life-or-death games | 生死をかけたゲームの心理的圧力 |
| Hallucination | 幻覚 | Characters unable to distinguish real from imagined | 現実と想像を区別できないキャラクター |
| Cult of Personality | 個人崇拝 | Charismatic leaders manipulating followers | カリスマ的なリーダーが信者を操る |
| PTSD | PTSD | Characters dealing with post-traumatic stress | 心的外傷後ストレスに対処するキャラクター |
| Philosophical | 哲学的 | Deep exploration of philosophical concepts | 哲学的概念の深い探究 |
| Social Isolation | 社会的孤立 | Withdrawal from society and its effects | 社会からの引きこもりとその影響 |
| Power Corruption | 権力腐敗 | Psychological effects of gaining great power | 大きな力を得ることの心理的影響 |
| Stockholm Dynamic | ストックホルム関係 | Complex bonds between captor and captive | 捕獲者と被捕虜の間の複雑な絆 |
| Impostor Syndrome | インポスター症候群 | Characters doubting their own achievements | 自分の成果を疑うキャラクター |
| Peer Pressure | 同調圧力 | Being forced to conform by social groups | 社会集団による同調への強制 |
| Psychopath | サイコパス | Characters with antisocial personality disorder | 反社会性パーソナリティ障害のキャラクター |
| Thought Experiment | 思考実験 | Narrative as a philosophical thought experiment | 哲学的思考実験としての物語 |

### School / 学園 (mal_id: 23)
| Name | Name (JA) | Description | Description (JA) |
|---|---|---|---|
| High School | 高校 | Japanese high school setting | 日本の高校を舞台 |
| Middle School | 中学校 | Junior high school setting | 中学校を舞台 |
| University | 大学 | College and university life | 大学生活 |
| Student Council | 生徒会 | Student government and school politics | 生徒会と学校政治 |
| School Festival | 文化祭 | Cultural festivals and school events | 文化祭と学校行事 |
| Boarding School | 寄宿学校 | Residential school setting | 全寮制の学校を舞台 |
| Transfer Student | 転校生 | New student arriving at school | 学校に新しくやってくる生徒 |
| Delinquent School | 不良学園 | Schools dominated by delinquents and gangs | 不良やギャングが支配する学校 |
| Exam Hell | 受験地獄 | Academic pressure and entrance exam stress | 学業のプレッシャーと受験のストレス |
| Teacher-Student | 師弟関係 | Meaningful mentor-student relationships | 意味のある師弟関係 |
| Elementary School | 小学校 | Primary school setting | 小学校を舞台 |
| Cram School | 塾 | After-school tutoring and study academies | 放課後の塾と学習アカデミー |
| School Trip | 修学旅行 | Adventures during school excursions | 修学旅行中の冒険 |
| Graduation | 卒業 | Stories about the end of school life | 学校生活の終わりの物語 |
| School Rivalry | 学校対抗 | Competition between rival schools | ライバル校間の競争 |
| Class Representative | 学級委員長 | Student leadership and class management | 生徒のリーダーシップと学級運営 |
| School Mystery | 学園ミステリー | Mysteries happening within school grounds | 学校の敷地内で起こるミステリー |
| School Battle | 学園バトル | Combat or competition within school settings | 学校を舞台にした戦闘や競争 |
| After-School Activities | 放課後活動 | What happens after classes end | 授業が終わった後の活動 |
| Summer School | 夏期講習 | Summer academic programs and activities | 夏の学習プログラムと活動 |
| School Hierarchy | スクールカースト | Social hierarchies and cliques in school | 学校内の社会的階層とグループ |
| New School Year | 新学期 | Starting fresh in a new academic year | 新しい学年の始まり |
| School Rooftop | 屋上 | Iconic school rooftop as key setting | 象徴的な学校の屋上を重要な舞台として |
| Library Committee | 図書委員 | School library as central gathering place | 中心的な集合場所としての学校図書館 |
| Swimming Pool | プール | School pool activities and events | 学校のプール活動とイベント |

### Military / 軍事 (mal_id: 38)
| Name | Name (JA) | Description | Description (JA) |
|---|---|---|---|
| Special Forces | 特殊部隊 | Elite military units and covert operations | 精鋭部隊と秘密作戦 |
| Mercenary | 傭兵 | Soldiers for hire and private military | 雇われ兵士と民間軍事 |
| Cold War | 冷戦 | Espionage and tension between superpowers | 超大国間のスパイ活動と緊張 |
| Military Academy | 士官学校 | Training to become military officers | 軍の将校になるための訓練 |
| Anti-War | 反戦 | Stories emphasizing the futility of war | 戦争の無意味さを強調する物語 |
| Guerrilla Warfare | ゲリラ戦 | Resistance fighters and unconventional warfare | レジスタンスと非正規戦争 |
| Naval Military | 海軍 | Navy and submarine warfare | 海軍と潜水艦戦 |
| Air Force | 空軍 | Fighter pilots and aerial military operations | 戦闘機パイロットと航空軍事作戦 |
| Tank Warfare | 戦車戦 | Armored vehicle combat | 装甲車両の戦闘 |
| Trench Warfare | 塹壕戦 | WWI-style defensive combat | 第一次世界大戦型の防衛戦闘 |
| Military Intelligence | 軍事情報 | Spying and intelligence within military context | 軍事的な文脈でのスパイ活動と情報収集 |
| Nuclear Warfare | 核戦争 | Threat or use of nuclear weapons | 核兵器の脅威または使用 |
| Prisoner of War | 捕虜 | Stories of captured soldiers | 捕虜になった兵士の物語 |
| Military Occupation | 軍事占領 | Life under foreign military control | 外国軍の支配下での生活 |
| Rebellion | 反乱 | Armed uprising against established authority | 確立された権力に対する武装蜂起 |
| Siege Warfare | 包囲戦 | Extended military siege of fortifications | 要塞の長期的な軍事包囲 |
| Commando Raid | コマンド急襲 | Small team high-risk military missions | 少人数チームの高リスク軍事任務 |
| Battlefield Medicine | 戦場医療 | Medical treatment in combat zones | 戦闘地域での医療 |
| Draft / Conscription | 徴兵 | Forced military service and its effects | 強制的な兵役とその影響 |
| War Crime | 戦争犯罪 | Atrocities committed during warfare | 戦争中に犯された残虐行為 |
| Peacekeeper | 平和維持 | Military forces maintaining peace | 平和を維持する軍事力 |
| Child Soldier | 少年兵 | Children forced into military combat | 軍事戦闘に強制された子供 |

### Harem / ハーレム (mal_id: 35)
| Name | Name (JA) | Description | Description (JA) |
|---|---|---|---|
| Battle Harem | バトルハーレム | Multiple love interests who also fight alongside protagonist | 主人公と共に戦う複数の恋愛対象 |
| Fantasy Harem | ファンタジーハーレム | Harem in a fantasy world setting | ファンタジー世界でのハーレム |
| School Harem | 学園ハーレム | Multiple love interests in a school setting | 学園での複数の恋愛対象 |
| Monster Girl | モンスター娘 | Love interests are non-human female creatures | 恋愛対象が人間以外の女性の生き物 |
| Accidental Harem | 天然ハーレム | Protagonist unintentionally attracts multiple partners | 主人公が無意識に複数のパートナーを引きつける |
| Isekai Harem | 異世界ハーレム | Harem formed after being transported to another world | 異世界に転送された後に形成されるハーレム |
| Workplace Harem | 職場ハーレム | Multiple love interests at work | 職場での複数の恋愛対象 |
| Demon Girl | 魔族娘 | Love interests are demonic or dark beings | 恋愛対象が悪魔的または闇の存在 |
| Elf Harem | エルフハーレム | Elves and fantasy races as love interests | エルフやファンタジー種族が恋愛対象 |
| Maid Harem | メイドハーレム | Maids and servants as love interests | メイドや使用人が恋愛対象 |
| Ninja Harem | 忍者ハーレム | Kunoichi and ninja love interests | くノ一や忍者が恋愛対象 |
| Robot Girl | ロボット娘 | Android or robot female love interests | アンドロイドやロボットの女性が恋愛対象 |
| Spirit Harem | 精霊ハーレム | Supernatural spirits as love interests | 超自然的な精霊が恋愛対象 |
| Royal Harem | 王族ハーレム | Princesses and nobility as love interests | 王女や貴族が恋愛対象 |
| Goddess Harem | 女神ハーレム | Divine beings as love interests | 神聖な存在が恋愛対象 |

### Mecha / メカ (mal_id: 18)
| Name | Name (JA) | Description | Description (JA) |
|---|---|---|---|
| Real Robot | リアルロボット | Realistic mechanical design, mass-produced units | 現実的なメカデザイン、量産型ユニット |
| Super Robot | スーパーロボット | Fantastical, one-of-a-kind powerful robots | 幻想的で唯一無二の強力なロボット |
| Combining Mecha | 合体メカ | Multiple units merging into one giant robot | 複数のユニットが一体の巨大ロボットに合体 |
| Transforming Mecha | 変形メカ | Robots that change between forms | 形態を変えるロボット |
| Powered Suit | パワードスーツ | Wearable exoskeletons and power armor | 装着型の外骨格とパワーアーマー |
| AI Mecha | AIメカ | Sentient or AI-controlled robots | 知性を持つ、またはAI制御のロボット |
| Remote Control | 遠隔操作 | Piloting robots remotely, not from inside | ロボットの中からではなく遠隔で操縦 |
| Biological Mecha | 生体メカ | Organic or bio-mechanical robots | 有機的またはバイオメカニカルなロボット |
| Mass Produced | 量産型 | Stories focusing on regular soldiers in common mecha | 一般的なメカの通常兵士に焦点 |
| Prototype | 試作機 | One-of-a-kind experimental mecha | 唯一無二の実験的メカ |
| Drone Swarm | ドローン群 | Unmanned robotic swarms in combat | 戦闘での無人ロボット群 |
| Neural Link | 神経接続 | Mind-linked pilot-robot interface | 心で繋がるパイロット・ロボットインターフェース |
| Giant vs Giant | 巨大対決 | Kaiju-scale mecha vs monster battles | 怪獣規模のメカ対モンスターバトル |
| Arms Race | 軍拡競争 | Nations competing to build better mecha | 国家間のより優れたメカ建造競争 |
| Mecha Sports | メカスポーツ | Competitive mecha piloting as sport | スポーツとしての競技メカ操縦 |
| Repair / Mechanic | 整備士 | Focus on maintaining and repairing mecha | メカの整備と修理に焦点 |

### Space / 宇宙 (mal_id: 29)
| Name | Name (JA) | Description | Description (JA) |
|---|---|---|---|
| Space Exploration | 宇宙探検 | Discovering new planets and star systems | 新しい惑星や星系の発見 |
| Space Station | 宇宙ステーション | Life on orbital space stations | 軌道上の宇宙ステーションでの生活 |
| Planet Colonization | 惑星植民 | Settling on new worlds | 新しい世界への移住 |
| Space Pirates | 宇宙海賊 | Piracy in outer space | 宇宙空間での海賊行為 |
| Space Western | スペースウェスタン | Western themes in space settings | 宇宙を舞台にした西部劇のテーマ |
| Moon Base | 月面基地 | Stories set on lunar settlements | 月面居住地を舞台にした物語 |
| Mars Colony | 火星植民地 | Stories on Mars | 火星を舞台にした物語 |
| Asteroid Mining | 小惑星採掘 | Mining resources from asteroids | 小惑星からの資源採掘 |
| Deep Space | 深宇宙 | Ventures far beyond our solar system | 太陽系を遥かに超えた冒険 |
| Space Debris | 宇宙ゴミ | Dealing with orbital debris and space junk | 軌道上のデブリと宇宙ゴミへの対処 |
| First Contact | ファーストコンタクト | Humanity's first meeting with aliens | 人類と宇宙人の最初の出会い |
| Space Race | 宇宙開発競争 | Competition to explore and claim space | 宇宙の探索と領有の競争 |

### Vampire / 吸血鬼 (mal_id: 32)
| Name | Name (JA) | Description | Description (JA) |
|---|---|---|---|
| Vampire Hunter | 吸血鬼ハンター | Characters who hunt and slay vampires | 吸血鬼を狩り滅ぼすキャラクター |
| Vampire Romance | 吸血鬼ロマンス | Romantic relationships involving vampires | 吸血鬼が関わるロマンチックな関係 |
| Dhampir | ダンピール | Half-vampire, half-human characters | 半吸血鬼、半人間のキャラクター |
| Vampire Society | 吸血鬼社会 | Hidden vampire civilizations and politics | 隠された吸血鬼文明と政治 |
| Blood Drinking | 吸血 | Focus on the act and meaning of blood consumption | 吸血の行為と意味に焦点 |
| Daywalker | デイウォーカー | Vampires who can survive in sunlight | 日光の下で生存できる吸血鬼 |
| Vampire Origin | 吸血鬼起源 | Exploring how vampires came to exist | 吸血鬼がどのように存在するようになったかを探る |
| Vampire War | 吸血鬼戦争 | Conflicts between vampire factions or vs humans | 吸血鬼派閥間または対人間の紛争 |
| Nosferatu | ノスフェラトゥ | Classic ugly/monstrous vampire archetype | 古典的な醜い/怪物的な吸血鬼の原型 |
| Vampire Lord | 吸血鬼の王 | Ancient powerful vampire rulers | 古代の強力な吸血鬼の支配者 |

### Survival / サバイバル (mal_id: 76)
| Name | Name (JA) | Description | Description (JA) |
|---|---|---|---|
| Death Game | デスゲーム | Forced participation in lethal games | 致命的なゲームへの強制参加 |
| Deserted Island | 無人島 | Stranded on an uninhabited island | 無人島に取り残される |
| Zombie Survival | ゾンビサバイバル | Surviving a zombie apocalypse | ゾンビ黙示録を生き延びる |
| Wilderness Survival | 野外サバイバル | Surviving in untamed nature | 未開の自然での生存 |
| Post-Nuclear | 核戦争後 | Surviving after nuclear devastation | 核による壊滅後の生存 |
| Pandemic Survival | パンデミック | Surviving a deadly disease outbreak | 致命的な疾病の流行を生き延びる |
| Food Scarcity | 食糧危機 | Struggling to find food and water | 食料と水を見つけるための苦闘 |
| Shelter Building | シェルター建設 | Constructing safe havens for survival | 生存のための安全な避難所の建設 |
| Cannibal Island | カニバルアイランド | Survival among human predators | 人間の捕食者の中での生存 |
| Natural Disaster | 自然災害 | Surviving earthquakes, tsunamis, volcanic eruptions | 地震、津波、噴火を生き延びる |
| Lifeboat | 救命ボート | Survival on open water after shipwreck | 難破後の外洋での生存 |
| Hunt or Be Hunted | 狩るか狩られるか | Predator-prey dynamics among survivors | 生存者間の捕食者と被食者の関係 |

### Organized Crime / 組織犯罪 (mal_id: 68)
| Name | Name (JA) | Description | Description (JA) |
|---|---|---|---|
| Yakuza | ヤクザ | Japanese organized crime syndicates | 日本の組織犯罪シンジケート |
| Mafia | マフィア | Italian-style organized crime families | イタリア式の組織犯罪ファミリー |
| Triad | 三合会 | Chinese organized crime groups | 中国の組織犯罪グループ |
| Drug Cartel | 麻薬カルテル | Drug trafficking organizations | 麻薬密売組織 |
| Street Gang | ストリートギャング | Urban street-level criminal groups | 都市の路上レベルの犯罪グループ |
| Crime Boss | 犯罪ボス | Rise to power within criminal organizations | 犯罪組織内での権力の台頭 |
| Undercover | 潜入 | Infiltrating criminal organizations | 犯罪組織への潜入 |
| Money Laundering | マネーロンダリング | Financial crime and money cleaning | 金融犯罪と資金洗浄 |
| Turf War | 縄張り争い | Territory disputes between criminal groups | 犯罪グループ間の縄張り争い |
| Corruption | 汚職 | Criminals influencing government and police | 犯罪者が政府と警察に影響を与える |

### Boys Love / ボーイズラブ (mal_id: 28)
| Name | Name (JA) | Description | Description (JA) |
|---|---|---|---|
| Seme-Uke | 攻め受け | Traditional top-bottom dynamic in BL | BLにおける伝統的な攻め受けの関係性 |
| School BL | 学園BL | Boys love in school settings | 学園を舞台にしたボーイズラブ |
| Office BL | オフィスBL | Workplace boys love stories | 職場のボーイズラブ |
| Fantasy BL | ファンタジーBL | Boys love in fantasy settings | ファンタジーを舞台にしたBL |
| Historical BL | 歴史BL | Boys love in historical periods | 歴史的な時代のBL |
| Sports BL | スポーツBL | Boys love between athletes | スポーツ選手間のBL |
| Omegaverse | オメガバース | Alpha/Beta/Omega dynamics | アルファ/ベータ/オメガの世界観 |
| Bara | バラ | Masculine men romance | 男性的な男性同士のロマンス |
| Age Gap BL | 年の差BL | Significant age difference in BL | BLにおける大きな年齢差 |
| Idol BL | アイドルBL | Boys love between idol performers | アイドル間のBL |

### Girls Love / 百合 (mal_id: 26)
| Name | Name (JA) | Description | Description (JA) |
|---|---|---|---|
| School Yuri | 学園百合 | Girls love in school settings | 学園を舞台にした百合 |
| Adult Yuri | 大人百合 | Mature women in romantic relationships | 成熟した女性のロマンチックな関係 |
| Fantasy Yuri | ファンタジー百合 | Girls love in fantasy settings | ファンタジーを舞台にした百合 |
| Workplace Yuri | 職場百合 | Girls love between coworkers | 同僚間の百合 |
| Class S | クラスS | Romantic friendships in all-girls schools | 女子校でのロマンチックな友情 |
| Tomboy Yuri | ボーイッシュ百合 | Masculine-presenting female in yuri | ボーイッシュな女性が登場する百合 |
| Sports Yuri | スポーツ百合 | Girls love between female athletes | 女性アスリート間の百合 |
| Military Yuri | 軍事百合 | Girls love in military context | 軍事的な文脈での百合 |
| Idol Yuri | アイドル百合 | Girls love between idol performers | アイドル間の百合 |
| Sci-Fi Yuri | SF百合 | Girls love in science fiction settings | SFを舞台にした百合 |

### Gourmet / グルメ (mal_id: 47)
| Name | Name (JA) | Description | Description (JA) |
|---|---|---|---|
| Cooking Battle | 料理バトル | Competitive cooking contests | 料理コンテスト |
| Restaurant Management | レストラン経営 | Running and managing restaurants | レストランの運営と経営 |
| Street Food | 屋台料理 | Food stalls and street vendor culture | 屋台と露店文化 |
| Fine Dining | 高級料理 | Haute cuisine and Michelin-star cooking | 高級料理とミシュラン |
| Japanese Cuisine | 和食 | Traditional Japanese cooking | 伝統的な日本料理 |
| Baking | 製菓 | Pastry, bread, and dessert making | 菓子、パン、デザート作り |
| Wine / Sake | ワイン・日本酒 | Alcoholic beverages, sommelier stories | アルコール飲料、ソムリエの物語 |
| Ramen | ラーメン | Ramen culture and shop stories | ラーメン文化とラーメン店の物語 |
| Food Travel | 食旅 | Traveling to experience different cuisines | 異なる料理を体験するために旅する |
| Home Cooking | 家庭料理 | Everyday home-cooked meals and family recipes | 日常の家庭料理と家族のレシピ |
| Food Science | 料理科学 | Scientific approach to cooking and food | 料理と食品への科学的アプローチ |
| Comfort Food | 癒し飯 | Emotionally healing through food | 食を通じた心の癒し |

### Mahou Shoujo / 魔法少女 (mal_id: 66)
| Name | Name (JA) | Description | Description (JA) |
|---|---|---|---|
| Classic Magical Girl | 古典的魔法少女 | Traditional transformation and fighting evil | 伝統的な変身と悪との戦い |
| Dark Magical Girl | ダーク魔法少女 | Deconstructed, dark take on the genre | ジャンルの脱構築的で暗い解釈 |
| Magical Girl Team | 魔法少女チーム | Group of magical girls fighting together | 一緒に戦う魔法少女グループ |
| Magical Boy | 魔法少年 | Male equivalent of magical girl | 魔法少女の男性版 |
| Mascot Character | マスコット | Cute animal companion granting powers | 力を与える可愛い動物の相棒 |
| Magical Girl Rival | 魔法少女ライバル | Competing magical girls | 競い合う魔法少女たち |
| Transformation Sequence | 変身シーン | Iconic costume change sequences | 象徴的な衣装チェンジシーン |
| Corrupted Magical Girl | 堕落魔法少女 | Magical girls turning evil or being corrupted | 悪に堕ちた、または腐敗した魔法少女 |
| Retired Magical Girl | 引退魔法少女 | Former magical girls dealing with normal life | 普通の生活に向き合う元魔法少女 |
| Magical Girl Origins | 魔法少女起源 | How a girl first gains her powers | 少女が最初に力を得る物語 |

### Reincarnation / 転生 (mal_id: 72)
| Name | Name (JA) | Description | Description (JA) |
|---|---|---|---|
| Reborn as Baby | 赤ちゃん転生 | Starting life over from birth with past memories | 前世の記憶を持って赤ちゃんから人生をやり直す |
| Reborn as Noble | 貴族転生 | Reincarnated into aristocratic family | 貴族の家庭に転生 |
| Reborn as Commoner | 平民転生 | Reincarnated into a common family | 平民の家庭に転生 |
| Reborn as Monster | モンスター転生 | Reincarnated as a non-human creature | 人間以外の生き物に転生 |
| Past Life Memories | 前世の記憶 | Remembering previous lives | 前世を思い出す |
| Karmic Cycle | 因果応報 | Reincarnation tied to karma and past deeds | カルマと過去の行いに結びついた転生 |
| Age Regression | 年齢退行 | Adult mind in a child's body | 子供の体に大人の精神 |
| Reborn in Same World | 同世界転生 | Reincarnated in the same world, different time | 同じ世界の異なる時代に転生 |
| Reborn as Opposite Gender | 性別転換転生 | Reincarnated as the opposite sex | 異性に転生 |
| Reborn with System | システム転生 | Reincarnated with a game-like system | ゲームのようなシステムを持って転生 |

---

Total: **702 sub-genres** across **30 parent genres**.
合計：**30の親ジャンル**にわたる**702のサブジャンル**。
