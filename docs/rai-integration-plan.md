# RAI (Roaming Adventurer Incursions) — интеграционный план

> Статус: **план, реализация НЕ начата** (2026-11-20).
> Модуль из `WaloriaOld/scripts/RAI`, порт на контур реалма «Эхо Пустоты»
> (mod-ale + SQL-миграции + клиентский patch-x). Крупный отдельный этап.

## 1. Что делает модуль

«Странствующие искатели приключений» (Roaming Adventurer Incursions): на
картах реалма в свободных зонах спавнятся патрули/паки существ
выбранного-по-зоне уровня, с фазами боя (меняются по проценту здоровья),
групповым ИИ (лидер, следование, патрулирование) и кастомными спеллами
«уровней приключений» из своего Spell.dbc (Patch-T.MPQ).

## 2. Инвентаризация исходников

| Файл в `WaloriaOld/scripts/RAI/` | Назначение | В mod-ale? |
|-----------------------------------|-----------|-----------|
| `raiserver.lua` (184 стр) | точка входа: хуки спавна/боя/смерти, командная система `.rai …` | да, события 5/1/2/9/4/24 |
| `raicombat.lua` | боевой AI, кастинг фаз | да |
| `raiencounter.lua` | фазы энкаунтера по здоровью | да |
| `railogic.lua` | регистрация фаз | да |
| `raicreature.lua` | аур/вид/экипировка «искателя» | частично |
| `raigroup.lua` | групповой AI (лидер/фолловер) | да |
| `raispawner.lua` | `PerformIngameSpawn`, патрули/паки | yes (`PerformIngameSpawn`) |
| `raicreaturepicker.lua` | подбор entry 100000+level по зоне (`rai_zone_level`) | да |
| `raicommands.lua` | GM-команды добавления спавнов | да |
| `raidbhelper.lua` / `raitablehelper.lua` | работа с БД RAI | да (WorldDBQuery) |
| `raispellpicker.lua` | выбор кастомных спеллов | да |
| `raitargets.lua` | выбор целей | да |
| `raigenerator.lua` / `raiphase.lua` / `raicommands` | генераторы/фазы | да |
| `eluna.cpp` (3 метода) | `CastSpellRAI`, `PatrolArea`, `ReInitialize` | **НЕТ** — C++-патч Eluna |
| `randommovementgenerator.cpp/h` | патченный случайный movement для существ | **НЕТ** — патч ядра |
| `rai.sql` (139 КБ) | таблицы `rai_spawns`, `rai_line_spawns`, `rai_line_moveto`, `rai_zone_level`, `rai_creature` + дубли SpellAIO-таблиц | мигрировать |
| `Patch-T.MPQ.rar` (7.3 МБ) | Spell.dbc кастомных спеллов «уровней приключений» | разобрать |

**Важно:** `rai.sql` содержит И дубли уже адаптированных SpellAIO-таблиц
(`custom_spell_system*`, → наши `realm_custom_spell_*` из 0058–0061), И
собственные `rai_*`. При порте брать только `rai_*` (SpellAIO уже сделан).

## 3. Аудит совместимости с mod-ale (результат)

Почти весь Lua-API, используемый RAI, в mod-ale **есть**:
`RegisterCreatureEvent`, `RegisterPlayerEvent`, `RegisterEvent`/`RemoveEvents`
(WorldObject), `CreateLuaEvent`, `PerformIngameSpawn`, `SpawnCreature`,
`MoveRandom`, `MoveFollow`, `SetFaction`, `SetDefaultMovementType`,
`GetHealthPct`, `SetDisplayId`, `SendUnitYell`, `ClearUnitState`,
`GetMapId`/`GetZoneId`/`GetAreaId`, `GetX/Y/Z/O`, `WorldDBQuery`/`CharDBQuery`,
`SetData`/`GetData` (через `ObjectVariables.ext`), `CastSpell`.

Отсутствуют / требуют адаптации:
1. **`eluna.cpp` C++-методы** (`CastSpellRAI`, `PatrolArea`, `ReInitialize`) —
   это добавленные в Eluna юнит-методы. В mod-ale их нет. Необходимо либо:
   - эквивалент на Lua (`object:SetData`, `SetDefaultMovementType` +
     `SetRespawnRadius` ≈ `PatrolArea`), либо
   - C++-метод в ядре (как уже делалось для `Cast.Moving`).
   `CastSpellRAI` использует `sSpellStore` + `TRIGGERED_IGNORE_POWER_AND_REAGENT_COST`
   — в mod-ale это просто `unit:CastSpell(target, spell, triggered)`.
2. **`randommovementgenerator.cpp`** — правка ядра (патченный `PathGenerator`
   произвольного движения). Влияет на движение RAI-существ; без неё — штатное
   RANDOM_MOTION_TYPE.
