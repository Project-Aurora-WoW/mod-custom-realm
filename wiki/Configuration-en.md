# ⚙️ Configuration & parameters

> **EN.** Server config and realm module parameters.
> **RU:** см. [Configuration.md](Configuration.md).

---

## 1. Core server config

After building, copy the dist configs:

```bash
# Linux
cp $HOME/acore/bin/etc/worldserver.conf.dist $HOME/acore/bin/etc/worldserver.conf
cp $HOME/acore/bin/etc/authserver.conf.dist $HOME/acore/bin/etc/authserver.conf
# Windows
copy C:\acore\bin\etc\worldserver.conf.dist C:\acore\bin\etc\worldserver.conf
```

### Key `worldserver.conf` parameters

| Parameter | Description |
|-----------|-------------|
| `DataDir` | Path to `maps/vmaps/mmaps/dbc` |
| `LoginDatabaseInfo` | `127.0.0.1;3306;root;<password>;acore_auth` |
| `WorldDatabaseInfo` | `127.0.0.1;3306;root;<password>;acore_world` |
| `CharacterDatabaseInfo` | `127.0.0.1;3306;root;<password>;acore_characters` |
| `EnablePlayerSettings` | **`1`** — required for challenge modes (progress stored in characters-DB player settings) |
| `RealmID` | `1` (or yours) |
| `MaxPlayerLevel` | `80` (realm concept: max level 80) |

`authserver.conf`: `LoginDatabaseInfo` → `acore_auth`.

> Module configs `echo-*.conf` are created automatically at build time
> (`conf/*.conf.dist` are copied by the core) and live in `etc/modules/`.

---

## 2. Realm modules (echo-*)

### `echo-balance` — global damage/healing balance
| Parameter | Default | Description |
|-----------|---------|-------------|
| `EchoBalance.WorldDamageScalar` | `1.0` | Creature→player damage multiplier |
| `EchoBalance.PlayerDamageScalar` | `1.0` | Player outgoing damage multiplier |
| `EchoBalance.HealingScalar` | `1.0` | Healing multiplier |
| `EchoBalance.MaxHitPercent` | `0` | One-shot cap (% max HP); `0` = off |
| `EchoBalance.BossDamageScalar` | `1.0` | Extra boss (rank 3) damage |
| `EchoBalance.CampaignCompletionTokens` | `3` | Tokens for campaign completion (module) |

### `echo-campaigns` — campaign commands
| Parameter | Default | Description |
|-----------|---------|-------------|
| `EchoCampaigns.CommandSource` | `both` | `both`/`core`/`lua` — who handles `.ae*` |
| `EchoCampaigns.EnableLogging` | `1` | Log to `realm_campaign_log` |
| `EchoCampaigns.CheckLoadOrder` | `1` | Log load-order check |

### `echo-challenge-modes` — challenge modes
| Parameter | Default | Description |
|-----------|---------|-------------|
| `ChallengeModes.Enable` | `1` | Enable system (Altar GO 705605) |
| `<Mode>.Enable` | `1` | Enable a mode (Hardcore / SemiHardcore / SelfCrafted / ItemQualityLevel / SlowXpGain / VerySlowXpGain / QuestXpOnly / IronMan) |
| `<Mode>.XPMultiplier` | `1` | Mode XP multiplier |
| `<Mode>.TitleRewards` | `""` | Title reward: `"level titleID"` |
| `<Mode>.TalentRewards` | `""` | Talent reward: `"level count"` |
| `<Mode>.ItemRewards` | `""` | Item reward: `"level itemEntry"` |
| `<Mode>.ItemRewardAmount` | `1` | Item count |
| `<Mode>.AchievementReward` | `""` | Achievement reward: `"level achievementID"` |
| `<Mode>.DisableLevel` | `0` | Auto-disable at level; `0` = never |

Example rewards:
```ini
Hardcore.TitleRewards   = "80 48"        # "Guardian of Echo"
Hardcore.ItemRewards    = "80 70001"     # Tear of Dawn
VerySlowXpGain.TalentRewards = "20 1, 40 1, 60 1, 80 2"
```

