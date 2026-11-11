// ============================================================
// echo-pvp — src/EchoPvp.cpp
// PvP-механики Пустоты реалма «Эхо Пустоты» (AzerothCore).
//
// Лор-основания (docs/lore/universe.md):
//   - Драконий Погост — зона власти Культа: за кровь, пролитую
//     у разлома, Культ платит Жетонами Эха.
//   - «Месть Эха»: Пустота мстит за своих — падение бойца
//     с длинной серией пробуждает эхо его ярости и даёт ему
//     силу на время после возрождения.
//
// Функции:
//   1. Жетоны Эха за киллы в PvP-зоне (анти-абюз: разница
//      уровней, фарм-кулдаун на пару).
//   2. Killstreak-объявления в мир (3/5/10) на языке клиента.
//   3. «Месть Эха»: павший с серией >= N получает временное
//      усиление урона (таймер внутри модуля, без спеллов).
//
// Конвенции синхронизированы с 20_PvpSystem.lua (Lua ведёт
// таблицу realm_pvp_stats; ядро — быстрые механики без БД).
//
// Сборка: модульная система AzerothCore подхватывает modules/echo-pvp
// автоматически. Конфиг: echo-pvp.conf.dist.
// ============================================================

#include "ScriptMgr.h"
#include "Unit.h"
#include "Player.h"
#include "Config.h"
#include "Log.h"
#include "World.h"
#include "GameTime.h"
#include "Chat.h"
#include "Common.h"
#include <unordered_map>
#include <cstring>

namespace
{
    // ---- Конфиг (кэшируется при загрузке) ----
    bool enable = true;
    uint32 pvpZoneId = 4080;
    uint32 zoneTokenKill = 1;
    uint32 minLevelDiff = 10;
    uint32 farmCooldownSecs = 300;
    bool enableStreakAnnounce = true;
    uint32 streakThresholds[3] = { 3, 5, 10 };
    uint32 revengeStreakMin = 5;
    uint32 revengeDamageBonusPct = 15;
    uint32 revengeDurationSecs = 120;

    constexpr uint32 ECHO_TOKEN_ITEM = 70005; // «Жетон Эха»

    // Фарм-кулдаун: key = (killerGuid << 32) | victimGuid -> время последнего зачёта
    std::unordered_map<uint64, time_t> farmCooldown;

    // Серии игроков: guid -> streak (ядровая копия для быстрых механик;
    // истина — в realm_pvp_stats, ведётся Lua 20_PvpSystem.lua)
    std::unordered_map<uint32, uint32> playerStreaks;

    // «Месть Эха»: guid -> время окончания действия баффа (Unix-время)
    std::unordered_map<uint32, time_t> revengeUntil;

    // «Месть Эха», ожидающие активации: guid -> серия жертвы на момент смерти
    // (бафф вешается при возрождении — OnPlayerRespawn)
    std::unordered_map<uint32, uint32> pendingRevenge;

    uint64 PairKey(uint32 killer, uint32 victim)
    {
        return (uint64(killer) << 32) | victim;
    }

    // Локаль игрока: "ru" | "en"
    char const* GetLocale(Player const* player)
    {
        return player && player->GetSession()->GetSessionDbcLocale() == LOCALE_ruRU ? "ru" : "en";
    }

    class EchoPvpWorldscript : public WorldScript
    {
    public:
        EchoPvpWorldscript() : WorldScript("EchoPvpWorldscript") { }

