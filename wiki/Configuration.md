# ⚙️ Конфигурация и параметры

> **RU.** Параметры серверных конфигов и модулей реалма.
> **EN:** see [Configuration-en.md](Configuration-en.md).

---

## 1. Основной конфиг сервера / Core server config

После сборки скопируйте дистрибутивные конфиги:

```bash
# Linux
cp $HOME/acore/bin/etc/worldserver.conf.dist $HOME/acore/bin/etc/worldserver.conf
cp $HOME/acore/bin/etc/authserver.conf.dist $HOME/acore/bin/etc/authserver.conf
# Windows
copy C:\acore\bin\etc\worldserver.conf.dist C:\acore\bin\etc\worldserver.conf
```

### Ключевые параметры `worldserver.conf`

| Параметр | Описание |
|----------|----------|
| `DataDir` | Путь к `maps/vmaps/mmaps/dbc` |
| `LoginDatabaseInfo` | `127.0.0.1;3306;root;<пароль>;acore_auth` |
| `WorldDatabaseInfo` | `127.0.0.1;3306;root;<пароль>;acore_world` |
| `CharacterDatabaseInfo` | `127.0.0.1;3306;root;<пароль>;acore_characters` |
| `EnablePlayerSettings` | **`1`** — обязательно для режимов испытаний (прогресс хранится в player settings characters-БД) |
| `RealmID` | `1` (или ваш) |
| `MaxPlayerLevel` | `80` (концепция реалма — макс. уровень 80) |

`authserver.conf`: `LoginDatabaseInfo` → `acore_auth`.

> Конфиги модулей `echo-*.conf` создаются автоматически при сборке
> (`conf/*.conf.dist` копируются ядром) и лежат в `etc/modules/`.

---

## 2. Модули реалма / Realm modules (echo-*)

### `echo-balance` — глобальный баланс урона/лечения
| Параметр | По умолч. | Описание |
|----------|-----------|----------|
| `EchoBalance.WorldDamageScalar` | `1.0` | Множитель урона существ по игрокам |
| `EchoBalance.PlayerDamageScalar` | `1.0` | Множитель исходящего урона игроков |
| `EchoBalance.HealingScalar` | `1.0` | Множитель лечения |
| `EchoBalance.MaxHitPercent` | `0` | Отсечка ваншотов (% max HP); `0` = выкл |
| `EchoBalance.BossDamageScalar` | `1.0` | Доп. урон боссов (rank 3) |
| `EchoBalance.CampaignCompletionTokens` | `3` | Жетоны за завершение кампании (из модуля) |

### `echo-campaigns` — команды кампаний
| Параметр | По умолч. | Описание |
|----------|-----------|----------|
| `EchoCampaigns.CommandSource` | `both` | `both`/`core`/`lua` — кто обрабатывает `.ae*` |
| `EchoCampaigns.EnableLogging` | `1` | Журнал `realm_campaign_log` |
| `EchoCampaigns.CheckLoadOrder` | `1` | Лог порядка загрузки подсистем |

### `echo-challenge-modes` — режимы испытаний
| Параметр | По умолч. | Описание |
|----------|-----------|----------|
| `ChallengeModes.Enable` | `1` | Включить систему (Алтарь GO 705605) |
| `<Mode>.Enable` | `1` | Включить конкретный режим (Hardcore / SemiHardcore / SelfCrafted / ItemQualityLevel / SlowXpGain / VerySlowXpGain / QuestXpOnly / IronMan) |
| `<Mode>.XPMultiplier` | `1` | Множитель опыта режима |
| `<Mode>.TitleRewards` | `""` | Награда-титул: `"уровень titleID"` |
| `<Mode>.TalentRewards` | `""` | Награда-таланты: `"уровень кол-во"` |
| `<Mode>.ItemRewards` | `""` | Награда-предмет: `"уровень itemEntry"` |
| `<Mode>.ItemRewardAmount` | `1` | Кол-во предметов |
| `<Mode>.AchievementReward` | `""` | Награда-достижение: `"уровень achievementID"` |
| `<Mode>.DisableLevel` | `0` | Авто-отключение на уровне; `0` = никогда |

Пример наград:
```ini
Hardcore.TitleRewards   = "80 48"        # «Хранитель Эха»
Hardcore.ItemRewards    = "80 70001"     # Слеза Рассвета
VerySlowXpGain.TalentRewards = "20 1, 40 1, 60 1, 80 2"
```

