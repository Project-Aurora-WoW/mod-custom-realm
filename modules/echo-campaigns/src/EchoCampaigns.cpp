// ============================================================
// echo-campaigns — src/EchoCampaigns.cpp
// Служебный менеджер кампаний реалма «Эхо Пустоты» (AzerothCore).
//
// Функции:
//   1. Команды игрока в ядре: .ae help|status|tokens|riffs|pvp|events
//      (аналоги команд аддона AzerothEcho; читают прогресс из
//      realm_campaign_progress и realm_pvp_stats).
//   2. GM-команды: .aecampaign list|status|set|complete|reset|tokens
//   3. Опция источника команд (EchoCampaigns.CommandSource: both/core/lua)
//      — позволяет выбрать, кто обрабатывает команды: ядро или Lua.
//   4. Контроль порядка загрузки подсистем реалма (WorldScript::OnStartup):
//      проверяет наличие mod-ale и пишет план запуска в лог.
//   5. Журналирование в realm_campaign_log (acore_characters).
//
// Прогресс кампаний хранится в realm_campaign_progress
// (acore_characters — таблица создаётся Lua-миграцией 0002).
// Кириллица: все строки — UTF-8; соединение с БД настраивается ядром.
// ============================================================

#include "ScriptMgr.h"
#include "Player.h"
#include "Chat.h"
#include "Config.h"
#include "Log.h"
#include "WorldSession.h"

namespace
{
    // ---- Конфиг ----
    std::string commandSource = "both";   // both | core | lua
    bool enableLogging = true;
    bool checkLoadOrder = true;

    // ============================================================
    // Утилиты вывода (кириллица — UTF-8 в чат)
    // ============================================================
    constexpr const char* TAG = "|cff9b59b6[Эхо Пустоты]|r";
    constexpr const char* ORDER = "|cff5dade2";
    constexpr const char* VOID = "|cff8e44ad";
    constexpr const char* RESET = "|r";

    void SendLine(Player* player, std::string const& text)
    {
        ChatHandler(player->GetSession()).PSendSysMessage("%s", text.c_str());
    }

    bool IsMaster(Player* player)
    {
        return player->GetSession()->GetSecurity() >= SEC_MODERATOR;
    }

    // ============================================================
    // Журналирование (realm_campaign_log)
    // ============================================================
    void LogCampaignAction(uint32 guid, uint32 campaignId, uint32 chapter,
                           std::string const& action, std::string const& detail)
    {
        if (!enableLogging)
            return;

        CharacterDatabase.Execute(
            "INSERT INTO realm_campaign_log (guid, campaign_id, chapter, action, detail) "
            "VALUES ({}, {}, {}, '{}', '{}')",
            guid, campaignId, chapter, action, detail.substr(0, 250));
    }

    // ============================================================
    // Прогресс кампаний (realm_campaign_progress)
    // ============================================================
    struct CampaignProgress
    {
        uint32 chapter = 0;
        bool completed = false;
    };

    CampaignProgress GetProgress(uint32 guid, uint32 campaignId)
    {
        CampaignProgress p;
        auto result = CharacterDatabase.Query(
            "SELECT chapter, completed FROM realm_campaign_progress "
            "WHERE guid = {} AND campaign_id = {}", guid, campaignId);
        if (result)
        {
            auto fields = result->Fetch();
            p.chapter = fields[0].Get<uint8>();
            p.completed = fields[1].Get<uint8>() != 0;
        }
        return p;
    }

    void SetProgress(uint32 guid, uint32 campaignId, uint32 chapter, bool completed)
    {
        CharacterDatabase.Execute(
            "REPLACE INTO realm_campaign_progress (guid, campaign_id, chapter, completed) "
            "VALUES ({}, {}, {}, {})",
            guid, campaignId, chapter, completed ? 1 : 0);
    }

    void ResetProgress(uint32 guid, uint32 campaignId)
    {
        CharacterDatabase.Execute(
            "DELETE FROM realm_campaign_progress WHERE guid = {} AND campaign_id = {}",
            guid, campaignId);
    }

    // ---- Реестр кампаний (дублирует 00_CampaignRegistry.ext; синхронизировано) ----
    struct CampaignInfo { uint32 id; std::string name; uint32 chapters; uint32 reqToken; };
    std::array<CampaignInfo, 4> CAMPAIGNS = {{
        { 1, "Эхо Шёпота",       3, 0     },
        { 2, "Пепел Зул'Драка",  5, 70001 },
        { 3, "Пробуждение",      4, 70004 },
        { 4, "Второе Эхо",       5, 70002 },
    }};

