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

# 2. Модули — ВСЕ вендорены в modules/ этого репозитория (echo-*, mod-ale,
#    внешние mod-* — снапшоты без .git). Копируются в ядро одним циклом:
#    (или через scripts/setup-build.sh --no-core)
for d in ../mod-custom-realm/modules/*/; do
  name="$(basename "$d")"
  rm -rf "modules/$name"
  cp -R "$d" "modules/$name"
done

# 3. Проверить: в azerothcore-wotlk/modules/ лежат echo-*, mod-ale и все mod-*.
```

> С 2026-11-13 внешние модули **не клонируются** по SHA: версия фиксируется
> содержимым `modules/` репозитория (вендоринг, коммит `9f95550`). Это касается
> и mod-ale. Обновление модуля = заменить его каталог в `modules/` свежим
> снапшотом и закоммитить. Подробности — [`../modules/README.md`](../modules/README.md).

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
# 0002: realm_campaign_progress → acore_characters:
mysql -u root -p acore_characters < sql/world/0002_campaign_progress.sql
mysql -u root -p acore_world < sql/world/0003_cult_npcs.sql
mysql -u root -p acore_world < sql/world/0004_campaign_reward_item.sql
mysql -u root -p acore_world < sql/world/0005_campaign2_content.sql
mysql -u root -p acore_world < sql/world/0006_campaign3_rewards.sql
mysql -u root -p acore_world < sql/world/0007_campaign3_content.sql
mysql -u root -p acore_world < sql/world/0008_npc_displayid.sql
# 0009: item_template → acore_world, realm_pvp_stats → acore_characters:
mysql -u root -p acore_world < sql/world/0009_event_pvp_world.sql
mysql -u root -p acore_characters < sql/world/0009_event_pvp_characters.sql
mysql -u root -p acore_world < sql/world/0010_pvp_shop.sql
mysql -u root -p acore_world < sql/world/0011_lore_archivist.sql
mysql -u root -p acore_world < sql/world/0012_campaign4_content.sql
# 0013: realm_campaign_log → acore_characters:
mysql -u root -p acore_characters < sql/world/0013_campaign_manager.sql
# 0014: items 70100/70101 → acore_world, realm_level_rewards → acore_characters:
mysql -u root -p acore_world < sql/world/0014_waloria_rewards_world.sql
mysql -u root -p acore_characters < sql/world/0014_waloria_rewards_characters.sql
# 0015: realm_token_outbox + realm_token_receipt → acore_characters:
mysql -u root -p acore_characters < sql/world/0015_token_outbox.sql
# 0016: закомментированный образец DBC-миграции (см. sql/README.md):
# mysql -u root -p acore_world < sql/world/0016_dbc_reference_sample.sql
# 0017: realm_fixgear → acore_characters:
mysql -u root -p acore_characters < sql/world/0017_waloria_tools.sql
# 0018: NPC/items/spell_dbc → acore_world, realm_gold_storage → acore_characters:
mysql -u root -p acore_world < sql/world/0018_eluna_scripts_tier_a_world.sql
mysql -u root -p acore_characters < sql/world/0018_eluna_scripts_tier_a_characters.sql
mysql -u root -p acore_world < sql/world/0019_challenge_modes.sql
mysql -u root -p acore_world < sql/world/0020_store_system.sql
# 0021 — ЗААРХИВИРОВАНА (sql/archive/0021_public_scripts.sql): не применять.
#       Рабочий НПС 70174 и досозд спавна 70170 создаёт 0022.
mysql -u root -p acore_world < sql/world/0022_fix_release_blockers.sql
# 0023: оптимизация схемы (item_template) → acore_world:
mysql -u root -p acore_world < sql/world/0023_echo_schema_alignment.sql
# 0024: NPC → acore_world, realm_lottery{,_tickets} → acore_characters:
mysql -u root -p acore_world < sql/world/0024_tier_b_world.sql
mysql -u root -p acore_characters < sql/world/0024_tier_b_characters.sql
# 0025: character_classless → acore_characters (Classless K5):
mysql -u root -p acore_characters < sql/world/0025_classless.sql
# 0026-0027: realm_store_* → acore_world:
mysql -u root -p acore_world < sql/world/0026_store_expansion.sql
mysql -u root -p acore_world < sql/world/0027_pvp_store.sql
# 0028: random-энчанты → acore_world:
mysql -u root -p acore_world < sql/world/0028_item_enchant_random.sql
# 0029: Parangon (account_parangon + characters_parangon) → acore_characters:
mysql -u root -p acore_characters < sql/world/0029_parangon.sql
# 0030: Classless полная версия (talent col) → acore_characters:
mysql -u root -p acore_characters < sql/world/0030_classless_full.sql
# 0031: GPT-НПС (realm_gpt_queue) → acore_characters:
mysql -u root -p acore_characters < sql/world/0031_gpt_npc.sql
# 0032: Full-Loot PvP (сундук) → acore_world:
mysql -u root -p acore_world < sql/world/0032_pvp_full_loot.sql
# 0033: Сундуки Пустоты (custom_treasure_chest_*) → acore_world:
mysql -u root -p acore_world < sql/world/0033_treasure_chest.sql
# 0034: Ставки на дуэли (duel_bets + duel_bet_stats) → acore_characters:
mysql -u root -p acore_characters < sql/world/0034_duel_bet.sql
# 0035: VIP-система (realm_vip) → acore_characters:
mysql -u root -p acore_characters < sql/world/0035_vip.sql
# 0036: Труппа выступления (НПС 70390—70394) → acore_world:
mysql -u root -p acore_world < sql/world/0036_band_npcs.sql
# 0037: ЦК «Песнь Пустоты» (НПС 70395 + предметы → acore_world;
#       realm_band_quest → acore_characters):
mysql -u root -p acore_world < sql/world/0037_band_quest_world.sql
mysql -u root -p acore_characters < sql/world/0037_band_quest_characters.sql
# 0038: расширение магазина VIP (realm_store_* → acore_world):
mysql -u root -p acore_world < sql/world/0038_store_vip_expansion.sql
# 0039: Classless Hero (alter character_classless) → acore_characters:
mysql -u root -p acore_characters < sql/world/0039_classless_hero.sql
# --- кампании 5–11 и новые системы (0040–0053) ---
mysql -u root -p acore_world < sql/world/0040_dungeon_quest_npc.sql
# 0041: realm_echo_* → acore_characters, НПС 70601–70603 → acore_world:
mysql -u root -p acore_characters < sql/world/0041_echo_worldsoul_characters.sql
mysql -u root -p acore_world < sql/world/0041_echo_worldsoul_world.sql
# 0042: realm_campaign_profile → acore_characters:
mysql -u root -p acore_characters < sql/world/0042_campaign_profile.sql
# 0043: кампании 5–7 → acore_world:
mysql -u root -p acore_world < sql/world/0043_campaigns_5_7.sql
# 0044: ивенты mist/royal → acore_world:
mysql -u root -p acore_world < sql/world/0044_events_mist_royal.sql
# 0045: realm_legacy_score → acore_characters, items/NPC К8 → acore_world:
mysql -u root -p acore_characters < sql/world/0045_legacy_illidan_characters.sql
mysql -u root -p acore_world < sql/world/0045_legacy_illidan_world.sql
# 0046: realm_cursed_score → acore_characters, items/NPC К9 → acore_world:
mysql -u root -p acore_characters < sql/world/0046_cursed_world_characters.sql
mysql -u root -p acore_world < sql/world/0046_cursed_world.sql
# 0047: realm_lightlie_score → acore_characters, items/NPC К10 → acore_world:
mysql -u root -p acore_characters < sql/world/0047_light_lie_characters.sql
mysql -u root -p acore_world < sql/world/0047_light_lie_world.sql
# 0048: фракционные механики + К11 → acore_world:
mysql -u root -p acore_world < sql/world/0048_factions.sql
# 0049: realm_guild_progress → acore_characters:
mysql -u root -p acore_characters < sql/world/0049_guild_progress.sql
# 0050: realm_homes → acore_characters:
mysql -u root -p acore_characters < sql/world/0050_homes.sql
# 0051: realm_social_links + realm_mentor → acore_characters:
mysql -u root -p acore_characters < sql/world/0051_social.sql
# 0052: сезонная валюта 70019–70026 → acore_world, realm_season_state → acore_characters:
mysql -u root -p acore_world < sql/world/0052_season_events_world.sql
mysql -u root -p acore_characters < sql/world/0052_season_events_characters.sql
# 0053: фикс НПС К8 → acore_world:
mysql -u root -p acore_world < sql/world/0053_fix_campaign8_npcs.sql
# 0054: точки телепортов game_tele (карта 5000 + зоны кампаний) → acore_world:
mysql -u root -p acore_world < sql/world/0054_game_tele.sql
# 0055: окружение локаций (мобы/флора/постройки/ресурсы, карта 5000 + 571) → acore_world:
mysql -u root -p acore_world < sql/world/0055_world_env.sql
# 0056: кладбища для стокового воскрешения в новых локациях → acore_world:
mysql -u root -p acore_world < sql/world/0056_graveyards.sql
```

> Все миграции применены строго по порядку. После применения выполните в консоли
> `worldserver`: `.reload creature_template` и `.reload items`.

✓ Миграция `0002` создаёт таблицу `realm_campaign_progress` в
**acore_characters** (скрипты ALE читают её через `CharDBQuery`). Применяется командой
`mysql -u root -p acore_characters < sql/world/0002_campaign_progress.sql`.

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

## 8. ВАЖНО: таблица прогресса кампаний в acore_characters

Скрипты кампаний (`Campaign1/2/3.lua` и `00_CampaignRegistry.ext`) обращаются к
таблице прогресса `realm_campaign_progress` через `CharDBQuery` (characters-БД).
Миграция `0002` применяется именно в `acore_characters`:

```bash
mysql -u root -p acore_characters < sql/world/0002_campaign_progress.sql
```

Таблица `realm_campaign_progress` обязана находиться в **acore_characters** —
иначе скрипты кампаний не прочитают прогресс при входе/выполнении квестов.

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