        void OnAfterConfigLoad(bool /*reload*/) override
        {
            enable = sConfigMgr->GetOption<bool>("EchoPvp.Enable", true);
            pvpZoneId = sConfigMgr->GetOption<uint32>("EchoPvp.ZoneId", 4080);
            zoneTokenKill = sConfigMgr->GetOption<uint32>("EchoPvp.ZoneTokenKill", 1);
            minLevelDiff = sConfigMgr->GetOption<uint32>("EchoPvp.MinLevelDiff", 10);
            farmCooldownSecs = sConfigMgr->GetOption<uint32>("EchoPvp.FarmCooldownSecs", 300);
            enableStreakAnnounce = sConfigMgr->GetOption<bool>("EchoPvp.EnableStreakAnnounce", true);
            streakThresholds[0] = sConfigMgr->GetOption<uint32>("EchoPvp.StreakThreshold1", 3);
            streakThresholds[1] = sConfigMgr->GetOption<uint32>("EchoPvp.StreakThreshold2", 5);
            streakThresholds[2] = sConfigMgr->GetOption<uint32>("EchoPvp.StreakThreshold3", 10);
            revengeStreakMin = sConfigMgr->GetOption<uint32>("EchoPvp.RevengeStreakMin", 5);
            revengeDamageBonusPct = sConfigMgr->GetOption<uint32>("EchoPvp.RevengeDamageBonusPct", 15);
            revengeDurationSecs = sConfigMgr->GetOption<uint32>("EchoPvp.RevengeDurationSecs", 120);

            LOG_INFO("module.echo-pvp",
                "echo-pvp загружен: enable=%s zone=%u tokenKill=%u minLvlDiff=%u farmCd=%us streaks=%u/%u/%u revenge=%u(+%u%%/%us)",
                enable ? "on" : "off", pvpZoneId, zoneTokenKill, minLevelDiff, farmCooldownSecs,
                streakThresholds[0], streakThresholds[1], streakThresholds[2],
                revengeStreakMin, revengeDamageBonusPct, revengeDurationSecs);
        }
    };

    class EchoPvpUnitscript : public UnitScript
    {
    public:
        EchoPvpUnitscript() : UnitScript("EchoPvpUnitscript", true) { }

        // «Месть Эха»: усиление исходящего урона игрока с активной местью
        void ModifyMeleeDamage(Unit* target, Unit* attacker, uint32& damage) override
        {
            ApplyRevenge(attacker, damage);
        }

        void ModifySpellDamageTaken(Unit* target, Unit* attacker, int32& damage, SpellInfo const* /*spellInfo*/) override
        {
            if (damage <= 0)
                return;
            uint32 dmg = uint32(damage);
            ApplyRevenge(attacker, dmg);
            damage = int32(dmg);
        }

    private:
        void ApplyRevenge(Unit* attacker, uint32& damage)
        {
            if (!enable || revengeDamageBonusPct == 0 || !attacker || !attacker->IsPlayer())
                return;

            Player* p = attacker->ToPlayer();
            if (!p)
                return;

            auto it = revengeUntil.find(p->GetGUID().GetCounter());
            if (it == revengeUntil.end() || GameTime::GetGameTime().count() >= it->second)
                return;

            damage = uint32(damage * (100 + revengeDamageBonusPct) / 100);
        }
    };

    class EchoPvpPlayerscript : public PlayerScript
    {
    public:
        EchoPvpPlayerscript() : PlayerScript("EchoPvpPlayerscript") { }