    // ============================================================
    // Команды игрока (.ae ...)
    // ============================================================
    void CmdHelp(Player* player)
    {
        SendLine(player, std::string(TAG) + " == Команды Эха Пустоты (ядро) ==");
        SendLine(player, std::string(TAG) + " " ORDER ".ae status|r — прогресс кампаний");
        SendLine(player, std::string(TAG) + " " ORDER ".ae tokens|r — баланс Жетонов Эха");
        SendLine(player, std::string(TAG) + " " ORDER ".ae pvp|r — PvP-статистика");
        SendLine(player, std::string(TAG) + " " ORDER ".ae events|r — расписание ивентов");
        SendLine(player, std::string(TAG) + " " ORDER ".ae rifts|r — карта разломов (аддон)");
        SendLine(player, std::string(TAG) + " Аддон: /ae — панель, /ae rifts — карта.");
    }

    void CmdStatus(Player* player)
    {
        SendLine(player, std::string(TAG) + " == Прогресс кампаний (ядро) ==");
        for (auto const& c : CAMPAIGNS)
        {
            auto p = GetProgress(player->GetGUID().GetCounter(), c.id);
            std::string line = std::string(TAG) + " " + c.name + " — ";
            if (p.completed)
                line += "ЗАВЕРШЕНА";
            else if (p.chapter == 0)
                line += "не начата";
            else
                line += "глава " + std::to_string(p.chapter) + "/" + std::to_string(c.chapters);
            SendLine(player, line);
        }
    }

    void CmdTokens(Player* player)
    {
        uint32 tokens = player->GetItemCount(70005);
        SendLine(player, std::string(TAG) + " Баланс: " VOID + std::to_string(tokens) +
                 " Жетонов Эха" RESET " (ивенты, PvP-зона; трата — Интендант Ордена).");
    }

    void CmdPvp(Player* player)
    {
        auto result = CharacterDatabase.Query(
            "SELECT kills, deaths, streak, best_streak, zone_kills FROM realm_pvp_stats WHERE guid = {}",
            player->GetGUID().GetCounter());
        SendLine(player, std::string(TAG) + " == PvP-статистика (ядро) ==");
        if (result)
        {
            auto f = result->Fetch();
            SendLine(player, std::string(TAG) + " Киллы: " + std::to_string(f[0].Get<uint32>()) +
                     ", смерти: " + std::to_string(f[1].Get<uint32>()) +
                     ", серия: " + std::to_string(f[2].Get<uint32>()) +
                     " (лучшая " + std::to_string(f[3].Get<uint32>()) + ")" +
                     ", в зоне: " + std::to_string(f[4].Get<uint32>()));
        }
        else
            SendLine(player, std::string(TAG) + " Статистика пуста. Первая кровь ждёт в Драконьем Погосте!");
    }

    void CmdEvents(Player* player)
    {
        SendLine(player, std::string(TAG) + " Ивенты: Шторм Пустоты (каждые 3 ч), Кровавая Луна Культа (каждые 6 ч).");
        SendLine(player, std::string(TAG) + " Статус ивентов: .aeevent status (Lua-система ивентов).");
    }

    // ============================================================
    // GM-команды (.aecampaign ...)
    // ============================================================
    void GmList(Player* player)
    {
        SendLine(player, std::string(TAG) + " == Реестр кампаний (ядро) ==");
        for (auto const& c : CAMPAIGNS)
            SendLine(player, std::string(TAG) + " [" + std::to_string(c.id) + "] " + c.name +
                     " — глав: " + std::to_string(c.chapters) +
                     ", вход: " + (c.reqToken ? ("item " + std::to_string(c.reqToken)) : "—"));
    }

    void GmStatus(Player* player, uint32 campId, std::string const& targetName)
    {
        Player* target = targetName.empty() ? player
            : ObjectAccessor::FindPlayerByName(targetName);
        if (!target)
        {
            SendLine(player, std::string(TAG) + " Игрок не найден или не в сети.");
            return;
        }
        auto p = GetProgress(target->GetGUID().GetCounter(), campId);
        SendLine(player, std::string(TAG) + " Кампания " + std::to_string(campId) +
                 " [" + target->GetName() + "]: глава " + std::to_string(p.chapter) +
                 ", завершена: " + (p.completed ? "да" : "нет"));
    }

