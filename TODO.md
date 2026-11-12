# 📋 TODO / Backlog — Azeroth: Эхо Пустоты

> Живой файл задач реалма. **Правило ведения:** обновляется после каждого
> нового коммита — выполненное переносится в «Готово» с хешем коммита,
> новые задачи добавляются в актуальный бэклог.
>
> Live project task list. **Maintenance rule:** updated after every new commit —
> completed work moves to "Done" with its commit hash, new tasks are added to
> the current backlog.
>
> Дата последнего обновления / Last updated: 2026-11-11

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

---

## 🔥 Актуально (следующий шаг) / Next up

- [ ] **Закоммитить и запушить CI** — `.github/` (workflow + composite action) ещё не в git. / **Commit and push CI** — `.github/` (workflow + composite action) is not yet in git.
- [ ] **Клиентский аддон AIO_Client**: взять из Rochet2/AIO и вшить в patch-x как `Interface/AddOns/AIO/` — без него AIO-клиентская часть не работает. / **AIO_Client addon**: take from Rochet2/AIO and embed into patch-x as `Interface/AddOns/AIO/`.
- [ ] **Тестовый прогон Tier A/B + Classless** на тестовом реалме: логи загрузки `[EchoOfTheVoid] 13_…18_…, 23_…27_`, чек-листы. / **Test run of Tier A/B + Classless** on a test realm: `[EchoOfTheVoid] 13_…18_…, 23_…27_` load logs, checklists.
- [ ] **Пересборка ядра** с модулями + миграции 0018–0025 → чек-листы разделов 12–15 (`echo-challenge-modes`, AIO, Tier A/B, Classless). / **Core rebuild** with modules + migrations 0018–0025 → checklist sections 12–15 (`echo-challenge-modes`, AIO, Tier A/B, Classless).
- [ ] **Сборка `patch-x.mpq`** по `client-patch.md` (база `Patch-T.MPQ.rar`; Map.dbc НЕ включать; Store_UI BLP + аддон AIO_Client). / **Build `patch-x.mpq`** per `client-patch.md`.
- [ ] **Проверить фактический прогон CI** (зарегистрировать репозиторий на GitHub Actions — мастере-ядро собирает все 7 модулей + mod-ale). / **Verify CI actually runs** (register repo on GitHub Actions — master core builds all 7 modules + mod-ale).

---

## 📦 Бэклог (по приоритету) / Backlog (by priority)

- [x] **GPT-НПС** (референс `elunamod-gpt-npcs`, Ember-RP, MIT): разговоры с НПС через чат. ✅ Allowlist заполнен (70110/70120/70130/70160/70180/70210) в `gpt_npc_config.lua`; модель `gpt-4o-mini`, канал ответа (broadcast от имени НПС), rate-limit, локализация ru/en — реализованы в `gpt_npc.lua`; Python-сервис `service/gpt_npc.py` + очередь `realm_gpt_queue` (0031). Осталось: API-ключ на сервере (вне репо). / **GPT-NPC** (ref. `elunamod-gpt-npcs`): ✅ allowlist filled (70110/70120/70130/70160/70180/70210); model, rate-limit, rg/en, Python service + queue ready. Only server-side API key left.
- [ ] Заполнить SHA256/size в `client/manifest.json` после выкладки `patch-Z.mpq` и сборки `patch-x.mpq`. / Fill SHA256/size in `client/manifest.json` after shipping `patch-Z.mpq` and building `patch-x.mpq`.
- [ ] Тестовый прогон кастомных карт — `testing-plan.md` раздел 11. / Test run of custom maps — `testing-plan.md` section 11.
- [ ] Настройка наград режимов испытаний в `echo-challenge-modes.conf` (титул 48 / item 70001 — примеры). / Configure challenge-mode rewards in `echo-challenge-modes.conf`.
- [ ] Наполнение магазина: расширение `realm_store_services` (маунты за жетоны, VIP-категория requiredRank, SERVER_HANDLED-валюта). / Expand store: `realm_store_services` (token mounts, VIP requiredRank tier, SERVER_HANDLED currency).
- [ ] Миграция PvP-шопа (`30_PvpShop.lua`, 70170) в AIO-магазин. / Migrate PvP shop (`30_PvpShop.lua`, 70170) into the AIO store.
- [x] **Parangon** (референс `lua-parangon`, Open-Wow/Khalar, AGPL): уровень Paragon на аккаунт, стаки штатных аур 7464/7471/7477/7468, `.parangon`. ✅ Реализовано: `29_Parangon.lua` + `0029_parangon.sql` (таблицы `account_parangon`/`characters_parangon`, acore_characters). Снята пометка «отложен» — пересечение с балансом статов не блокирует (аура-стаки работают поверх). / **Parangon** (ref. `lua-parangon`): ✅ Implemented: `29_Parangon.lua` + `0029_parangon.sql`.
- [ ] **Classless — полная версия** (таланты + AIO-UI + класс Hero + мобильный кастинг): сейчас включена минимальная версия (спеллы+глифы); таланты требуют C++-класс талантов / референс-ядро. / **Classless — full version** (talents + AIO-UI + Hero class + mobile casting): currently minimal version (spells+glyphs) is in; talents need the C++ talent class / classless reference core.
- [ ] RAI / SpellAIO из waloriaold (крупные модули). / RAI / SpellAIO from waloriaold (large modules).
- [ ] mod-delves (wow-mod-delves) — после запуска тестового реалма. / mod-delves (wow-mod-delves) — after test realm launch.
- [ ] Интеграция модулей AzerothCore: mod-ah-bot, mod-transmog, mod-cfbg, mod-duel-reset (`modules/README.md`). / Integrate AzerothCore modules: mod-ah-bot, mod-transmog, mod-cfbg, mod-duel-reset.
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
- CI: `.github/workflows/core-build.yml` эмулирует мастер-сборку (мастер-ядро + 7 модулей + mod-ale, Linux/Windows). / CI: `.github/workflows/core-build.yml` emulates a master build (master core + 7 modules + mod-ale, Linux/Windows).
- Референсы: `azerothcore-wotlk`, `waloria(old)`, `wow-mod-delves`, `mod-ale`, `eluna-scripts`, `custom-maps`, `mod-challenge-modes`, `elunamod-gpt-npcs`, `eluna-aio-storesystem`, `public-scripts`, `dwrath-eluna-3-3-5a`, `lua-parangon`, `azerothcore-content`, `azerothcore-classless-solo`. / References: listed above.