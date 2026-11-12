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

## 🧩 Оценка внешних репозиториев — вердикты

Сводка решений по кандидатам (2026-11-12). Из «Референс/Отклонить» в код ничего не добавлялось —
интегрирован только `extend_paladin_buffs` из ACScripts как `30_PaladinBlessings.lua`.
Источники оценок по авторам: Youpeoples / 55Honey / zyggy123 / haha2345 / stevemcqueenz.

| Репозиторий | Лицензия | Вердикт | Почему |
|---|---|---|---|
| `Youpeoples/ACScripts` | MIT | **Частично взят** | `extend_paladin_buffs` → `lua_scripts/30_PaladinBlessings.lua` (QoL, продление баффов паладина до 60 мин; коммит `027d008`). Прочее (gold_to_guild, faster_mounts, freeze, trial-gate, dbc_spells_sql) — не берём: не нужно для нас или конфликтует с балансом (faster_mounts/SetSpeed), дублирует БД (dbc). |
| `Youpeoples/Black-Market-Auction-House` | GPL-3.0 | **Референс/не ставить** | Идея аукциона хороша, но «как есть» нельзя: второй AIO-UI-канал конкурирует с нашим магазином (`Store_*.lua`), entry `2069430` вне 70xxx, только золото (не Жетоны Эха), en-тексты, молод (8 коммитов). Механику при желании перенести как сервис AIO-магазина — отдельным этапом. |
| `Youpeoples/Prestige-and-Draft-Mode` | MIT | **Референс/не ставить** | Престиж-сброс стирает спеллы/таланты → ломает Classless (`27_Classless.lua`) и Parangon (`29_Parangon.lua`). Макс-уровень 70 vs наш 80, en-тексты, требует DBC/MPQ. Брать только после явного решения о сосуществовании с Classless/Parangon (крупный этап). |
| `Youpeoples/Ultimate-Full-Loot-Pvp` | MIT | **Интегрирован** | Порт в `lua_scripts/31_PvpFullLoot.lua` + сундук 700020 (`0032_pvp_full_loot.sql`), коммит `027d008`. Адаптация под реалм: команды через `ON_CHAT(18)`, MMR/webhook выключены, ru/en. |
| `55Honey/Acore_eventScripts` | AGPL-3.0 | **Референс, не устанавливать** | Зрелый (237 коммитов), но модель «GM-вручную ивенты/боссы»; entry `1112xxx` вне 70xxx; команды `.startevent/.bonusbuff/.fun`; частично пересекается с нашими `10_EventSystem`/`22_SanctuaryPvP`. Полезен как референс логики custom-боссов с фазами и bonusbuff. |

### zyggy123 (WoW-модули, в осн. Eluna/ALE)

