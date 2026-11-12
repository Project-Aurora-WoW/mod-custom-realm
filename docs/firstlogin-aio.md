# mod-FirstLogin-AIO — решение по конфигурации (Азерот: Эхо Пустоты)

## Контекст

[`Gozzim/mod-FirstLogin-AIO`](https://github.com/Gozzim/mod-FirstLogin-AIO) — C++-модуль
AzerothCore «Additional First Login Features» (AGPL-3.0). Добавлен в сборку
(Фаза 5): `setup-tree/action.yml` + `scripts/setup-build.sh`.

Наш реалм уже выдаёт новичкам **предметы и Жетоны**:
- `06_WaloriaRewards.lua` — награды за уровни (Паёк Ордена 70100, Сумка Эха 70101,
  припасы, Жетоны Эха 70005);
- `echo-startup` — стартовые настройки реалма.

Эти Lua-скрипты **не трогают** классовые параметры и слоты. Поэтому в FirstLogin-AIO
включены только те опции, которых у нас нет.

## Включённые опции (чего нет у нас)

Полный лист опций — `conf/FirstLogin.conf.dist` модуля. Ниже — выбранные значения
оверрайда реалма (применяются в `modules/FirstLogin.conf` рядом с `worldserver`):

```ini
[worldserver]
FirstLogin.Enable = 1
FirstLogin.Announce = 1

# Охотник: стартовые слоты стабила (0-4)
FirstLogin.StableSlots = 2

# Охотник: случайный стартовый питомец + его спеллы (+ генерация имени)
FirstLogin.Pet = 1
FirstLogin.RandPetName = 1
FirstLogin.LearnPetSpells = 1

# Чернокнижник: стартовые миньоны (bitmask: 1 Imp, 8 Felhunter, 32 Drain Soul => 41)
FirstLogin.WarlockMinion = 41

# Банк: стартовые слоты банка + сумка (Рунотканная сумка 34475)
FirstLogin.BankSlots = 2
FirstLogin.BagID = 34475

# Дуал-спек на старте
FirstLogin.DualSpec = 1
```

## Сверка с нашими старт-модулями

| Опция FirstLogin | Включаем? | Почему |
|---|---|---|
| `StableSlots` | да (2) | слотов стабила у нас нет |
| `Pet` / `RandPetName` / `LearnPetSpells` | да | стартового пета нет |
| `WarlockMinion` | да (41) | стартовых миньонов нет |
| `BankSlots` / `BagID` | да (2/34475) | расширения банка на старте нет |
| `DualSpec` | да | выдачи дуал-спека нет |
| `Announce` | да | анонс модуля при логине |

Награды Waloria (предметы/Жетоны на уровнях) модулем **не дублируются** — это разные
слои: Waloria — предметы/валюта, FirstLogin — классовые/слотовые стартовые бонусы.