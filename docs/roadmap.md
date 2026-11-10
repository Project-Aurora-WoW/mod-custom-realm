# 🗺️ Roadmap — Azeroth: Эхо Пустоты

> План развития кастомного реалма на базе **AzerothCore (azerothcore-wotlk)**,
> клиент **WoW 3.3.5a**.
> Базовый репозиторий ядра: https://github.com/azerothcore/azerothcore-wotlk.git

---

## Фаза 0 — Инфраструктура (базис) ✅ завершена

- [x] Структура репозитория (`docs/`, `lua_scripts/`, `modules/`, `sql/`)
- [x] Лор вселенной — `docs/lore/universe.md`
- [x] SQL-миграции: НПС «Портальный Страж» (70001) — `sql/world/0001_world_baseline.sql`
- [x] SQL-миграции: таблица прогресса кампаний — `sql/world/0002_campaign_progress.sql`
- [x] Eluna-скрипты: приветствие и портальный телепортер — `lua_scripts/`
- [x] Инструкция по модулям AzerothCore (`modules/README.md`)
- [ ] Развёртывание ядра AzerothCore + применение миграций (вне репозитория)

## Фаза 1 — Кампании (серверный контент) ✅ завершена

- [x] **Кампания 1 «Эхо Шёпота»** — вводная, 3 главы (`lua_scripts/Campaign1.lua`,
      НПС 70100/70110/70120, item 70001 «Слеза Рассвета»)
- [x] **Кампания 2 «Пепел Зул'Драка»** — 5 глав (`lua_scripts/Campaign2.lua`,
      босс 70500 Хора Шёпота, Пророк Нал'кур 70130, Сквернозор 70140,
      item 70004 «Клеймо Стражей Пустоты»)
- [x] **Кампания 3 «Пробуждение»** — 4 главы, рейд-босс Усмешка Бездны 70510
      с 3 фазами по HP (`lua_scripts/Campaign3.lua`,
      item 70002 «Печать Хранителя Эха», item 70003 «Бездна-Пегас»)
- [x] Реализация кампаний через Eluna: скрипты глав, награды, запись прогресса
      в `realm_campaign_progress`
- [x] Кастомные НПС/объекты Культа Усмешки Бездны (entry 70100–70199, 70500–70510)

## Фаза 2 — Клиентский аддон (UI) ✅ базовая версия готова

- [x] Каркас аддона для клиента 3.3.5a (`addons/AzerothEcho`)
- [x] Таблица функций (TOC), UI-панель прогресса кампаний (команда `/ae`)
- [x] Синхронизация прогресса с сервером (`AddonBridge.lua`,
      протокол `SendAddonMessage("AECHO", ...)`)
- [x] Кастомная карта разломов Пустоты (`/ae rifts` — пины на карте
      Northrend с тултипами и уровнями опасности)
- [x] Расширенный UI: трекер активной главы (прогресс-бары кампаний),
      вкладки Ивенты и PvP-статистика, справка по лору,
      всплывающие уведомления о прогрессе (v2.0.0)

## Фаза 3 — Баланс и кастомизация (в процессе)

- [x] Кастомные спеллы и ауры Пустоты: скриптовая система «Эхо Шёпота»
      (`lua_scripts/05_VoidAuras.lua`) — стаки у разлома, шёпот,
      «коллапс рассудка», баланс в реестре (`void_aura`), локализация ru/en.
      Стоковый дебафф 33757 — только визуальная основа (без правки DBC)
- [x] Кастомные предметы (награды кампаний: 70001–70004, К4: 70006/70007)
- [x] **Лор-архив в игре**: НПС «Хронист Ордена» (70180) — хроника, фигуры,
      бестиарий, артефакты, правила, словарь (`LoreArchive.lua`, 0011)
- [x] **Кампания 4 «Второе Эхо»**: новая арка 5 глав, босс Архонт Нехал'тхар
      (70520), НПС 70210/70201/70202/70204 (`Campaign4.lua`, 0012)
- [x] **C++-модуль баланса** `echo-balance`: глобальные мультипликаторы
      урона/лечения, отсечка ваншотов, босс-фактор
      (`modules/echo-balance/`, конфиг `echo-balance.conf.dist`)