3. **Свои спеллы** из `Patch-T.MPQ`: кастомный Spell.dbc. Их надо разобрать
   на наши `spell_dbc` (entry 70xxx) + клиентский patch-x (+ аддон SpellAIO
   уже ссылается на такие). Без них `raispellpicker` не найдёт спеллы.

## 4. Этапы интеграции

1. **Разбор спеллов (ПРОВЕДЁН 2026-11-20)** → вывод: **новых кастомных
   спеллов для RAI добавлять НЕ нужно.** Свои боевые спеллы RAI берёт из БД
   `custom_spell_system`+`custom_spell_system_categories` (= наши
   `realm_custom_spell_*`, 0058), а не из своего Patch-T.MPQ. Аудит пула:
   2022 спелла в категориях (1=Damage,2=Healing,3=Buff,4=Utility, выбор по
   `spellLevel`, запрос в `raispellpicker.lua:76`) — 2021 стандартный игровой
   WotLK (уже в клиенте и серверном spell_dbc), 70909 — единственный с
   ID≥70000, в Patch-T битый (Name пуст, Effects 0, Description «Redoubt») →
   в пул не включается. Кастомные 70010/70050/90515–90521 уже в patch-x.mpq
   и серверном `spell_dbc`. Клиентский Patch-T в дистрибутив реалма НЕ нужен.
2. **Разбор `rai.sql` и таблицы (ПРОВЕДЁН 2026-11-20)** → миграция
   `sql/world/0063_rai_tables.sql` на `realm_rai_*` (acore_world):
   - `realm_rai_zone_level` — минимакс-уровни искателей по зонам (46 записей);
   - `realm_rai_line_spawns` — точки спавна линий (13, entry 100060, зона 40, ветки 11/119);
   - `realm_rai_line_moveto` — точки движения линий (12);
   - `realm_rai_creature` / `realm_rai_spawns` — пустые (заполняются runtime через
     `.rai …` / `raidbhelper`).
   `custom_*`-таблицы в rai.sql пропущены (уже адаптированы как
   `realm_custom_spell_*`, 0058–0062). Зарегистрировано в `sql/README.md`.
3. **Порт Lua-модулей** `raiserver/combat/encounter/logic/creature/group/
   spawner/creaturepicker/commands/dbhelper/tablehelper/spellpicker/targets/
   generator/phase` на mod-ale:
   - `require`-имена в один каталог `lua_scripts/RAI/`;
   - заменить `CastSpellRAI`/`PatrolArea`/`ReInitialize` на Lua-эквиваленты;
   - US-номера событий уже совпадают (5/1/2/9/4/24);
   - пер-зоны: `creature:GetData/SetData` через `ObjectVariables.ext`;
   - локализация ru/en (модуль сейчас en-только).
4. **C++-патч ядра** (опционально): `randommovementgenerator` для корректного
   движения RAI-существ. Пересборка `worldserver`. (Можно отложить: стандартный
   RANDOM_MOTION_TYPE работает, но без патченного pathing'а.)
5. **Балансировка контента**: `realm_rai_zone_level` (уровни по зонам —
   под нашу PvP-зону 5000 и зоны кампаний), стартовые спавны `realm_rai_spawns`.
6. **Тестовый прогон** на реалме: логи `[EchoOfTheVoid] RAI`, проверка фаз,
   групп, кастинга кастомных спеллов, команд `.rai …`.

## 5. Сводка рисков

| Риск | Оценка | Митигация |
|------|--------|-----------|
| C++-методы Eluna (eluna.cpp) | средний | Lua-эквиваленты (CastSpell уже есть) |
| randommovementgenerator (патч ядра) | средний | опционально, без него RANDOM_MOTION_TYPE |
| кастомный Spell.dbc Patch-T.MPQ | ~~высокий~~ снят | разбор проведён: кастомных спеллов RAI нет, Patch-T не нужен |
| кастомный спраfit-спелл.dbc Patch-T.MPQ | высокий | отдельный разбор → `spell_dbc` 70xxx + patch-x |
| большие `require`-модули (18 Lua) | средний | последовательный порт, синтаксис luaparser |
| ru/en + табличные префиксы | низкий | наша локаль L(), `realm_rai_*` |

## 6. Порядок запуска (когда начнём)

Крайне рекомендуется сначала реализовать **этап 1 (спеллы)** и **этап 2
(таблицы)**, затем **этап 3 (Lua)**; C++-патч (этап 4) — по желанию после
появления тестового реалма. Каждый этап — отдельный PR.

## Зависимости
- SpellAIO адаптирован (0058–0062) — это референс-порт + пул спеллов.
- Тестовый реалм для живого прогона (граница этапа 6).