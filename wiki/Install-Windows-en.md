# 🪟 Install core with modules — Windows

> **EN.** Full guide to deploying the "Echo of the Void" server on Windows.
> **RU:** см. [Install-Windows.md](Install-Windows.md).

---

## 1. System requirements

| Requirement | Value |
|-------------|-------|
| OS | Windows 10 / 11 (64-bit) |
| CPU | 4 cores |
| RAM | 8 GB (16 recommended) |
| Disk | 40 GB (sources + build + DB + maps/vmaps/mmaps) |
| Software | Visual Studio 2019/2022 (Desktop C++ workload), CMake ≥ 3.16, Git, MySQL 8.0, Boost ≥ 1.74, OpenSSL |
| Client | WoW 3.3.5a (build 12340) — for extracting maps |

---

## 2. Toolchain setup

| Tool | Where | Variable/path |
|------|-------|----------------|
| **Visual Studio 2022** | visualstudio.microsoft.com — "Desktop development with C++" workload | `C:\Program Files\Microsoft Visual Studio\2022\Community` |
| **CMake** | cmake.org → Windows installer | `C:\Program Files\CMake\bin` |
| **Git** | git-scm.com | `C:\Program Files\Git\cmd` |
| **MySQL 8.0** | MySQL Installer → MySQL Server | `C:\Program Files\MySQL\MySQL Server 8.0\bin` |
| **Boost** | sourceforge.net → prebuilt `boost_1_78_0-msvc-14.3-64.exe` | `C:\local\boost_1_78_0` (`BOOST_ROOT`) |
| **OpenSSL** | slproweb.com → Win64 OpenSSL | `C:\Program Files\OpenSSL-Win64` |
| **Python (opt.)** | python.org | `C:\Python315` |

> **Important: Visual Studio C++.** You MUST install the **"Desktop development with
> C++"** component (MSVC + Windows SDK), otherwise CMake cannot find a compiler.
>
> **Boost:** use the **msvc-14.3-64** build matching your MSVC. After install:
> `BOOST_ROOT=C:\local\boost_1_78_0`.

---

## 3. Get the sources

Open **Git Bash** (or cmd) and run:

```bash
# Core pinned at a FIXED commit (not master)
git clone https://github.com/azerothcore/azerothcore-wotlk.git
cd azerothcore-wotlk
git checkout 1459af9576eb8bd0a67f38ac54236965b5fe28eb

# ALE script engine — REQUIRED
git clone https://github.com/azerothcore/mod-ale.git modules/mod-ale
cd modules/mod-ale && git checkout 84b85cc55980dbf67d596f3d5cb34ded10c59102 && cd ../..

# Realm modules from THIS repo (modules/echo-*):
#   copy the modules/echo-* folders into azerothcore-wotlk/modules/
```

> **About mod-ale:** ALE uses AzerothCore internals and is incompatible with other
> revisions. Its version must match the pinned core commit.

---

## 4. Build with CMake

### Option A — CMake GUI (easy)
1. Launch **CMake GUI**.
2. "Where is the source code:" → path to `azerothcore-wotlk`.
3. "Where to build the binaries:" → `azerothcore-wotlk/build`.
4. Configure → choose **Visual Studio 17 2022** (Win64).
5. In variables set:
   - `CMAKE_INSTALL_PREFIX` → `C:\acore`
   - `SCRIPTS` → `static`, `MODULES` → `static`
   - `CMAKE_BUILD_TYPE` → `Release`
6. Generate → open `build/AzerothCore.sln` in Visual Studio.
7. Build the solution (**Build → Build Solution**), configuration **Release**.

### Option B — command line (advanced)
In **Git Bash**:
```bash
cd azerothcore-wotlk
mkdir -p build && cd build
cmake .. -DCMAKE_INSTALL_PREFIX=C:/acore -DSCRIPTS=static -DMODULES=static \
         -DCMAKE_BUILD_TYPE=Release
cmake --build . --config Release -j 8
cmake --install . --config Release
```

> Output goes to `build/bin/Release/` (MSVC) and installs to `CMAKE_INSTALL_PREFIX`
> (`C:/acore`). Binaries: `authserver.exe`, `worldserver.exe`.

---

## 5. Database setup

1. Connect to MySQL (Workbench / cmd):
   ```bash
   "C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe" -u root -p
   ```
2. Create schemas:
   ```sql
   CREATE DATABASE acore_world;
   CREATE DATABASE acore_auth;
   CREATE DATABASE acore_characters;
   ```
3. The core auto-initializes base SQL on first `worldserver` start (assembler),
   or apply the core's base libraries from `data/sql/base/`.

---

## 6. Apply realm migrations

From this repo's root, strictly in order of `sql/world/*.sql`
(full registry/order — in [`../sql/README.md`](../sql/README.md)):

```bash
mysql.exe -u root -p acore_world < sql\\world\\0001_world_baseline.sql
# ... (0002–0025 per sql/README.md)
```

> ⚠️ Some migrations target `acore_characters` (e.g. `0002`, `0013`, `0015`, `0017`,
> `0018`, `0021`, `0024`, `0025`) — see each migration and `sql/README.md`.

---

## 7. Client data (maps/vmaps/mmaps/dbc)

You need a 3.3.5a client. **Before extracting**, install `patch-Z.mpq` into the
client `Data\` folder (custom maps, see [`../docs/client-patch.md`](../docs/client-patch.md) part 6).

From the binary folder:
```bash
cd C:/acore/bin
.\mapextractor.exe --source E:\wow\World of Warcraft 3.3.5a
mkdir maps vmaps mmaps dbc
.\vmap4extractor.exe --source E:\wow\World of Warcraft 3.3.5a
.\vmap4assembler.exe Buildings vmaps
.\mmaps_generator.exe
```

---

## 8. Server configs

```bash
cd C:/acore/bin
copy etc\worldserver.conf.dist worldserver.conf
copy etc\authserver.conf.dist authserver.conf
```

Key `worldserver.conf` parameters (see [Configuration-en.md](Configuration-en.md)):
- `DataDir` → path to `maps/vmaps/mmaps/dbc`;
- `LoginDatabaseInfo` / `WorldDatabaseInfo` / `CharacterDatabaseInfo` →
  `127.0.0.1;3306;root;<password>;acore_auth|world|characters`;
- `EnablePlayerSettings = 1` — **required** for challenge modes (`echo-challenge-modes`).

---

## 9. Lua scripts

ALE (mod-ale) reads `lua_scripts/` next to the binaries (recursively):

```bash
cd C:/acore/bin
rmdir /S /Q lua_scripts & mkdir lua_scripts
xcopy /E /I /Y C:\path\to\azeroth-custom-realm\lua_scripts\* lua_scripts\
```

> Copy the **whole** tree, including the AIO-stack dependency subfolders
> (`queue.lua`, `Dep_*/`, `lualzw-zeros/`) — moving them breaks `require` paths.

---

## 10. Run

```bash
cd C:/acore/bin
start authserver.exe
start worldserver.exe
```

Add a realm to the auth DB:
```sql
USE acore_auth;
INSERT INTO realmlist (name, address, port, icon, realmflags)
VALUES ('Echo of the Void', '127.0.0.1', 8085, 0, 0);
```

In the client: `set realmlist 127.0.0.1`, log in.

---

## 🧪 Smoke test

- [ ] `worldserver` log has no `Could not prepare statements` / `Table ... doesn't exist`
- [ ] `[EchoOfTheVoid] 00_CampaignRegistry.ext loaded …` lines appear
- [ ] Client login works; "WelcomeSystem" greeting shows on enter