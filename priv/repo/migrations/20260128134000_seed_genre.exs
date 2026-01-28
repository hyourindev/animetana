defmodule Yunaos.Repo.Migrations.SeedGenresDemographicsThemes do
  use Ecto.Migration

  def up do
    # ============================================================================
    # CLEANUP: Remove existing data
    # ============================================================================
    execute "TRUNCATE TABLE anime_genres RESTART IDENTITY CASCADE"
    execute "TRUNCATE TABLE manga_genres RESTART IDENTITY CASCADE"
    execute "TRUNCATE TABLE anime_demographics RESTART IDENTITY CASCADE"
    execute "TRUNCATE TABLE manga_demographics RESTART IDENTITY CASCADE"
    execute "TRUNCATE TABLE anime_themes RESTART IDENTITY CASCADE"
    execute "TRUNCATE TABLE manga_themes RESTART IDENTITY CASCADE"
    execute "TRUNCATE TABLE genres RESTART IDENTITY CASCADE"
    execute "TRUNCATE TABLE demographics RESTART IDENTITY CASCADE"
    execute "TRUNCATE TABLE themes RESTART IDENTITY CASCADE"

    # ============================================================================
    # GENRES (18 from MAL/Jikan)
    # ============================================================================
    execute """
    INSERT INTO genres (mal_id, name, name_ja, type, description, description_ja, inserted_at) VALUES
    (1, 'Action', 'アクション', 'both', 'Exciting action sequences and combat', '興奮するアクションシーンと戦闘', NOW()),
    (2, 'Adventure', '冒険', 'both', 'Journeys and exploration of new places', '新しい場所への旅と探索', NOW()),
    (4, 'Comedy', 'コメディ', 'both', 'Humorous and funny content', 'ユーモラスで面白いコンテンツ', NOW()),
    (5, 'Avant Garde', 'アヴァンギャルド', 'both', 'Experimental and unconventional storytelling', '実験的で型破りな物語', NOW()),
    (7, 'Mystery', 'ミステリー', 'both', 'Puzzles, investigations, and suspenseful plots', 'パズル、調査、サスペンスのあるプロット', NOW()),
    (8, 'Drama', 'ドラマ', 'both', 'Emotional and character-driven stories', '感情的でキャラクター主導の物語', NOW()),
    (10, 'Fantasy', 'ファンタジー', 'both', 'Magic, mythical creatures, and imaginary worlds', '魔法、神話の生き物、想像上の世界', NOW()),
    (14, 'Horror', 'ホラー', 'both', 'Frightening and scary content', '恐ろしく怖いコンテンツ', NOW()),
    (22, 'Romance', '恋愛', 'both', 'Love and romantic relationships', '愛とロマンチックな関係', NOW()),
    (24, 'Sci-Fi', 'SF', 'both', 'Science fiction and futuristic settings', 'サイエンスフィクションと未来的な設定', NOW()),
    (26, 'Girls Love', '百合', 'both', 'Romantic relationships between women', '女性間のロマンチックな関係', NOW()),
    (28, 'Boys Love', 'ボーイズラブ', 'both', 'Romantic relationships between men', '男性間のロマンチックな関係', NOW()),
    (30, 'Sports', 'スポーツ', 'both', 'Athletic competitions and sports activities', '運動競技とスポーツ活動', NOW()),
    (36, 'Slice of Life', '日常', 'both', 'Everyday life and mundane experiences', '日常生活と平凡な体験', NOW()),
    (37, 'Supernatural', '超自然', 'both', 'Paranormal and supernatural elements', '超常現象と超自然的要素', NOW()),
    (41, 'Suspense', 'サスペンス', 'both', 'Tension and thrilling anticipation', '緊張感とスリリングな期待', NOW()),
    (46, 'Award Winning', '受賞作品', 'both', 'Works that have won notable awards', '著名な賞を受賞した作品', NOW()),
    (47, 'Gourmet', 'グルメ', 'both', 'Food, cooking, and culinary experiences', '食べ物、料理、食の体験', NOW())
    """

    # ============================================================================
    # DEMOGRAPHICS (5 from MAL/Jikan - Target audiences)
    # ============================================================================
    execute """
    INSERT INTO demographics (mal_id, name, name_ja, type, description, description_ja, inserted_at) VALUES
    (15, 'Kids', 'キッズ', 'both', 'Target audience: children (under 10)', '対象読者：子供（10歳未満）', NOW()),
    (25, 'Shoujo', '少女', 'both', 'Target audience: young girls (10-18)', '対象読者：少女（10〜18歳）', NOW()),
    (27, 'Shounen', '少年', 'both', 'Target audience: young boys (10-18)', '対象読者：少年（10〜18歳）', NOW()),
    (42, 'Seinen', '青年', 'both', 'Target audience: young adult men (18+)', '対象読者：青年男性（18歳以上）', NOW()),
    (43, 'Josei', '女性', 'both', 'Target audience: young adult women (18+)', '対象読者：青年女性（18歳以上）', NOW())
    """

    # ============================================================================
    # THEMES - Part 1: Official MAL Themes (53)
    # ============================================================================
    execute """
    INSERT INTO themes (mal_id, name, name_ja, type, description, description_ja, inserted_at) VALUES
    (3, 'Racing', 'レース', 'both', 'Competitive racing of vehicles', '車両による競争レース', NOW()),
    (6, 'Mythology', '神話', 'both', 'Stories based on mythological tales', '神話に基づく物語', NOW()),
    (11, 'Strategy Game', '戦略ゲーム', 'both', 'Games requiring strategic thinking', '戦略的思考を必要とするゲーム', NOW()),
    (13, 'Historical', '歴史', 'both', 'Set in a historical time period', '歴史的な時代を舞台', NOW()),
    (17, 'Martial Arts', '格闘技', 'both', 'Combat using martial arts techniques', '格闘技を使った戦闘', NOW()),
    (18, 'Mecha', 'メカ', 'both', 'Giant robots and mechanical suits', '巨大ロボットとメカスーツ', NOW()),
    (19, 'Music', '音楽', 'both', 'Music performance and industry', '音楽演奏と業界', NOW()),
    (20, 'Parody', 'パロディ', 'both', 'Humorous imitation of other works', '他作品のユーモラスな模倣', NOW()),
    (21, 'Samurai', '侍', 'both', 'Stories featuring samurai warriors', '侍を特徴とする物語', NOW()),
    (23, 'School', '学園', 'both', 'Set in a school environment', '学校環境を舞台', NOW()),
    (29, 'Space', '宇宙', 'both', 'Set in outer space', '宇宙を舞台', NOW()),
    (31, 'Super Power', '超能力', 'both', 'Characters with supernatural abilities', '超自然的な能力を持つキャラクター', NOW()),
    (32, 'Vampire', '吸血鬼', 'both', 'Stories featuring vampires', '吸血鬼を特徴とする物語', NOW()),
    (35, 'Harem', 'ハーレム', 'both', 'One character surrounded by many admirers', '多くの崇拝者に囲まれた一人のキャラクター', NOW()),
    (38, 'Military', '軍事', 'both', 'Military organizations and warfare', '軍事組織と戦争', NOW()),
    (39, 'Detective', '探偵', 'both', 'Investigation and solving mysteries', '調査とミステリーの解決', NOW()),
    (40, 'Psychological', '心理', 'both', 'Focus on mental and emotional states', '精神的・感情的状態に焦点', NOW()),
    (48, 'Workplace', '職場', 'both', 'Set in work environments', '職場を舞台', NOW()),
    (50, 'Adult Cast', '大人キャスト', 'both', 'Main cast consists of adults', '大人が主要キャスト', NOW()),
    (51, 'Anthropomorphic', '擬人化', 'both', 'Non-human characters with human traits', '人間の特性を持つ人間以外のキャラクター', NOW()),
    (52, 'CGDCT', '可愛い女の子日常系', 'both', 'Cute Girls Doing Cute Things', '可愛い女の子たちの可愛い日常', NOW()),
    (53, 'Childcare', '育児', 'both', 'Raising or caring for children', '子供の養育や世話', NOW()),
    (54, 'Combat Sports', '格闘スポーツ', 'both', 'Fighting-based sports competitions', '格闘技ベースのスポーツ競技', NOW()),
    (55, 'Delinquents', '不良', 'both', 'Juvenile delinquents and gangs', '不良とギャング', NOW()),
    (56, 'Educational', '教育', 'both', 'Educational content and learning', '教育的なコンテンツと学習', NOW()),
    (57, 'Gag Humor', 'ギャグ', 'both', 'Comedy focused on jokes and gags', 'ジョークやギャグに焦点を当てたコメディ', NOW()),
    (58, 'Gore', 'ゴア', 'both', 'Graphic depiction of blood and violence', '血と暴力のグラフィックな描写', NOW()),
    (59, 'High Stakes Game', '頭脳ゲーム', 'both', 'Games with serious consequences', '深刻な結果を伴うゲーム', NOW()),
    (60, 'Idols (Female)', 'アイドル（女性）', 'both', 'Female idol performers', '女性アイドル', NOW()),
    (61, 'Idols (Male)', 'アイドル（男性）', 'both', 'Male idol performers', '男性アイドル', NOW()),
    (62, 'Isekai', '異世界', 'both', 'Transported to another world', '異世界に転送される', NOW()),
    (63, 'Iyashikei', '癒し系', 'both', 'Healing and soothing stories', '癒し効果のある物語', NOW()),
    (64, 'Love Polygon', '三角関係', 'both', 'Complex romantic entanglements', '複雑な恋愛関係', NOW()),
    (65, 'Magical Sex Shift', '性転換', 'both', 'Magical gender transformation', '魔法による性別変換', NOW()),
    (66, 'Mahou Shoujo', '魔法少女', 'both', 'Magical girl stories', '魔法少女の物語', NOW()),
    (67, 'Medical', '医療', 'both', 'Medical and healthcare settings', '医療現場を舞台', NOW()),
    (68, 'Organized Crime', '組織犯罪', 'both', 'Criminal organizations and syndicates', '犯罪組織とシンジケート', NOW()),
    (69, 'Otaku Culture', 'オタク文化', 'both', 'Anime, manga, and geek culture', 'アニメ、マンガ、オタク文化', NOW()),
    (70, 'Performing Arts', '舞台芸術', 'both', 'Theater, dance, and performance', '演劇、ダンス、パフォーマンス', NOW()),
    (71, 'Pets', 'ペット', 'both', 'Stories featuring animal companions', '動物の相棒を特徴とする物語', NOW()),
    (72, 'Reincarnation', '転生', 'both', 'Rebirth into a new life', '新しい人生への転生', NOW()),
    (73, 'Reverse Harem', '逆ハーレム', 'both', 'One female surrounded by male admirers', '複数の男性に囲まれた女性', NOW()),
    (74, 'Love Status Quo', '恋愛現状維持', 'both', 'Romance without relationship progression', '関係が進展しない恋愛', NOW()),
    (75, 'Showbiz', '芸能界', 'both', 'Entertainment industry', '芸能界', NOW()),
    (76, 'Survival', 'サバイバル', 'both', 'Struggling to survive dangerous situations', '危険な状況で生き残る', NOW()),
    (77, 'Team Sports', 'チームスポーツ', 'both', 'Sports played in teams', 'チームで行うスポーツ', NOW()),
    (78, 'Time Travel', 'タイムトラベル', 'both', 'Traveling through time', '時間を旅する', NOW()),
    (79, 'Video Game', 'ビデオゲーム', 'both', 'Video game settings or themes', 'ビデオゲームの設定やテーマ', NOW()),
    (80, 'Visual Arts', 'ビジュアルアーツ', 'both', 'Painting, drawing, and visual arts', '絵画、デッサン、視覚芸術', NOW()),
    (81, 'Crossdressing', '女装・男装', 'both', 'Characters dressing as opposite gender', '異性の服装をするキャラクター', NOW()),
    (82, 'Urban Fantasy', '都市ファンタジー', 'both', 'Fantasy in modern urban settings', '現代都市を舞台にしたファンタジー', NOW()),
    (83, 'Villainess', '悪役令嬢', 'both', 'Villainous noble women stories', '悪役令嬢の物語', NOW())
    """

    # ============================================================================
    # THEMES - Part 2: Custom Isekai/Fantasy Tropes (10000-10019)
    # ============================================================================
    execute """
    INSERT INTO themes (mal_id, name, name_ja, type, description, description_ja, inserted_at) VALUES
    (10000, 'Overpowered Protagonist', '俺TUEEE', 'both', 'Main character with overwhelming power from the start', '最初から圧倒的な力を持つ主人公', NOW()),
    (10001, 'Village Building', '村づくり', 'both', 'Building and developing settlements or communities', '集落やコミュニティの建設と発展', NOW()),
    (10002, 'Kingdom Building', '国づくり', 'both', 'Building or reforming nations and empires', '国家や帝国の建設または改革', NOW()),
    (10003, 'Slow Life', 'スローライフ', 'both', 'Relaxed, peaceful life avoiding conflict', '争いを避けたのんびり平和な生活', NOW()),
    (10004, 'Cheat Skill', 'チートスキル', 'both', 'Protagonist with broken or unfair abilities', '壊れた不公平な能力を持つ主人公', NOW()),
    (10005, 'Status Window', 'ステータスウィンドウ', 'both', 'Game-like status screens and level systems', 'ゲームのようなステータス画面とレベルシステム', NOW()),
    (10006, 'Dungeon', 'ダンジョン', 'both', 'Exploring dungeons and labyrinths', 'ダンジョンや迷宮の探索', NOW()),
    (10007, 'Monster Tamer', 'モンスターテイマー', 'both', 'Taming and collecting monsters', 'モンスターをテイムして集める', NOW()),
    (10008, 'Summoned Hero', '召喚勇者', 'both', 'Hero summoned to save another world', '異世界を救うために召喚された勇者', NOW()),
    (10009, 'Demon Lord', '魔王', 'both', 'Stories about demon kings/lords', '魔王に関する物語', NOW()),
    (10010, 'Guild', 'ギルド', 'both', 'Adventurer guilds and quest systems', '冒険者ギルドとクエストシステム', NOW()),
    (10011, 'Regression', '回帰', 'both', 'Returning to the past to redo life', '過去に戻って人生をやり直す', NOW()),
    (10012, 'Second Chance', 'セカンドチャンス', 'both', 'Getting another opportunity at life', '人生のもう一度のチャンス', NOW()),
    (10013, 'Party Kicked Out', 'パーティー追放', 'both', 'Hero expelled from party proves their worth', 'パーティーから追放された勇者が実力を証明', NOW()),
    (10014, 'Skill Acquisition', 'スキル習得', 'both', 'Gaining and leveling up skills', 'スキルの獲得とレベルアップ', NOW()),
    (10015, 'Craft & Build', 'クラフト＆ビルド', 'both', 'Crafting items and building things', 'アイテムのクラフトと物づくり', NOW()),
    (10016, 'Modern Knowledge', '現代知識', 'both', 'Using modern knowledge in fantasy worlds', 'ファンタジー世界で現代知識を使う', NOW()),
    (10017, 'Game World', 'ゲーム世界', 'both', 'Trapped in or playing a game world', 'ゲーム世界に閉じ込められるか遊ぶ', NOW()),
    (10018, 'Death Game', 'デスゲーム', 'both', 'Forced participation in lethal games', '致命的なゲームへの強制参加', NOW()),
    (10019, 'Monster Evolution', 'モンスター進化', 'both', 'Reborn as monster, evolving to grow stronger', 'モンスターに転生し進化して強くなる', NOW())
    """

    # ============================================================================
    # THEMES - Part 3: Custom Fantasy & World-Building (10020-10035)
    # ============================================================================
    execute """
    INSERT INTO themes (mal_id, name, name_ja, type, description, description_ja, inserted_at) VALUES
    (10020, 'Dark Fantasy', 'ダークファンタジー', 'both', 'Grim, morally grey fantasy worlds', '暗く道徳的にグレーなファンタジー世界', NOW()),
    (10021, 'High Fantasy', 'ハイファンタジー', 'both', 'Epic quests in fully realized fantasy worlds', '構築されたファンタジー世界での壮大な冒険', NOW()),
    (10022, 'Low Fantasy', 'ローファンタジー', 'both', 'Minimal magic in mostly realistic world', 'ほぼ現実的な世界に最小限の魔法', NOW()),
    (10023, 'Sword and Sorcery', '剣と魔法', 'both', 'Classic fantasy with swords and magic', '剣と魔法の古典的なファンタジー', NOW()),
    (10024, 'Cultivation', '修行', 'both', 'Training to increase supernatural power', '超自然的な力を高めるための修行', NOW()),
    (10025, 'Wuxia', '武侠', 'both', 'Chinese martial arts fantasy', '中国武術ファンタジー', NOW()),
    (10026, 'Xianxia', '仙侠', 'both', 'Chinese immortal cultivation fantasy', '中国の仙人修行ファンタジー', NOW()),
    (10027, 'Magic Academy', '魔法学園', 'both', 'Schools teaching magic arts', '魔法を教える学校', NOW()),
    (10028, 'Alchemy', '錬金術', 'both', 'Transforming substances through mystical means', '神秘的な手段による物質変換', NOW()),
    (10029, 'Necromancy', '死霊術', 'both', 'Raising and controlling the dead', '死者を蘇らせ操る', NOW()),
    (10030, 'Summoning', '召喚術', 'both', 'Calling forth creatures to fight', '戦わせるために生物を呼び出す', NOW()),
    (10031, 'Elemental Magic', '属性魔法', 'both', 'Magic based on elements (fire, water, etc.)', '属性に基づく魔法（火、水など）', NOW()),
    (10032, 'Spirit World', '霊界', 'both', 'Interaction with spirits and afterlife', '霊や死後の世界との交流', NOW()),
    (10033, 'Familiar', '使い魔', 'both', 'Magical animal or spirit companions', '魔法の動物や精霊の相棒', NOW()),
    (10034, 'Prophecy', '予言', 'both', 'Story driven by foretold destiny', '予言された運命によって導かれる物語', NOW()),
    (10035, 'Mythical Creatures', '幻獣', 'both', 'Dragons, phoenixes, and legendary beasts', '龍、鳳凰、伝説の獣', NOW())
    """

    # ============================================================================
    # THEMES - Part 4: Custom Sci-Fi & Technology (10036-10047)
    # ============================================================================
    execute """
    INSERT INTO themes (mal_id, name, name_ja, type, description, description_ja, inserted_at) VALUES
    (10036, 'Cyberpunk', 'サイバーパンク', 'both', 'High tech, low life dystopian future', 'ハイテク・ローライフのディストピア未来', NOW()),
    (10037, 'Steampunk', 'スチームパンク', 'both', 'Victorian-era steam-powered technology', 'ヴィクトリア朝の蒸気機械技術', NOW()),
    (10038, 'Post-Apocalyptic', '終末後', 'both', 'Life after civilization collapse', '文明崩壊後の生活', NOW()),
    (10039, 'Dystopia', 'ディストピア', 'both', 'Oppressive totalitarian future societies', '抑圧的な全体主義の未来社会', NOW()),
    (10040, 'Virtual Reality', '仮想現実', 'both', 'VR worlds and digital consciousness', 'VR世界とデジタル意識', NOW()),
    (10041, 'Artificial Intelligence', '人工知能', 'both', 'AI consciousness and machine ethics', 'AI意識と機械倫理', NOW()),
    (10042, 'Space Opera', 'スペースオペラ', 'both', 'Epic adventures across galaxies', '銀河を舞台にした壮大な冒険', NOW()),
    (10043, 'Alien', 'エイリアン', 'both', 'Extraterrestrial life forms', '地球外生命体', NOW()),
    (10044, 'Android', 'アンドロイド', 'both', 'Human-like robots and cyborgs', '人間に似たロボットとサイボーグ', NOW()),
    (10045, 'Time Loop', 'タイムループ', 'both', 'Trapped repeating the same time period', '同じ時間を繰り返すことに囚われる', NOW()),
    (10046, 'Parallel World', '平行世界', 'both', 'Multiple coexisting realities', '複数の共存する現実', NOW()),
    (10047, 'Clone', 'クローン', 'both', 'Human cloning and genetic engineering', '人間のクローンと遺伝子工学', NOW())
    """

    # ============================================================================
    # THEMES - Part 5: Custom Romance Tropes (10048-10062)
    # ============================================================================
    execute """
    INSERT INTO themes (mal_id, name, name_ja, type, description, description_ja, inserted_at) VALUES
    (10048, 'Childhood Friends', '幼なじみ', 'both', 'Romance between people who grew up together', '一緒に育った人同士の恋愛', NOW()),
    (10049, 'Enemies to Lovers', '敵から恋人へ', 'both', 'Antagonists who fall in love', '敵対関係から恋に落ちる', NOW()),
    (10050, 'Fake Relationship', '偽装恋愛', 'both', 'Pretend dating that becomes real', '偽りの交際が本物になる', NOW()),
    (10051, 'Contract Marriage', '契約結婚', 'both', 'Marriage of convenience becoming love', '便宜上の結婚が愛に発展', NOW()),
    (10052, 'Age Gap', '年の差', 'both', 'Significant age difference between partners', 'パートナー間の大きな年齢差', NOW()),
    (10053, 'Office Romance', 'オフィスラブ', 'both', 'Romance in the workplace', '職場での恋愛', NOW()),
    (10054, 'Forbidden Romance', '禁断の恋', 'both', 'Love that breaks societal rules', '社会的ルールを破る恋', NOW()),
    (10055, 'Slow Burn', 'スローバーン', 'both', 'Romance developing very gradually', 'ゆっくり発展する恋愛', NOW()),
    (10056, 'First Love', '初恋', 'both', 'Pure, innocent first romantic experience', '純粋で無垢な初めての恋愛', NOW()),
    (10057, 'Unrequited Love', '片思い', 'both', 'One-sided romantic feelings', '一方的な恋愛感情', NOW()),
    (10058, 'Second Chance Romance', '再会の恋', 'both', 'Former lovers reuniting', 'かつての恋人が再会する', NOW()),
    (10059, 'Marriage Life', '結婚生活', 'both', 'Stories about married couples', '夫婦に関する物語', NOW()),
    (10060, 'Cohabitation', '同棲', 'both', 'Unmarried couples living together', '未婚のカップルが一緒に暮らす', NOW()),
    (10061, 'Master-Servant', '主従', 'both', 'Romance in power-imbalanced relationships', '力の不均衡な関係での恋愛', NOW()),
    (10062, 'Teacher-Student', '師弟恋愛', 'both', 'Romance between mentor and pupil', '師匠と弟子の恋愛', NOW())
    """

    # ============================================================================
    # THEMES - Part 6: Custom Character Archetypes (10063-10077)
    # ============================================================================
    execute """
    INSERT INTO themes (mal_id, name, name_ja, type, description, description_ja, inserted_at) VALUES
    (10063, 'Tsundere', 'ツンデレ', 'both', 'Cold exterior hiding warm feelings', '冷たい外見の裏に温かい感情', NOW()),
    (10064, 'Yandere', 'ヤンデレ', 'both', 'Obsessive, dangerous love interest', '執着的で危険な恋愛対象', NOW()),
    (10065, 'Kuudere', 'クーデレ', 'both', 'Emotionally cold character who warms up', '感情的に冷たいが温まるキャラクター', NOW()),
    (10066, 'Dandere', 'ダンデレ', 'both', 'Quiet, shy character who opens up', '静かで内気だが心を開くキャラクター', NOW()),
    (10067, 'Ojou-sama', 'お嬢様', 'both', 'Wealthy noble lady character', '裕福な貴族令嬢キャラクター', NOW()),
    (10068, 'Tomboy', 'ボーイッシュ', 'both', 'Masculine-presenting female character', '男性的な女性キャラクター', NOW()),
    (10069, 'Trap', '男の娘', 'both', 'Male characters appearing feminine', '女性的に見える男性キャラクター', NOW()),
    (10070, 'Gyaru', 'ギャル', 'both', 'Flashy fashion-conscious girls', '派手でファッション意識の高い女の子', NOW()),
    (10071, 'Maid', 'メイド', 'both', 'Maid characters and settings', 'メイドキャラクターと設定', NOW()),
    (10072, 'Butler', '執事', 'both', 'Butler characters and settings', '執事キャラクターと設定', NOW()),
    (10073, 'Ninja', '忍者', 'both', 'Ninja characters and stories', '忍者キャラクターと物語', NOW()),
    (10074, 'Royalty', '王族', 'both', 'Kings, queens, princes, princesses', '王、女王、王子、王女', NOW()),
    (10075, 'Nobility', '貴族', 'both', 'Aristocratic characters and settings', '貴族キャラクターと設定', NOW()),
    (10076, 'Anti-Hero', 'アンチヒーロー', 'both', 'Morally ambiguous protagonists', '道徳的に曖昧な主人公', NOW()),
    (10077, 'Villain Protagonist', '悪役主人公', 'both', 'Evil or morally corrupt main character', '悪または道徳的に腐敗した主人公', NOW())
    """

    # ============================================================================
    # THEMES - Part 7: Custom Yokai & Japanese Folklore (10078-10088)
    # ============================================================================
    execute """
    INSERT INTO themes (mal_id, name, name_ja, type, description, description_ja, inserted_at) VALUES
    (10078, 'Yokai', '妖怪', 'both', 'Japanese folklore creatures and spirits', '日本の民話の生き物と精霊', NOW()),
    (10079, 'Onmyouji', '陰陽師', 'both', 'Japanese yin-yang masters', '日本の陰陽道の達人', NOW()),
    (10080, 'Shinigami', '死神', 'both', 'Death gods and grim reapers', '死神', NOW()),
    (10081, 'Kitsune', '狐', 'both', 'Fox spirits', '狐の精霊', NOW()),
    (10082, 'Tengu', '天狗', 'both', 'Bird-like creatures from Japanese myth', '日本神話の鳥のような生き物', NOW()),
    (10083, 'Oni', '鬼', 'both', 'Japanese ogres and demons', '日本の鬼', NOW()),
    (10084, 'Shrine', '神社', 'both', 'Stories involving Shinto shrines', '神社に関わる物語', NOW()),
    (10085, 'Exorcism', '除霊', 'both', 'Banishing evil spirits', '悪霊の退治', NOW()),
    (10086, 'Curse', '呪い', 'both', 'Supernatural curses', '超自然的な呪い', NOW()),
    (10087, 'Ghost', '幽霊', 'both', 'Stories featuring ghosts', '幽霊を特徴とする物語', NOW()),
    (10088, 'Possession', '憑依', 'both', 'Spirits taking over bodies', '霊が体を乗っ取る', NOW())
    """

    # ============================================================================
    # THEMES - Part 8: Custom Action & Combat (10089-10100)
    # ============================================================================
    execute """
    INSERT INTO themes (mal_id, name, name_ja, type, description, description_ja, inserted_at) VALUES
    (10089, 'Battle Royale', 'バトルロイヤル', 'both', 'Free-for-all elimination contests', '自由参加の殲滅戦', NOW()),
    (10090, 'Tournament', 'トーナメント', 'both', 'Competitive fighting brackets', '対戦トーナメント', NOW()),
    (10091, 'Revenge', '復讐', 'both', 'Protagonist driven by vengeance', '復讐心に駆られた主人公', NOW()),
    (10092, 'Assassin', '暗殺者', 'both', 'Professional killers and hitmen', 'プロの殺し屋', NOW()),
    (10093, 'Bounty Hunter', '賞金稼ぎ', 'both', 'Hunting targets for rewards', '報酬のために標的を狩る', NOW()),
    (10094, 'Mercenary', '傭兵', 'both', 'Soldiers for hire', '雇われ兵士', NOW()),
    (10095, 'Pirate', '海賊', 'both', 'Seafaring outlaws and adventure', '海の無法者と冒険', NOW()),
    (10096, 'War', '戦争', 'both', 'Large-scale military conflict', '大規模な軍事紛争', NOW()),
    (10097, 'Yakuza', 'ヤクザ', 'both', 'Japanese organized crime', '日本の組織犯罪', NOW()),
    (10098, 'Gangs', 'ギャング', 'both', 'Street gangs and turf wars', 'ストリートギャングと縄張り争い', NOW()),
    (10099, 'Underground Fighting', '地下格闘', 'both', 'Illegal fighting rings', '違法な格闘リング', NOW()),
    (10100, 'Post-War', '戦後', 'both', 'Stories set after major wars', '大きな戦争後を舞台にした物語', NOW())
    """

    # ============================================================================
    # THEMES - Part 9: Custom Drama & Life (10101-10113)
    # ============================================================================
    execute """
    INSERT INTO themes (mal_id, name, name_ja, type, description, description_ja, inserted_at) VALUES
    (10101, 'Coming of Age', '成長物語', 'both', 'Growing up and self-discovery', '成長と自己発見', NOW()),
    (10102, 'Tragedy', '悲劇', 'both', 'Stories ending in loss or death', '喪失や死で終わる物語', NOW()),
    (10103, 'Family', '家族', 'both', 'Family bonds and conflicts', '家族の絆と葛藤', NOW()),
    (10104, 'Orphan', '孤児', 'both', 'Characters without parents', '親のいないキャラクター', NOW()),
    (10105, 'Disability', '障害', 'both', 'Characters with disabilities', '障害を持つキャラクター', NOW()),
    (10106, 'Terminal Illness', '不治の病', 'both', 'Characters facing fatal disease', '致命的な病気に直面するキャラクター', NOW()),
    (10107, 'Grief', '悲嘆', 'both', 'Processing loss and death', '喪失と死の受容', NOW()),
    (10108, 'Bullying', 'いじめ', 'both', 'Harassment and its effects', 'ハラスメントとその影響', NOW()),
    (10109, 'NEET', 'ニート', 'both', 'Characters not in education, employment, or training', '教育、雇用、訓練を受けていないキャラクター', NOW()),
    (10110, 'Hikikomori', 'ひきこもり', 'both', 'Social withdrawal and isolation', '社会的引きこもりと孤立', NOW()),
    (10111, 'Depression', 'うつ', 'both', 'Mental health struggles', 'メンタルヘルスの苦闘', NOW()),
    (10112, 'Redemption', '贖罪', 'both', 'Characters seeking forgiveness', '許しを求めるキャラクター', NOW()),
    (10113, 'Betrayal', '裏切り', 'both', 'Trust broken by allies', '味方による信頼の崩壊', NOW())
    """

    # ============================================================================
    # THEMES - Part 10: Custom Horror & Dark (10114-10124)
    # ============================================================================
    execute """
    INSERT INTO themes (mal_id, name, name_ja, type, description, description_ja, inserted_at) VALUES
    (10114, 'Body Horror', 'ボディホラー', 'both', 'Grotesque physical transformations', 'グロテスクな身体変異', NOW()),
    (10115, 'Cosmic Horror', '宇宙的恐怖', 'both', 'Lovecraftian existential dread', 'ラヴクラフト的な存在への恐怖', NOW()),
    (10116, 'Psychological Horror', '心理的恐怖', 'both', 'Terror from the mind', '精神からの恐怖', NOW()),
    (10117, 'Zombie', 'ゾンビ', 'both', 'Undead and zombie apocalypse', 'アンデッドとゾンビ黙示録', NOW()),
    (10118, 'Demon', '悪魔', 'both', 'Demonic beings and possession', '悪魔の存在と憑依', NOW()),
    (10119, 'Werewolf', '人狼', 'both', 'Lycanthropy and werewolves', '人狼と狼男', NOW()),
    (10120, 'Cult', 'カルト', 'both', 'Sinister religious groups', '邪悪な宗教団体', NOW()),
    (10121, 'Torture', '拷問', 'both', 'Extreme physical suffering', '極端な肉体的苦痛', NOW()),
    (10122, 'Cannibal', '人喰い', 'both', 'Human consumption as horror', '食人をホラーとして', NOW()),
    (10123, 'Urban Legend', '都市伝説', 'both', 'Modern myths and legends', '現代の神話と伝説', NOW()),
    (10124, 'Haunted', '心霊', 'both', 'Haunted locations and objects', '心霊スポットと呪物', NOW())
    """

    # ============================================================================
    # THEMES - Part 11: Custom Sports Specific (10125-10141)
    # ============================================================================
    execute """
    INSERT INTO themes (mal_id, name, name_ja, type, description, description_ja, inserted_at) VALUES
    (10125, 'Baseball', '野球', 'both', 'Baseball stories', '野球の物語', NOW()),
    (10126, 'Soccer', 'サッカー', 'both', 'Football/soccer stories', 'サッカーの物語', NOW()),
    (10127, 'Basketball', 'バスケットボール', 'both', 'Basketball stories', 'バスケットボールの物語', NOW()),
    (10128, 'Volleyball', 'バレーボール', 'both', 'Volleyball stories', 'バレーボールの物語', NOW()),
    (10129, 'Tennis', 'テニス', 'both', 'Tennis stories', 'テニスの物語', NOW()),
    (10130, 'Swimming', '水泳', 'both', 'Swimming stories', '水泳の物語', NOW()),
    (10131, 'Boxing', 'ボクシング', 'both', 'Boxing stories', 'ボクシングの物語', NOW()),
    (10132, 'Cycling', '自転車', 'both', 'Cycling and bicycle racing', '自転車競技', NOW()),
    (10133, 'Figure Skating', 'フィギュアスケート', 'both', 'Ice skating stories', 'フィギュアスケートの物語', NOW()),
    (10134, 'Motorsport', 'モータースポーツ', 'both', 'Car and motorcycle racing', '車とバイクのレース', NOW()),
    (10135, 'Esports', 'eスポーツ', 'both', 'Competitive video gaming', '競技的なビデオゲーム', NOW()),
    (10136, 'Shogi', '将棋', 'both', 'Japanese chess stories', '将棋の物語', NOW()),
    (10137, 'Go', '囲碁', 'both', 'Go board game stories', '囲碁の物語', NOW()),
    (10138, 'Mahjong', '麻雀', 'both', 'Mahjong game stories', '麻雀の物語', NOW()),
    (10139, 'Karuta', 'かるた', 'both', 'Japanese card game', '日本のカードゲーム', NOW()),
    (10140, 'Dance', 'ダンス', 'both', 'Dance performance and competition', 'ダンスパフォーマンスと競技', NOW()),
    (10141, 'Cheerleading', 'チアリーディング', 'both', 'Cheerleading teams', 'チアリーディングチーム', NOW())
    """

    # ============================================================================
    # THEMES - Part 12: Custom Historical Periods (10142-10151)
    # ============================================================================
    execute """
    INSERT INTO themes (mal_id, name, name_ja, type, description, description_ja, inserted_at) VALUES
    (10142, 'Sengoku Period', '戦国時代', 'both', 'Japan Warring States era (1467-1615)', '日本の戦国時代', NOW()),
    (10143, 'Edo Period', '江戸時代', 'both', 'Tokugawa shogunate era (1603-1868)', '徳川幕府の時代', NOW()),
    (10144, 'Meiji Era', '明治時代', 'both', 'Japan modernization period (1868-1912)', '日本の近代化期', NOW()),
    (10145, 'Taisho Era', '大正時代', 'both', 'Brief democratic period (1912-1926)', '短い民主主義の時代', NOW()),
    (10146, 'Showa Era', '昭和時代', 'both', 'Japan 1926-1989 including WWII', '昭和時代（戦争と戦後）', NOW()),
    (10147, 'World War II', '第二次世界大戦', 'both', 'Stories set during WWII', '第二次世界大戦中の物語', NOW()),
    (10148, 'Medieval', '中世', 'both', 'Medieval European settings', '中世ヨーロッパの設定', NOW()),
    (10149, 'Victorian', 'ヴィクトリア朝', 'both', 'Victorian era settings', 'ヴィクトリア朝の設定', NOW()),
    (10150, 'Ancient', '古代', 'both', 'Ancient civilizations', '古代文明', NOW()),
    (10151, 'Three Kingdoms', '三国志', 'both', 'Chinese Three Kingdoms period', '中国の三国時代', NOW())
    """

    # ============================================================================
    # THEMES - Part 13: Custom Miscellaneous Popular Tags (10152-10171)
    # ============================================================================
    execute """
    INSERT INTO themes (mal_id, name, name_ja, type, description, description_ja, inserted_at) VALUES
    (10152, 'Cooking', '料理', 'both', 'Cooking and culinary arts', '料理と調理芸術', NOW()),
    (10153, 'Farming', '農業', 'both', 'Agriculture and farm life', '農業と農場生活', NOW()),
    (10154, 'Fishing', '釣り', 'both', 'Fishing activities', '釣り活動', NOW()),
    (10155, 'Camping', 'キャンプ', 'both', 'Outdoor camping', 'アウトドアキャンプ', NOW()),
    (10156, 'Cafe', 'カフェ', 'both', 'Coffee shops and cafes', 'コーヒーショップとカフェ', NOW()),
    (10157, 'Band', 'バンド', 'both', 'Music bands and performances', '音楽バンドと演奏', NOW()),
    (10158, 'Idol Training', 'アイドル育成', 'both', 'Training to become an idol', 'アイドルになるための訓練', NOW()),
    (10159, 'Voice Acting', '声優', 'both', 'Voice acting industry', '声優業界', NOW()),
    (10160, 'Manga Artist', '漫画家', 'both', 'Creating manga professionally', 'プロとして漫画を作る', NOW()),
    (10161, 'Anime Industry', 'アニメ業界', 'both', 'Behind the scenes of anime', 'アニメ制作の舞台裏', NOW()),
    (10162, 'Game Development', 'ゲーム開発', 'both', 'Making video games', 'ビデオゲーム開発', NOW()),
    (10163, 'Photography', '写真', 'both', 'Photography as hobby or profession', '趣味や職業としての写真', NOW()),
    (10164, 'Calligraphy', '書道', 'both', 'Japanese calligraphy', '日本の書道', NOW()),
    (10165, 'Tea Ceremony', '茶道', 'both', 'Japanese tea ceremony', '日本の茶道', NOW()),
    (10166, 'Flower Arrangement', '華道', 'both', 'Japanese flower arrangement', '日本の華道', NOW()),
    (10167, 'Hot Springs', '温泉', 'both', 'Onsen and hot spring stories', '温泉の物語', NOW()),
    (10168, 'Beach', 'ビーチ', 'both', 'Beach episodes and settings', 'ビーチのエピソードと設定', NOW()),
    (10169, 'Festival', '祭り', 'both', 'Japanese festivals', '日本の祭り', NOW()),
    (10170, 'Christmas', 'クリスマス', 'both', 'Christmas themed stories', 'クリスマステーマの物語', NOW()),
    (10171, 'Valentine', 'バレンタイン', 'both', 'Valentine Day themed', 'バレンタインデーテーマ', NOW())
    """

    # ============================================================================
    # THEMES - Part 14: Custom Monster & Creature Types (10172-10183)
    # ============================================================================
    execute """
    INSERT INTO themes (mal_id, name, name_ja, type, description, description_ja, inserted_at) VALUES
    (10172, 'Dragon', 'ドラゴン', 'both', 'Dragon-focused stories', 'ドラゴンを中心とした物語', NOW()),
    (10173, 'Monster Girl', 'モンスター娘', 'both', 'Female monster characters', '女性モンスターキャラクター', NOW()),
    (10174, 'Elf', 'エルフ', 'both', 'Elf characters and settings', 'エルフキャラクターと設定', NOW()),
    (10175, 'Dwarf', 'ドワーフ', 'both', 'Dwarf characters and settings', 'ドワーフキャラクターと設定', NOW()),
    (10176, 'Beastman', '獣人', 'both', 'Animal-human hybrid characters', '動物と人間のハイブリッド', NOW()),
    (10177, 'Angel', '天使', 'both', 'Angelic beings', '天使の存在', NOW()),
    (10178, 'Slime', 'スライム', 'both', 'Slime creatures', 'スライム生物', NOW()),
    (10179, 'Goblin', 'ゴブリン', 'both', 'Goblin creatures', 'ゴブリン', NOW()),
    (10180, 'Orc', 'オーク', 'both', 'Orc creatures', 'オーク', NOW()),
    (10181, 'Undead', 'アンデッド', 'both', 'Undead creatures (not zombies)', 'アンデッド生物', NOW()),
    (10182, 'Skeleton', 'スケルトン', 'both', 'Skeleton characters', 'スケルトンキャラクター', NOW()),
    (10183, 'Golem', 'ゴーレム', 'both', 'Golem creatures', 'ゴーレム', NOW())
    """

    # ============================================================================
    # THEMES - Part 15: Custom Final Batch (10184-10203)
    # ============================================================================
    execute """
    INSERT INTO themes (mal_id, name, name_ja, type, description, description_ja, inserted_at) VALUES
    (10184, 'Amnesia', '記憶喪失', 'both', 'Memory loss as plot device', '記憶喪失をプロットの仕掛けとして', NOW()),
    (10185, 'Body Swap', '入れ替わり', 'both', 'Characters switching bodies', 'キャラクターの体の入れ替わり', NOW()),
    (10186, 'Mind Control', '洗脳', 'both', 'Mental manipulation and control', '精神的操作と支配', NOW()),
    (10187, 'Immortal', '不死', 'both', 'Characters who cannot die', '死ぬことができないキャラクター', NOW()),
    (10188, 'Heterochromia', 'オッドアイ', 'both', 'Characters with different colored eyes', '異なる色の目を持つキャラクター', NOW()),
    (10189, 'Glasses', 'メガネ', 'both', 'Glasses-wearing characters focus', 'メガネをかけたキャラクターの焦点', NOW()),
    (10190, 'Twins', '双子', 'both', 'Twin characters', '双子のキャラクター', NOW()),
    (10191, 'Siblings', '兄弟姉妹', 'both', 'Brother-sister relationships', '兄弟姉妹の関係', NOW()),
    (10192, 'Student Council', '生徒会', 'both', 'School student government', '学校の生徒会', NOW()),
    (10193, 'Transfer Student', '転校生', 'both', 'New student arriving at school', '学校にやってくる新しい生徒', NOW()),
    (10194, 'Delinquent Reform', '不良更生', 'both', 'Reformed delinquent characters', '更生した不良キャラクター', NOW()),
    (10195, 'Revenge Plot', '復讐劇', 'both', 'Elaborate revenge schemes', '入念な復讐計画', NOW()),
    (10196, 'Power of Friendship', '友情パワー', 'both', 'Friendship overcomes obstacles', '友情が障害を乗り越える', NOW()),
    (10197, 'Found Family', '疑似家族', 'both', 'Non-blood related family bonds', '血縁でない家族の絆', NOW()),
    (10198, 'Solo Adventurer', 'ソロ冒険者', 'both', 'Protagonist adventuring alone', '一人で冒険する主人公', NOW()),
    (10199, 'Hidden Identity', '正体隠し', 'both', 'Characters hiding their true identity', '本当の正体を隠すキャラクター', NOW()),
    (10200, 'Secret Organization', '秘密結社', 'both', 'Covert groups and societies', '秘密のグループと組織', NOW()),
    (10201, 'Conspiracy', '陰謀', 'both', 'Hidden plots and schemes', '隠された陰謀と策略', NOW()),
    (10202, 'Politics', '政治', 'both', 'Political intrigue and governance', '政治的陰謀と統治', NOW()),
    (10203, 'Economics', '経済', 'both', 'Trade, commerce, and economics', '貿易、商業、経済', NOW())
    """
  end

  def down do
    execute "TRUNCATE TABLE genres RESTART IDENTITY CASCADE"
    execute "TRUNCATE TABLE demographics RESTART IDENTITY CASCADE"
    execute "TRUNCATE TABLE themes RESTART IDENTITY CASCADE"
  end
end