# 📋 TODO — Azeroth: Эхо Пустоты

> Живой файл задач реалма. **Правило ведения:** обновляется после каждого
> нового коммита — выполненное переносится в «Готово» с хешем коммита,
> новые задачи добавляются в актуальный бэклог.
> Дата последнего обновления: после коммита `77b97df`.

---

## ✅ Готово

| Коммит | Что сделано |
|--------|-------------|
| (ранние) | Инфраструктура, кампании 1–4, аддон AzerothEcho, C++-модули echo-*, миграции 0001–0017, миграция на ALE (`00_CampaignRegistry.ext`) |
| `8ac9584` | **Tier A из eluna-scripts** (референс Cloticc): миграция `0018_eluna_scripts_tier_a.sql` (НПС 70172/70173, шаблоны 70190/70191, item 70008, спелл 70050, `realm_gold_storage`); секции реестра (`services.enchanter`, `gold_storage`, `account_mounts`, `auto_skills`, `time_rift`, `corruption`); скрипты 13–18 с исправленными багами оригиналов (см. шапки скриптов) |
| `0220ff3` | **Интеграция кастомных карт** (референс RStijn/custom-maps): телепорты Портального Стража на карту 5000 (Морза, Долина Предательства) + лор «опасных мест»; `patch-Z.mpq` в клиентском манифесте; docs — `client-patch.md` ч. 6 (правило Map.dbc только в patch-Z), `deployment.md` шаг 4 (экстракция с патчем), `testing-plan.md` раздел 11, `roadmap.md` |
| `6357815` | `TODO.md` — живой трекер задач (обновляется после каждого коммита) |
| `db92ea0` | **Режимы испытаний** (референс mod-challenge-modes, локализованный форк ru/en — `modules/echo-challenge-modes`): 8 режимов (Hardcore, SemiHardcore, SelfCrafted, ItemQualityLevel, Slow/VerySlow XP, QuestXpOnly, IronMan); Алтарь Испытаний GO 705605 (`0019_challenge_modes.sql`, 9 спавнов у кладбищ стартовых зон); конфиг с наградами за уровни; `setup-build.sh`, `modules/README.md`; docs — `deployment.md` (EnablePlayerSettings=1), `testing-plan.md` раздел 12, `roadmap.md` |
| `25dcf23` | GPT-НПС (elunamod-gpt-npcs) — в бэклог (нужны OpenAI-ключ и решения по entry/модели/каналу) |
| `6930313` | **AIO-магазин** (референс eluna-aio-storesystem): `Store_DataStruct/Server/Client.lua` (ru/en, guard без AIO, фикс `self.Flags` превью); миграция `0020_store_system.sql` — таблицы `realm_store_*`, валюты золото + Жетон Эха (70005), демо-услуги (Пегас, титул 48, баффы, смена имени); `client/store-ui/README.md`; docs — `client-patch.md` ч. 7, `deployment.md`, `testing-plan.md` раздел 13, `roadmap.md`, `lua_scripts/README.md` |
| `d9cc318` | TODO — AIO-магазин |
| `287b508` | **Системы public-scripts** (референс JadaDev, портировано на ALE): награды за наигранное время (`19_PlayedTimeRewards.lua`, `realm_played_time_rewards{,_claimed}` — 0021), смена фракции за 25 Жетонов Эха (НПС 70174 «Страж Перемен», `21_FactionChanger.lua`), убежища/FFA с фиксами оригинала (слит 4-кратный хендлер, сброс FFA при выходе — `22_SanctuaryPvP.lua`); миграция `0021_public_scripts.sql` (двойное применение); **не взято**: Reviving (конфликт с Hardcore), AllTalents/Level80-255 (против концепции 80 и стоковых классов); чек-лист — `testing-plan.md` раздел 14 |
| `77b97df` | **AIO-фреймворк** (референс dwrath-eluna-3-3-5a, оригинал Rochet2/AIO v1.74 GPLv2): серверный стек в `lua_scripts/` — `AIO.lua` + deps (queue, smallfolk, crc32lua, lualzw, LuaSrcDiet → модуль `process_code`), `extensions/` (StackTracePlus — traceback всех Lua-ошибок, `_Misc.ext`); магазин `Store_*.lua` ожил (guard снят). Клиентский аддон AIO_Client — из оригинального Rochet2/AIO (в референсе отсутствует), patch-x — `client-patch.md` ч. 8. Docs sync: `deployment.md` шаг 7 (`cp -r`, `AIO_CODE_OBFUSCATE` при отладке), `testing-plan.md` раздел 15 + 13.0.1, `roadmap.md`, `modules/README.md`, `lua_scripts/README.md`. **Не взято из dWrath**: ClassLess, RandomSpell/rollstable, StatAllo, rage_gen, nakedbugfix, learnkrabe, helloworld, sql/custom (classless / зависимость от C++ ядра dWrath) |

