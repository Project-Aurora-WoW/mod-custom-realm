# 🧰 Required software / Необходимый софт

> **EN:** A catalog of software needed to build, deploy and run the
> "Echo of the Void" server on AzerothCore. For each tool — what it is,
> why it is needed and where to download it.
>
> **RU:** Каталог программ, нужных для сборки, развёртывания и работы
> сервера «Эхо Пустоты» на базе AzerothCore. Для каждого инструмента —
> что это, зачем и где скачать.

---

## 1️⃣ Build toolchain / Обязательные инструменты

### Core & engines / Ядро и движки

| Software | Purpose / Назначение | Link / Ссылка |
|----------|----------------------|---------------|
| **AzerothCore** | WoW 3.3.5a server core (realm base) | [github.com/azerothcore/azerothcore-wotlk](https://github.com/azerothcore/azerothcore-wotlk.git) |
| **mod-ale** | ALE Lua engine (Eluna fork) — runs `lua_scripts/` | [github.com/azerothcore/mod-ale](https://github.com/azerothcore/mod-ale) |
| **WoW 3.3.5a client** | Game client (build 12340), used to extract maps | (Blizzard license — from your distribution) |

### Compilers & build systems / Компиляторы и системы сборки

| Software | Platform / ОС | Link / Ссылка |
|----------|--------------|---------------|
| **Visual Studio 2022** ("Desktop C++" workload) | Windows | [visualstudio.microsoft.com](https://visualstudio.microsoft.com/downloads/) |
| **CMake** (≥ 3.16) | Windows/Linux | [cmake.org](https://cmake.org/download/) |
| **Git** | Windows/Linux | [git-scm.com](https://git-scm.com/downloads) |
| **clang / gcc** | Linux (Ubuntu) | apt packages: `clang`, `gcc`, `g++`, `build-essential` |

### Libraries / Библиотеки

| Software | Purpose / Назначение | Link / Ссылка |
|----------|----------------------|---------------|
| **Boost** (≥ 1.74) | Core C++ libraries. Windows: `msvc-14.3-64` build | [sourceforge.net — boost-binaries](https://sourceforge.net/projects/boost/files/boost-binaries/) |
| **OpenSSL** | Crypto (login/connections). Windows | [slproweb.com/products/Win32OpenSSL](http://slproweb.com/products/Win32OpenSSL.html) |
| **MySQL 8.0** | Server database (`acore_*` schemas) | [dev.mysql.com/downloads/installer](https://dev.mysql.com/downloads/installer/) |
| **zlib / libbz2 / libreadline** | Build dependencies (Linux) | apt packages: `zlib1g-dev`, `libbz2-dev`, `libreadline-dev` |

---

## 2️⃣ Client data & editors / Клиентские данные и редакторы

| Software | Purpose / Назначение | Link / Ссылка |
|----------|----------------------|---------------|
| **ac-data** | Ready DBC data for the server (dry-run/run) | [github.com/ac-data/ac-data](https://github.com/ac-data/ac-data) |
| **Ladik's MPQ Editor** | Build/edit MPQ (patch-x/patch-Z) | [Ladik's MPQ Editor](http://www.zezula.net/en/mpq/mpqtools.html) |
| **WDBX Editor** | Edit DBC files (maps, spells) | [github.com/WDBXEditor/WDBX](https://github.com/WDBXEditor/WDBX) |
| **MySQL Workbench** | GUI DB client (optional) | [dev.mysql.com/downloads/workbench](https://dev.mysql.com/downloads/workbench/) |
| **HeidiSQL** | Lightweight DB client (alternative) | [heidisql.com](https://www.heidisql.com/download.php) |

---

## 3️⃣ Optional & tooling / Дополнительно

| Software | Purpose / Назначение | Link / Ссылка |
|----------|----------------------|---------------|
| **Python 3** | Project tools/scripts, CI | [python.org/downloads](https://www.python.org/downloads/) |
| **GitHub Desktop** | Git GUI (optional) | [desktop.github.com](https://desktop.github.com/) |
| **7-Zip** | Unpack Boost/MySQL archives | [7-zip.org](https://www.7-zip.org/) |
| **WinRAR** | Handle .rar (patch base) | [rarlab.com](https://www.rarlab.com/download.htm) |
| **Docker** (optional) | Run MySQL/tools in containers | [docker.com](https://www.docker.com/products/docker-desktop/) |

---

## 🔗 Related pages / Связанные страницы

- 🪟 [Install on Windows](Install-Windows-en.md) · [Установка на Windows](Install-Windows.md)
- 🐧 [Install on Ubuntu](Install-Ubuntu-en.md) · [Установка на Ubuntu](Install-Ubuntu.md)
- ⚙️ [Configuration](Configuration-en.md) · [Конфигурация](Configuration.md)