# 🧰 Необходимый софт / Required software

> **RU:** Каталог программ, нужных для сборки, развёртывания и работы
> сервера «Эхо Пустоты» на базе AzerothCore. Для каждого инструмента —
> что это, зачем и где скачать.
>
> **EN:** A catalog of software needed to build, deploy and run the
> "Echo of the Void" server on AzerothCore. For each tool — what it is,
> why it is needed and where to download it.

---

## 1️⃣ Обязательные инструменты / Build toolchain

### Ядро и движки / Core & engines

| Софт | Назначение / Purpose | Ссылка / Link |
|------|----------------------|---------------|
| **AzerothCore** | Ядро сервера WoW 3.3.5a (основа реалма) | [github.com/azerothcore/azerothcore-wotlk](https://github.com/azerothcore/azerothcore-wotlk.git) |
| **mod-ale** | Lua-движок ALE (форк Eluna) — исполняет `lua_scripts/` | [github.com/azerothcore/mod-ale](https://github.com/azerothcore/mod-ale) |
| **Клиент WoW 3.3.5a** | Игровой клиент (build 12340), из него извлекаются карты | (лицензия Blizzard — из вашего дистрибутива) |

### Компиляторы и системы сборки / Compilers & build systems

| Софт | ОС / Platform | Ссылка / Link |
|------|--------------|---------------|
| **Visual Studio 2022** (workload «C++») | Windows | [visualstudio.microsoft.com](https://visualstudio.microsoft.com/downloads/) |
| **CMake** (≥ 3.16) | Windows/Linux | [cmake.org](https://cmake.org/download/) |
| **Git** | Windows/Linux | [git-scm.com](https://git-scm.com/downloads) |
| **clang / gcc** | Linux (Ubuntu) | пакеты из apt: `clang`, `gcc`, `g++`, `build-essential` |

### Библиотеки / Libraries

| Софт | Назначение / Purpose | Ссылка / Link |
|------|----------------------|---------------|
| **Boost** (≥ 1.74) | C++-библиотеки ядра. Windows: сборка `msvc-14.3-64` | [sourceforge.net — boost-binaries](https://sourceforge.net/projects/boost/files/boost-binaries/) |
| **OpenSSL** | Криптография (логин/соединения). Windows | [slproweb.com/products/Win32OpenSSL](http://slproweb.com/products/Win32OpenSSL.html) |
| **MySQL 8.0** | База данных сервера (схемы `acore_*`) | [dev.mysql.com/downloads/installer](https://dev.mysql.com/downloads/installer/) |
| **zlib / libbz2 / libreadline** | Зависимости сборки (Linux) | пакеты apt: `zlib1g-dev`, `libbz2-dev`, `libreadline-dev` |

---

## 2️⃣ Клиентские данные и редакторы / Client data & editors

| Софт | Назначение / Purpose | Ссылка / Link |
|------|----------------------|---------------|
| **ac-data** | Готовые DBC-данные для сервера (dry-run/запуск) | [github.com/ac-data/ac-data](https://github.com/ac-data/ac-data) |
| **Ladik's MPQ Editor** | Сборка/редактирование MPQ (patch-x/patch-Z) | [Ladik's MPQ Editor (forum/зеркала)](http://www.zezula.net/en/mpq/mpqtools.html) |
| **WDBX Editor** | Редактирование DBC-файлов (карты, спеллы) | [github.com/WDBXEditor/WDBX](https://github.com/WDBXEditor/WDBX) |
| **MySQL Workbench** | Графический клиент БД (опционально) | [dev.mysql.com/downloads/workbench](https://dev.mysql.com/downloads/workbench/) |
| **HeidiSQL** | Лёгкий клиент БД (альтернатива) | [heidisql.com](https://www.heidisql.com/download.php) |

---

## 3️⃣ Дополнительно / Optional & tooling

| Софт | Назначение / Purpose | Ссылка / Link |
|------|----------------------|---------------|
| **Python 3** | Инструменты/скрипты проекта, CI | [python.org/downloads](https://www.python.org/downloads/) |
| **GitHub Desktop** | GUI для git (опционально) | [desktop.github.com](https://desktop.github.com/) |
| **7-Zip** | Распаковка архивов Boost/MySQL | [7-zip.org](https://www.7-zip.org/) |
| **WinRAR** | Обработка .rar (база patch) | [rarlab.com](https://www.rarlab.com/download.htm) |
| **Docker** (опц.) | Запуск MySQL/инструментов в контейнере | [docker.com](https://www.docker.com/products/docker-desktop/) |

---

## 🔗 Связанные страницы / Related pages

- 🪟 [Установка на Windows](Install-Windows.md) · [Windows (EN)](Install-Windows-en.md)
- 🐧 [Установка на Ubuntu](Install-Ubuntu.md) · [Ubuntu (EN)](Install-Ubuntu-en.md)
- ⚙️ [Конфигурация](Configuration.md) · [Configuration (EN)](Configuration-en.md)