- [x] **Lua-баланс** в реестре (`balance`): жетоны за кампании, бонусы
      ивентов/PvP-серий, скейлинг ивентовых элит
- [x] **Служебный модуль кампаний** (`CampaignManager.lua`): единый API
      (гейты/прогресс/награды/жетоны), игрок-команды `.ae *` — аналоги
      команд аддона, GM-команды `.aecampaign *`, журнал
      `realm_campaign_log` (0013)
- [x] **Фикс команд аддона**: `/ae pvp` и `/ae events` переключают вкладки,
      серверные команды `AECHOUI`/`AECHORIFTS` управляют UI из ядра
- [x] **Интеграция подхода Waloria** (референс: `m-orlovrus59/waloria`):
      дистрибуция патчей через веб-каталог + manifest.json
      (`docs/client-patch.md` ч. 4a), план AIO (`docs/aio-integration.md`),
      награды за уровни — welcome (lvl 2) + каждые 5 уровней
      (`06_WaloriaRewards.lua`, `0014_waloria_rewards.sql`)
- [x] **Адаптация waloriaold**: выбор стартовой зоны (`07_StartingZone.lua`),
      клиентские фиксы и лор-анонсы (`08_ClientFixes.lua`), база MPQ
      и тулзы для патча (`client-patch.md` ч. 4b)
- [x] **Паттерны wow-mod-delves** (референс: `m-orlovrus59/wow-mod-delves`):
      outbox-доставка наград с квитанциями (`echo-economy`,
      `0015_token_outbox.sql`), профильный ночной скейлинг (`echo-pve`),
      конвейер DBC-кандидатов (`client-patch.md` ч. 4c);
      сам модуль delves — под рассмотрение после запуска тестового реалма
- [x] **Настройка rates, кастомизация стартовых зон** — выбор стартовой
      зоны у Портального Стража (`07_StartingZone.lua`, адаптация
      waloriaold/startingzonepicker); rates — см. модуль echo-balance
      и план тестирования
- [x] **Интеграция classless-модулей** (референс:
      `m-orlovrus59/azerothcore-wotlk-classless`): mod-starter-guild,
      mod-dungeonmaster, mod-ah-bot-plus подключены в
      `setup-build.sh`; эталонная схема `*_dbc`-таблиц — основа
      миграции-образца `0016_dbc_reference_sample.sql`.
      **Classless-ядро и класс Hero не включены** — задокументированы
      как опция арки кампании 5 «Пустота дробит классы»
      (`docs/classless-option.md`)
- [x] **Миграция на ALE** (референс: `m-orlovrus59/mod-ale`, форк Eluna):
      движок реалма — mod-ale; реестр кампаний перенесён в
      `00_CampaignRegistry.ext` (ALE грузит `.ext` до всех `.lua`),
      исправлен баг события PvP-киллов (21→6), обновлены
      `setup-build.sh`, `modules/README.md`, `deployment.md`
- [x] **Кастомные зоны** (референс: `m-orlovrus59/custom-maps`, работа RStijn):
      карта 5000 — Остров Морза (флотский перевал Культа) и Долина
      Предательства (перевалочный пункт Культа); готовый патч
      `patch-Z.mpq` дистрибутируется через клиентский манифест, телепорты
      добавлены Портальному Стражу, серверное извлечение карт —
      `client-patch.md` ч. 6, `deployment.md` шаг 4, чек-лист —
      `testing-plan.md` раздел 11
- [x] **Режимы испытаний** (референс: `m-orlovrus59/mod-challenge-modes`,
      локализованный форк ru/en — `modules/echo-challenge-modes`):
      8 добровольных режимов у Алтаря Испытаний (GO 705605,
      `0019_challenge_modes.sql`, спавны у кладбищ стартовых зон) —
      Hardcore, SemiHardcore, SelfCrafted, ItemQualityLevel, Slow/VerySlow
      XP, QuestXpOnly, IronMan; награды за уровни из конфига;
      требования и чек-лист — `deployment.md` (EnablePlayerSettings),
      `testing-plan.md` раздел 12
