# 📖 Wiki — Azeroth: Эхо Пустоты / Echo of the Void

> **RU:** Двуязычная вики репозитория модуля. Здесь — установка ядра AzerothCore
> с модулями реалма, параметры конфигурации и настройка софта под **Windows**
> и **Ubuntu/Debian**, включая все команды для Linux.
>
> **EN:** Bilingual wiki of the module repository. Covers AzerothCore installation
> with the realm modules, configuration parameters and software setup on **Windows**
> and **Ubuntu/Debian**, including all Linux commands.

---

## 🗺️ Карта вики / Wiki map

| Русский / Russian | English |
|-------------------|---------|
| [🏠 Главная](README.md) | [💻 English home](Home.md) |
| [🪟 Установка на Windows](Install-Windows.md) | [🪟 Windows installation (EN)](Install-Windows-en.md) |
| [🐧 Установка на Ubuntu/Debian](Install-Ubuntu.md) | [🐧 Ubuntu/Debian installation (EN)](Install-Ubuntu-en.md) |
| [⚙️ Конфигурация и параметры](Configuration.md) | [⚙️ Configuration & parameters (EN)](Configuration-en.md) |
| [🤖 CI и компиляция в GitHub Actions](CI-Build.md) | [🤖 CI builds & releases (EN)](CI-Build-en.md) |
| [🛡️ Известные замечания](Notes.md) | [🛡️ Notes & limitations (EN)](Notes-en.md) |
| [🧰 Необходимый софт](Software.md) | [🧰 Required software (EN)](Software-en.md) |
| [🌍 Публикация сервера](Public-Server.md) | [🌍 Making the server public (EN)](Public-Server-en.md) |

---

## 📌 Кратко: что это / TL;DR

**RU:** Кастомный реалм WoW 3.3.5a на базе **AzerothCore** с:
- 7 C++-модулями реалма (`echo-*`: баланс, кампании, режимы испытаний, экономика, PvE/PvP, стартовый набор);
- Lua-движком **ALE** (`mod-ale`) + ~40 Lua-скриптов (кампании 1–4, ивенты, магазин, Classless и др.);
- SQL-миграциями `0001–0025` для world/characters-БД;
- клиентским аддоном `AzerothEcho` и патчами MPQ.

**EN:** Custom WoW 3.3.5a realm built on **AzerothCore** with:
- 7 realm C++ modules (`echo-*`: balance, campaigns, challenge modes, economy, PvE/PvP, starter kit);
- **ALE** Lua engine (`mod-ale`) + ~40 Lua scripts (campaigns 1–4, events, store, Classless, etc.);
- SQL migrations `0001–0025` for world/characters DBs;
- `AzerothEcho` client addon and MPQ patches.

---

## 🧰 Стек / Tech stack

| Компонент / Component | Значение / Value |
|-----------------------|------------------|
| Ядро / Core | `azerothcore/azerothcore-wotlk`, коммит `1459af9576eb8bd0a67f38ac54236965b5fe28eb` |
| Скриптовый движок / Script engine | `mod-ale` (ALE) |
| Клиент / Client | WoW 3.3.5a (build 12340) |
| БД / DB | MySQL 8.0 (схемы `acore_world`, `acore_auth`, `acore_characters`; в схеме товаров — `echo_world`) |
| Сборка / Build | CMake ≥ 3.16, MSVC (Windows) / clang | gcc (Linux), Boost ≥ 1.74 |
| CI | GitHub Actions: Linux + Windows build, Windows release артефакт |

---

## 🔐 Учётные данные / Credentials

> По умолчанию в гайдах используется MySQL `root`/пароль. В CI (dry-run)
> серверы запускаются с инфо `root/root`. В продакшене **не используйте**
> пароль `root` — задайте отдельного пользователя БД.

---

## 📚 Основные ссылки / Key links

- 🇷🇺 Подробная документация — [`docs/`](../docs/)
- 🗳️ Миграции — [`sql/README.md`](../sql/README.md)
- 🧩 Lua-скрипты — [`lua_scripts/README.md`](../lua_scripts/README.md)
- 📦 Модули — [`modules/README.md`](../modules/README.md)
- 📋 TODO / Backlog — [`TODO.md`](../TODO.md)