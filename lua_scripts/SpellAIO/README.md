# SpellAIO — система выбора кастомных спеллов

Адаптация `WaloriaOld/scripts/SpellAIO` на контур реалма «Эхо Пустоты».

## Что делает
Игрок получает окно выбора (AIO) с 4 кнопками — категории
(Damage/Healing/Buff/Utility). При выборе категории сервер даёт случайные
кастомные спеллы из нашей БД, игрок изучает один (или получает свиток).
Unlearn-переключатель возвращает изученный спелл свитком. Вход — при первом
входе в мир, по команде GM `.ae spell` или через НПС-тренера 70179.

## Отличия от оригинала Waloria
| Аспект | Waloria | Адаптация |
|--------|---------|-----------|
| Таблицы | `custom_spell_system*` | `realm_custom_spell_*` |
| Источник спеллов | 2036 чужих Валерианских | наши `spell_dbc` (70xxx/905xx) + 1892 стандартных классовых спелла Waloria |
| Счётчик изученных | C++-метод `GetCustomSpellAmount` | Lua через `realm_custom_spell_learned` |
| Локализация | en | ru/en |
| Движок | Eluna | mod-ale (номера событий совместимы) |
| Тонкий пул | жёстко 6/4 кандидатов | устойчиво к каталогу из 1 спелла |

## Файлы
- `spellclass.lua` — ядро логики (БД, выбор, лимиты).
- `server.lua` — серверный контур (события, AIO-обработчики, команда `.ae spell`,
  госсип НПС-тренера 70179).
- `client.lua` — клиентский AIO-интерфейс (окно выбора).

## События игрока (номера ALE, = Eluna)
- FIRST_LOGIN=30, LOGIN=3, DELETE=2, LEVEL_CHANGE=13, COMMAND=42.
- НПС-тренер 70179 «Хранитель Спеллов»: GOSSIP_EVENT_ON_HELLO=1, ON_SELECT=2.

## Миграции
`sql/world/0058_custom_spell_system.sql`:
- `realm_custom_spell_system` / `_categories` — каталог спеллов (acore_world);
- `realm_custom_spell_choices` / `_category_choices` / `_learned` — пер-персонаж
  (применять к acore_characters).

`sql/world/0059_spellaio_pool.sql` (acore_world): наполнение пула — спеллы
70050, 90515–90521 по категориям (см. ниже).

`sql/world/0060_spellaio_trainer.sql` (acore_world): НПС-тренер 70179
(creature_template + спавн в Даларане).

`sql/world/0061_spellaio_pool_waloria.sql` (acore_world): расширение пула
стандартными классовыми спеллами WotLK из WaloriaOld (`spellsystem.sql`) —
1892 спелла, привязка к категориям 1–4, забаненные исключены. `id` заданы
с 1001, чтобы не конфликтовать с записями 0059 (id 1–8). Категории спеллов,
уже добавленных в 0059, остаются без дублей.

## Пополнение пула
Добавить строки в `realm_custom_spell_system` + `realm_custom_spell_categories`
(спелл должен существовать в `spell_dbc`/клиентском Spell.dbc). Категории:
1=Damage, 2=Healing, 3=Buff, 4=Utility.
При слиянии больших пулов следите за `id`: задавайте новый диапазон (как в 0061
с 1001), чтобы не конфликтовать с уже вставленными записями.

Наши спеллы (миграция 0059):
| spellID | Название | Категории |
|---------|----------|-----------|
| 70050 | Пустотная порча | 1 (Damage) |
| 90515 | Thaurissan's Ember (огонь) | 1 (Damage) |
| 90520 | Ahn'kahar Venom (природный урон) | 1 (Damage) |
| 90519 | Light of the Naaru (исцеление) | 2 (Healing) |
| 90517 | Zandalari Vigor (хаст) | 3 (Buff) |
| 90518 | Amber Ward (абсорб-щит) | 3 (Buff) |
| 90516 | Highborne Focus (восст. силы) | 4 (Utility) |
| 90521 | Val'kyr's Mercy (защита от смерти) | 4 (Utility) |

Плюс 1892 стандартных классовых спелла Waloria (миграция 0061): Frostbolt/
Blizzard/Ice Barrier и т.п. по всем классам — см. распределение категорий
в начале файла 0061.