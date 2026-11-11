// ============================================================
// echo-pve — src/EchoPve.cpp
// PvE-механики Пустоты реалма «Эхо Пустоты» (AzerothCore).
//
// Лор-основание (docs/lore/universe.md):
//   «Ночью шёпот громче» — порождения Пустоты черпают силу
//   из разлома, и после заката их ярость усиливается.
//
// Функции:
//   1. Ночной скаляр урона: порождения Пустоты (список entry в
//      конфиге) ночью наносят повышенный урон игрокам.
//   2. Шанс выпадения Жетона Эха (item 70005) с пустотных существ
//      с внутренним кулдауном на игрока (анти-фарм).
//
// Локализация сообщений: ru/en по локали DBC клиента игрока
// (8 = ruRU, остальные — en).
//
// Сборка: модульная система AzerothCore подхватывает modules/echo-pve
// автоматически. Конфиг: echo-pve.conf.dist.
// ============================================================

#include "ScriptMgr.h"
#include "Unit.h"
#include "Player.h"
#include "Creature.h"
#include "Item.h"
#include "Config.h"
#include "Log.h"
#include "World.h"
#include "GameTime.h"
#include "Tokenize.h"
#include "StringFormat.h"
#include "Random.h"
#include "StringFormat.h"
#include "Common.h"
#include <unordered_map>
#include <unordered_set>
#include <cstdlib>
#include <cstring>
#include <string>

// Публичный API outbox-доставки echo-economy (модуль линкуется
// раньше в статической библиотеке modules: echo-economy < echo-pve
// по алфавиту). Реализация — modules/echo-economy/src/EchoEconomy.cpp.
extern void EchoEconomy_EnqueueTokenReward(Player* player, std::string const& rewardKey,
                                           uint32 tokens, std::string const& reason);

static std::string TrimStr(std::string s)
{
    std::string::size_type b = s.find_first_not_of(" \t\r\n");
    std::string::size_type e = s.find_last_not_of(" \t\r\n");
    return b == std::string::npos ? std::string() : s.substr(b, e - b + 1);
}

namespace
{
    // ---- Конфиг (кэшируется при загрузке) ----
    bool enable = true;
    float nightDamageScalar = 1.25f;
    uint32 nightStartHour = 18;
    uint32 nightEndHour = 6;
    float midnightBonusScalar = 1.15f;   // пик ночи (22:00–04:00): дополнительный множитель
    std::unordered_set<uint32> voidCreatures;
    float tokenDropChance = 0.0f;      // в процентах, 0 = выкл
    uint32 tokenDropCooldownSecs = 600;

    constexpr uint32 ECHO_TOKEN_ITEM = 70005; // «Жетон Эха»

    // Кулдаун выпадения жетона: guid игрока -> время последнего дропа (сек)
    std::unordered_map<uint32, time_t> tokenDropCooldown;

    // ------------------------------------------------------------
    // Профиль ночной силы (паттерн wow-mod-delves MakeScaleProfile):
    // множитель зависит от фазы ночи, а не один на всё окно.
    //   сумерки (окно старта, 2 ч)  -> 1.0 (без бонуса)
    //   ночь (18/6-окно)            -> nightDamageScalar
    //   пик (22:00–04:00)           -> nightDamageScalar * midnightBonusScalar
    // ------------------------------------------------------------
    bool IsNight(uint32 hour);

    float NightScalarForHour(uint32 hour)
    {
        if (!IsNight(hour))
            return 1.0f;

        bool isPeak = (hour >= 22 || hour < 4);
        float scalar = nightDamageScalar;
        if (isPeak)
            scalar *= midnightBonusScalar;
        return scalar;
    }

    // Текущий час игровых суток (0–23) из мирового времени
    uint32 CurrentHour()
    {
        return uint32((GameTime::GetGameTime().count() % DAY) / HOUR);
    }

    bool IsNight(uint32 hour)
    {
        // Окно 18:00–06:00 переходит через полночь
        return nightStartHour > nightEndHour
            ? (hour >= nightStartHour || hour < nightEndHour)
            : (hour >= nightStartHour && hour < nightEndHour);
    }

    bool IsVoidCreature(Creature const* c)
    {
        return c && voidCreatures.count(c->GetEntry()) > 0;
    }

    // Локаль игрока: "ru" | "en"
    char const* GetLocale(Player const* player)
    {
        return player && player->GetSession()->GetSessionDbcLocale() == LOCALE_ruRU ? "ru" : "en";
    }

    class EchoPveWorldscript : public WorldScript
    {
    public:
        EchoPveWorldscript() : WorldScript("EchoPveWorldscript") { }

