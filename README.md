# 🌌 Azeroth: Эхо Пустоты — Azeroth Custom Realm

> Кастомный реалм на базе **AzerothCore** для клиента **WoW 3.3.5a (build 12340)**.
> Альтернативная временная линия: осколок трона Короля-лича пропитался энергией
> Пустоты, и Культ Усмешки Бездны готовит пробуждение Старого Бога.

---

## 🧰 Стек

| Компонент | Версия / источник |
|-----------|-------------------|
| Ядро | [azerothcore/azerothcore-wotlk](https://github.com/azerothcore/azerothcore-wotlk.git) (master) — **внешний клон рядом с репозиторием**, не хранится в нём (см. [`modules/README.md`](modules/README.md)) |
| Клиент | WoW 3.3.5a (12340) |
| Скриптовый движок | [mod-ale](https://github.com/azerothcore/mod-ale) (ALE — AzerothCore Lua Engine, форк Eluna) |
| БД | MySQL (схемы `acore_world` и др.) |
| Клиентские аддоны | [`addons/AzerothEcho`](addons/README.md) — панель кампаний, карта разломов |

> **Принцип**: этот репозиторий содержит только контент реалма
> (миграции, Lua, аддон, доки). Ядро развёртывается отдельно — клонированием
> рядом с репозиторием, по гайду [`docs/deployment.md`](docs/deployment.md).

---

## 📁 Структура репозитория

```
azeroth-custom-realm/
├── addons/
│   ├── AzerothEcho/             # Клиентский аддон (WoW 3.3.5a)
│   │   ├── AzerothEcho.toc
│   │   └── AzerothEcho.lua      # UI-панель прогресса кампаний (/ae)
│   └── README.md                # Установка аддона в клиент
├── docs/
│   ├── campaigns/README.md      # Реестр кампаний (главы, награды, механики)
│   ├── lore/universe.md         # Лор вселенной «Эхо Пустоты»
│   ├── roadmap.md               # План развития по фазам
│   ├── deployment.md            # Гайд развёртывания ядра + миграции
│   ├── testing-plan.md          # Чек-листы тестирования
│   └── client-patch.md          # DBC-патч клиента (титул, маунт)
├── lua_scripts/                 # Lua-скрипты сервера (движок ALE)
│   ├── 00_CampaignRegistry.ext  # Центральный реестр кампаний + баланс (.ext грузится первым)
│   ├── CampaignManager.lua      # Служебный модуль кампаний: API, .ae*, .aecampaign*, журнал
│   ├── WelcomeSystem.lua        # Приветствие и лор-вступление при входе
│   ├── PortalGuardian.lua       # Gossip-телепортер (НПС 70001)
│   ├── Campaign1.lua            # Кампания 1 «Эхо Шёпота» (главы 1–3)
│   ├── Campaign2.lua            # Кампания 2 «Пепел Зул'Драка» (главы 1–5)
│   ├── Campaign3.lua            # Кампания 3 «Пробуждение» (главы 1–4, рейд-босс)
│   ├── Campaign4.lua            # Кампания 4 «Второе Эхо» (главы 1–5, Архонт Нехал'тхар)
│   ├── LoreArchive.lua          # Лор-архив: Хронист Ордена (НПС 70180)
│   ├── AddonBridge.lua          # Мост аддон↔сервер (AECHO + AECHOEV + AECHOPVP)
│   ├── 10_EventSystem.lua       # Ивенты: Шторм Пустоты, Кровавая Луна (.aeevent)
│   ├── 20_PvpSystem.lua         # PvP: статистика, killstreak, PvP-зона (.aepvp)
│   ├── 30_PvpShop.lua           # PvP-шоп за Жетоны Эха (НПС 70170)
│   └── README.md                # Документация скриптов
├── modules/                     # Модули AzerothCore
│   ├── README.md                # Инструкция по модулям
│   └── echo-balance/            # 🆡 Кастомный C++-модуль баланса (урон/лечение/ваншоты)
└── sql/
    ├── world/                   # Миграции world-БД (нумерованные, 0001–0010)
    └── README.md                # Реестр миграций и порядок применения
```

---

## 🚀 Быстрый старт

1. Клонировать этот репозиторий и **рядом с ним** — ядро AzerothCore
   (ядро не хранится внутри репозитория реалма):
   ```bash
   git clone <этот репозиторий>.git
   git clone https://github.com/azerothcore/azerothcore-wotlk.git
   cd azerothcore-wotlk
   ```
2. Установить модули (mod-ale обязателен) и собрать ядро —
   см. [`modules/README.md`](modules/README.md).
3. Применить миграции из `sql/world/` **в порядке нумерации** —
   см. [`sql/README.md`](sql/README.md) и [`docs/deployment.md`](docs/deployment.md).
4. Скопировать `lua_scripts/*.ext` и `lua_scripts/*.lua` в каталог
   `lua_scripts/` сервера.
5. Запустить `worldserver`. В логе ожидать строки:
   ```
   [EchoOfTheVoid] 00_CampaignRegistry.ext загружен (реестр кампаний: 4 кампании).
   [EchoOfTheVoid] WelcomeSystem.lua загружен.
   [EchoOfTheVoid] PortalGuardian.lua загружен (НПС 70001).
   [EchoOfTheVoid] Campaign1.lua загружен (НПС 70100/70110/70120).
   [EchoOfTheVoid] Campaign2.lua загружен (кампания 2, главы 1–5).
   [EchoOfTheVoid] Campaign3.lua загружен (кампания 3, главы 1–4, рейд-босс 70510).
   [EchoOfTheVoid] Campaign4.lua загружен (кампания 4 «Второе Эхо», главы 1–5, босс 70520).
   [EchoOfTheVoid] LoreArchive.lua загружен (НПС 70180, архив лора: 6 разделов).
   [EchoOfTheVoid] 10_EventSystem.lua загружен (ивенты: storm, blood; GM: .aeevent).
   [EchoOfTheVoid] 20_PvpSystem.lua загружен (статистика, killstreak, PvP-зона, .aepvp).
   [EchoOfTheVoid] 30_PvpShop.lua загружен (шоп НПС 70170, товаров: 6).
   [EchoOfTheVoid] AddonBridge.lua загружен (аддон AzerothEcho, AE_SendProgress экспортирован).
   [EchoOfTheVoid] CampaignManager.lua загружен (API кампаний, .ae*, .aecampaign*, журнал realm_campaign_log).
   echo-balance загружен: worldDmg=1.00 playerDmg=1.00 heal=1.00 maxHit=0% bossDmg=1.00
   ```
5. Для клиентского аддона — скопировать `addons/AzerothEcho/`
   в `WoW/Interface/AddOns/` (см. [`addons/README.md`](addons/README.md)).

---

## 📜 Конвенции проекта

| Конвенция | Значение |
|-----------|----------|
| Entry НПС (кастомные) | 70001–79999 |
| ├─ Портальный Страж | 70001 |
| ├─ Культ / порождения Пустоты | 70100–70199 |
| ├─ Ключевые сюжетные НПС | 70110+ (сюжет), 70120+ (квестодатели) |
| Item--entry (кастомные) | 70001–79999 |
| ID кампаний | 1–3 (см. `docs/campaigns/README.md`) |
| Прогресс игроков | таблица `realm_campaign_progress` |
| Миграции | `sql/world/NNNN_*.sql`, только вперёд |
| Цвета чата | Пустота `|cff8e44ad`, Орден `|cff5dade2`, Культ `|cffc0392b` |

---

## 🔗 Документация

- 🌌 Лор — [`docs/lore/universe.md`](docs/lore/universe.md)
- ⚔️ Кампании — [`docs/campaigns/README.md`](docs/campaigns/README.md)
- 🗺️ Roadmap — [`docs/roadmap.md`](docs/roadmap.md)
- 🧪 Развёртывание сервера — [`docs/deployment.md`](docs/deployment.md)
- 🧪 План тестирования — [`docs/testing-plan.md`](docs/testing-plan.md)
- 🧩 DBC-патч клиента (титул/маунт) — [`docs/client-patch.md`](docs/client-patch.md)
- 🧩 Скрипты — [`lua_scripts/README.md`](lua_scripts/README.md)
- 🗃️ Миграции — [`sql/README.md`](sql/README.md)
- 🧩 Аддон — [`addons/README.md`](addons/README.md)
- 📦 Модули — [`modules/README.md`](modules/README.md)
