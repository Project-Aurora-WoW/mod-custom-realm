# 📋 TODO / Backlog — Azeroth: Эхо Пустоты

> Живой файл задач реалма. **Правило ведения:** обновляется после каждого
> нового коммита — выполненное переносится в «Готово» с хешем коммита,
> новые задачи добавляются в актуальный бэклог.
>
> Live project task list. **Maintenance rule:** updated after every new commit —
> completed work moves to "Done" with its commit hash, new tasks are added to
> the current backlog.
>
> Дата последнего обновления / Last updated: 2026-11-14

---

## ✅ Готово / Done

| Коммит / Commit | Что сделано / What was done |
|--------|-------------|
| (ранние / early) | Инфраструктура, кампании 1–4, аддон AzerothEcho, C++-модули echo-*, миграции 0001–0017, миграция на ALE (`00_CampaignRegistry.ext`). / Infrastructure, campaigns 1–4, AzerothEcho addon, echo-* C++ modules, migrations 0001–0017, ALE migration (`00_CampaignRegistry.ext`). |
| `8ac9584` | **Tier A из eluna-scripts** (референс Cloticc): миграция `0018_eluna_scripts_tier_a.sql` (НПС 70172/70173, шаблоны 70190/70191, item 70008, спелл 70050, `realm_gold_storage`); секции реестра; скрипты 13–18. / **Tier A from eluna-scripts** (ref. Cloticc): migration `0018_eluna_scripts_tier_a.sql` (NPCs 70172/70173, templates 70190/70191, item 70008, spell 70050, `realm_gold_storage`); registry sections; scripts 13–18. |
| `0220ff3` | **Интеграция кастомных карт** (RStijn/custom-maps): телепорты Портального Стража на карту 5000 + лор; `patch-Z.mpq`; docs. / **Custom maps** (RStijn/custom-maps): Portal Guardian teleports to map 5000 + lore; `patch-Z.mpq`; docs. |
| `db92ea0` | **Режимы испытаний** (mod-challenge-modes, ru/en): 8 режимов, Алтарь Испытаний GO 705605 (`0019`), конфиг наград. / **Challenge modes** (mod-challenge-modes, ru/en): 8 modes, Trial Altar GO 705605 (`0019`), rewards config. |
| `6930313` | **AIO-магазин** (eluna-aio-storesystem): `Store_DataStruct/Server/Client.lua` (ru/en), миграция `0020_store_system.sql` (`realm_store_*`). / **AIO store** (eluna-aio-storesystem): `Store_DataStruct/Server/Client.lua` (ru/en), migration `0020_store_system.sql` (`realm_store_*`). |
| `287b508` | **Системы public-scripts** (JadaDev, на ALE): награды за время (`19`, 0021), смена фракции (`21`, НПС 70174), убежища/FFA (`22`). / **public-scripts systems** (JadaDev, on ALE): played-time rewards (`19`, 0021), faction change (`21`, NPC 70174), sanctuary/FFA (`22`). |
| `77b97df` | **AIO-фреймворк** (Rochet2/AIO v1.74, на ALE): `AIO.lua` + deps, `extensions/` (StackTracePlus), магазин ожил. / **AIO framework** (Rochet2/AIO v1.74, on ALE): `AIO.lua` + deps, `extensions/` (StackTracePlus), store enabled. |
| `90fd3bd` | **Фиксы задач 1/3/4**: хелпер `escape` против SQL-инъекций (registry, `16_GoldStorage.lua`, `CampaignManager.lua`); выверенные ID дебаффов Corruption (55095/770/55078/51735/48301 вместо несуществующих 822xx); `pcall`-guard загрузки таблиц в `19_PlayedTimeRewards.lua`. / **Fixes 1/3/4**: `escape` helper vs SQL injection (registry, `16_GoldStorage.lua`, `CampaignManager.lua`); verified Corruption debuff IDs (55095/770/55078/51735/48301 instead of non-existent 822xx); `pcall` guard for table load in `19_PlayedTimeRewards.lua`. |
| `4431211` | **Фикс задачи 2**: краш `HandleAcReset` на нечисловом ID (`value_or(0)` вместо UB-разыменования) в `echo-campaigns`. / **Fix 2**: `HandleAcReset` crash on non-numeric ID (`value_or(0)` instead of UB deref) in `echo-campaigns`. |
| `f22536e` | **Tier B из eluna-scripts (задача 5)**: Weapon Master (`23`, 70175), Lottery (`24`, 70176), Skip DK Starter (`25`, 70177), Prayer Altar (`26`, 70178); миграция `0024_tier_b.sql` + таблицы `realm_lottery{,_tickets}`. / **Tier B from eluna-scripts (task 5)**: Weapon Master (`23`, 70175), Lottery (`24`, 70176), Skip DK Starter (`25`, 70177), Prayer Altar (`26`, 70178); migration `0024_tier_b.sql` + `realm_lottery{,_tickets}` tables. |
| `f0956d6` | **Classless-арка К5 (задача 6)**: минимальный порт `azerothcore-classless-solo` (Shikifuyin) на ALE — обучение «чужих» классовых спеллов и глифов через `.aeclassless`; таблица `character_classless` (`0025_classless.sql`); таланты НЕ включены (см. скрипт). / **Campaign arc K5 (task 6)**: minimal ALE port of `azerothcore-classless-solo` (Shikifuyin) — learn foreign-class spells and glyphs via `.aeclassless`; `character_classless` table (`0025_classless.sql`); talents excluded (see script). |
| `86842f3` | Docs sync: `lua_scripts/README.md`, `sql/README.md` (Tier B + Classless, миграции 0024/0025). / Docs sync: `lua_scripts/README.md`, `sql/README.md` (Tier B + Classless, migrations 0024/0025). |
| (не закоммичено / not committed) | **Наполнение магазина (1.1)**: VIP-категория id 8 доступна с ранга 1, титул/бафф связаны с VIP, VIP-эксклюзив «Печать Бездны» (услуга 20, спелл 70051) за Жетоны (`0038_store_vip_expansion.sql`); `Store_Server.lua` отдаёт `accountRank = max(GM, VIP)` из `realm_vip` для фильтра `requiredRank` в клиенте. Маунт за Жетоны и `SERVER_HANDLED` уже были в 0020/0026. / **Store expansion (1.1)**: VIP category id 8 rank≥1, title/buff linked to VIP, VIP-exclusive "Seal of the Void" service (20, spell 70051) for Tokens (`0038`); `Store_Server.lua` returns `accountRank = max(GM, VIP)`. |
| (не закоммичено / not committed) | **Миграция PvP-шопа (1.2)**: ассортимент уже в AIO (0027, категория 10); старый НПС-шоп (`30_PvpShop.lua`) отключён guard'ом `REG.shop.enabled=false` — без дублирования НПС, фолбэк при отсутствии AIO-клиента. / **PvP shop migration (1.2)**: wares already in AIO (0027, cat 10); legacy NPS shop disabled via `REG.shop.enabled=false`. |
| (не закоммичено / not committed) | **CI/эмуляция мастер-сборки** (`.github/`): `.github/workflows/core-build.yml` (Linux clang + Windows MSVC, CCP-clone master+модули+mod-ale, dry-run), `.github/actions/setup-tree/action.yml`. / **CI / master-build emulation** (`.github/`): `.github/workflows/core-build.yml` (Linux clang + Windows MSVC, master clone+modules+mod-ale, dry-run), `.github/actions/setup-tree/action.yml`. |
| `d12691d`,`3af8980` | **Принудительное окно выбора кампании** (2026-11): сервер `40_CampaignWindow.lua` + `realm_campaign_profile` (0042), клиент `CampaignWindow.lua`, клиентский обработчик OnPlayerCreate (флаг force_show_window). / **Forced campaign-select window** (2026-11): server `40_CampaignWindow.lua` + `realm_campaign_profile` (0042), client `CampaignWindow.lua`. |
| `a6a8dd9` | **Переименование export-функций echo-***: `AddEcho*Scripts` → `Addecho_<dir>Scripts` — имена, которые ждёт свежий сборщик AC (ModulesLoader). / **Rename echo-* script loaders** to `Addecho_<dir>Scripts` (AC macro derives name from module dir, lowercase). |
| `8665aca` | **Клиентский zip AzerothEcho обновлён** до всех файлов (добавлены `Lore.lua`, `CampaignWindow.lua`); manifest v5. / **AzerothEcho client zip refreshed** (add Lore.lua + CampaignWindow.lua), manifest v5. |
| `2c0cc0d` | **Панель-хаб AzerothEcho**: `Hub.lua` — кнопки-ссылки на аддоны Journal и ArchaeologyUI (через их публичные API); manifest v6. / **AzerothEcho hub panel**: `Hub.lua` links to Journal and ArchaeologyUI; manifest v6. |
| `9f95550` | **Вендоринг ВСЕХ модулей в `modules/`** (2026-11-13): 14 внешних модулей (mod-ah-bot, mod-transmog, mod-cfbg, mod-duel-reset, mod-solocraft, mod-firstlogin-aio, mod-individual-xp, mod-starter-guild, mod-dungeonmaster, mod-ah-bot-plus, mod-hunger-thirst, mod-warband-camp, mod-forever-journal, mod-archaeology) как снапшоты без `.git`; `setup-build.sh` копирует `modules/*/` в ядро одним циклом вместо клонирования по SHA. / **Vendored all modules into `modules/`**: 14 external mods as .git-less snapshots; setup-build copies modules/*/ into core. |
| `f674170` | **CI: вендоринг** — setup-tree/action.yml копирует все модули из `modules/` репо в ядро (без `git clone`/`MOD_PIN`); обновлены core-build + windows-release. / **CI: vendoring** — setup-tree copies all modules from repo `modules/`; dropped git clone/MOD_PIN. |
| `20fdfad` | **CI: Lua 5.2.4 через `actions/checkout`** (LuaDist/lua, tag 5.2.4) вместо curl+heredoc — heredoc падал на Windows-раннере. / **CI: Lua 5.2.4 via actions/checkout** (LuaDist/lua tag), removing the heredoc that broke on Windows. |
| `4d69c0f` | **mod-dungeonmaster: фикс bash** — `MOD_DUNGEON_MASTER_ROOT` → `MOD_DUNGON_MASTER_ROOT` в `conf/conf.sh.dist` (auth path); под `set -u` были `unbound variable` в CI ci-pending-sql.sh. / **mod-dungeonmaster: bash fix** — align auth path var in conf.sh.dist (unbound variable under set -u). |

---

## 🔥 Актуально (следующий шаг) / Next up

- [x] **Обновить вики/доки** под вендоринг и последние изменения. / **Update wiki/docs** for vendoring and recent changes.
  ✅ Сделано коммитом `9169232` (2026-11-13): README, modules/addons/client README, RELEASE, deployment, ROADMAP,
  wiki CI/Install (RU+EN), TODO — вендоринг модулей, manifest v6, экспорт-функции. / 
  ✅ Done in commit `9169232`: all README/wiki/TODO docs updated for vendoring + client manifest v6.
- [ ] **Клиентский аддон AIO_Client**: вшить в patch-x как `Interface/AddOns/AIO/` — без него AIO-клиентская часть магазина не работает. / **AIO_Client addon**: embed into patch-x as `Interface/AddOns/AIO/`.
- [ ] **Тестовый прогон Tier A/B + Classless** на тестовом реалме: логи загрузки `[EchoOfTheVoid] 13_…18_…, 23_…27_`, чек-листы. / **Test run of Tier A/B + Classless** on a test realm: load logs, checklists.
- [ ] **Мирации 0018–0042 на тестовой БД** → чек-листы разделов 12–15 (`echo-challenge-modes`, AIO, Tier A/B, Classless). / **Apply migrations 0018–0042** on a test DB → checklist sections 12–15.
- [ ] **Сборка `patch-x.mpq`** по `client-patch.md` (база `Patch-T.MPQ.rar`; Map.dbc НЕ включать; Store_UI BLP + аддон AIO_Client). / **Build `patch-x.mpq`** per `client-patch.md`.
- [ ] **Проверить фактический прогон CI** на GitHub Actions (ветка `main`; master-ядро + все вендоренные модули + mod-ale). / **Verify CI actually runs** on GitHub Actions (main; master core + all vendored modules + mod-ale).

---

## 📦 Бэклог (по приоритету) / Backlog (by priority)

- [x] **GPT-НПС** (референс `elunamod-gpt-npcs`, Ember-RP, MIT): разговоры с НПС через чат. ✅ Allowlist заполнен (70110/70120/70130/70160/70180/70210) в `gpt_npc_config.lua`; модель `gpt-4o-mini`, канал ответа (broadcast от имени НПС), rate-limit, локализация ru/en — реализованы в `gpt_npc.lua`; Python-сервис `service/gpt_npc.py` + очередь `realm_gpt_queue` (0031). Осталось: API-ключ на сервере (вне репо). / **GPT-NPC** (ref. `elunamod-gpt-npcs`): ✅ allowlist filled (70110/70120/70130/70160/70180/70210); model, rate-limit, rg/en, Python service + queue ready. Only server-side API key left.
- [ ] Заполнить SHA256/size в `client/manifest.json` после выкладки `patch-Z.mpq` и сборки `patch-x.mpq`. / Fill SHA256/size in `client/manifest.json` after shipping `patch-Z.mpq` and building `patch-x.mpq`.
- [ ] Тестовый прогон кастомных карт — `testing-plan.md` раздел 11. / Test run of custom maps — `testing-plan.md` section 11.
- [ ] Настройка наград режимов испытаний в `echo-challenge-modes.conf` (титул 48 / item 70001 — примеры). / Configure challenge-mode rewards in `echo-challenge-modes.conf`.
- [ ] Наполнение магазина: расширение `realm_store_services` (маунты за жетоны, VIP-категория requiredRank, SERVER_HANDLED-валюта). / Expand store: `realm_store_services` (token mounts, VIP requiredRank tier, SERVER_HANDLED currency).
- [ ] Миграция PvP-шопа (`30_PvpShop.lua`, 70170) в AIO-магазин. / Migrate PvP shop (`30_PvpShop.lua`, 70170) into the AIO store.
- [x] **Parangon** (референс `lua-parangon`, Open-Wow/Khalar, AGPL): уровень Paragon на аккаунт, стаки штатных аур 7464/7471/7477/7468, `.parangon`. ✅ Реализовано: `29_Parangon.lua` + `0029_parangon.sql` (таблицы `account_parangon`/`characters_parangon`, acore_characters). Снята пометка «отложен» — пересечение с балансом статов не блокирует (аура-стаки работают поверх). / **Parangon** (ref. `lua-parangon`): ✅ Implemented: `29_Parangon.lua` + `0029_parangon.sql`.
- [x] **Classless — полная версия** (таланты + AIO-UI + класс Hero + мобильный кастинг): ✅ таланты реализованы в Lua (`27_Classless.lua` `.aeclassless learn talent`, `talent_dbc`+`talenttab_dbc`; AIO-UI `27_ClasslessClient.lua`; колонка `talents` — `0030_classless_full.sql`). ✅ **Hero-класс реализован в Lua** (`.aeclassless hero`, аур-бонусы силы/ловкости + Fortitude, колонка `hero` — `0039_classless_hero.sql`). ⏭ Мобильный кастинг — **C++-этап** (ядро AC/ALE не имеют серверного «каст при движении»; пересборка ядра). / **Classless — full version**: ✅ talents + AIO-UI + 0030. ✅ Hero class in Lua (+0039). ⏭ Mobile casting — C++ stage (core rebuild).
- [ ] RAI / SpellAIO из waloriaold (крупные модули). / RAI / SpellAIO from waloriaold (large modules).
- [ ] mod-delves (wow-mod-delves) — после запуска тестового реалма. / mod-delves (wow-mod-delves) — after test realm launch.
- [x] Интеграция модулей AzerothCore: mod-ah-bot, mod-transmog, mod-cfbg, mod-duel-reset, mod-solocraft, mod-firstlogin-aio, mod-individual-xp, mod-starter-guild, mod-dungeonmaster, mod-ah-bot-plus, mod-hunger-thirst, mod-warband-camp, mod-forever-journal, mod-archaeology. ✅ **Все завендорены в `modules/`** (снапшоты без `.git`, commit `9f95550`), `setup-build.sh` и CI копируют их в ядро. / Integrate AzerothCore modules. ✅ **All vendored into `modules/`** (commit `9f95550`).
- [ ] Полный тестовый прогон кампаний 1–4 по чек-листам. / Full test run of campaigns 1–4 per checklists.
- [x] **Random-энчанты предметов** (референс `azerothcore-content`): реализовано как весовые тиры оружия T1–T4 по ilvl (`28_RandomEnchant.lua` + `0028_item_enchant_random.sql`, НПС 70192). Решение (2026-11-13): «~700» из первоначальной идеи переработано в осознанную тир-модель — оставить тиры, полный справочник энчантов не наполняем. / **Random item enchants**: implemented as weighted weapon tiers T1–T4 by ilvl (28_RandomEnchant + 0028). Decision: keep tiers (full ~700 roster not populated).
- [x] **Solo-friendly данжи** (мод-solocraft / vasautobalance): ✅ модуль `mod-solocraft` зарегистрирован в интеграции — `.github/actions/setup-tree/action.yml` (78, 87) и `scripts/setup-build.sh` (70); собирается с ядром. Масштабирование статов/HP от размера группы — C++-слоем модуля. / **Solo-friendly dungeons** (mod-solocraft/vasautobalance): ✅ registered in setup-tree + setup-build, built with core.
- [ ] Вариант B PermaDeath (Hardcore) — рассмотрен, отложен. / PermaDeath (Hardcore) variant B — considered, deferred.

---

## ⚠️ Техдолг / известные проблемы (Technical debt / known issues)

- [ ] `deployment.md` шаг 8: расхождение CharDB/WorldDB в `0002` — применять в `acore_characters` (вариант A). / `deployment.md` step 8: CharDB/WorldDB mismatch in `0002` — apply to `acore_characters` (variant A).
- [ ] Координаты спавнов Драконьего Погоста/Зул'Драка приблизительные — выверка на тестовом реалме. / Dragonblight/Zul'Drak spawn coords approximate — verify on test realm.
- [ ] Титул ID 48 (TitleMask) — эмпирика, обязательная проверка на клиенте. / Title ID 48 (TitleMask) — empirical, must verify in client.
- [ ] Entry-занятость при новых миграциях: НПС 70170–70178/70180, items 70001–70008/70100/70101, guid 7000170–7000178, GO 705605+guid 7005601–7005609 — см. `sql/README.md`. / Entry usage for new migrations: NPCs 70170–70178/70180, items 70001–70008/70100/70101, guid 7000170–7000178, GO 705605+guid 7005601–7005609 — see `sql/README.md`.

---

## Конвенции (кратко) / Conventions (short)

- Entry НПС/предметы: 70001–79999; SQL-миграции `NNNN_*.sql` строго вперёд. / NPC/item entries: 70001–79999; migrations strictly forward.
- Порядок загрузки ALE: `*.ext` до всех `*.lua`; реестр — `00_CampaignRegistry.ext`. / ALE load order: `*.ext` before `*.lua`; registry — `00_CampaignRegistry.ext`.
- Локализация скриптов — полная ru/en. / Script localization — full ru/en.
- CI: `.github/workflows/core-build.yml` эмулирует мастер-сборку (мастер-ядро + все вендоренные модули + mod-ale, Linux/Windows). / CI: `.github/workflows/core-build.yml` emulates a master build (master core + all vendored modules + mod-ale, Linux/Windows).
- Референсы: `azerothcore-wotlk`, `waloria(old)`, `wow-mod-delves`, `mod-ale`, `eluna-scripts`, `custom-maps`, `mod-challenge-modes`, `elunamod-gpt-npcs`, `eluna-aio-storesystem`, `public-scripts`, `dwrath-eluna-3-3-5a`, `lua-parangon`, `azerothcore-content`, `azerothcore-classless-solo`. / References: listed above.