| Репозиторий | Лицензия | Вердикт | Почему |
|---|---|---|---|
| `zyggy123/CrateSystem-AIO` | AGPL-3.0 | **Кандидат** | Лутбоксы/краты (CS:GO-стиль, 6 редкос­тей, босс-дроп ключей) — сильная механика для эхо-экономики. Встроенный **P2P-маркетплейс избыточен** (есть AIO-магазин `Store_*.lua`). Адаптация: ключи/краты → наш entry 70xxx, валюта → Жетоны Эха (70005), AIO-клиент проверить на v1.74. Молод (3 коммита) — тестировать. |
| `zyggy123/mod-duel-bet` | AGPL-3.0 | **Кандидат** | Ставки на дуэли: DB-escrow + mail-возврат (защита от Alt+F4/краша), anti-exploit, anti-spam, лимиты. **Единственный у автора, заявленный под mod-ale** (12 коммитов — зрелый). Вписывается в PvP-ветку (`31_PvpFullLoot`, `realm_pvp_stats`). Gossip→AIO-окно; нулевая-сумма золотом, лимиты/кулдаун обязательны. |
| `zyggy123/lottery-lua` | GPL-3.0 | **Кандидат (порт)** | Лотерея (вход за Эмблемы Льда, автотираж, приз). Идея — хороший sink Жетонов Эха. Нужен порт: валюта→70005, NPC→70xxx, gossip→AIO, эскроу вкладов. 34 коммита — зрелый. |
| `zyggy123/mod-beginner-companion` | AGPL-3.0 | **Референс-идея** | Wiki-гид новичка + журнал с наградами за чтение. Eluna (не AIO) → код не портировать; автономный AIO-гайд за Жетоны Эха — отдельной записью. |
| `zyggy123/Crime-Bounty-System` | AGPL-3.0 | **Отклонён** | «Розыск»+НПС-охотники. Нарушает: entry `900xxx` (вне 70001+), НПС 82–85 (макс 80), рантайм-DDL, Eluna-API. Не ниша. |
| `zyggy123/Morphing-Flask` | AGPL-3.0 | **Отклонён** | Морф игрока в НПС. entry `900xxx`, Infinite Dust (не наш токен), ручная чистка WDB-кэша, Eluna. Идея морф-косметики — в задел. |
| `zyggy123/BetterPosada` | License (не AGPL) | **Отклонён** | Клиентский аддон чата «posada» под чужой сервер UltimoWoW (испан.). Не серверный. |
| `zyggy123/LUA_AstronaX` | License | **Отклонён** | Клиентский мульти-аккаунт аддон (FuBar/GearScore/Ace3Lib), форк kantmn. Не серверный, чужие зависимости. |
| `zyggy123/CosmicChat` | — | **Отклонён** | Standalone web P2P (WebRTC/PeerJS), README-only (2 коммита). Не WoW-сервер. |

### haha2345 (разное)

| Репозиторий | Лицензия | Вердикт | Почему |
|---|---|---|---|
| `haha2345/BFA-HavenCore` | GPL-3.0 | **Отклонён** | Отдельный C++ ядро-эмулятор BFA 8.3.7. Не WotLK — несовместим с нашим AzerothCore/ALE-стеком (не модуль, а другое ядро). |
| `haha2345/grok-bot-0.18-reconstructed` | — | **Отклонён** | Реверс-инжиниринг чужого Electron-приложения (macOS), правовой риск (форк xianyu110). Не WoW. |
| `haha2345/SoloStorySuiteV2` | All rights reserved | **Отклонён** | 4-продуктовый self-hosted фреймворк + **DLL-инъекция** в клиент (ClientQuestMarkers/CQMInjector). Лицензия не выбрана, приватные ассеты, alpha. Идею Solo Adventure Guide — как геймплей-заметку. |
| `haha2345/DragonUI_NewEra` | — | **Отклонён** | Клиентский UI-аддон (DragonUI+ClassicAPI), форк ghbset. Не серверный, чужая инфраструктура. |
| `haha2345/awesome-wow-335-dev` | CC BY 4.0 / MIT | **Референс-база знаний** | Двуязычная база знаний по разработке 3.3.5a/AzerothCore: шкала статусов приёмки и принцип «серверный SQL/Lua/модуль прежде инъекции». Справочник для решений. |
| `haha2345/awesome-wow-335-clients` | CC BY 4.0 | **Референс-каталог** | Каталог клиентских сборок/реврит-клиентов. Термины LAA/x64 и границы «клиент-сервер». Подтверждает серверный подход. |

### stevemcqueenz (в осн. клиентские аддоны/форки)

| Репозиторий | Лицензия | Вердикт | Почему |
|---|---|---|---|
| `stevemcqueenz/gathermate-and-database-3.3.5a` | GPL-2.0 | **Референс-инструмент** | GatherMate + БД узлов из AzerothCore world-DB. Клиентский аддон, но `generate.py` — методика извлечения узлов добычи из нашей world-DB (карта добычи реалма). |
| `stevemcqueenz/CartoMapper` | License | **Отклонён** | Клиентский map-аддон (Mapster/Magnify/Leatrix/Mozz вместе), форк Zendevve. Не серверный. |
| `stevemcqueenz/awesome_wotlk` | License | **Отклонён** | Клиентский DLL-патчер/инъекция в `Wow.exe` (Detours). Нарушает «без клиентских модификаций/DLL». |
| `stevemcqueenz/ConsoleXP` | MIT | **Отклонён** | Клиентский DLL-inject + патч `Wow.exe` (MinHook). Автор предупреждает: риск Warden/бана и несовместимость на приватных серверах. |

