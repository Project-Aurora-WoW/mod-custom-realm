// ============================================================
// echo-startup — src/EchoStartup.cpp
// Стартовый набор реалма «Эхо Пустоты» (AzerothCore).
//
// Лор-основание (docs/lore/universe.md):
//   Орден Рассвета встречает каждого героя, способного услышать
//   шёпот, и снабжает его перед первой встречей с Пустотой.
//
// Функции:
//   1. При первом входе (персонаж-новичок: played time < порога,
//      уровень >= MinLevel) выдаёт стартовые предметы из конфига
//      и бафф «Напутствие Ордена».
//   2. Локализация сообщений ru/en по DBC-локали клиента.
//
// Сборка: модульная система AzerothCore подхватывает
// modules/echo-startup автоматически. Конфиг: echo-startup.conf.dist.
// ============================================================

#include "ScriptMgr.h"
#include "Player.h"
#include "Config.h"
#include "Log.h"
#include "World.h"
#include "SpellMgr.h"
#include <vector>
#include <cstring>

namespace
{
    // ---- Конфиг (кэшируется при загрузке) ----
    bool enable = true;
    uint32 newbieMaxPlayedTimeSecs = 60;
    uint32 minLevel = 0;
    std::vector<std::pair<uint32, uint32>> startupItems; // entry, count
    uint32 buffSpell = 58452;

    char const* GetLocale(Player const* player)
    {
        return player && player->GetDbcLocale() == LOCALE_ruRU ? "ru" : "en";
    }

    class EchoStartupWorldscript : public WorldScript
    {
    public:
        EchoStartupWorldscript() : WorldScript("EchoStartupWorldscript") { }

        void OnAfterConfigLoad(bool /*reload*/) override
        {
            enable = sConfigMgr->GetBoolDefault("EchoStartup.Enable", true);
            newbieMaxPlayedTimeSecs = sConfigMgr->GetIntDefault("EchoStartup.NewbieMaxPlayedTimeSecs", 60);
            minLevel = sConfigMgr->GetIntDefault("EchoStartup.MinLevel", 0);
            buffSpell = sConfigMgr->GetIntDefault("EchoStartup.BuffSpell", 58452);

            startupItems.clear();
            std::string list = sConfigMgr->GetStringDefault("EchoStartup.Items", "33470:3,33475:3,43005:5,70005:2");
            for (std::string_view token : Acore::StringSplit(list, ','))
            {
                std::string pair = std::string(Acore::Trim(token));
                auto colon = pair.find(':');
                if (colon == std::string::npos)
                    continue;
                uint32 entry = atoi(pair.substr(0, colon).c_str());
                uint32 count = atoi(pair.substr(colon + 1).c_str());
                if (entry && count)
                    startupItems.push_back({ entry, count });
            }

            LOG_INFO("module.echo-startup",
                "echo-startup загружен: enable=%s newbieTime=%us minLvl=%u items=%u buff=%u",
                enable ? "on" : "off", newbieMaxPlayedTimeSecs, minLevel,
                uint32(startupItems.size()), buffSpell);
        }
    };

    class EchoStartupPlayerscript : public PlayerScript
    {
    public:
        EchoStartupPlayerscript() : PlayerScript("EchoStartupPlayerscript") { }

        // Первый вход: детект новичка по played time
        void OnLogin(Player* player) override
        {
            if (!enable || !player)
                return;

            // Новичок: суммарное игровое время персонажа меньше порога
            if (player->GetTotalPlayedTime() >= newbieMaxPlayedTimeSecs)
                return;

            if (minLevel > 0 && player->GetLevel() < minLevel)
                return;

            bool ru = (strcmp(GetLocale(player), "ru") == 0);

            // Приветствие Ордена
            if (ru)
                player->SendSystemMessage("|cff5dade2[Орден Рассвета]|r Добро пожаловать, герой. Шёпот уже назвал твоё имя — не слушай его. Возьми снаряжение Ордена и будь готов.");
            else
                player->SendSystemMessage("|cff5dade2[Order of Dawn]|r Welcome, hero. The Whisper already knows your name — do not listen to it. Take the Order's gear and be ready.");

            // Стартовые предметы
            for (auto const& [entry, count] : startupItems)
            {
                if (sObjectMgr->GetItemTemplate(entry))
                    player->AddItem(entry, count);
                else
                    LOG_ERROR("module.echo-startup", "Startup item %u not found in item_template — пропущен", entry);
            }

            // Бафф «Напутствие Ордена»
            if (buffSpell && sSpellMgr->GetSpellInfo(buffSpell))
                player->CastSpell(player, buffSpell, true);

            LOG_INFO("module.echo-startup", "Startup kit granted to %s (guid %u, played %us)",
                player->GetName().c_str(), player->GetGUID().GetCounter(),
                uint32(player->GetTotalPlayedTime()));
        }
    };
}

// Регистрация в ядре
EchoStartupWorldscript* EchoStartupWorldscriptInstance = new EchoStartupWorldscript();
EchoStartupPlayerscript* EchoStartupPlayerscriptInstance = new EchoStartupPlayerscript();

// Точка входа для генерируемого загрузчика модулей ядра
void AddEchoStartupScripts()
{
    // Скрипты зарегистрированы глобальными инстансами выше.
}
