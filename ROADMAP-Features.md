# 🗺 План реализации новых функций / New Features Implementation Plan

> План по «Бэклогу» из `TODO.md` (по состоянию на 2026-11-11).
> Проверяемость: каждая фича = отдельный этап с зависимостями, SQL-миграцией, скриптом/модулем и чек-листом проверки.
>
> Feature plan from the "Backlog" in `TODO.md` (as of 2026-11-11).
> Each feature is a separate stage with dependencies, SQL migration, script/module, and a verification checklist.

---

## 🔧 Общие правила / Global conventions

- **Entry-диапазон НПС/предметов**: `70001–79999`; новые миграции идут **строго вперёд** (`0026_…`, `0027_…` …). / NPC/item entries: `70001–79999`; migrations always forward (`0026_…`, `0027_…`, …).
- **Магазин**: таблица `realm_store_services` (col: entry, name_ru/en, category, requiredRank, currency, `SERVER_HANDLED` для серверных валют). / Store: `realm_store_services` (col: entry, name_ru/en, category, requiredRank, currency, `SERVER_HANDLED` for server currencies).
- **PvP-шоп**: сейчас `30_PvpShop.lua`, НПС 70170. / PvP shop: currently `30_PvpShop.lua`, NPC 70170.
- **Загрузка ALE**: `*.ext` грузятся раньше всех `*.lua`; реестр — `00_CampaignRegistry.ext`. / ALE load order: `*.ext` before all `*.lua`; registry — `00_CampaignRegistry.ext`.
- **Локализация**: скрипты полной ru/en. / Scripts are fully ru/en localized.
- **C++-модули** (`modules/echo-*`) требуют сборку ядра; чистые Lua-фичи — только файлы `lua_scripts/`. / C++ modules (`modules/echo-*`) need a core rebuild; pure Lua features are just files in `lua_scripts/`.
- Референсы хранятся в `./` (папка references) и из `TODO.md` Конвенции. / References are kept locally (`references/`) and listed in TODO.md Conventions.

---

## 📦 Фаза 1 — Магазин и экономика (Lua-only, без пересборки) / Phase 1 — Store & economy (Lua-only)

### 1.1 Наполнение магазина / Store expansion
**Источник / Source:** TODO Backlog `Наполнение магазина`.
**Где / Where:** `lua_scripts/Store_Server.lua`, `sql/world/0026_store_expansion.sql`.
**Что / What:**
- Маунты за жетоны (currency = item 70005).
- VIP-категория: `requiredRank` (ранг/подписка, читать из `requiredRank`).
- Валюта `SERVER_HANDLED` (награды, выдаваемые сервером, без списания item).
**SQL миграция / Migration:** `0026_store_expansion.sql` — строки в `realm_store_services` (entries 70110–70120 свободны по `sql/README.md`).
**Зависимости / Deps:** AIO-фреймворк (уже в `AIO.lua`), таблица `realm_store_services` (миграция `0020`).
**Проверка / Verify:**
- [ ] В магазине отображается маунт за жетоны, списание `70005` при покупке.
- [ ] VIP-категория видна только при `requiredRank`.
- [ ] `SERVER_HANDLED`-валюта выводится без списания item.

### 1.2 Миграция PvP-шопа в AIO / Migrate PvP shop into AIO
**Источник / Source:** TODO Backlog `Миграция PvP-шопа`.
**Где / Where:** `lua_scripts/30_PvpShop.lua` → `Store_Server/Client.lua` + `sql/world/0027_pvp_store.sql`.
**Что / What:** перенос покупок PvP-экипировки с НПС 70170 в AIO-категорию магазина.
**SQL миграция / Migration:** `0027_pvp_store.sql` — товары PvP-шопа (арена/поля боя) в `realm_store_services`.
**Зависимости / Deps:** 1.1 (структура магазина).
**Проверка / Verify:**
- [ ] PvP-товары доступны в категории магазина.
- [ ] Старый `30_PvpShop.lua` отключён/заменён без дублирования НПС.

---

## ⚔️ Фаза 2 — PvP-баланс и энчанты / Phase 2 — PvP balance & enchants

### 2.1 Random-энчанты предметов / Random item enchants
**Источник / Source:** TODO Backlog `Random-энчанты`.
**Где / Where:** `lua_scripts/` (Lua-потребитель) или `modules/echo-pve` (C++). Таблица `item_enchantment_random_tiers` (~700 энчантов, референс `azerothcore-content`).
**SQL миграция / Migration:** `0028_item_enchant_random.sql` + данные.
**Что / What:** таблица энчантов; потребитель применяет случайный энчант при крафте/дропе.
**Зависимости / Deps:** C++-модуль если нужен (пересборка ядра) ИЛИ чистый Lua-хук (`PLAYER_EVENT_ON_...`).
**Открытый вопрос / Open:** C++-потребитель => этап в Фазе 3 сильнее, но можно начать Lua-хуком без пересборки.
**Проверка / Verify:**
- [ ] Энчант применяется случайно и сохраняется в инвентаре.
- [ ] Список ~700 энчантов корректен и отфильтрован по классу/проф.

