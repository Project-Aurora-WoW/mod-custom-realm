# 📖 Wiki — Azeroth: Echo of the Void

> **EN:** Bilingual wiki of the module repository. Covers AzerothCore installation
> with the realm modules, configuration parameters and software setup on **Windows**
> and **Ubuntu/Debian**, including all Linux commands.
>
> **RU:** Двуязычная вики репозитория модуля. Здесь — установка ядра AzerothCore
> с модулями реалма, параметры конфигурации и настройка софта под **Windows**
> и **Ubuntu/Debian**, включая все команды для Linux.

---

## 🗺️ Wiki map / Карта вики

| English | Русский |
|---------|---------|
| [🏠 English home (this page)](Home.md) | [🏠 Главная](README.md) |
| [🪟 Windows installation](Install-Windows-en.md) | [🪟 Установка на Windows](Install-Windows.md) |
| [🐧 Ubuntu/Debian installation](Install-Ubuntu-en.md) | [🐧 Установка на Ubuntu/Debian](Install-Ubuntu.md) |
| [⚙️ Configuration & parameters](Configuration-en.md) | [⚙️ Конфигурация и параметры](Configuration.md) |
| [🤖 CI builds & releases](CI-Build-en.md) | [🤖 CI и компиляция в GitHub Actions](CI-Build.md) |
| [🛡️ Notes & limitations](Notes-en.md) | [🛡️ Известные замечания](Notes.md) |
| [🧰 Required software](Software-en.md) | [🧰 Необходимый софт](Software.md) |
| [🌍 Making the server public](Public-Server-en.md) | [🌍 Публикация сервера](Public-Server.md) |

---

## 📌 TL;DR

**EN:** Custom WoW 3.3.5a realm built on **AzerothCore** with:
- 7 realm C++ modules (`echo-*`: balance, campaigns, challenge modes, economy, PvE/PvP, starter kit);
- **ALE** Lua engine (`mod-ale`) + ~40 Lua scripts (campaigns 1–4, events, store, Classless, etc.);
- SQL migrations `0001–0025` for world/characters DBs;
- `AzerothEcho` client addon and MPQ patches.

**RU:** Кастомный реалм WoW 3.3.5a на базе **AzerothCore** с:
- 7 C++-модулями реалма (`echo-*`: баланс, кампании, режимы испытаний, экономика, PvE/PvP, стартовый набор);
- Lua-движком **ALE** (`mod-ale`) + ~40 Lua-скриптов (кампании 1–4, ивенты, магазин, Classless и др.);
- SQL-миграциями `0001–0025` для world/characters-БД;
- клиентским аддоном `AzerothEcho` и патчами MPQ.

---

## 🧰 Tech stack / Стек

| Component/Компонент | Value/Значение |
|---------------------|----------------|
| Core/Ядро | `azerothcore/azerothcore-wotlk`, commit `1459af9576eb8bd0a67f38ac54236965b5fe28eb` |
| Script engine/Движок скриптов | `mod-ale` (ALE) |
| Client/Клиент | WoW 3.3.5a (build 12340) |
| DB/БД | MySQL 8.0 (`acore_world`, `acore_auth`, `acore_characters`) |
| Build/Сборка | CMake ≥ 3.16, MSVC (Windows) / clang·gcc (Linux), Boost ≥ 1.74 |
| CI | GitHub Actions: Linux + Windows build, Windows release artifact |

---

## 🔐 Credentials / Учётные данные

> Default DB credentials `root`/your-password are used in these guides. CI dry-run
> uses `root/root`. **Do not use the root password in production** — create a
> dedicated DB user.

---

## 📚 Key links / Основные ссылки

- 📦 Full docs — [`docs/`](../docs/), 🇷🇺
- 🗳️ Migrations — [`sql/README.md`](../sql/README.md)
- 🧩 Lua scripts — [`lua_scripts/README.md`](../lua_scripts/README.md)
- 📦 Modules — [`modules/README.md`](../modules/README.md)
- 📋 TODO / Backlog — [`TODO.md`](../TODO.md)