> Требует `EnablePlayerSettings = 1` в `worldserver.conf`.

### `echo-economy` — экономика / анти-инфляция
| Параметр | По умолч. | Описание |
|----------|-----------|----------|
| `EchoEconomy.Enable` | `1` | Влючить |
| `EchoEconomy.TokenItem` | `70005` | Валюта «Жетон Эха» |
| `EchoEconomy.TokenCap` | `50` | Мягкий лимит жетонов на персонаже |
| `EchoEconomy.DrainPercent` | `50` | % избытка, изымаемый Пустотой при входе |
| `EchoEconomy.AnnounceDrain` | `1` | Сообщать о сливе |
| `EchoEconomy.Outbox.Enable` | `1` | Отложенная выдача (outbox) |
| `EchoEconomy.Outbox.BatchSize` | `5` | Макс. доставок за вход |

### `echo-pve` — PvE-механики Пустоты
| Параметр | По умолч. | Описание |
|----------|-----------|----------|
| `EchoPve.Enable` | `1` | Включить |
| `EchoPve.NightDamageScalar` | `1.25` | «Ночью шёпот громче» — ночной множитель урона пустотных |
| `EchoPve.NightStartHour` / `NightEndHour` | `18` / `6` | Ночное окно (игровое время) |
| `EchoPve.VoidCreatures` | список | Entry пустотных существ |
| `EchoPve.TokenDropChance` | `3` | % дропа Жетона Эха вне ивентов |
| `EchoPve.TokenDropCooldownSecs` | `600` | Анти-фарм кулдаун |
| `EchoPve.MidnightBonusScalar` | `1.15` | Пик ночи (22–04) доп. множитель |

### `echo-pvp` — PvP-механики Пустоты
| Параметр | По умолч. | Описание |
|----------|-----------|----------|
| `EchoPvp.Enable` | `1` | Включить |
| `EchoPvp.ZoneId` | `4080` | PvP-зона (Драконий Погост) |
| `EchoPvp.ZoneTokenKill` | `1` | Жетонов за килл в зоне |
| `EchoPvp.MinLevelDiff` | `10` | Анти-абюз по уровням |
| `EchoPvp.FarmCooldownSecs` | `300` | Анти-фарм пары |
| `EchoPvp.EnableStreakAnnounce` | `1` | Killstreak-объявления |
| `EchoPvp.RevengeStreakMin` / `RevengeDamageBonusPct` / `RevengeDurationSecs` | `5`/`15`/`120` | «Месть Эха» |

### `echo-startup` — стартовый набор
| Параметр | По умолч. | Описание |
|----------|-----------|----------|
| `EchoStartup.Enable` | `1` | Включить |
| `EchoStartup.NewbieMaxPlayedTimeSecs` | `60` | Порог «новичок» (игровое время) |
| `EchoStartup.MinLevel` | `0` | Мин. уровень выдачи |
| `EchoStartup.Items` | `33470:3,33475:3,43005:5,70005:2` | Стартовые предметы `entry:count` |
| `EchoStartup.BuffSpell` | `58452` | Бафф «Напутствие Ордена» |

---

## 3. Redact параметры Lua (реестр) / Lua-side parameters (registry)

Большая часть игровых настроек (ивенты, разломы, лотерея, Classless, цены магазина)
находится в [`../lua_scripts/00_CampaignRegistry.ext`](../lua_scripts/00_CampaignRegistry.ext)
(таблица `AzerothEchoCampaigns`):

| Раздел | Что настраивает |
|--------|-----------------|
| `meta` | Тэг чата, `min_level` (80), `token_item` (70005), команды |
| `events` | Расписание ивентов (Шторм/Кровавая Луна), награды |
| `pvp` | Анти-абюз, killstreak, жетоны PvP-зоны |
| `shop` | Ассортимент и цены PvP-шопа (НПС 70170) |
| `tier_b` | Цены/кулдауны Weapon Master, Lottery, Skip DK, Prayer Altar |
| `corruption` | «Пустотная порча»: стаки, дебаффы по порогам |
| `void_aura` | Ауры Пустоты «Эхо Шёпота» |
| `balance` | Баланс кампаний/ивентов (зеркало C++-модулей) |

---

## 4. Перезагрузка конфигов / Reloading configs

В консоли `worldserver` выполните:

```
.reload config          # перечитать worldserver.conf и конфиги модулей
.reload creature_template
.reload items
.reload ale             # перезагрузить Lua-скрипты (только dev)
```