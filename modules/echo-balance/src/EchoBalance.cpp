// ============================================================
// echo-balance — src/EchoBalance.cpp
// Модуль баланса реалма «Эхо Пустоты» (AzerothCore).
//
// Функции:
//   1. Глобальные мультипликаторы урона/лечения (UnitScript).
//   2. Отсечка ваншотов: урон существа игроку за один удар
//      урезается до MaxHitPercent% HP цели (если включено).
//   3. Бонус жетонов за завершение кампании выдаётся на Lua
//      (00_CampaignRegistry -> balance); модуль лишь читает
//      конфиг-значение и пишет его в лог для сведения.
//
// Сборка: модульная система AzerothCore подхватывает modules/echo-balance
// автоматически (см. CMakeLists.txt). Конфиг: echo-balance.conf.dist.
// ============================================================

#include "ScriptMgr.h"
#include "ScriptedCreature.h"
#include "Unit.h"
#include "Player.h"
#include "Config.h"
#include "Log.h"

namespace
{
    // ---- Конфиг (кэшируется при загрузке) ----
    float worldDamageScalar = 1.0f;
    float playerDamageScalar = 1.0f;
    float healingScalar = 1.0f;
    float maxHitPercent = 0.0f;      // 0 = выкл
    float bossDamageScalar = 1.0f;

    class EchoBalanceWorldscript : public WorldScript
    {
    public:
        EchoBalanceWorldscript() : WorldScript("EchoBalanceWorldscript") { }

        void OnAfterConfigLoad(bool /*reload*/) override
        {
            worldDamageScalar  = sConfigMgr->GetFloatDefault("EchoBalance.WorldDamageScalar", 1.0f);
            playerDamageScalar = sConfigMgr->GetFloatDefault("EchoBalance.PlayerDamageScalar", 1.0f);
            healingScalar      = sConfigMgr->GetFloatDefault("EchoBalance.HealingScalar", 1.0f);
            maxHitPercent      = sConfigMgr->GetFloatDefault("EchoBalance.MaxHitPercent", 0.0f);
            bossDamageScalar   = sConfigMgr->GetFloatDefault("EchoBalance.BossDamageScalar", 1.0f);

            LOG_INFO("module.echo-balance",
                "echo-balance загружен: worldDmg=%.2f playerDmg=%.2f heal=%.2f maxHit=%.0f%% bossDmg=%.2f",
                worldDamageScalar, playerDamageScalar, healingScalar, maxHitPercent, bossDamageScalar);
        }
    };

    class EchoBalanceUnitscript : public UnitScript
    {
    public:
        EchoBalanceUnitscript() : UnitScript("EchoBalanceUnitscript", true) { }

        // --- Урон, получаемый игроком от существ ---
        void ModifyPeriodicDamageAurasTick(Unit* target, Unit* attacker, uint32& damage) override
        {
            if (!attacker || attacker->IsPlayer() || !target || !target->IsPlayer())
                return;

            float scalar = worldDamageScalar;

            // Боссы (rank 3) — дополнительный множитель
            if (Creature* c = attacker->ToCreature())
                if (c->IsWorldBoss() || c->GetCreatureTemplate()->rank == CREATURE_ELITE_WORLDBOSS)
                    scalar *= bossDamageScalar;

            damage = uint32(damage * scalar);
            ClampOneHit(target, damage);
        }

        void ModifyMeleeDamage(Unit* target, Unit* attacker, uint32& damage) override
        {
            ApplyDamageScalar(target, attacker, damage);
        }

        void ModifySpellDamageTaken(Unit* target, Unit* attacker, int32& damage) override
        {
            if (damage <= 0)
                return;
            uint32 dmg = uint32(damage);
            ApplyDamageScalar(target, attacker, dmg);
            damage = int32(dmg);
        }

        void ModifyHealReceived(Unit* target, Unit* healer, uint32& heal) override
        {
            if (!healer || !healer->IsPlayer() || !target || !target->IsPlayer())
                return;
            heal = uint32(heal * healingScalar);
        }

    private:
        void ApplyDamageScalar(Unit* target, Unit* attacker, uint32& damage)
        {
            if (!attacker || !target)
                return;

            // Игрок бьёт существо: множитель игрока
            if (attacker->IsPlayer() && !target->IsPlayer())
            {
                damage = uint32(damage * playerDamageScalar);
                return;
            }

            // Существо бьёт игрока: множитель мира (+босс-фактор)
            if (!attacker->IsPlayer() && target->IsPlayer())
            {
                float scalar = worldDamageScalar;
                if (Creature* c = attacker->ToCreature())
                    if (c->GetCreatureTemplate()->rank == CREATURE_ELITE_WORLDBOSS)
                        scalar *= bossDamageScalar;

                damage = uint32(damage * scalar);
                ClampOneHit(target, damage);
            }
        }

        // Отсечка ваншотов: урон > MaxHitPercent% макс. HP цели
        // урезается до этого порога (только существа -> игроки).
        void ClampOneHit(Unit* target, uint32& damage)
        {
            if (maxHitPercent <= 0.0f || !target || !target->IsPlayer())
                return;

            uint32 maxHp = target->GetMaxHealth();
            if (maxHp == 0)
                return;

            uint32 cap = uint32(maxHp * maxHitPercent / 100.0f);
            if (cap > 0 && damage > cap)
                damage = cap;
        }
    };
}

// Регистрация в ядре
EchoBalanceWorldscript* EchoBalanceWorldscriptInstance = new EchoBalanceWorldscript();
EchoBalanceUnitscript*  EchoBalanceUnitscriptInstance  = new EchoBalanceUnitscript();

// Точка входа для генерируемого загрузчика модулей ядра
// (modules/CMakeLists.txt -> ConfigureScriptLoader -> AddEchoBalanceScripts()).
// Модульная система AC требует эту функцию у каждого статического модуля.
void AddEchoBalanceScripts()
{
    // Скрипты зарегистрированы глобальными инстансами выше.
}