### Helias (мейнтейнер AC)

| Репозиторий | Лицензия | Вердикт | Почему |
|---|---|---|---|
| `Helias/BG-Queue-Abuser-Viewer` | — (нет в README) | **Отклонён** | Angular 14 **web-приложение** (src/, package.json, angular.json) — «просмотр злоупотребления очереди BG». Не серверный Lua/ALE-модуль; требует отдельный веб-сервер/API-доступ к БД вне ядра. Наша PvP-логика и анти-абуз решаются на сервере (`31_PvpFullLoot`, `realm_pvp_stats`, `22_SanctuaryPvP`), а не отдельным фронтендом. Не вписывается в `lua_scripts/`/`modules/`. |
| `Helias/WDBXEditor` | — (нет в README) | **Отклонён** | **Desktop-программа** (.NET, `WDBXEditor.sln`/AppVeyor, форк WowDevTools): редактор клиентских DBC/DB2/WDB/ADB/DBCache для разработчика. Инструмент вне ядра; мы избегаем клиентских модификаций; не вписывается в `lua_scripts/`/`modules/`. |
| `Helias/wow-model-viewer` | — (нет LICENSE) | **Отклонён** | **JS/Node web-библиотека** (npm, jQuery 3.x + Wowhead ZamModelViewer, форк Miorey) для рендера 3D-модели персонажа WoW на сайте (сделана под Murloc Village). Клиентский веб-виджет + внешние CDN-зависимости (ZamImg), не серверный Lua/ALE/CI-модуль; не вписывается в наш стек. |
| `Helias/TC-PvEStats` | AGPL-3.0 | **Отклонён** | **web-frontend** статистики (HTML/CSS/JS, дашборд на сайте) поверх **устаревшего TC-JSON-API** (автор: deprecated; планирует переписать под AzerothAPI). Не серверный Lua/ALE-модуль; требует отдельный REST/JSON-API + веб-хостинг вне ядра. Наша статистика уже серверная (`realm_pvp_stats`, `.aecampaign`, `29_Parangon`). Не вписывается в `lua_scripts/`/`modules/`. |

**Кандидат на будущий этап (по желанию):** перенос механики Black-Market AH как категории AIO-магазина; адаптация `customWorldboss` из Acore_eventScripts под entry-диапазон 70xxx и автоматику реалма.

### Кандидат Фазы 5 (требует пересборки ядра): mod_weather_vibe