> Requires `EnablePlayerSettings = 1` in `worldserver.conf`.

### `echo-economy` — economy / anti-inflation
| Parameter | Default | Description |
|-----------|---------|-------------|
| `EchoEconomy.Enable` | `1` | Enable |
| `EchoEconomy.TokenItem` | `70005` | Currency "Echo Token" |
| `EchoEconomy.TokenCap` | `50` | Soft token cap per character |
| `EchoEconomy.DrainPercent` | `50` | % of excess drained by the Void on login |
| `EchoEconomy.AnnounceDrain` | `1` | Announce the drain |
| `EchoEconomy.Outbox.Enable` | `1` | Deferred delivery (outbox) |
| `EchoEconomy.Outbox.BatchSize` | `5` | Max deliveries per login |

### `echo-pve` — Void PvE mechanics
| Parameter | Default | Description |
|-----------|---------|-------------|
| `EchoPve.Enable` | `1` | Enable |
| `EchoPve.NightDamageScalar` | `1.25` | "The whisper grows louder at night" — night damage multiplier for void creatures |
| `EchoPve.NightStartHour` / `NightEndHour` | `18` / `6` | Night window (game time) |
| `EchoPve.VoidCreatures` | list | Void creature entries |
| `EchoPve.TokenDropChance` | `3` | % Echo Token drop outside events |
| `EchoPve.TokenDropCooldownSecs` | `600` | Anti-farm cooldown |
| `EchoPve.MidnightBonusScalar` | `1.15` | Night peak (22–04) extra multiplier |

### `echo-pvp` — Void PvP mechanics
| Parameter | Default | Description |
|-----------|---------|-------------|
| `EchoPvp.Enable` | `1` | Enable |
| `EchoPvp.ZoneId` | `4080` | PvP zone (Dragonblight) |
| `EchoPvp.ZoneTokenKill` | `1` | Tokens per kill in zone |
| `EchoPvp.MinLevelDiff` | `10` | Anti-abuse level gap |
| `EchoPvp.FarmCooldownSecs` | `300` | Anti-farm pair cooldown |
| `EchoPvp.EnableStreakAnnounce` | `1` | Killstreak announcements |
| `EchoPvp.RevengeStreakMin` / `RevengeDamageBonusPct` / `RevengeDurationSecs` | `5`/`15`/`120` | "Echo of Revenge" buff |

### `echo-startup` — starter kit
| Parameter | Default | Description |
|-----------|---------|-------------|
| `EchoStartup.Enable` | `1` | Enable |
| `EchoStartup.NewbieMaxPlayedTimeSecs` | `60` | "Newbie" threshold (played time) |
| `EchoStartup.MinLevel` | `0` | Min level for the kit |
| `EchoStartup.Items` | `33470:3,33475:3,43005:5,70005:2` | Starter items `entry:count` |
| `EchoStartup.BuffSpell` | `58452` | "Order's Blessing" buff |

---

## 3. Lua-side parameters (registry)

Most game settings (events, rifts, lottery, Classless, store prices) live in
[`../lua_scripts/00_CampaignRegistry.ext`](../lua_scripts/00_CampaignRegistry.ext)
(the `AzerothEchoCampaigns` table):

| Section | What it configures |
|---------|--------------------|
| `meta` | Chat tag, `min_level` (80), `token_item` (70005), commands |
| `events` | Event schedules (Storm / Blood Moon), rewards |
| `pvp` | Anti-abuse, killstreak, PvP-zone tokens |
| `shop` | PvP-shop assortment & prices (NPC 70170) |
| `tier_b` | Prices/cooldowns for Weapon Master, Lottery, Skip DK, Prayer Altar |
| `corruption` | "Void corruption": stacks, threshold debuffs |
| `void_aura` | "Echo of the Whisper" void auras |
| `balance` | Campaign/event balance (mirror of C++ modules) |

---

## 4. Reloading configs

In the `worldserver` console run:

```
.reload config          # reload worldserver.conf and module configs
.reload creature_template
.reload items
.reload ale             # reload Lua scripts (dev only)
```