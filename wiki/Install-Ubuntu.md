# 🐧 Установка ядра с модулями — Ubuntu/Debian

> **RU.** Полный гайд развёртывания сервера «Эхо Пустоты» на Ubuntu/Debian.
> **EN:** see [Install-Ubuntu-en.md](Install-Ubuntu-en.md).

---

## 1. Системные требования / System requirements

| Требование | Значение |
|-----------|----------|
| ОС | Ubuntu 20.04+ / Debian 11+ |
| CPU | 4 ядра |
| RAM | 8 ГБ (рекомендуется 16) |
| Диск | 40 ГБ |
| Софт | git, cmake ≥ 3.16, clang/gcc, MySQL 8.0, boost ≥ 1.74, openssl, zlib, libmysqlclient |

---

## 2. Установка зависимостей / Installing dependencies

```bash
sudo apt update
sudo apt install -y git cmake make gcc g++ clang \
  libmysqlclient-dev libssl-dev libbz2-dev libreadline-dev libncurses-dev \
  mysql-server libboost-all-dev zlib1g-dev unzip
```

> Для извлечения карт дополнительно понадобится клиент 3.3.5a (локально или
> по сети). Для сборки достаточно зависимостей выше.

---

## 3. Получение исходников / Getting the sources

```bash
# Ядро — ФИКСИРОВАННЫЙ коммит (не master)
git clone https://github.com/azerothcore/azerothcore-wotlk.git
cd azerothcore-wotlk
git checkout 1459af9576eb8bd0a67f38ac54236965b5fe28eb

# Скриптовый движок ALE — ВЕНДОРЕН в modules/ репо (не клонируется)

# Все модули реалма (echo-*, mod-ale, внешние mod-*) — в modules/ ЭТОГО репозитория.
# Скопировать ВСЕ модули в ядро:
for d in ../mod-custom-realm/modules/*/; do
  name="$(basename "$d")"
  rm -rf "modules/$name"
  cp -R "$d" "modules/$name"
done
```

> **Ускорение (опционально):** скрипт [`../scripts/setup-build.sh`](../scripts/setup-build.sh)
> автоматизирует клонирование ядра + раскладку модулей (все из `modules/`) и сборку:
> ```bash
> ./scripts/setup-build.sh          # полный цикл: ядро + все модули + сборка
> ./scripts/setup-build.sh --no-core  # ядро уже есть — только модули + сборка
> ```

---

## 4. Сборка / Building

```bash
cd azerothcore-wotlk
mkdir build && cd build
cmake .. -DCMAKE_INSTALL_PREFIX="$HOME/acore" -DSCRIPTS=static -DMODULES=static -DCMAKE_BUILD_TYPE=Release
make -j"$(nproc)"
make install
```

> Результат: `$HOME/acore/bin/{authserver,worldserver}`.

---

## 5. Базы данных / Database setup

```bash
sudo systemctl start mysql
sudo mysql -u root -p
```
```sql
CREATE DATABASE acore_world;
CREATE DATABASE acore_auth;
CREATE DATABASE acore_characters;
```

> Ядро само накатывает базовые SQL при первом старте `worldserver` (assembler).

---

## 6. Применение миграций реалма / Realm migrations

Строго по порядку `sql/world/*.sql` (полный реестр — [`../sql/README.md`](../sql/README.md)):

```bash
cd /путь/к/azeroth-custom-realm
mysql -u root -p acore_world < sql/world/0001_world_baseline.sql
# ... (0002–0025 по sql/README.md; часть — в acore_characters)
```

> ⚠️ Несколько миграций пишут в `acore_characters` (например `0002`, `0013`, `0015`,
> `0017`, `0018`, `0021`, `0024`, `0025`) — смотрите каждую миграцию и `sql/README.md`.

---

## 7. Клиентские данные / Client data

Перед извлечением установить `patch-Z.mpq` в `Data\` клиента (кастомные карты,
см. [`../docs/client-patch.md`](../docs/client-patch.md) ч. 6).

```bash
cd "$HOME/acore/bin"
./mapextractor --source /путь/к/клиенту/World\ of\ Warcraft   # клиент С patch-Z.mpq
mkdir -p maps vmaps mmaps dbc
./vmap4extractor --source /путь/к/клиенту
./vmap4assembler Buildings vmaps
./mmaps_generator
```

---

## 8. Конфиги / Configs

```bash
cd "$HOME/acore/bin"
cp etc/worldserver.conf.dist worldserver.conf
cp etc/authserver.conf.dist authserver.conf
```

Ключевые параметры `worldserver.conf` (см. [Configuration.md](Configuration.md)):
- `DataDir`; `LoginDatabaseInfo`/`WorldDatabaseInfo`/`CharacterDatabaseInfo`;
- `EnablePlayerSettings = 1` — **обязательно** для режимов испытаний.

---

## 9. Lua-скрипты / Lua scripts

```bash
cd "$HOME/acore/bin"
rm -rf lua_scripts && mkdir -p lua_scripts
cp -r /путь/к/azeroth-custom-realm/lua_scripts/. lua_scripts/
```

> Копировать **целиком** (включая подкаталоги AIO-стека).

---

## 10. Запуск / Running

```bash
cd "$HOME/acore/bin"
./authserver &        # демонизировать или через systemd
./worldserver
```

Реалм в auth-БД:
```sql
USE acore_auth;
INSERT INTO realmlist (name, address, port, icon, realmflags)
VALUES ('Эхо Пустоты', '127.0.0.1', 8085, 0, 0);
```

---

## 🐧 Полезные команды Linux / Handy Linux commands

| Действие | Команда |
|----------|---------|
| Обновить исходники ядра | `cd azerothcore-wotlk && git pull && git checkout <commit>` |
| Пересобрать | `cd build && cmake --build . -j"$(nproc)"` |
| Очистить сборку | `cd build && cmake --build . --target clean && rm -rf CMakeCache.txt` |
| Запустить мир-сервер в фоне | `nohup ./worldserver > world.log 2>&1 &` |
| Смотреть лог | `tail -f world.log` |
| Проверить процессы | `pgrep -a worldserver` |
| Остановить | `pkill worldserver` |
| Снятие дампа порта | `ss -tlnp \| grep 8085` |
| Бэкап БД | `mysqldump -u root -p acore_characters > chars.sql` |
| Применить миграцию | `mysql -u root -p acore_world < sql/world/0001_world_baseline.sql` |
| Перезапуск MySQL | `sudo systemctl restart mysql` |

---

## 🧪 Smoke-тест / Smoke test

- [ ] лог без `Table ... doesn't exist`;
- [ ] строки `[EchoOfTheVoid] 00_CampaignRegistry.ext загружен …`;
- [ ] логин клиентом и приветствие WelcomeSystem.