---

## 🎁 Фаза 3 — Специальные модули (пересборка ядра) / Phase 3 — Special modules (core rebuild)

### 3.1 Parangon (уровень Paragon на аккаунт) / Parangon
**Источник / Source:** TODO Backlog `Parangon`.
**Где / Where:** `lua_scripts/` (Lua) + зависимости `ObjectVariables.ext` + `GossipSetText` (SMSG 384).
**Что / What:** уровень Paragon на аккаунт, стаки штатных аур `7464/7471/7477/7468`, команда `.parangon`.
**Отложено / Deferred:** пересечение с балансом статов — включить только после решения по балансу.
**Проверка / Verify:**
- [ ] `.parangon` показывает/повышает уровень.
- [ ] Ауры стакаются корректно, вывод через GossipSetText.

### 3.2 Classless — полная версия / Classless full version
**Источник / Source:** TODO Backlog `Classless — полная версия`.
**Где / Where:** `lua_scripts/27_Classless.lua` + C++-класс талантов (референс-ядро `azerothcore-classless-solo`).
**Что / What:** таланты + AIO-UI + класс Hero + мобильный кастинг.
**Зависимости / Deps:** C++-класс талантов; пересборка ядра; AIO-UI.
**Проверка / Verify:**
- [ ] Таланты снимаются/применяются чисто через `RemoveSpell`/талант-класс.
- [ ] AIO-UI показывает класс Hero.
- [ ] Мобильный кастинг работает.

---

## 🤖 Фаза 4 — GPT-НПС (новый внешний сервис) / Phase 4 — GPT-NPC (external service)

### 4.1 GPT-НПС / GPT-NPC
**Источник / Source:** TODO Backlog `GPT-НПС` (референс `elunamod-gpt-npcs`, Ember-RP, MIT).
**Где / Where:** `lua_scripts/gpt_npc.lua` + Python-сервис (зависимость openai, API-ключ), референс `elunamod-gpt-npcs`.
**Что / What:** НПС-чат в игре.
**Открытые вопросы / Open:**
- Entry-allowlist (какие НПС говорят).
- Модель — по умолчанию `gpt-4o-mini`.
- Канал ответа — шёпот (`Whisper`).
- Экранирование argv, rate-limit.
- Локализация ru/en.
**Зависимости / Deps:** Python3 + `openai` + API-ключ (вне репо, на сервере).
**Проверка / Verify:**
- [ ] НПС отвечает шёпотом после сообщения игрока.
- [ ] Rate-limit не даёт заспамить.
- [ ] ru/en ответ локаль-зависим.

---

## 📚 Фаза 5 — Модули AzerothCore (интеграция) / Phase 5 — AzerothCore modules (integration)

### 5.1 Интеграция стандартных модулей / Standard modules integration
**Источник / Source:** TODO Backlog `Интеграция модулей`.
**Где / Where:** `modules/` + `setup-tree/action.yml`.
**Что / What:** mod-ah-bot, mod-transmog, mod-cfbg, mod-duel-reset.
**SQL / Config:** конфиги модулей + нужные таблицы.
**Проверка / Verify:**
- [ ] Модули собираются в CI (мастер-ядро + 7 модулей + новые).
- [ ] Не конфликтуют с echo-* entry-диапазонами.

### 5.2 Solo-friendly данжи (mod-solocraft / vasautobalance)
**Источник / Source:** TODO Backlog `Solo-friendly данжи`.
**Где / Where:** модуль (C++/Lua) — масштабирование статов/HP от размера группы.
**Проверка / Verify:**
- [ ] В соло-группе статы/HP масштабируются.
- [ ] Не ломается баланс в рейдах.

---

## 🧪 Фаза 6 — Тесты и полировка / Phase 6 — Testing & polish

### 6.1 Тестовый прогон новых фич
**Что / What:** прогнать на тестовом реалме магазин (1.x), PvP (2), Parangon (3.1), Classless full (3.2), GPT (4), модули (5).
**Зависимости / Deps:** Фазы 1–5.
**Проверка / Verify:**
- [ ] Логи загрузки `[EchoOfTheVoid]` всех новых скриптов.
- [ ] Миграции `0026–00ZZ` применяются без ошибок.

---

## 🧩 Оценка внешних репозиториев (Youpeoples / 55Honey) — вердикты

Сводка решений по кандидатам (2026-11-12). Из «Референс/Отклонить» в код ничего не добавлялось —
интегрирован только `extend_paladin_buffs` из ACScripts как `30_PaladinBlessings.lua`.