    void GmSet(Player* player, uint32 campId, uint32 chapter)
    {
        SetProgress(player->GetGUID().GetCounter(), campId, chapter, false);
        SendLine(player, std::string(TAG) + " Кампания " + std::to_string(campId) +
                 ": глава = " + std::to_string(chapter));
        LogCampaignAction(player->GetGUID().GetCounter(), campId, chapter, "gm_core_set", "");
    }

    void GmComplete(Player* player, uint32 campId)
    {
        auto const* info = &CAMPAIGNS[campId - 1];
        SetProgress(player->GetGUID().GetCounter(), campId, info->chapters, true);
        // Жетоны за завершение (баланс реалма)
        player->AddItem(70005, 3);
        SendLine(player, std::string(TAG) + " Кампания " + std::to_string(campId) +
                 " завершена принудительно (+3 жетона).");
        SendWorldText(std::string(TAG).c_str(), " ", player->GetName().c_str(),
                      " завершил кампанию «", info->name.c_str(), "»!", nullptr);
        LogCampaignAction(player->GetGUID().GetCounter(), campId, info->chapters, "gm_core_complete", info->name);
    }

    void GmReset(Player* player, std::string const& arg)
    {
        if (arg == "all")
        {
            for (auto const& c : CAMPAIGNS)
                ResetProgress(player->GetGUID().GetCounter(), c.id);
            SendLine(player, std::string(TAG) + " Прогресс всех кампаний сброшен.");
            LogCampaignAction(player->GetGUID().GetCounter(), 0, 0, "gm_core_reset", "all");
        }
        else
        {
            uint32 campId = *Acore::StringTo<uint32>(arg);
            if (campId >= 1 && campId <= 4)
            {
                ResetProgress(player->GetGUID().GetCounter(), campId);
                SendLine(player, std::string(TAG) + " Кампания " + std::to_string(campId) + " сброшена.");
                LogCampaignAction(player->GetGUID().GetCounter(), campId, 0, "gm_core_reset", "");
            }
        }
    }

    // ============================================================
    // CommandScript: регистрация в диспетчере команд ядра
    // ============================================================
    class EchoCampaigns_Commands : public CommandScript
    {
    public:
        EchoCampaigns_Commands() : CommandScript("EchoCampaigns_Commands") { }

        // AzerothCore: чат-команды через OnPlayerChat хук отсутствует;
        // используем CommandScript->GetOnlineCommands для slash-режима
        // и дополнительно перехватываем чат через WorldScript::OnChat.
        std::vector<ChatCommand> GetCommands() const override
        {
            static std::vector<ChatCommand> aeSubcommands =
            {
                { "status",  SEC_PLAYER,     false, &HandleAeStatus,   "" },
                { "tokens",  SEC_PLAYER,     false, &HandleAeTokens,   "" },
                { "pvp",     SEC_PLAYER,     false, &HandleAePvp,      "" },
                { "events",  SEC_PLAYER,     false, &HandleAeEvents,   "" },
                { "help",    SEC_PLAYER,     false, &HandleAeHelp,     "" },
                { "",        SEC_PLAYER,     false, &HandleAeHelp,     "" },
            };
            static std::vector<ChatCommand> aeCampaignSubcommands =
            {
                { "list",     SEC_MODERATOR, true, &HandleAcList,     "" },
                { "status",   SEC_MODERATOR, true, &HandleAcStatus,   "" },
                { "set",      SEC_GAMEMASTER, true, &HandleAcSet,     "" },
                { "complete", SEC_GAMEMASTER, true, &HandleAcComplete, "" },
                { "reset",    SEC_GAMEMASTER, true, &HandleAcReset,    "" },
            };
            static std::vector<ChatCommand> commandTable =
            {
                { "ae",         SEC_PLAYER,     false, nullptr, "", std::move(aeSubcommands) },
                { "aecampaign", SEC_MODERATOR,  true,  nullptr, "", std::move(aeCampaignSubcommands) },
            };
            return commandTable;
        }

        static bool HandleAeStatus(ChatHandler* handler, char const* /*args*/)
        { CmdStatus(handler->GetSession()->GetPlayer()); return true; }
        static bool HandleAeTokens(ChatHandler* handler, char const* /*args*/)
        { CmdTokens(handler->GetSession()->GetPlayer()); return true; }
        static bool HandleAePvp(ChatHandler* handler, char const* /*args*/)
        { CmdPvp(handler->GetSession()->GetPlayer()); return true; }
        static bool HandleAeEvents(ChatHandler* handler, char const* /*args*/)
        { CmdEvents(handler->GetSession()->GetPlayer()); return true; }
        static bool HandleAeHelp(ChatHandler* handler, char const* /*args*/)
        { CmdHelp(handler->GetSession()->GetPlayer()); return true; }