## 🔥 Актуально (следующий шаг)

- [ ] **Клиентский аддон AIO_Client**: взять из оригинального репозитория
      Rochet2/AIO (github) и вшить в patch-x как `Interface/AddOns/AIO/`
      (`client-patch.md` ч. 8) — без него AIO-клиентская часть не работает
- [ ] **Тестовый прогон Tier A** на тестовом реалме: логи загрузки
      `[EchoOfTheVoid] 13_AccountMounts … 18_VoidCorruption`, чек-листы
      зачарователя/казны/маунтов/авто-навыков/разломов/порчи
- [ ] **Пересборка ядра** с `echo-challenge-modes` + миграции 0019–0021 +
      `EnablePlayerSettings = 1` → чек-листы разделов 12, 13, 14, 15
      (раздел 15 — AIO: рукопожатие, доставка кода, кэш, `/aio`-команды)
- [ ] **Выверка Corruption-дебаффов**: в реестре (`corruption`) стоят
      ID-заглушки порогов 20/40/60/80/100 — подобрать/создать реальные
      спеллы (миграция `0021+`)
- [ ] **Сборка `patch-x.mpq`** по `client-patch.md` ч. 1–4 + ч. 7–8
      (база `Patch-T.MPQ.rar`; Map.dbc НЕ включать; + Store_UI BLP
      из eluna-aio-storesystem + аддон AIO_Client)

## 📦 Бэклог (по приоритету)

- [ ] **Tier B из eluna-scripts**: Weapon Master, Lottery, Skip DK Starter,
      Алтари молитвы — инспекция и адаптация с фиксами
- [ ] **GPT-НПС** (референс `elunamod-gpt-npcs`, Ember-RP, MIT — Lua+Python+
      OpenAI): разговоры с НПС через чат. Открытые вопросы перед реализацией:
      ограничение entry-листом кастомных НПС, модель (рекомендуется
      `gpt-4o-mini` вместо устаревшего gpt-3.5-turbo), канал ответа
      (рекомендуется шёпот вместо SendUnitSay), экранирование argv в
      os.execute (инъекция в оригинале), rate-limit, локализация ru/en промпта.
      Зависимость: Python3 + pip openai + OPENAI_API_KEY на хосте сервера
- [ ] Заполнить SHA256/size в `client/manifest.json` после выкладки
      `patch-Z.mpq` и сборки `patch-x.mpq` на хостинг
- [ ] Тестовый прогон кастомных карт — `testing-plan.md` раздел 11
      (нужен клиент с patch-Z + извлечённые серверные данные)
- [ ] Настройка наград режимов испытаний в `echo-challenge-modes.conf`
      (титул 48 / item 70001 — значения-примеры в `.conf.dist`)
- [ ] Наполнение магазина: расширение ассортимента `realm_store_services`
      (маунты за жетоны, VIP-категория requiredRank, SERVER_HANDLED-валюта)
- [ ] Миграция PvP-шопа (`30_PvpShop.lua`, НПС 70170) в AIO-магазин
      (по мере готовности UI)
- [ ] **Parangon** (референс `lua-parangon`, Open-Wow/Khalar, AGPL —
      Diablo 3 Paragon без UI): уровень Paragon на аккаунт (exp за PvE/PvP
      киллы, анти-абюз ±10 lvl, опыт группе), 2 очка/уровень → 4 стата
      через стаки штатных аур 7464/7471/7477/7468 (`SetStackAmount`),
      gossip-меню `.parangon`, локализация уже с ru. **Зависимости**:
      ObjectVariables.ext (`SetData/GetData`, инспектирован в
      dwrath-eluna-3-3-5a) + `GossipSetText` (кастомный пакет SMSG 384).
      **Известные баги оригинала** (для фиксов при адаптации): nil `pAcc`
      при первом входе, `player` вместо `self` в SetParangonLevel,
      ru-PvE показывает pvpKill, gossip-хендлер перехватывает ВСЕХ НПС,
      отдельная БД `R1_Eluna` → наша конвенция — `0022_*` в
      acore_characters. **Отложено осознанно**: как и StatAllo (dWrath),
      распределение статов поверх стокового баланса — отдельное решение
      (пересечение с echo-balance, место в прогрессии 80+)