        // Зачёт PvP-киллов: жетоны в зоне, серии, месть
        void OnPlayerPVPKill(Player* killer, Player* victim) override
        {
            if (!enable || !killer || !victim || killer == victim)
                return;

            time_t now = GameTime::GetGameTime().count();
            uint32 killerGuid = killer->GetGUID().GetCounter();
            uint32 victimGuid = victim->GetGUID().GetCounter();

            // --- Анти-абюз: разница уровней ---
            if (killer->GetLevel() > victim->GetLevel() + minLevelDiff)
                return;

            // --- Анти-абюз: фарм-кулдаун на пару ---
            auto fcIt = farmCooldown.find(PairKey(killerGuid, victimGuid));
            if (fcIt != farmCooldown.end() && now - fcIt->second < farmCooldownSecs)
                return;

            // --- Серии (до обнуления жертвы) ---
            uint32 victimStreak = playerStreaks.count(victimGuid) ? playerStreaks[victimGuid] : 0;
            uint32 streak = ++playerStreaks[killerGuid];
            playerStreaks[victimGuid] = 0;

            // --- Жетоны за килл в PvP-зоне (Драконий Погост) ---
            if (zoneTokenKill > 0 && killer->GetZoneId() == pvpZoneId)
            {
                killer->AddItem(ECHO_TOKEN_ITEM, zoneTokenKill);
                farmCooldown[PairKey(killerGuid, victimGuid)] = now;

                if (strcmp(GetLocale(killer), "ru") == 0)
                    killer->SendSystemMessage("|cff9b59b6[Эхо Пустоты]|r Культ отметил вашу победу: +Жетон Эха.");
                else
                    killer->SendSystemMessage("|cff9b59b6[Echo of the Void]|r The Cult marks your victory: +Echo Token.");
            }

            // --- Killstreak-объявления в мир ---
            if (enableStreakAnnounce)
            {
                for (uint32 tier = 0; tier < 3; ++tier)
                {
                    if (streakThresholds[tier] > 0 && streak == streakThresholds[tier])
                    {
                        std::string name = killer->GetName();
                        bool ru = (strcmp(GetLocale(killer), "ru") == 0);
                        std::string msg;
                        switch (tier)
                        {
                            case 0:
                                msg = ru
                                    ? "|cff9b59b6[Эхо Пустоты]|r " + name + " несёт Эхо через поле боя!"
                                    : "|cff9b59b6[Echo of the Void]|r " + name + " carries the Echo across the battlefield!";
                                break;
                            case 1:
                                msg = ru
                                    ? "|cff9b59b6[Эхо Пустоты]|r Шёпот боится клинка " + name + "!"
                                    : "|cff9b59b6[Echo of the Void]|r The Whisper fears " + name + "'s blade!";
                                break;
                            default:
                                msg = ru
                                    ? "|cff9b59b6[Эхо Пустоты]|r " + name + " — ЛЕГЕНДА ПОЛЯ БОЯ!"
                                    : "|cff9b59b6[Echo of the Void]|r " + name + " — LEGEND OF THE BATTLEFIELD!";
                                break;
                        }
                        ChatHandler(killer->GetSession()).SendWorldText(msg);
                    }
                }
            }

            // --- «Месть Эха», фаза 1: павший с длинной серией получает ярость Пустоты.
            // Бафф активируется при возрождении (фаза 2, OnPlayerRespawn),
            // поэтому на жертву только запоминаем время активации. ---
            if (revengeStreakMin > 0 && victimStreak >= revengeStreakMin)
            {
                // Запоминаем серию; время выставим при респавне
                pendingRevenge[victimGuid] = victimStreak;

                LOG_INFO("module.echo-pvp", "Echo's Revenge pending: player %u died with streak %u >= %u",
                    victimGuid, victimStreak, revengeStreakMin);
            }
        }

        void OnPlayerMapChanged(Player* player) override
        {
            // «Месть Эха», фаза 2: активация баффа при возрождении
            if (!enable || revengeStreakMin == 0 || !player)
                return;

            uint32 guid = player->GetGUID().GetCounter();
            auto it = pendingRevenge.find(guid);
            if (it == pendingRevenge.end())
                return;

            uint32 victimStreak = it->second;
            pendingRevenge.erase(it);
            revengeUntil[guid] = GameTime::GetGameTime().count() + revengeDurationSecs;

            if (strcmp(GetLocale(player), "ru") == 0)
                player->SendSystemMessage("|cffc0392b[Месть Эха]|r Пустота помнит ваши победы. Ярость павших — с вами!");
            else
                player->SendSystemMessage("|cffc0392b[Echo's Revenge]|r The Void remembers your victories. The fury of the fallen is with you!");

            LOG_INFO("module.echo-pvp", "Echo's Revenge activated: player %u (streak %u) damage +%u%% for %us",
                guid, victimStreak, revengeDamageBonusPct, revengeDurationSecs);
        }

        void OnPlayerLogin(Player* player) override
        {
            // Ядровая копия серии сбрасывается при входе (истина — в realm_pvp_stats)
            playerStreaks[player->GetGUID().GetCounter()] = 0;
        }

        void OnPlayerLogout(Player* player) override
        {
            uint32 guid = player->GetGUID().GetCounter();
            playerStreaks.erase(guid);
            revengeUntil.erase(guid);
            pendingRevenge.erase(guid);
        }
    };
}

// Регистрация в ядре
EchoPvpWorldscript* EchoPvpWorldscriptInstance = new EchoPvpWorldscript();
EchoPvpUnitscript* EchoPvpUnitscriptInstance = new EchoPvpUnitscript();
EchoPvpPlayerscript* EchoPvpPlayerscriptInstance = new EchoPvpPlayerscript();

// Точка входа для генерируемого загрузчика модулей ядра
// (modules/CMakeLists.txt -> ConfigureScriptLoader -> AddEchoPvpScripts()).
// Модульная система AC требует эту функцию у каждого статического модуля.
void AddEchoPvpScripts()
{
    // Скрипты зарегистрированы глобальными инстансами выше.
}