| Репозиторий | Лицензия | Вердикт | Почему |
|---|---|---|---|
| `Youpeoples/ACScripts` | MIT | **Частично взят** | `extend_paladin_buffs` → `lua_scripts/30_PaladinBlessings.lua` (QoL, продление баффов паладина до 60 мин; коммит `027d008`). Прочее (gold_to_guild, faster_mounts, freeze, trial-gate, dbc_spells_sql) — не берём: не нужно для нас или конфликтует с балансом (faster_mounts/SetSpeed), дублирует БД (dbc). |
| `Youpeoples/Black-Market-Auction-House` | GPL-3.0 | **Референс/не ставить** | Идея аукциона хороша, но «как есть» нельзя: второй AIO-UI-канал конкурирует с нашим магазином (`Store_*.lua`), entry `2069430` вне 70xxx, только золото (не Жетоны Эха), en-тексты, молод (8 коммитов). Механику при желании перенести как сервис AIO-магазина — отдельным этапом. |
| `Youpeoples/Prestige-and-Draft-Mode` | MIT | **Референс/не ставить** | Престиж-сброс стирает спеллы/таланты → ломает Classless (`27_Classless.lua`) и Parangon (`29_Parangon.lua`). Макс-уровень 70 vs наш 80, en-тексты, требует DBC/MPQ. Брать только после явного решения о сосуществовании с Classless/Parangon (крупный этап). |
| `Youpeoples/Ultimate-Full-Loot-Pvp` | MIT | **Интегрирован** | Порт в `lua_scripts/31_PvpFullLoot.lua` + сундук 700020 (`0032_pvp_full_loot.sql`), коммит `027d008`. Адаптация под реалм: команды через `ON_CHAT(18)`, MMR/webhook выключены, ru/en. |
| `55Honey/Acore_eventScripts` | AGPL-3.0 | **Референс, не устанавливать** | Зрелый (237 коммитов), но модель «GM-вручную ивенты/боссы»; entry `1112xxx` вне 70xxx; команды `.startevent/.bonusbuff/.fun`; частично пересекается с нашими `10_EventSystem`/`22_SanctuaryPvP`. Полезен как референс логики custom-боссов с фазами и bonusbuff. |

**Кандидат на будущий этап (по желанию):** перенос механики Black-Market AH как категории AIO-магазина; адаптация `customWorldboss` из Acore_eventScripts под entry-диапазон 70xxx и автоматику реалма.

### Кандидат Фазы 5 (требует пересборки ядра): mod_weather_vibe

**Источник:** [hermensbas/mod_weather_vibe](https://github.com/hermensbas/mod_weather_vibe) (AGPL-3.0).
**Статус:** зафиксирован как кандидат; НЕ интегрирован (требует C++-пересборки ядра + настройки `ActivateWeather`).

- **Что:** C++-модуль погоды «по настроению»: зоны с атмосферой (туманы/гроза/шквал), плавные переходы состояния (fade/crossfade), сезоны из серверного времени, синхронизация зон (Stormwind = Elwynn), доставка при логине/смене зоны.
- **Требования:** пересборка ядра (cmake+make), в worldserver.conf `ActivateWeather = 0` (отключает штатный WeatherMgr AC — проверить совместимость), автомathические GM-команды `.wvibe set/setRaw/show`.
- **Почему кандидат, а не сейчас:** погода шлёт `WorldPackets::Misc::Weather` через `SendZoneMessage` — это чистый C++-слой (в ALE/Lua нереализуемо). По плану относится к Фазе 5 «модули AC».
- **Вход в проект:** клонировать в `modules/mod-weather-vibe`, добавить в `setup-build.sh`, конфиг + проверка `ActivateWeather`, профили зон под лор реалма.

---

## ⚠️ Не входит в этот план / Out of scope (осознанно отложено)

- Вариант B PermaDeath (Hardcore) — отложен. / PermaDeath variant B — deferred.
- RAI / SpellAIO из waloriaold — крупные модули, отдельный этап. / RAI / SpellAIO — large modules, separate effort.
- mod-delves — после запуска тестового реалма. / mod-delves — after test realm launch.

---

## 📌 Глоссарий зависимостей / Dependency glossary

- **AIO store**: `realm_store_services` (0020) + `Store_Server/Client.lua` + `AIO.lua`.
- **AIO framework**: Rochet2/AIO v1.74 в `AIO.lua` / `extensions/`.
- **echo-* C++ modules**: `modules/echo-balance|challenge-modes|economy|pve|pvp|startup|campaigns`.
- **ObjectVariables.ext / GossipSetText**: ALE-расширения для Parangon.
- **Референсы / References**: `azerothcore-content`, `elunamod-gpt-npcs`, `lua-parangon`, `azerothcore-classless-solo`, `mod-ah-bot`, `mod-transmog`, `mod-cfbg`, `mod-duel-reset`, `mod-solocraft`, `vasautobalance`, `eluna-aio-storesystem`.