        void OnAfterConfigLoad(bool /*reload*/) override
        {
            enable = sConfigMgr->GetOption<bool>("EchoPve.Enable", true);
            nightDamageScalar = sConfigMgr->GetOption<float>("EchoPve.NightDamageScalar", 1.25f);
            nightStartHour = sConfigMgr->GetOption<uint32>("EchoPve.NightStartHour", 18);
            nightEndHour = sConfigMgr->GetOption<uint32>("EchoPve.NightEndHour", 6);
            midnightBonusScalar = sConfigMgr->GetOption<float>("EchoPve.MidnightBonusScalar", 1.15f);
            tokenDropChance = sConfigMgr->GetOption<float>("EchoPve.TokenDropChance", 0.0f);
            tokenDropCooldownSecs = sConfigMgr->GetOption<uint32>("EchoPve.TokenDropCooldownSecs", 600);

            voidCreatures.clear();
            std::string list = sConfigMgr->GetOption<std::string>("EchoPve.VoidCreatures", "70100,70101,70105,70201,70202,70500,70510,70520");
            for (std::string_view token : Acore::Tokenize(list, ',', false))
            {
                if (uint32 entry = atoi(std::string(TrimStr(std::string(token))).c_str()))
                    voidCreatures.insert(entry);
            }

            LOG_INFO("module.echo-pve",
                "echo-pve загружен: enable=%s nightDmg=%.2f midnightBonus=%.2f (%02u:00-%02u:00) voidCreatures=%u tokenDrop=%.1f%% cd=%us",
                enable ? "on" : "off", nightDamageScalar, midnightBonusScalar, nightStartHour, nightEndHour,
                uint32(voidCreatures.size()), tokenDropChance, tokenDropCooldownSecs);
        }
    };

    class EchoPveUnitscript : public UnitScript
    {
    public:
        EchoPveUnitscript() : UnitScript("EchoPveUnitscript", true) { }

        // Урон существа игроку: ночной множитель для порождений Пустоты
        void ModifyMeleeDamage(Unit* target, Unit* attacker, uint32& damage) override
        {
            ApplyNightScalar(target, attacker, damage);
        }

        void ModifySpellDamageTaken(Unit* target, Unit* attacker, int32& damage, SpellInfo const* /*spellInfo*/) override
        {
            if (damage <= 0)
                return;
            uint32 dmg = uint32(damage);
            ApplyNightScalar(target, attacker, dmg);
            damage = int32(dmg);
        }

        void ModifyPeriodicDamageAurasTick(Unit* target, Unit* attacker, uint32& damage, SpellInfo const* /*spellInfo*/) override
        {
            ApplyNightScalar(target, attacker, damage);
        }

    private:
        void ApplyNightScalar(Unit* target, Unit* attacker, uint32& damage)
        {
            if (!enable || damage == 0)
                return;
            if (!target || !target->IsPlayer() || !attacker || attacker->IsPlayer())
                return;

            Player* victim = target->ToPlayer();
            Creature* attackerCreature = attacker->ToCreature();
            if (!victim || !attackerCreature || !IsVoidCreature(attackerCreature))
                return;

            // Профиль ночной силы (см. NightScalarForHour):
            // сумерки -> 1.0, ночь -> nightDamageScalar,
            // пик (22:00–04:00) -> nightDamageScalar * midnightBonus
            float scalar = NightScalarForHour(CurrentHour());
            if (scalar <= 1.0f)
                return;

            damage = uint32(damage * scalar);
        }
    };

    class EchoPvePlayerkillhook : public PlayerScript
    {
    public:
        EchoPvePlayerkillhook() : PlayerScript("EchoPvePlayerkillhook") { }
        // Награда за победу над Пустотой: шанс Жетона Эха

        void OnPlayerCreatureKill(Player* killer, Creature* killed) override
        {
            if (!enable || tokenDropChance <= 0.0f || !killer || !killed)
                return;

            if (!IsVoidCreature(killed) || killed->IsPet() || killed->IsTotem())
                return;

            // Анти-фарм: кулдаун на игрока
            time_t now = time(nullptr);
            auto it = tokenDropCooldown.find(killer->GetGUID().GetCounter());
            if (it != tokenDropCooldown.end() && now - it->second < tokenDropCooldownSecs)
                return;

            if (roll_chance_f(tokenDropChance))
            {
                // Durable-выдача через outbox echo-economy (паттерн
                // wow-mod-delves): событие не теряется при рестарте,
                // повторно не платит (reward_key уникален по мобу/времени).
                std::string rewardKey = "echo-pve:" + std::to_string(killer->GetGUID().GetCounter()) +
                                        ":" + std::to_string(uint64(now));
                EchoEconomy_EnqueueTokenReward(killer, rewardKey, 1, "pve_void_kill");
                tokenDropCooldown[killer->GetGUID().GetCounter()] = now;

                if (strcmp(GetLocale(killer), "ru") == 0)
                    killer->SendSystemMessage("|cff8e44ad[Эхо Пустоты]|r Из рассеявшейся Пустоты выпадает |cffFFFFFFЖетон Эха|r...");
                else
                    killer->SendSystemMessage("|cff8e44ad[Echo of the Void]|r An |cffFFFFFFEcho Token|r falls from the dissipated Void...");
            }
        }
    };
}

// Регистрация в ядре
EchoPveWorldscript* EchoPveWorldscriptInstance = new EchoPveWorldscript();
EchoPveUnitscript* EchoPveUnitscriptInstance = new EchoPveUnitscript();
EchoPvePlayerkillhook* EchoPvePlayerkillhookInstance = new EchoPvePlayerkillhook();

// Точка входа для генерируемого загрузчика модулей ядра
// (modules/CMakeLists.txt -> ConfigureScriptLoader -> AddEchoPveScripts()).
// Модульная система AC требует эту функцию у каждого статического модуля.
void AddEchoPveScripts()
{
    // Скрипты зарегистрированы глобальными инстансами выше.
}
