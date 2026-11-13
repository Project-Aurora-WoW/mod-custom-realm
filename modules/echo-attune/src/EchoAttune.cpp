// ============================================================
// echo-attune — src/EchoAttune.cpp
// Аттюнмент Мировой Души (параллельная кампания «Мировая Душа»).
//
// Лор-основание: земные глубины помнят мир до раскола Пустоты.
// Надетый предмет «срастается» с владельцем во время боя, копя
// пер-предметный прогресс по его item-guid. Прогресс хранится в
// realm_echo_attune (acore_characters) и читается Lua-скриптом
// 39_EchoWorldsoul.lua для UI/мастерства.
//
// Хуки (ядро 1459af9):
//   PlayerScript::OnPlayerEquip / OnPlayerUnequip — фиксация надетого предмета;
//   SessionScript::OnSessionUpdate                — накопление прогресса за бой (тик);
//   PlayerScript::OnPlayerLogout                  — flush в БД.
// Сборка: модульная система AzerothCore. Конфиг: echo-attune.conf.dist.
// ============================================================

#include "ScriptMgr.h"
#include "Player.h"
#include "Item.h"
#include "WorldSession.h"
#include "Config.h"
#include "Log.h"
#include "DatabaseEnv.h"
#include <unordered_map>
#include <vector>

namespace
{
    // ---- Конфиг ----
    bool enable = true;
    uint32 minLevel = 80;
    uint32 progressPerSecond = 2;
    uint32 maxProgress = 1000;
    uint32 maxAttunedPerPlayer = 200;

    struct AttuneEntry
    {
        uint32 itemGuid;
        uint32 entry;
        uint32 progress;
    };

    // Кэш: [player-guid-low] -> { item-guid -> {entry, progress} }
    using PlayerKey = uint32;
    std::unordered_map<PlayerKey, std::unordered_map<uint32, AttuneEntry>> sCache;

    void FlushPlayer(Player* player)
    {
        if (!player) return;
        PlayerKey key = player->GetGUID().GetCounter();
        uint32 accountid = player->GetSession()->GetAccountId();
        std::unordered_map<uint32, AttuneEntry> items;
        {
            auto it = sCache.find(key);
            if (it == sCache.end() || it->second.empty()) return;
            items = std::move(it->second);
            sCache.erase(it);
        }

        CharacterDatabaseTransaction trans = CharacterDatabase.BeginTransaction();
        for (auto& [guid, e] : items)
        {
            if (e.progress <= 0) continue;
            trans->Append("INSERT INTO realm_echo_attune (accountid, item_guid, entry, progress, max_prog) "
                          "VALUES (%u, %u, %u, %u, %u) "
                          "ON DUPLICATE KEY UPDATE progress = LEAST(progress + VALUES(progress), max_prog), "
                          "entry = VALUES(entry), max_prog = VALUES(max_prog)",
                          accountid, e.itemGuid, e.entry, e.progress, maxProgress);
        }
        CharacterDatabase.CommitTransaction(trans);
    }

    class EchoAttunePlayerscript : public PlayerScript
    {
    public:
        EchoAttunePlayerscript() : PlayerScript("EchoAttunePlayerscript") { }

        void OnPlayerLogin(Player* player) override
        {
            if (!player) return;
            sCache.erase(player->GetGUID().GetCounter());
        }

        void OnPlayerLogout(Player* player) override
        {
            if (!player) return;
            FlushPlayer(player);
        }

        void OnPlayerEquip(Player* player, Item* it, uint8 /*bag*/, uint8 /*slot*/, bool /*update*/) override
        {
            if (!enable || !player || !it) return;
            if (player->GetLevel() < minLevel) return;
            PlayerKey key = player->GetGUID().GetCounter();
            auto& m = sCache[key];
            if (m.size() >= maxAttunedPerPlayer) return;
            AttuneEntry e{ it->GetGUID().GetCounter(), it->GetEntry(), 0 };
            // Не затираем уже существующий прогресс (повторный экип того же предмета).
            m.emplace(e.itemGuid, e);
        }

        void OnPlayerUnequip(Player* player, Item* it) override
        {
            if (!player || !it) return;
            PlayerKey key = player->GetGUID().GetCounter();
            auto itM = sCache.find(key);
            if (itM == sCache.end()) return;
            itM->second.erase(it->GetGUID().GetCounter());
        }
    };

    // Накопление за активный бой: OnSessionUpdate принадлежит SessionScript.
    class EchoAttuneSessionscript : public SessionScript
    {
    public:
        EchoAttuneSessionscript() : SessionScript("EchoAttuneSessionscript") { }

        void OnSessionUpdate(WorldSession* session, uint32 diff) override
        {
            if (!enable || !session) return;
            Player* player = session->GetPlayer();
            if (!player) return;
            if (player->GetLevel() < minLevel) return;
            if (!player->IsInCombat()) return;

            PlayerKey key = player->GetGUID().GetCounter();
            auto it = sCache.find(key);
            if (it == sCache.end() || it->second.empty()) return;
            uint32 inc = uint32(diff / 1000.0f * progressPerSecond);
            if (inc == 0) return;
            for (auto& [guid, e] : it->second)
                if (e.progress < maxProgress)
                    e.progress = std::min<uint32>(maxProgress, e.progress + inc);
        }
    };

    class EchoAttuneWorldscript : public WorldScript
    {
    public:
        EchoAttuneWorldscript() : WorldScript("EchoAttuneWorldscript") { }

        void OnAfterConfigLoad(bool /*reload*/) override
        {
            enable = sConfigMgr->GetOption<bool>("EchoAttune.Enable", true);
            minLevel = sConfigMgr->GetOption<uint32>("EchoAttune.MinLevel", 80);
            progressPerSecond = sConfigMgr->GetOption<uint32>("EchoAttune.ProgressPerSecond", 2);
            maxProgress = sConfigMgr->GetOption<uint32>("EchoAttune.MaxProgress", 1000);
            maxAttunedPerPlayer = sConfigMgr->GetOption<uint32>("EchoAttune.MaxAttunedPerPlayer", 200);

            LOG_INFO("module.echo-attune",
                "echo-attune загружен: enable=%s minLvl=%u prog/sec=%u max=%u cap=%u",
                enable ? "on" : "off", minLevel, progressPerSecond, maxProgress,
                maxAttunedPerPlayer);
        }
    };
}

EchoAttunePlayerscript* EchoAttunePlayerscriptInstance = new EchoAttunePlayerscript();
EchoAttuneSessionscript* EchoAttuneSessionscriptInstance = new EchoAttuneSessionscript();
EchoAttuneWorldscript* EchoAttuneWorldscriptInstance = new EchoAttuneWorldscript();

void Addecho_attuneScripts()
{
    // Скрипты зарегистрированы глобальными инстансами выше.
}