- [x] **AIO-магазин** (референс: `m-orlovrus59/eluna-aio-storesystem`,
      AIO Store System): серверные скрипты `Store_*.lua` (ru/en, таблицы
      `realm_store_*` — `0020_store_system.sql`), валюты золото + Жетон
      Эха (70005), 9 типов услуг, скидки/новинки, журнал покупок;
      клиентская часть (BLP + AIO-аддон) — в patch-x, инструкции
      `client/store-ui/README.md`, `client-patch.md` ч. 7,
      чек-лист — `testing-plan.md` раздел 13
- [x] **AIO-фреймворк** (референс: `m-orlovrus59/dwrath-eluna-3-3-5a`,
      оригинал Rochet2/AIO v1.74, GPLv2): серверный стек в `lua_scripts/` —
      `AIO.lua` (сервер+клиент, LZW-сжатие, CRC-кэш аддонов, version-check,
      команды `.aio`/`/aio`) + зависимости (`queue`, smallfolk, crc32lua,
      LuaSrcDiet — адаптирован в модуль `process_code`, lualzw);
      расширения `.ext`: StackTracePlus (подробный traceback всех
      Lua-ошибок) + `_Misc.ext` (randomseed, включение traceback).
      Клиентский аддон AIO_Client — из оригинального репозитория
      Rochet2/AIO, размещение в patch-x — `client-patch.md` ч. 8;
      развёртывание и предупреждение об `AIO_CODE_OBFUSCATE` при отладке —
      `deployment.md` шаг 7; чек-лист — `testing-plan.md` раздел 15.
      Магазин (`Store_*.lua`) ожил автоматически (guard снят).
      Из референса dWrath не взяты: ClassLess, RandomSpell/rollstable,
      StatAllo, rage_gen, nakedbugfix, learnkrabe, helloworld, sql/custom —
      classless-механики и зависимость от кастомных C++-методов ядра
      dWrath, противоречат концепции реалма (стоковые классы 1–80)
- [x] **Системы public-scripts** (референс: `m-orlovrus59/public-scripts`,
      JadaDev; портировано на ALE): награды за наигранное время
      (`19_PlayedTimeRewards.lua`, `realm_played_time_rewards{,_claimed}` —
      0021), смена фракции за Жетоны Эха (НПС 70174 «Страж Перемен»,
      `21_FactionChanger.lua`), убежища/FFA-зоны со сбросом флагов
      (`22_SanctuaryPvP.lua`); не взяты: Reviving (конфликт с
      Hardcore), AllTalents и Level80-255 (против концепции 80 и
      стоковых классов); чек-лист — `testing-plan.md` раздел 14
- [ ] Интеграция модулей AzerothCore: mod-ah-bot, mod-transmog,
      mod-cfbg, mod-duel-reset (см. `modules/README.md`)
- [x] DBC-патч клиента: инструкция готова — кастомный титул «Хранитель Эха»,
      маунт «Бездна-Пегас» (`docs/client-patch.md`; токены items 70002/70003 готовы)
- [x] Гайд развёртывания ядра + применение миграций (`docs/deployment.md`)
- [x] План тестирования с чек-листами кампаний, спавнов и displayid
      (`docs/testing-plan.md`)

## Фаза 4 — Релиз

- [x] Подготовлено: гайд развёртывания и план тестирования
- [ ] Полное тестирование кампаний на тестовом реалме по чек-листам
      (`docs/testing-plan.md`): выверка координат спавнов Зул'Драка и
      Драконьего Погоста, визуальная проверка displayid НПС
- [ ] Применить DBC-патч клиента по `docs/client-patch.md`
- [ ] Онбординг игроков (сайт/дискорд, реалм-лист)
- [ ] Публичный запуск «Эха Пустоты» 🚀

---

## Принятые конвенции

| Конвенция | Значение |
|-----------|----------|
| Клиент | WoW 3.3.5a (12340) |
| Ядро | AzerothCore (azerothcore-wotlk, master) |
| Скриптовый движок | ALE (mod-ale, форк Eluna) |
| Entry-диапазон кастомных НПС | 70001–79999 |
| ID кампаний | см. `docs/campaigns/README.md` |
| SQL-миграции | нумерация `NNNN_*.sql` в `sql/world/` |