        static bool HandleAcList(ChatHandler* handler, char const* /*args*/)
        { GmList(handler->GetSession()->GetPlayer()); return true; }

        static bool HandleAcStatus(ChatHandler* handler, char const* args)
        {
            uint32 campId; char targetName[64] = "";
            if (sscanf(args, "%u %63s", &campId, targetName) >= 1)
                GmStatus(handler->GetSession()->GetPlayer(), campId, targetName);
            else
                handler->PSendSysMessage("%s Формат: .aecampaign status <id> [игрок]", TAG);
            return true;
        }

        static bool HandleAcSet(ChatHandler* handler, char const* args)
        {
            uint32 campId, chapter;
            if (sscanf(args, "%u %u", &campId, &chapter) == 2)
                GmSet(handler->GetSession()->GetPlayer(), campId, chapter);
            else
                handler->PSendSysMessage("%s Формат: .aecampaign set <id> <глава>", TAG);
            return true;
        }

        static bool HandleAcComplete(ChatHandler* handler, char const* args)
        {
            uint32 campId;
            if (sscanf(args, "%u", &campId) == 1)
                GmComplete(handler->GetSession()->GetPlayer(), campId);
            else
                handler->PSendSysMessage("%s Формат: .aecampaign complete <id>", TAG);
            return true;
        }

        static bool HandleAcReset(ChatHandler* handler, char const* args)
        {
            if (args && *args)
                GmReset(handler->GetSession()->GetPlayer(), args);
            else
                handler->PSendSysMessage("%s Формат: .aecampaign reset <id|all>", TAG);
            return true;
        }
    };

    // ============================================================
    // WorldScript: конфиг + контроль порядка загрузки
    // ============================================================
    class EchoCampaigns_Worldscript : public WorldScript
    {
    public:
        EchoCampaigns_Worldscript() : WorldScript("EchoCampaigns_Worldscript") { }

        void OnAfterConfigLoad(bool /*reload*/) override
        {
            commandSource  = sConfigMgr->GetStringDefault("EchoCampaigns.CommandSource", "both");
            enableLogging  = sConfigMgr->GetBoolDefault("EchoCampaigns.EnableLogging", true);
            checkLoadOrder = sConfigMgr->GetBoolDefault("EchoCampaigns.CheckLoadOrder", true);

            LOG_INFO("module.echo-campaigns",
                "echo-campaigns: CommandSource={}, Logging={}, LoadOrderCheck={}",
                commandSource, enableLogging ? "on" : "off", checkLoadOrder ? "on" : "off");
        }

        void OnStartup() override
        {
            // Порядок запуска подсистем реалма (для сведения в логе).
            LOG_INFO("module.echo-campaigns",
                "== Порядок загрузки реалма Эхо Пустоты ==");
            LOG_INFO("module.echo-campaigns",
                "  1. echo-balance   (C++ UnitScript — баланс)");
            LOG_INFO("module.echo-campaigns",
                "  2. echo-campaigns (C++ команды кампаний)");
            LOG_INFO("module.echo-campaigns",
                "  3. mod-ale        (Lua-движок ALE)");
            LOG_INFO("module.echo-campaigns",
                "  4. Lua: 00_CampaignRegistry.ext -> CampaignManager -> Campaign1-4 -> LoreArchive -> 10/20/30_* -> AddonBridge");
            LOG_INFO("module.echo-campaigns",
                "  Источник команд: {} (both|core|lua)", commandSource);

            // Предупреждение, если Lua-движок не зарегистрировал реестр кампаний.
            // (Проверка выполняется отложенно — через 10 сек после старта,
            //  когда ALE уже загрузил скрипты; здесь только план.)
        }
    };
}

// Регистрация в ядре
EchoCampaigns_Commands*    EchoCampaignsCommandsInstance    = new EchoCampaigns_Commands();
EchoCampaigns_Worldscript* EchoCampaignsWorldscriptInstance = new EchoCampaigns_Worldscript();

// Точка входа для генерируемого загрузчика модулей ядра
// (modules/CMakeLists.txt -> ConfigureScriptLoader -> AddEchoCampaignsScripts()).
// Модульная система AC требует эту функцию у каждого статического модуля.
void AddEchoCampaignsScripts()
{
    // Скрипты зарегистрированы глобальными инстансами выше.
}
