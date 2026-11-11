# 🌌 Azeroth: Эхо Пустоты / Echo of the Void
[![windows-release](https://github.com/Project-Aurora-WoW/mod-custom-realm/actions/workflows/windows-release.yml/badge.svg)](https://github.com/Project-Aurora-WoW/mod-custom-realm/actions/workflows/windows-release.yml)

> **RU:** Кастомный реалм на базе **AzerothCore** для клиента **WoW 3.3.5a (build 12340)**.
> Альтернативная временная линия: осколок трона Короля-лича пропитался энергией
> Пустоты, и Культ Усмешки Бездны готовит пробуждение Старого Бога.
>
> **EN:** A custom realm built on **AzerothCore** for the **WoW 3.3.5a (build 12340)** client.
> An alternate timeline: a shard of the Lich King's throne became saturated with Void
> energy, and the Cult of the Voided Smile prepares the awakening of an Old God.

> **Двуязычность / Bilingual:** README ведётся и на русском, и на английском.
> Документация в `docs/` — на русском. / This README is maintained in both Russian
> and English. Documentation under `docs/` is in Russian.

---

## 🧰 Стек / Tech stack

| Компонент / Component | Версия / источник · Version / source |
|-----------|-------------------|
| Ядро / Core | [azerothcore/azerothcore-wotlk](https://github.com/azerothcore/azerothcore-wotlk.git), **фиксированный коммит** `1459af9576eb8bd0a67f38ac54236965b5fe28eb` — внешний клон рядом с репозиторием (см. [`modules/README.md`](modules/README.md)). / **pinned commit** — external clone next to this repo. |
| Клиент / Client | WoW 3.3.5a (12340) |
| Скриптовый движок / Script engine | [mod-ale](https://github.com/azerothcore/mod-ale) (ALE — AzerothCore Lua Engine, форк Eluna) |
| БД / DB | MySQL (схемы `acore_world` и др.) |
| CI | GitHub Actions: `core-build.yml` — Linux (clang) + Windows (MSVC), эмуляция мастер-сборки ядра со всеми модулями. / GitHub Actions: `core-build.yml` — Linux (clang) + Windows (MSVC), master-build emulation with all modules. |

> **Принцип / Principle:** этот репозиторий содержит только контент реалма
> (миграции, Lua, аддон, доки, CI). Ядро развёртывается отдельно — клонированием
> рядом. / This repo holds only realm content (migrations, Lua, addon, docs, CI).
> The core is deployed separately, cloned next to it.

---

## 📁 Структура репозитория / Repository layout

```
azeroth-custom-realm/
├── .github/
│   ├── workflows/core-build.yml    # CI: Linux + Windows мастер-сборка ядра
│   └── actions/setup-tree/         # composite action: checkout ядра + модули + mod-ale
├── addons/AzerothEcho/            # Клиентский аддон (WoW 3.3.5a) — campaign panel + rift map
├── docs/                          # Документация (ландшафт, деплой, тесты, client-patch)
├── lua_scripts/                   # Lua-скрипты ALE (00_CampaignRegistry.ext → 27_Classless.lua, магазин, кампании)
├── modules/
│   ├── echo-balance/ … echo-startup/   # Кастомные C++-модули реалма (7 шт.)
│   └── README.md                  # Инструкция по модулям
└── sql/world/                     # Миграции 0001–0025 (нумерованные, только вперёд)
```

---

## 🚀 Быстрый старт / Quick start (**RU**)

1. Клонировать этот репозиторий и **рядом с ним** — ядро AzerothCore:
   ```bash
   git clone <этот репозиторий>.git
   git clone https://github.com/azerothcore/azerothcore-wotlk.git
   git checkout 1459af9576eb8bd0a67f38ac54236965b5fe28eb   # фиксированная версия ядра
   cd azerothcore-wotlk
   ```
2. Установить модули (mod-ale обязателен) и собрать ядро — см. [`modules/README.md`](modules/README.md).
3. Применить миграции из `sql/world/` **в порядке нумерации** — см. [`sql/README.md`](sql/README.md).
4. Скопировать `lua_scripts/*.ext` и `lua_scripts/*.lua` в `lua_scripts/` сервера.
5. Запустить `worldserver`. В логе ожидать строки `[EchoOfTheVoid] …` (см. `lua_scripts/README.md`).

## 🚀 Quick start (**EN**)

1. Clone this repository and, **next to it**, the AzerothCore core:
   ```bash
   git clone <this-repo>.git
   git clone https://github.com/azerothcore/azerothcore-wotlk.git
   git checkout 1459af9576eb8bd0a67f38ac54236965b5fe28eb   # pinned core version
   cd azerothcore-wotlk
   ```
2. Install modules (mod-ale is required) and build the core — see [`modules/README.md`](modules/README.md).
3. Apply migrations from `sql/world/` **in numeric order** — see [`sql/README.md`](sql/README.md).
4. Copy `lua_scripts/*.ext` and `lua_scripts/*.lua` into the server `lua_scripts/` dir.
5. Start `worldserver`. Expect `[EchoOfTheVoid] …` log lines (see `lua_scripts/README.md`).

---

## 🧪 CI / Emulated master build

`core-build.yml` клонирует мастер-ядро `azerothcore/azerothcore-wotlk@master`, встраивает
все 7 кастомных модулей `echo-*` и обязательный `mod-ale`, затем собирает ядро:

- **Linux** (`ubuntu-26.04`, clang-20 + ccache): CMake `SCRIPTS=static`, `MODULES=static`, `-Werror`,
  build → install → dry-run `authserver`/`worldserver` → проверка `Errors.log` → юнит-тесты.
- **Windows** (`windows-latest`, MSVC): кэш Boost 1.87 + MySQL 8.4, OpenSSL из образа,
  сборка через `./acore.sh compiler build`.

Подготовка дерева вынесена в composite action `.github/actions/setup-tree`.

Trigger: push/PR на `main`/`master`.

*(EN: CI clones the master core, embeds all 7 `echo-*` modules + required `mod-ale`, then builds:
Linux clang static build with dry-run and error check; Windows MSVC via `acore.sh`.)*

---

## 📜 Конвенции проекта / Project conventions

| Конвенция / Convention | Значение / Value |
|-----------|----------|
| Entry НПС (кастомные) / Custom NPC entries | 70001–79999 |
| item entry (кастомные) / custom item entries | 70001–79999 |
| ID кампаний / Campaign IDs | 1–4 |
| Прогресс игроков / Player progress | таблица `realm_campaign_progress` |
| Миграции / Migrations | `sql/world/NNNN_*.sql`, только вперёд / forward only |
| Цвета чата / Chat colors | Пустота `|cff8e44ad`, Орден `|cff5dade2`, Культ `|cffc0392b` |
| Локализация / Localization | полная ru/en (скрипты, магазин, аддон) / full ru/en |

---

## 🔗 Документация / Documentation

> 🆕 **Вики / Wiki (RU/EN):** [`wiki/`](wiki/) — установка на Windows/Ubuntu,
> конфигурация, CI. / installation on Windows/Ubuntu, config, CI.
- 🌌 Лор / Lore — [`docs/lore/universe.md`](docs/lore/universe.md)
- ⚔️ Кампании / Campaigns — [`docs/campaigns/README.md`](docs/campaigns/README.md)
- 🗺️ Roadmap — [`docs/roadmap.md`](docs/roadmap.md)
- 🧪 Развёртывание сервера / Server deployment — [`docs/deployment.md`](docs/deployment.md)
- 🧪 План тестирования / Testing plan — [`docs/testing-plan.md`](docs/testing-plan.md)
- 🧩 DBC-патч клиента / Client DBC patch — [`docs/client-patch.md`](docs/client-patch.md)
- 🧩 Скрипты / Scripts — [`lua_scripts/README.md`](lua_scripts/README.md)
- 🗃️ Миграции / Migrations — [`sql/README.md`](sql/README.md)
- 📦 Модули / Modules — [`modules/README.md`](modules/README.md)
- 📋 TODO / Backlog — [`TODO.md`](TODO.md)
