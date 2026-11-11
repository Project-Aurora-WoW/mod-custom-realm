# 🧪 Развёртывание — Azeroth: Эхо Пустоты

> Пошаговый гайд развёртывания сервера на базе AzerothCore и применения
> миграций реалма. Гайд предполагает Linux (Ubuntu/Debian); для Windows
> отличия отмечены отдельно.
> Ядро: https://github.com/azerothcore/azerothcore-wotlk.git · Клиент: WoW 3.3.5a (12340)

---

## 1. Системные требования

| Компонент | Минимум |
|-----------|---------|
| ОС | Ubuntu 20.04+ / Debian 11+ (или Windows 10+ с Visual Studio 2019) |
| CPU | 4 ядра |
| RAM | 8 ГБ |
| Диск | 30 ГБ (исходники + сборка + БД + maps/vmaps/mmaps) |
| ПО | git, cmake ≥ 3.16, clang/gcc, MySQL 8.0, boost ≥ 1.74, openssl |

Зависимости (Ubuntu):
```bash
sudo apt update && sudo apt install git cmake make gcc g++ clang libmysqlclient-dev \
  libssl-dev libbz2-dev libreadline-dev libncurses-dev mysql-server libboost-all-dev
```

---

## 2. Получение ядра и модулей

```bash
# 1. Ядро — ФИКСИРОВАННЫЙ КОММИТ, не master.
#    Версия, на которой собраны и проверены модули реалма.
git clone https://github.com/azerothcore/azerothcore-wotlk.git
cd azerothcore-wotlk
git checkout 1459af9576eb8bd0a67f38ac54236965b5fe28eb

# 2. Скриптовый движок ALE — ОБЯЗАТЕЛЬНО.
#    Версия должна соответствовать коммиту ядра: ALE использует
#    внутренние API AzerothCore и несовместим с чужими ревизиями.
#    Указать проверенный коммит mod-ale перед публикацией релиза.
git clone https://github.com/azerothcore/mod-ale.git modules/mod-ale
# cd modules/mod-ale && git checkout <commit-mod-ale>

# 3. Модули реалма из этого репозитория (echo-*):
#    скопировать modules/echo-* в azerothcore-wotlk/modules/
```

Доп. модули по желанию — см. [`../modules/README.md`](../modules/README.md).

---

## 3. Сборка

### Linux
```bash
mkdir build && cd build
cmake .. -DCMAKE_INSTALL_PREFIX=$HOME/acore -DWITH_COREDEBUG=0
make -j$(nproc)
make install
```

### Windows
Открыть `build` через CMake GUI → генерация для Visual Studio → собрать
конфигурацию Release (mod-ale подхватится автоматически модульной системой AzerothCore).

Бинарники: `worldserver`, `authserver` (bin/ или env/dist/bin).

---

## 4. Клиентские данные (maps, dbc и т.д.)

Нужен клиент 3.3.5a (build 12340). Из него извлекаются карты.