- [ ] **Classless-арка К5 «Пустота дробит классы»** — выбранная
      реализация: референс `azerothcore-classless-solo` (Shikifuyin):
      спеллы/таланты/глифы всех 10 классов через чистый Eluna + AIO-UI,
      сессионный токен против темперинга, полные таблицы ID 3.3.5a,
      платный сброс (прогрессирующие цены), авто-брони 10/20/40,
      таблица `character_classless` (guid + сериализованные массивы).
      **Лучше dWrath ClassLess** (не требует пересборки ядра). Запуск
      возможен сразу: AIO уже в репозитории (77b97df); понадобится
      OOP-зависимость `class.lua` (взять из репозитория Shikifuyin или
      заменить на нашу структуру). Привязка к опции —
      `docs/classless-option.md`. **Не запускаем**: противоречит текущей
      концепции «стоковые классы 1–80» — только в рамках арки К5
- [ ] RAI / SpellAIO из waloriaold (крупные, отдельные модули)
- [ ] mod-delves (wow-mod-delves) — после запуска тестового реалма
- [ ] Интеграция модулей AzerothCore: mod-ah-bot, mod-transmog, mod-cfbg,
      mod-duel-reset (`modules/README.md`)
- [ ] Полный тестовый прогон кампаний 1–4 по чек-листам
- [ ] **Random-энчанты предметов** — референс `azerothcore-content`
      (StygianTheBest, 2017, mod-randomenchants): таблица
      `item_enchantment_random_tiers` (~700 энчантов, тиры 1–5,
      классы WEAPON/ARMOR/ANY, exclusiveSubClass). **Требует C++-модуля-
      потребителя** (оригинальный mod-randomenchants устарел) — реализация
      будет своей (echo-модуль или Lua-хук на лут/крафт), таблица — база
      данных; пересечение с зачарователем (15_Enchanter) — проверить
- [ ] **Solo-friendly данжи** — идея из `azerothcore-content`
      (mod-solocraft / mod-vasautobalance): масштабирование статов/HP
      игрока или мобов от размера группы и типа инстанса. Кандидат на
      обсуждение после тестового прогона; реализация была бы своей
      (echo-модуль по паттерну echo-balance), оригиналы — C++ и
      конфликтуют с echo-balance/челлендж-режимами при прямом переносе
- [ ] Вариант B PermaDeath (Hardcore) — рассмотрен, отложен

## ⚠️ Техдолг / известные проблемы

- [ ] `deployment.md` шаг 8: расхождение CharDB/WorldDB в `0002` —
      применять миграцию в `acore_characters` (вариант A) до запуска кампаний
- [ ] Координаты спавнов Драконьего Погоста/Зул'Драка приблизительные —
      выверка на тестовом реалме (testing-plan р. 1)
- [ ] Титул ID 48 (TitleMask) — эмпирика, обязательная проверка на клиенте
- [ ] Entry-занятость при новых миграциях: НПС 70170/70172/70173/70174/70180,
      items 70001–70008, 70100/70101, guid 7000170–7000174,
      GO 705605 + guid 7005601–7005609 — см. `sql/README.md`

---

## Конвенции (кратко)

- Entry НПС/предметы: 70001–79999; SQL-миграции `NNNN_*.sql` строго вперёд
- Порядок загрузки ALE: `*.ext` до всех `*.lua`; реестр — `00_CampaignRegistry.ext`
- Локализация скриптов — полная ru/en
- Референсы: `maxteam/azerothcore-wotlk`, `waloria`, `waloriaold`,
  `wow-mod-delves`, `azerothcore-wotlk-classless`, `mod-ale`,
  `skywall-hardcore-mode-3-3-5-wow`, `eluna-scripts`, `custom-maps`,
  `mod-challenge-modes`, `elunamod-gpt-npcs`, `eluna-aio-storesystem`,
  `public-scripts`, `dwrath-eluna-3-3-5a`, `lua-parangon`,
  `counterscripts` (инспектирован, не применим — MVC-шаблон без контента),
  `azerothcore-classless-solo` (кандидат на реализацию classless-арки К5),
  `azerothcore-content` (архив StygianTheBest 2017; взяты идеи:
  random-enchants, solo-данжи — см. бэклог; остальное дублирует
  имеющиеся системы)
