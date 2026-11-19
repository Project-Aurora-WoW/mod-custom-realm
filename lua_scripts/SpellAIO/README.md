# SpellAIO — система выбора кастомных спеллов

Адаптация `WaloriaOld/scripts/SpellAIO` на контур реалма «Эхо Пустоты».

## Что делает
Игрок получает окно выбора (AIO) с 4 кнопками — категории
(Damage/Healing/Buff/Utility). При выборе категории сервер даёт 4 случайных
кастомных спелла из нашей БД, игрок изучает один (или получает свиток).
Unlearn-переключатель возвращает изученный спелл свитком.

## Отличия от оригинала Waloria
| Аспект | Waloria | Адаптация |
|--------|---------|-----------|
| Таблицы | `custom_spell_system*` | `realm_custom_spell_*` |
| Источник спеллов | 2036 чужих Валерианских | только наши `spell_dbc` (70xxx) |
| Счётчик изученных | C++-метод `GetCustomSpellAmount` | Lua через `realm_custom_spell_learned` |
| Локализация | en | ru/en |
| Движок | Eluna | mod-ale (номера событий совместимы) |

## Файлы
- `spellclass.lua` — ядро логики (БД, выбор, лимиты).
- `server.lua` — серверный контур (события, AIO-обработчики, команда `.ae spell`).
- `client.lua` — клиентский AIO-интерфейс (окно выбора).

## События игрока (номера ALE, = Eluna)
- FIRST_LOGIN=30, LOGIN=3, DELETE=2, LEVEL_CHANGE=13, COMMAND=42.

## Миграции
`sql/world/0058_custom_spell_system.sql`:
- `realm_custom_spell_system` / `_categories` — каталог спеллов (acore_world);
- `realm_custom_spell_choices` / `_category_choices` / `_learned` — пер-персонаж
  (применять к acore_characters).

## Пополнение пула
Добавить строки в `realm_custom_spell_system` + `realm_custom_spell_categories`
(спелл должен существовать в `spell_dbc`/клиентском Spell.dbc).