**Источник:** [hermensbas/mod_weather_vibe](https://github.com/hermensbas/mod_weather_vibe) (AGPL-3.0).
**Статус:** зафиксирован как кандидат; НЕ интегрирован (требует C++-пересборки ядра + настройки `ActivateWeather`).

- **Что:** C++-модуль погоды «по настроению»: зоны с атмосферой (туманы/гроза/шквал), плавные переходы состояния (fade/crossfade), сезоны из серверного времени, синхронизация зон (Stormwind = Elwynn), доставка при логине/смене зоны.
- **Требования:** пересборка ядра (cmake+make), в worldserver.conf `ActivateWeather = 0` (отключает штатный WeatherMgr AC — проверить совместимость), автомathические GM-команды `.wvibe set/setRaw/show`.
- **Почему кандидат, а не сейчас:** погода шлёт `WorldPackets::Misc::Weather` через `SendZoneMessage` — это чистый C++-слой (в ALE/Lua нереализуемо). По плану относится к Фазе 5 «модули AC».
- **Вход в проект:** клонировать в `modules/mod-weather-vibe`, добавить в `setup-build.sh`, конфиг + проверка `ActivateWeather`, профили зон под лор реалма.

### Клиентский кандидат (не серверный модуль): AIVoiceover для 3.3.5

**Источник:** [hermensbas/Aivoiceover3.3.5](https://github.com/hermensbas/Aivoiceover3.3.5) (форк Aelaksmith; 0⭐, 8 коммитов).
**Статус:** зафиксирован как возможный будущий клиентский QoL; НЕ интегрирован.

- **Что:** клиентский аддон `AI_VoiceOver` — озвучка квестов синтезированной речью (based on MrThinger аддон + данные Darkneo). Папки под 1.12/2.4.3/3.3.5.
- **Почему не сейчас:** это **клиентский аддон** (распространяется в `Interface/AddOns`), а не серверный модуль; форк незрелый (0⭐), а WotLK-озвучка по README частично готова («quirks с квестами одинаковых имён»).
- **Вход (если решим):** собственное клиентское озвучивание квестов реалма в нашем аддоне `AzerothEcho`, а не заимствование этого форка.

### Клиентский кандидат (не серверный модуль): RestedXP RXPGuides — WotLK 3.3.5a

**Источник:** [PottedSalame/RestedXP_RXPGuides-WotLK_3.3.5a](https://github.com/PottedSalame/RestedXP_RXPGuides-WotLK_3.3.5a) (GPL-3.0 + mixed; 17⭐, 187 коммитов).
**Статус:** зафиксирован как возможный клиентский QoL; НЕ интегрирован.

- **Что:** клиентский левеллинг-гид-аддон — пошаговые гайды Альянс/Орда до 80 (Classic/TBC/WotLK, DK, хардкор-маршруты, данжи/реп/далики), навигация (стрелки/карта/рейсы), авто-приём/сдача квестов, рекомендации по талантам/шмоту; есть ru-перевод (`ruRU`).
- **Почему не сейчас:** это **клиентский аддон** (`Interface/AddOns`), не серверный модуль; в код реалма не встраивается, а для игроков носит опциональный характер.
- **Нюанс:** гид ведёт по **стоковым** квестам и не знает кастомную арку реалма (НПС/квесты 70xxx, Эхо Пустоты) — рядом с нашим контентом даёт стандартные подсказки.
- **Вход (если решим):** рекомендация/распространение рядом с аддоном `AzerothEcho` для стоковых зон; кастомные маршруты арки — отдельно (Guide Editor / Custom guides).

### Отклонённый кандидат: AzerCore-Ops Platform

**Источник:** [Fersantos1975/AzerCore-Ops](https://github.com/Fersantos1975/AzerCore-Ops) (GPL-3.0; 15⭐, 82 коммита, rc 0.7.5j).
**Статус:** отклонён — НЕ интегрировать.

- **Что:** «операционная панель» для ОС/GM: C++-модуль (`src/`, CMake) + клиентский аддон 3.3.5a (`addon/AzerCoreOps`). Поиск/инспекция квестов и персонажей, групповой аудит, запись боёв (ICC), движение (game_tele/инстансы), отчёты; Player Mode — только просмотр для игроков.
- **Почему отклонён:** требует **пересборки ядра** (C++-модуль) — вне «Lua-only» контура; **избыточен/дублирует** наши GM-инструменты (`CampaignManager`, `.aecampaign`, `.aepvp`, `.fixgear`), лор-аддон `AzerothEcho`; нацелен на стоковый ICC-контент, а не на наши кастомные кампании; второй клиентский аддон без реальной выгоды именно для лорпроекта.

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
- **Референсы / References**: `azerothcore-content`, `elunamod-gpt-npcs`, `lua-parangon`, `azerothcore-classless-solo`, `mod-ah-bot`, `mod-transmog`, `mod-cfbg`, `mod-duel-reset`, `mod-solocraft`, `vasautobalance`, `eluna-aio-storesystem`, `Helias/reusable-workflows` (официальные reusable-workflows AC; наш CI самописный — composite `setup-tree` + core-build/windows-release, ориентир/проверка практики сборки).