⚠️ **Кастомные карты (patch-Z)**: перед извлечением установить в `Data\`
клиента патч `patch-Z.mpq` (см. [`client-patch.md`](client-patch.md),
Часть 6) — иначе экстракторы не увидят карту **5000** (Остров Морза,
Долина Предательства): на неё нельзя будет телепортироваться, мобы будут
проваливаться под текстуры, навмэши для зоны не построятся.

```bash
cd $HOME/acore/bin
./mapextractor --source <путь/к/клиенту>   # клиент С установленным patch-Z.mpq
mkdir -p maps vmaps mmaps dbc
./vmap4extractor --source <путь/к/клиенту>
./vmap4assembler Buildings vmaps
./mmaps_generator
```

Пути к данным прописываются в конфигах (шаг 6).

---

## 5. Базы данных

### 5.1. Создание схем и загрузка ядра

```bash
mysql -u root -p
```
```sql
CREATE DATABASE acore_world;
CREATE DATABASE acore_auth;
CREATE DATABASE acore_characters;
```

Ядро AzerothCore поставляет автоинициализацию: при первом запуске
`worldserver` сам накатывает базовые SQL ядра (assembler). Альтернатива —
библиотеки миграций из репозитория ядра (`data/sql/base/db_world/` и др.).

### 5.2. Применение миграций реалма (строго по порядку!)

```bash
cd <путь/к>/azeroth-custom-realm
mysql -u root -p acore_world < sql/world/0001_world_baseline.sql
mysql -u root -p acore_world < sql/world/0002_campaign_progress.sql
mysql -u root -p acore_world < sql/world/0003_cult_npcs.sql
mysql -u root -p acore_world < sql/world/0004_campaign_reward_item.sql
mysql -u root -p acore_world < sql/world/0005_campaign2_content.sql
mysql -u root -p acore_world < sql/world/0006_campaign3_rewards.sql
mysql -u root -p acore_world < sql/world/0007_campaign3_content.sql
mysql -u root -p acore_world < sql/world/0008_npc_displayid.sql
# 0009: item_template → acore_world, realm_pvp_stats → acore_characters:
mysql -u root -p acore_world < sql/world/0009_event_pvp.sql
mysql -u root -p acore_characters < sql/world/0009_event_pvp.sql
mysql -u root -p acore_world < sql/world/0010_pvp_shop.sql
mysql -u root -p acore_world < sql/world/0011_lore_archivist.sql
mysql -u root -p acore_world < sql/world/0012_campaign4_content.sql
# 0013: realm_campaign_log → acore_characters:
mysql -u root -p acore_characters < sql/world/0013_campaign_manager.sql
# 0014: items 70100/70101 → acore_world, realm_level_rewards → acore_characters:
mysql -u root -p acore_world < sql/world/0014_waloria_rewards.sql
mysql -u root -p acore_characters < sql/world/0014_waloria_rewards.sql
# 0015: realm_token_outbox + realm_token_receipt → acore_characters:
mysql -u root -p acore_characters < sql/world/0015_token_outbox.sql
# 0016: закомментированный образец DBC-миграции (см. sql/README.md):
# mysql -u root -p acore_world < sql/world/0016_dbc_reference_sample.sql
# 0017: realm_fixgear → acore_characters:
mysql -u root -p acore_characters < sql/world/0017_waloria_tools.sql
# 0018: NPC/items/spell_dbc → acore_world, realm_gold_storage → acore_characters:
mysql -u root -p acore_world < sql/world/0018_eluna_scripts_tier_a.sql
mysql -u root -p acore_characters < sql/world/0018_eluna_scripts_tier_a.sql
mysql -u root -p acore_world < sql/world/0019_challenge_modes.sql
mysql -u root -p acore_world < sql/world/0020_store_system.sql
# 0021: realm_played_time_rewards{,_claimed} → acore_characters,
#       НПС 70174 «Страж Перемен» → acore_world:
mysql -u root -p acore_characters < sql/world/0021_public_scripts.sql
mysql -u root -p acore_world < sql/world/0021_public_scripts.sql
```

⚠️ `0002` создаёт таблицу `realm_campaign_progress` в **world**-БД.
Скрипты ALE читают её через `WorldDBQuery`, а не `CharDBQuery`,
если вы выбрали world-вариант. См. примечание в шаге 8.

---

## 6. Конфигурация

Скопировать дистрибутивные конфиги и отредактировать:

```bash
cp $HOME/acore/bin/env/dist/etc/worldserver.conf.dist $HOME/acore/bin/etc/worldserver.conf
cp $HOME/acore/bin/env/dist/etc/authserver.conf.dist $HOME/acore/bin/etc/authserver.conf
```

Ключевые параметры `worldserver.conf`:

| Параметр | Значение |
|----------|----------|
| `DataDir` | путь к `maps/vmaps/mmaps/dbc` |
| `LoginDatabaseInfo` / `WorldDatabaseInfo` / `CharacterDatabaseInfo` | `127.0.0.1;3306;root;<пароль>;acore_auth / acore_world / acore_characters` |
| `CampaignProgress` (нет в ядре) | — таблица берётся напрямую скриптами |
| `EnablePlayerSettings` | **`1`** — обязательно: режимы испытаний (echo-challenge-modes) хранят включённые режимы в player settings characters-БД; при 0 модуль не работает |

`authserver.conf`: `LoginDatabaseInfo` → `acore_auth`.

> Режимы испытаний (echo-challenge-modes): настройки режимов —
> `etc/echo-challenge-modes.conf` (копия `.dist` создаётся автоматически
> при сборке; там же награды за уровни — титулы/таланты/предметы/ачивки).
> Алтарь Испытаний — GO 705605 (миграция `0019_challenge_modes.sql`).

### Реалм в БД auth

```sql
USE acore_auth;
INSERT INTO realmlist (name, address, port, icon, realmflags)
VALUES ('Эхо Пустоты', '127.0.0.1', 8085, 0, 0);
```

---

## 7. Lua-скрипты

```bash
# ALE строит require-пути рекурсивно — копировать весь каталог целиком:
rm -rf $HOME/acore/bin/lua_scripts
mkdir -p $HOME/acore/bin/lua_scripts
cp -r <путь/к>/azeroth-custom-realm/lua_scripts/. $HOME/acore/bin/lua_scripts/
```

Порядок загрузки ALE: все `*.ext` грузятся **до** всех `*.lua`. Файлы `.ext`:

| Файл | Роль |
|------|------|
| `00_CampaignRegistry.ext` | Реестр кампаний (гарантированно первым) |
| `extensions/_Misc.ext` | randomseed + включение StackTracePlus |
| `extensions/StackTracePlus/StackTracePlus.ext` | Подробный traceback при ошибках Lua-скриптов |

Среди `.lua` сначала грузится **AIO-стек** (`AIO.lua` + зависимости
`queue.lua`, `Dep_Smallfolk/`, `Dep_crc32lua/`, `Dep_LuaSrcDiet/`,
`lualzw-zeros/` — путь в `require` совпадает со структурой каталогов,
перемещать файлы нельзя), затем `Store_*.lua` (AIO-магазин).

- Без `AIO.lua` скрипты магазина (`Store_*.lua`) автоматически отключаются
  с сообщением в логе. Таблицы магазина — миграция `0020_store_system.sql`.
- Клиентская часть AIO — аддон **AIO_Client** в patch-x
  (см. [`client-patch.md`](client-patch.md), ч. 8).
- ⚠️ **Отладка и `AIO_CODE_OBFUSCATE`**: в шапке `AIO.lua` есть флаг
  `AIO_CODE_OBFUSCATE` — при `true` клиентский код минифицируется
  (LuaSrcDiet), что ломает номера строк в трейсбеках и затрудняет поиск
  ошибок в `Store_Client.lua`/аддонах. **При отладке ставьте `false`**
  (или временно закомментируйте включение obfuscate), в проде — `true`.
- Ошибки всех Lua-скриптов (не только AIO) печатаются с подробным
  traceback (StackTracePlus через `_Misc.ext`) — используйте их при
  диагностике вместо голых сообщений.

---

## 8. ВАЖНО: расхождение CharDB/WorldDB в скриптах кампаний

Скрипты кампаний (`Campaign1/2/3.lua`) обращаются к таблице прогресса через
`CharDBQuery` (characters-БД), а миграция `0002` создаёт таблицу в **world**-БД.

**Два варианта решения (выбрать один до запуска):**

- **Вариант A (рекомендуемый)**: применить `0002_campaign_progress.sql` в
  `acore_characters` вместо `acore_world`:
  ```bash
  mysql -u root -p acore_characters < sql/world/0002_campaign_progress.sql
  ```
- **Вариант B**: заменить в `Campaign1/2/3.lua` все `CharDBQuery` на
  `WorldDBQuery` (таблица остаётся в world-БД).

---

## 9. Запуск и smoke-тест

```bash
cd $HOME/acore/bin
./authserver &
./worldserver
```

**Smoke-чек-лист при старте `worldserver`:**

- [ ] В логе нет ошибок `Could not prepare statements` / `Table ... doesn't exist`
- [ ] Миграции применились: `SELECT COUNT(*) FROM acore_world.creature_template WHERE entry BETWEEN 70001 AND 70599;` → ≥ 15
- [ ] Появились строки загрузки ALE:
  ```
  [EchoOfTheVoid] 00_CampaignRegistry.ext загружен (реестр кампаний: 4 кампании).
  [EchoOfTheVoid] WelcomeSystem.lua загружен.
  [EchoOfTheVoid] PortalGuardian.lua загружен (НПС 70001).
  [EchoOfTheVoid] Campaign1.lua загружен (НПС 70100/70110/70120).
  [EchoOfTheVoid] Campaign2.lua загружен (кампания 2, главы 1–5).
  [EchoOfTheVoid] Campaign3.lua загружен (кампания 3, главы 1–4, рейд-босс 70510).
  [EchoOfTheVoid] AddonBridge.lua загружен (аддон AzerothEcho).
  ```
- [ ] Логин клиентом 3.3.5a (реалм-лист: `set realmlist 127.0.0.1`), создание персонажа
- [ ] При входе — приветствие WelcomeSystem в чате
- [ ] `.go creature 7000101` — виден Портальный Страж в Штормграде

Дальнейшее тестирование — по плану [`testing-plan.md`](testing-plan.md).
