# 🗃️ SQL-миграции — Azeroth: Эхо Пустоты

> Нумерованные миграции для world-БД AzerothCore (`acore_world`).
> Применяются **строго в порядке нумерации**, только вперёд (без даунгрейдов).

---

## Реестр миграций

| Файл | Назначение | Зависимости |
|------|-----------|-------------|
| `world/0001_world_baseline.sql` | НПС «Портальный Страж» (70001) + спавны в Штормграде и Оргриммаре | — |
| `world/0002_campaign_progress.sql` | Таблица прогресса кампаний `realm_campaign_progress` **→ acore_characters** (её читают `Campaign*.lua` через `CharDBQuery` и `EchoCampaigns.cpp` через `CharacterDatabase`) | — |
| `world/0003_cult_npcs.sql` | НПС Культа и сюжетные персонажи: Ахерон-Пустотник (70100), Культист (70101), Пленный маг (70110), Архимаг Элианна (70120) + спавны | 0001 |
| `world/0004_campaign_reward_item.sql` | Предмет «Слеза Рассвета» (item 70001) — награда кампании 1 | 0001 |
| `world/0005_campaign2_content.sql` | Контент кампании 2: Хора Шёпота (70500), Пророк Нал'кур (70130), Сквернозор (70140), Командир Валирия (70150), алтари (70103 ×4), культисты в Зул'Драке (×10), item 70004 «Клеймо Стражей Пустоты» | 0001, 0003 |
| `world/0006_campaign3_rewards.sql` | Награды кампании 3: item 70002 «Печать Хранителя Эха» (титул-токен), item 70003 «Бездна-Пегас» (маунт-токен; требуется DBC-патч клиента) | 0001 |
| `world/0007_campaign3_content.sql` | Контент кампании 3: рейд-босс Усмешка Бездны (70510), Пустотные Стражи (70105 ×10), Очаги Ритуала (70106 ×3), Советник Мортега (70160) | 0001, 0006 |
| `world/0008_npc_displayid.sql` | Модели (displayid) всех 14 кастомных НПС + scale боссов. Displayid приблизительные — выверить на тестовом реалме | 0001–0007 |
| `world/0009_event_pvp.sql` | Item 70005 «Жетон Эха» (world-БД) + таблица `realm_pvp_stats` (**acore_characters**!) для PvP-статистики | 0001 |
| `world/0010_pvp_shop.sql` | НПС «Интендант Ордена» (70170, Даларан) — PvP-шоп за Жетоны Эха; ассортимент в `30_PvpShop.lua` | 0009 |
| `world/0011_lore_archivist.sql` | НПС «Хронист Ордена» (70180, Даларан) — игровой лор-архив; скрипт `LoreArchive.lua` | 0001, 0008 |
| `world/0012_campaign4_content.sql` | Контент кампании 4: Хранительница Аэрис (70210), Осколочные Фантомы (70201 ×8), Иссушенные Легионеры (70202 ×4), Осколки Эха (70204 ×3), Архонт Нехал'тхар (70520), items 70006/70007 | 0001, 0003 |
| `world/0013_campaign_manager.sql` | Журнал действий кампаний `realm_campaign_log` (**acore_characters**) — журналирование всех действий менеджера кампаний | 0002 |
| `world/0014_waloria_rewards.sql` | Награды за уровни (подход Waloria): items 70100 «Паёк Ордена» и 70101 «Сумка Эха» (**acore_world**) + таблица антидублей `realm_level_rewards` (**acore_characters**); скрипт `06_WaloriaRewards.lua` | 0001 |
| `world/0015_token_outbox.sql` | Outbox-награды (паттерн wow-mod-delves): `realm_token_outbox` + `realm_token_receipt` (**acore_characters**) — durable-выдача Жетонов Эха с идемпотентной доставкой; пишут модули echo-pve/echo-economy | 0009 |
| `world/0016_dbc_reference_sample.sql` | Образец миграции `spell_dbc`/`chartitles_dbc` по эталонной схеме ядра [azerothcore-wotlk-classless](https://sourcecraft.dev/m-orlovrus59/azerothcore-wotlk-classless) (`data/sql/base/db_world/*_dbc.sql`); закомментирован, активируется при DBC-патче (см. `docs/client-patch.md` ч. 4c) | — |
| `world/0017_waloria_tools.sql` | Таблица учётa `.fixgear`: `realm_fixgear` (**acore_characters**) — одноразовость починки предмета на персонажа; скрипт `11_FixGear.lua` | — |
| `world/0018_eluna_scripts_tier_a.sql` | Контент Tier A (eluna-scripts): НПС «Рунный Обжиг» (70172, зачарователь), «Хранитель Золота» (70173), шаблоны «Разлом Пустоты» (70190) и «Иссушенный из Разлома» (70191), item 70008 «Осколок Пустоты», спелл 70050 «Пустотная порча» (spell_dbc, требует DBC-патча клиента); таблица `realm_gold_storage` (**acore_characters**) | 0001, 0008 |
| `world/0019_challenge_modes.sql` | GO «Алтарь Испытаний» (705605) + 9 спавнов у кладбищ стартовых зон (guid 7005601–7005609) — режимы испытаний `echo-challenge-modes` | — |
| `world/0020_store_system.sql` | Таблицы AIO-магазина `realm_store_*` (категории/услуги/валюты/связи/журнал) + демо-контент: валюты золото + Жетон Эха, услуги реалма (Пегас 70010, титул 48, баффы, смена имени) | 0009 (жетоны) |
| `world/0021_public_scripts.sql` | Системы public-scripts (JadaDev): таблицы наград за наигранное время `realm_played_time_rewards{,_claimed}` (**acore_characters**) + НПС «Страж Перемен» (70174, Даларан, guid 7000174) — смена фракции за Жетоны Эха (**acore_world**). ⚠️ Часть acore_world написана по схеме WotLK (`modelid1`, `dmgschool`, `spawndist`, `creature.id`) — на AzerothCore упадёт; рабочий НПС создаёт `0022` | 0009 |
| `world/0022_fix_release_blockers.sql` | Релизные фиксы: НПС «Страж Перемен» (70174) по схеме AC + модель 15279 + спавн 7000174; идемпотентный досозд спавна PvP-шопа 70170 (**acore_world**) | 0010, 0021 |
| `world/0024_tier_b.sql` | Tier B (eluna-scripts): НПС 70175 «Рунный Оружейник» (Weapon Master), 70176 «Хранитель Тиражей» (Lottery), 70177 «Вестник Забвения» (Skip DK Starter), 70178 «Алтарь Ордена» (Prayer) + таблицы `realm_lottery{,_tickets}` (**acore_characters**); гаиды 7000175–7000178 | 0009 (жетоны), 0022 (схема НПС) |
| `world/0026_store_expansion.sql` | Расширение AIO-магазина: валюта id 3 «Очки Возмездия» (SERVER_HANDLED, из `realm_pvp_stats.tokens_earned`), VIP-категория id 9 (`requiredRank=4`), маунты за жетоны (услуги 10–12); потребляет `Store_Server.lua` (SERVER_HANDLED) | 0020, 0009, 0015/0021 |
| `world/0027_pvp_store.sql` | Перенос PvP-шопа в AIO-магазин: категория id 10 «Снабжение Ордена» + услуги 20–25 (тип 1, за Жетоны Эха); НПС-шоп (`30_PvpShop.lua`) остаётся fallback | 0020, 0009 |
| `world/0028_item_enchant_random.sql` | Random-энчанты (Фаза 2): таблица `item_enchantment_random_tiers` (тиры оружия T1–T4, веса, ilvl-диапазоны) + НПС 70192 «Рандомный Зачарователь» (Даларан, guid 7000192); потребляет `28_RandomEnchant.lua` | 0009, 0001 (схема НПС) |
| `world/0029_parangon.sql` | Parangon (Фаза 3, Lua-only): таблицы `account_parangon` (уровень/опыт на аккаунт) + `characters_parangon` (потраченные очки) (**acore_characters**); потребляет `29_Parangon.lua` | — |
| `world/0030_classless_full.sql` | Classless «полная версия» (Фаза 3): расширяет `character_classless` (**acore_characters**) колонкой `talents` (CSV «talentSpellID\|talentID\|rank;») — таланты обучаются из БД ядра (`talent_dbc`+`talenttab_dbc`); потребляет `27_Classless.lua` | 0025 |
| `world/0031_gpt_npc.sql` | GPT-НПС (Фаза 4): очередь `realm_gpt_queue` (**acore_characters**) для обмена ALE-скрипта `gpt_npc.lua` с внешним Python-сервисом (`service/gpt_npc.py`), который вызывает OpenAI | — |
| `world/0032_pvp_full_loot.sql` | Full-Loot PvP: сундук «Добыча войны» (gameobject 700020, type 3 GO_CHEST, displayId 259) — выпадение предметов/золота жертвы при PvP-килле; потребляет `31_PvpFullLoot.lua` | — |
| `world/0033_treasure_chest.sql` | Сундуки Пустоты: сундук 700021 (GO_CHEST, displayId 8686) + таблицы `custom_treasure_chest_{loot,config,spawn}` — GM-система сундуков-сокровищ (референс zyggy123/Treasure-Chest-System); потребляет `32_TreasureChest.lua` | — |
| `world/0025_classless.sql` | Classless-арка К5 (порт Shikifuyin/AzerothCore-ClassLess-Solo): таблица `character_classless` (**acore_characters**) — «чужие» спеллы/глифы персонажа CSV; таланты — в 0030; скрипт `27_Classless.lua` | — |

---

## Порядок применения

```bash
mysql -u <user> -p acore_world < sql/world/0001_world_baseline.sql
# 0002: realm_campaign_progress -> acore_characters:
mysql -u <user> -p acore_characters < sql/world/0002_campaign_progress.sql
mysql -u <user> -p acore_world < sql/world/0003_cult_npcs.sql
mysql -u <user> -p acore_world < sql/world/0004_campaign_reward_item.sql
mysql -u <user> -p acore_world < sql/world/0005_campaign2_content.sql
mysql -u <user> -p acore_world < sql/world/0006_campaign3_rewards.sql
mysql -u <user> -p acore_world < sql/world/0007_campaign3_content.sql
mysql -u <user> -p acore_world < sql/world/0008_npc_displayid.sql
# 0009: item_template → acore_world, realm_pvp_stats → acore_characters:
mysql -u <user> -p acore_world < sql/world/0009_event_pvp.sql
mysql -u <user> -p acore_characters < sql/world/0009_event_pvp.sql
mysql -u <user> -p acore_world < sql/world/0010_pvp_shop.sql
mysql -u <user> -p acore_world < sql/world/0011_lore_archivist.sql
mysql -u <user> -p acore_world < sql/world/0012_campaign4_content.sql
# 0013: realm_campaign_log → acore_characters:
mysql -u <user> -p acore_characters < sql/world/0013_campaign_manager.sql
# 0014: items 70100/70101 → acore_world, realm_level_rewards → acore_characters:
mysql -u <user> -p acore_world < sql/world/0014_waloria_rewards.sql
mysql -u <user> -p acore_characters < sql/world/0014_waloria_rewards.sql
# 0015: realm_token_outbox + realm_token_receipt → acore_characters:
mysql -u <user> -p acore_characters < sql/world/0015_token_outbox.sql
# 0016: закомментированный образец DBC-миграции — применить при
# включении кастомных спеллов/титулов (раскомментировать нужное):
# mysql -u <user> -p acore_world < sql/world/0016_dbc_reference_sample.sql
# 0017: realm_fixgear → acore_characters:
mysql -u <user> -p acore_characters < sql/world/0017_waloria_tools.sql
# 0018: NPC/items/spell_dbc → acore_world, realm_gold_storage → acore_characters:
mysql -u <user> -p acore_world < sql/world/0018_eluna_scripts_tier_a.sql
mysql -u <user> -p acore_characters < sql/world/0018_eluna_scripts_tier_a.sql
# 0019: Алтарь Испытаний (705605) → acore_world:
mysql -u <user> -p acore_world < sql/world/0019_challenge_modes.sql
# 0020: таблицы магазина realm_store_* → acore_world:
mysql -u <user> -p acore_world < sql/world/0020_store_system.sql
# 0021: realm_played_time_rewards{,_claimed} → acore_characters,
#       НПС 70174 «Страж Перемен» → acore_world:
mysql -u <user> -p acore_characters < sql/world/0021_public_scripts.sql
mysql -u <user> -p acore_world < sql/world/0021_public_scripts.sql
# 0022: фикс схемы НПС 70174 + досозд спавна 70170 → acore_world:
mysql -u <user> -p acore_world < sql/world/0022_fix_release_blockers.sql
# 0025: character_classless → acore_characters (Classless арка К5):
mysql -u <user> -p acore_characters < sql/world/0025_classless.sql
# 0026: расширение магазина (realm_store_* → acore_world):
mysql -u <user> -p acore_world < sql/world/0026_store_expansion.sql
# 0027: перенос PvP-шопа в AIO-магазин (realm_store_* → acore_world):
mysql -u <user> -p acore_world < sql/world/0027_pvp_store.sql
# 0028: random-энчанты (таблица тиров + НПС → acore_world):
mysql -u <user> -p acore_world < sql/world/0028_item_enchant_random.sql
# 0029: Parangon (account_parangon + characters_parangon → acore_characters):
mysql -u <user> -p acore_characters < sql/world/0029_parangon.sql
# 0030: Classless «полная версия» (alter character_classless → acore_characters):
mysql -u <user> -p acore_characters < sql/world/0030_classless_full.sql
# 0031: GPT-НПС (очередь realm_gpt_queue → acore_characters):
mysql -u <user> -p acore_characters < sql/world/0031_gpt_npc.sql
# 0032: Full-Loot PvP (сундук «Добыча войны» → acore_world):
mysql -u <user> -p acore_world < sql/world/0032_pvp_full_loot.sql
# 0033: Сундуки Пустоты (сундук 700021 + таблицы → acore_world):
mysql -u <user> -p acore_world < sql/world/0033_treasure_chest.sql
```

После применения выполните в консоли `worldserver`:
```
.reload creature_template
.reload items
```

---

## Конвенции

| Конвенция | Значение |
|-----------|----------|
| Нумерация | `NNNN_имя.sql`, инкремент +1, пропуски запрещены |
| Кастомные entry НПС | 70001–79999 |
| ├─ Портальный Страж | 70001 |
| ├─ Порождения Пустоты / Культ | 70100–70199 |
| ├─ Сюжетные НПС (спасение, диалоги) | 70110–70119 |
| ├─ Квестодатели / брифинги | 70120–70199 |
| ├─ Интерактивные объекты-НПС (алтари) | 70103 |
| └─ Боссы кампаний | 70500–70599 |
| Кастомные item entry | 70001–79999 |
| ├─ 70001 | «Слеза Рассвета» (кампания 1) |
| ├─ 70002 | «Печать Хранителя Эха» (титул, кампания 3) |
| ├─ 70003 | «Бездна-Пегас» (маунт-токен, кампания 3) |
| └─ 70004 | «Клеймо Стражей Пустоты» (кампания 2) |
| ├─ 70005 | «Жетон Эха» (валюта ивентов/PvP) |
| ├─ 70006 | «Сердце Второго Эха» (кампания 4) |
| ├─ 70007 | «Венец Пустоты» (косметика, кампания 4) |
| ├─ 70008 | «Осколок Пустоты» (источник порчи, 0018) |
| ├─ 70100 | «Паёк Ордена» (welcome reward lvl 2, Waloria) |
| └─ 70101 | «Сумка Эха» (level-up reward, Waloria) |
| Кастомные НПС-сервисы | |
| ├─ 70172 | «Рунный Обжиг» (зачарователь, 0018) |
| ├─ 70173 | «Хранитель Золота» (казначей, 0018) |
| ├─ 70174 | «Страж Перемен» (смена фракции, 0021) |
| ├─ 70190 | «Разлом Пустоты» (портал ивента, 0018; только шаблон) |
| └─ 70191 | «Иссушенный из Разлома» (моб ивента, 0018; только шаблон) |
| Кастомные спеллы (spell_dbc) | |
| └─ 70050 | «Пустотная порча» (стакающийся маркер Corruption, 0018; требует DBC-патча) |
| Кастомные guid спавнов | 7000000+ (0011: 7000120; 0012: 7000121, 7000130–7000160; 0018: 7000172/7000173; 0019: 7005601–7005609; 0021: 7000174) |
| Gossip menu id | 70000+ (при добавлении в БД) |
| Обратная совместимость | все миграции идемпотентны (`DELETE`+`INSERT` или `IF NOT EXISTS`) |

---

## Связанные документы

- 🧩 Скрипты, использующие эти данные — [`../lua_scripts/README.md`](../lua_scripts/README.md)
- ⚔️ Реестр кампаний — [`../docs/campaigns/README.md`](../docs/campaigns/README.md)
- 📦 Модули и сборка ядра — [`../modules/README.md`](../modules/README.md)
