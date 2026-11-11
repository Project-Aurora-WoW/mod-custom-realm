# 🐧 Install core with modules — Ubuntu/Debian

> **EN.** Full guide to deploying the "Echo of the Void" server on Ubuntu/Debian.
> **RU:** см. [Install-Ubuntu.md](Install-Ubuntu.md).

---

## 1. System requirements

| Requirement | Value |
|-------------|-------|
| OS | Ubuntu 20.04+ / Debian 11+ |
| CPU | 4 cores |
| RAM | 8 GB (16 recommended) |
| Disk | 40 GB |
| Software | git, cmake ≥ 3.16, clang/gcc, MySQL 8.0, boost ≥ 1.74, openssl, zlib, libmysqlclient |

---

## 2. Install dependencies

```bash
sudo apt update
sudo apt install -y git cmake make gcc g++ clang \
  libmysqlclient-dev libssl-dev libbz2-dev libreadline-dev libncurses-dev \
  mysql-server libboost-all-dev zlib1g-dev unzip
```

---

## 3. Get the sources

```bash
# Core pinned at a FIXED commit (not master)
git clone https://github.com/azerothcore/azerothcore-wotlk.git
cd azerothcore-wotlk
git checkout 1459af9576eb8bd0a67f38ac54236965b5fe28eb

# ALE script engine — REQUIRED
git clone https://github.com/azerothcore/mod-ale.git modules/mod-ale
cd modules/mod-ale && git checkout 84b85cc55980dbf67d596f3d5cb34ded10c59102 && cd ../..

# Realm modules from THIS repo: copy modules/echo-* into ./modules/
```

> **Optional automation:** [`../scripts/setup-build.sh`](../scripts/setup-build.sh)
> automates core + modules cloning (incl. the custom `echo-*`) and build:
> ```bash
> ./scripts/setup-build.sh            # full cycle: core + modules + build
> ./scripts/setup-build.sh --no-core  # core already present — only modules + build
> ```

---

## 4. Build

```bash
cd azerothcore-wotlk
mkdir build && cd build
cmake .. -DCMAKE_INSTALL_PREFIX="$HOME/acore" -DSCRIPTS=static -DMODULES=static -DCMAKE_BUILD_TYPE=Release
make -j"$(nproc)"
make install
```

> Result: `$HOME/acore/bin/{authserver,worldserver}`.

---

## 5. Database setup

```bash
sudo systemctl start mysql
sudo mysql -u root -p
```
```sql
CREATE DATABASE acore_world;
CREATE DATABASE acore_auth;
CREATE DATABASE acore_characters;
```

> The core auto-initializes base SQL on first `worldserver` start (assembler).

---

## 6. Realm migrations

Strictly in order of `sql/world/*.sql` (full registry — [`../sql/README.md`](../sql/README.md)):

```bash
cd /path/to/azeroth-custom-realm
mysql -u root -p acore_world < sql/world/0001_world_baseline.sql
# ... (0002–0025 per sql/README.md; some target acore_characters)
```

> ⚠️ Some migrations target `acore_characters` (e.g. `0002`, `0013`, `0015`, `0017`,
> `0018`, `0021`, `0024`, `0025`) — see each migration and `sql/README.md`.

---

## 7. Client data

Install `patch-Z.mpq` into the client `Data\` folder before extracting (custom maps,
see [`../docs/client-patch.md`](../docs/client-patch.md) part 6).

```bash
cd "$HOME/acore/bin"
./mapextractor --source /path/to/client/World\ of\ Warcraft   # client WITH patch-Z.mpq
mkdir -p maps vmaps mmaps dbc
./vmap4extractor --source /path/to/client
./vmap4assembler Buildings vmaps
./mmaps_generator
```

---

## 8. Configs

```bash
cd "$HOME/acore/bin"
cp etc/worldserver.conf.dist worldserver.conf
cp etc/authserver.conf.dist authserver.conf
```

Key `worldserver.conf` parameters (see [Configuration-en.md](Configuration-en.md)):
- `DataDir`; `LoginDatabaseInfo`/`WorldDatabaseInfo`/`CharacterDatabaseInfo`;
- `EnablePlayerSettings = 1` — **required** for challenge modes.

---

## 9. Lua scripts

```bash
cd "$HOME/acore/bin"
rm -rf lua_scripts && mkdir -p lua_scripts
cp -r /path/to/azeroth-custom-realm/lua_scripts/. lua_scripts/
```

> Copy the **whole** tree (including AIO-stack subfolders).

---

## 10. Run

```bash
cd "$HOME/acore/bin"
./authserver &
./worldserver
```

Realm in auth DB:
```sql
USE acore_auth;
INSERT INTO realmlist (name, address, port, icon, realmflags)
VALUES ('Echo of the Void', '127.0.0.1', 8085, 0, 0);
```

---

## 🐧 Handy Linux commands

| Action | Command |
|--------|---------|
| Update core sources | `cd azerothcore-wotlk && git pull && git checkout <commit>` |
| Rebuild | `cd build && cmake --build . -j"$(nproc)"` |
| Clean build | `cd build && cmake --build . --target clean && rm -rf CMakeCache.txt` |
| Run worldserver in background | `nohup ./worldserver > world.log 2>&1 &` |
| Follow log | `tail -f world.log` |
| Check processes | `pgrep -a worldserver` |
| Stop | `pkill worldserver` |
| Check port 8085 | `ss -tlnp \| grep 8085` |
| DB backup | `mysqldump -u root -p acore_characters > chars.sql` |
| Apply a migration | `mysql -u root -p acore_world < sql/world/0001_world_baseline.sql` |
| Restart MySQL | `sudo systemctl restart mysql` |

---

## 🧪 Smoke test

- [ ] log has no `Table ... doesn't exist`;
- [ ] `[EchoOfTheVoid] 00_CampaignRegistry.ext loaded …` lines appear;
- [ ] client login works and WelcomeSystem greeting shows.