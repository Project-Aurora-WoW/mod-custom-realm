# 📦 Модули AzerothCore

## Структура каталогов (вариант B: ядро — внешний клон)

Ядро AzerothCore **не хранится в этом репозитории** — клонируется отдельно,
**рядом** с репозиторием контента реалма:

```
<рабочий каталог>/
├── azeroth-custom-realm/   # ЭТОТ репозиторий — только контент реалма
│   ├── addons/             # клиентский аддон
│   ├── docs/               # документация (деплой, тесты, DBC-патч)
│   ├── lua_scripts/        # Lua-скрипты ALE → копируются в ядро/bin
│   ├── modules/README.md   # эта инструкция
│   └── sql/world/          # миграции 0001–0008
└── azerothcore-wotlk/      # ВНЕШНИЙ клон ядра (git clone)
    └── modules/            # модули клонируются сюда
```

> Ядро: [azerothcore/azerothcore-wotlk](https://github.com/azerothcore/azerothcore-wotlk.git) —
> рабочая копия импортирована в SourceCraft:
> [m-orlovrus59/azerothcore-wotlk](https://sourcecraft.dev/m-orlovrus59/azerothcore-wotlk)
> (клонировать для сборки лучше из неё).
> Обязательный модуль mod-ale (Lua-движок ALE, форк Eluna) импортирован
> в SourceCraft:
> [m-orlovrus59/mod-ale](https://sourcecraft.dev/m-orlovrus59/mod-ale)
> (клон [azerothcore/mod-ale](https://github.com/azerothcore/mod-ale);
> `setup-build.sh` использует клон с fallback на GitHub).
> Клиент — WoW 3.3.5a (12340).
> Модули клонируются в `azerothcore-wotlk/modules/` и включаются при сборке
> через CMake.
> Обновление ядра: `cd azerothcore-wotlk && git pull` — репозиторий реалма
> при этом не затрагивается.
>
> Быстрая сборка «всё в одном» — скрипт
> [`scripts/setup-build.sh`](../scripts/setup-build.sh): клонирует ядро и
> модули, собирает и раскладывает Lua-скрипты:
> ```bash
> ./scripts/setup-build.sh
> ```

---

## Рекомендуемый набор модулей

| Модуль | Назначение | Обязателен для проекта? |
|--------|------------|--------------------------|
| [mod-ale](https://github.com/azerothcore/mod-ale) — клон: [m-orlovrus59/mod-ale](https://sourcecraft.dev/m-orlovrus59/mod-ale) | Lua-движок ALE (AzerothCore Lua Engine, форк Eluna) — **без него не работают скрипты из `lua_scripts/`** | ✅ Обязателен |
| [mod-ah-bot](https://github.com/azerothcore/mod-ah-bot) | Бот аукциона — наполняет Аукционный дом | 🔶 Рекомендуется |
| [mod-transmog](https://github.com/azerothcore/mod-transmog) | Система трансмогрификации | 🔶 Рекомендуется |
| [mod-cfbg](https://github.com/azerothcore/mod-cfbg) | Кросс-фракционные поля боя | 🔶 Рекомендуется |
| [mod-duel-reset](https://github.com/azerothcore/mod-duel-reset) | Сброс КД и здоровья после дуэлей | 🔶 Рекомендуется |
| [mod-individual-xp](https://github.com/azerothcore/mod-individual-xp) | Индивидуальный множитель опыта | 🔶 Рекомендуется |
| [mod-starter-guild](https://github.com/Turor/mod-starter-guild.git) | Стартовая гильдия для новичков (социальная поддержка первых уровней) — из classless-ядра `azerothcore-wotlk-classless` | 🔶 Рекомендуется |
| [mod-dungeonmaster](https://github.com/Turor/mod-dungeonmaster.git) | Инструменты мастера подземелий (динамическая сложность/события в данжах) — из classless-ядра | 🔶 Рекомендуется |
| [mod-ah-bot-plus](https://github.com/Turor/mod-ah-bot-plus.git) | Расширенный бот аукциона (замена/дополнение mod-ah-bot) — из classless-ядра | 🔶 Рекомендуется |

---

## Порядок подключения

1. Находясь в родительском каталоге, клонировать ядро **рядом** с репозиторием
   реалма (не внутрь!):
   ```bash
   git clone https://github.com/azerothcore/azerothcore-wotlk.git
   cd azerothcore-wotlk
   ```

2. Клонировать модули в каталог `modules/`. Для mod-ale используется
   клон SourceCraft (m-orlovrus59/mod-ale) с fallback на GitHub
   — тот же механизм, что в [`scripts/setup-build.sh`](../scripts/setup-build.sh):
   ```bash
   # mod-ale: сначала клон SourceCraft, при недоступности — GitHub
   git clone https://git.sourcecraft.dev/m-orlovrus59/mod-ale.git modules/mod-ale \
     || git clone https://github.com/azerothcore/mod-ale.git modules/mod-ale
   git clone https://github.com/azerothcore/mod-ah-bot.git modules/mod-ah-bot
   git clone https://github.com/azerothcore/mod-transmog.git modules/mod-transmog
   git clone https://github.com/azerothcore/mod-cfbg.git modules/mod-cfbg
   git clone https://github.com/azerothcore/mod-duel-reset.git modules/mod-duel-reset
   git clone https://github.com/azerothcore/mod-individual-xp.git modules/mod-individual-xp
   ```

3. Применить SQL-миграции этого репозитория:
   ```bash
   mysql -u <user> -p acore_world < ../azeroth-custom-realm/sql/world/0001_world_baseline.sql
   mysql -u <user> -p acore_world < ../azeroth-custom-realm/sql/world/0002_campaign_progress.sql
   ```

4. Собрать ядро с модулями (стандартная процедура AzerothCore):
   ```bash
   mkdir build && cd build
   cmake .. -DCMAKE_INSTALL_PREFIX=$HOME/acore
   make -j$(nproc)
   make install
   ```

5. Скопировать Lua-скрипты в каталог скриптов сервера
   (целиком — у AIO-стека есть подкаталоги с зависимостями):
   ```bash
   rm -rf $HOME/acore/bin/lua_scripts
   mkdir -p $HOME/acore/bin/lua_scripts
   cp -r ../azeroth-custom-realm/lua_scripts/. $HOME/acore/bin/lua_scripts/
   ```

6. Запустить `worldserver` — в логе должны появиться строки:
   ```
   [EchoOfTheVoid] WelcomeSystem.lua загружен.
   [EchoOfTheVoid] PortalGuardian.lua загружен (НПС 70001).
   ```

---

## Настройка mod-ale

В `env/dist/etc/modules/` (или через конфиг ALE) при необходимости
задать путь к скриптам — по умолчанию это `lua_scripts/` рядом с
бинарниками. Разработка: `.reload ale` (только dev; для продакшена —
перезапуск worldserver). Полезные опции конфига: `ALE.Enable`,
`ALE.TraceBack` (трейсбеки ошибок скриптов в лог).

---

## Иерархия загрузки (модули → ALE → Lua)

AzerothCore инициализирует модули **в алфавитном порядке имён каталогов**
в `azerothcore-wotlk/modules/`. Строчные буквы `echo-` идут раньше `mod-`,
поэтому кастомные модули реалма грузятся до стандартных:

```
1. Инициализация C++-модулей (алфавитный порядок каталогов):
   echo-balance          ← баланс урона/лечения (мультипликаторы, ваншоты)
   echo-challenge-modes  ← режимы испытаний (Алтарь 705605, hardcore/iron man и др.)
   echo-campaigns        ← команды .ae/.aecampaign в ядре (если command_source="core")
   echo-economy          ← анти-инфляция: слив жетонов сверх лимита при входе
   echo-pve              ← PvE Пустоты: ночной урон порождений, дроп Жетонов Эха
   echo-pvp              ← PvP Пустоты: жетоны в зоне, killstreak, Месть Эха
   echo-startup          ← стартовый набор новичкам (предметы + бафф Ордена)
   mod-ah-bot            ← бот аукциона
   mod-cfbg              ← кросс-фракционные БГ
   mod-duel-reset        ← сброс КД после дуэлей
   mod-ale               ← Lua-движок ALE (регистрация движка, скрипты ещё НЕ грузятся)
   mod-individual-xp     ← индивидуальный опыт
   mod-transmog          ← трансмогрификация

2. Инициализация мира завершена → ALE запускается и грузит
   lua_scripts/: сначала *.ext, затем *.lua (см. lua_scripts/README.md):
   00_CampaignRegistry.ext   ← реестр кампаний — ПЕРВЫМ (.ext до всех .lua)
   extensions/_Misc.ext + StackTracePlus.ext ← traceback для всех Lua-скриптов
   05_VoidAuras.lua          ← ауры Пустоты
   AIO.lua + Dep_*/lualzw    ← AIO-стек (до Store_*.lua — путь сортируется раньше)
   Store_DataStruct/Server/Client.lua ← AIO-магазин
   10_EventSystem.lua / 20_PvpSystem.lua / 30_PvpShop.lua
   AddonBridge.lua → Campaign1–4.lua → CampaignManager.lua
   LoreArchive.lua → PortalGuardian.lua → WelcomeSystem.lua
```

Важные следствия:
- **mod-ale обязателен и должен быть в наборе всегда** — без него
  `lua_scripts/` не загрузятся вовсе (модуль включён в
  [`scripts/setup-build.sh`](../scripts/setup-build.sh) первым в списке);
- C++-модули (`echo-balance`, `echo-campaigns`) инициализируются **до**
  ALE — Lua-скрипты могут полагаться на их конфиги, но не наоборот;
- если в `echo-campaigns.conf` задано `command_source = "core"`, команды
  `.ae*` обрабатывает ядро, а Lua-обработчик пропускает их
  (флаг `command_source` в реестре `00_CampaignRegistry.ext`).
- совместимость скаляров: `echo-balance`, `echo-pve` и `echo-pvp`
  используют одни и те же хуки `UnitScript` (Modify*). Множители
  применяются независимо и мультипликативно: ночью пустотный моб
  бьёт игрока с учётом `worldDamage` (echo-balance) × `nightDamage`
  (echo-pve); «Месть Эха» (echo-pvp) усиливает только игроков.

---

## Опция «Classless» (не включена)

Референс: [azerothcore-wotlk-classless](https://sourcecraft.dev/m-orlovrus59/azerothcore-wotlk-classless)
— форк ядра с безклассовой системой (mod-classless, класс Hero,
мобильный кастинг). Из него взяты модули `mod-starter-guild`,
`mod-dungeonmaster`, `mod-ah-bot-plus` (совместимы с лором).

**Само classless-ядро НЕ используется** — это смена дизайн-направления:
в [`docs/integration.md`](../docs/integration.md) зафиксировано
«никаких изменений в стоковых классах». Опция задокументирована как
кандидат на **арку кампании 5 «Пустота дробит классы»**
(см. [`docs/classless-option.md`](../docs/classless-option.md)).

⚠️ Если однажды включить classless: перепроверить весь баланс-контур
(echo-balance/echo-pve/echo-pvp) против classless-хуков урона, а также
систему классовых реплик (`class_greetings`) и гейты кампаний.

---

## Кастомные модули этого проекта

Каталог `modules/` содержит собственные C++-модули реалма:

| Модуль | Назначение | Ключевые хуки |
|--------|------------|----------------|
| `echo-balance` | Глобальный баланс: мультипликаторы урона/лечения, отсечка ваншотов, босс-фактор | `UnitScript` (Modify*), конфиг `echo-balance.conf.dist` |
| `echo-challenge-modes` | **Режимы испытаний** (референс: [mod-challenge-modes](https://sourcecraft.dev/m-orlovrus59/mod-challenge-modes), локализованный форк ru/en): 8 добровольных режимов у Алтаря Испытаний (GO 705605, миграция 0019) — Hardcore, SemiHardcore, SelfCrafted, ItemQualityLevel, Slow/VerySlow XP, QuestXpOnly, IronMan; награды за уровни из конфига. Требует `EnablePlayerSettings = 1` | `WorldScript` (конфиг), `PlayerScript` (XP/смерть/награды/ограничения), `GameObjectScript` (Алтарь), конфиг `echo-challenge-modes.conf.dist` |
| `echo-campaigns` | Служебный: команды `.ae/.aecampaign` в ядре, контроль порядка загрузки | Конфиг `echo-campaigns.conf.dist` (`CommandSource`) |
| `echo-economy` | **Анти-инфляция**: жетоны сверх мягкого лимита при входе урезаются на DrainPercent% («Пустота забираёт своё») | `PlayerScript` (OnLogin), конфиг `echo-economy.conf.dist` |
| `echo-pve` | **PvE Пустоты**: ночной скаляр урона порождений Пустоты («ночью шёпот громче»), шанс выпадения Жетона Эха с кулдауном | `UnitScript` (ночной урон), `CreatureScript` (дроп жетонов), конфиг `echo-pve.conf.dist` |
| `echo-pvp` | **PvP Пустоты**: Жетоны Эха за киллы в PvP-зоне, killstreak-объявления, «Месть Эха» (бафф павшему с серией ≥5 при респавне) | `PlayerScript` (OnPVPKill/OnPlayerRespawn), `UnitScript` (месть), конфиг `echo-pvp.conf.dist` |
| `echo-startup` | **Стартовый набор**: новичкам (played time < порога) — приветствие Ордена, предметы и бафф «Напутствие Ордена» | `PlayerScript` (OnLogin), конфиг `echo-startup.conf.dist` |

Общие конвенции модулей:
- локализация сообщений ru/en — по DBC-локали клиента (8 = ruRU → русский, иначе английский);
- значения по умолчанию конфигов синхронизированы с `lua_scripts/00_CampaignRegistry.ext`;
- Lua ведёт «истину» в БД (`realm_pvp_stats`, `realm_campaign_progress`), C++-модули — быстрые механики без обращения к БД;
- **outbox-паттерн для наград** (референс wow-mod-delves DelveRewardDelivery): durable-намерение (`realm_token_outbox`, уникальный `reward_key`) + идемпотентная доставка с квитанцией (`realm_token_receipt`); событие не теряется при рестарте и не платит дважды. Публичный API: `EchoEconomy_EnqueueTokenReward()` / `EchoEconomy_ProcessTokenOutbox()` (echo-economy линкуется раньше echo-pve/echo-pvp по алфавиту);
- разделение обязанностей PvP: жетоны/серии в PvP-зоне и «Месть Эха» — ядро (`echo-pvp`), полная статистика и команды `.aepvp` — Lua (`20_PvpSystem.lua`); жетоны за мобов на ивентах — Lua (`10_EventSystem.lua`), дроп жетонов с пустотных существ вне ивентов — ядро (`echo-pve`, через outbox).

Структура модуля:

```
modules/custom-module/
├── conf/custom-module.conf.dist   # копируется ядром (CopyModuleConfig)
└── src/CustomModule.cpp           # обязателен Add<Имя>Scripts()
```

Требования модульной системы AC (см. `modules/CMakeLists.txt` ядра):
- ядро само собирает исходники (`CollectSourceFiles`) в библиотеку `modules`
  — собственный `CMakeLists.txt` внутри модуля **не нужен и игнорируется**;
- конфиги `conf/*.conf.dist` копируются автоматически при сборке;
- каждый модуль обязан экспортировать функцию `void Add<ИмяМодуля>Scripts()`
  (дефисы в имени каталога заменяются на подчёркивания) — её генерирует
  `ConfigureScriptLoader`; иначе — ошибка линковки worldserver.
