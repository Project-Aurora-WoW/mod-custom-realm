// ============================================================
// echo-economy — src/EchoEconomy.cpp
// Экономика реалма «Эхо Пустоты» (AzerothCore).
//
// Лор-основание (docs/lore/universe.md):
//   «Пустота забираёт своё» — жетоны, скопленные в избытке,
//   истаивают, как эхо без камня. Культ объясняет это волей
//   разлома; на деле — защита экономики реалма.
//
// Функции:
//   1. Слив избытка жетонов при входе (анти-инфляция).
//   2. Outbox-доставка жетонов (паттерн wow-mod-delves:
//      DelveRewardDelivery): намерение награды пишется в
//      realm_token_outbox с уникальным reward_key; доставка
//      идемпотентна — событие не может заплатить дважды, рестарт
//      между событием и выдачей награду не теряет. Квитанции —
//      realm_token_receipt.
//   3. Локализация сообщений ru/en по DBC-локали клиента.
//
// Сборка: модульная система AzerothCore подхватывает
// modules/echo-economy автоматически. Конфиг: echo-economy.conf.dist.
// Миграции: 0015_token_outbox.sql (acore_characters).
// ============================================================

#include "ScriptMgr.h"
#include "Player.h"
#include "Config.h"
#include "Log.h"
#include "World.h"
#include "GameTime.h"
#include "DatabaseEnv.h"
#include <cstring>
#include <ctime>

namespace
{
    // ---- Конфиг (кэшируется при загрузке) ----
    bool enable = true;
    uint32 tokenItem = 70005;
    uint32 tokenCap = 50;
    uint32 drainPercent = 50;
    bool announceDrain = true;
    bool outboxEnabled = true;
    uint32 outboxBatchSize = 5;   // максимум отложенных наград на тик игрока

    char const* GetLocale(Player const* player)
    {
        return player && player->GetSession()->GetSessionDbcLocale() == LOCALE_ruRU ? "ru" : "en";
    }

    class EchoEconomyWorldscript : public WorldScript
    {
    public:
        EchoEconomyWorldscript() : WorldScript("EchoEconomyWorldscript") { }

        void OnAfterConfigLoad(bool /*reload*/) override
        {
            enable = sConfigMgr->GetOption<bool>("EchoEconomy.Enable", true);
            tokenItem = sConfigMgr->GetOption<uint32>("EchoEconomy.TokenItem", 70005);
            tokenCap = sConfigMgr->GetOption<uint32>("EchoEconomy.TokenCap", 50);
            drainPercent = sConfigMgr->GetOption<uint32>("EchoEconomy.DrainPercent", 50);
            announceDrain = sConfigMgr->GetOption<bool>("EchoEconomy.AnnounceDrain", true);
            outboxEnabled = sConfigMgr->GetOption<bool>("EchoEconomy.Outbox.Enable", true);
            outboxBatchSize = sConfigMgr->GetOption<uint32>("EchoEconomy.Outbox.BatchSize", 5);

            if (drainPercent > 100)
                drainPercent = 100;

            LOG_INFO("module.echo-economy",
                "echo-economy загружен: enable=%s token=%u cap=%u drain=%u%% announce=%s outbox=%s batch=%u",
                enable ? "on" : "off", tokenItem, tokenCap, drainPercent,
                announceDrain ? "on" : "off", outboxEnabled ? "on" : "off", outboxBatchSize);
        }
    };

    // ============================================================
    // Outbox-доставка (паттерн wow-mod-delves DelveRewardDelivery):
    //   1. EnqueueOutboxReward() — поставить намерение (идемпотентно
    //      по уникальному reward_key).
    //   2. ProcessOutboxFor() — на OnLogin/OnUpdateZone доставить
    //      до BatchSize недоставленных наград игрока; каждая
    //      доставка фиксируется квитанцией; повторная попытка по
    //      тому же ключу видит квитанцию и не платит второй раз.
    // ============================================================

    class EchoEconomyPlayerscript : public PlayerScript
    {
    public:
        EchoEconomyPlayerscript() : PlayerScript("EchoEconomyPlayerscript") { }

        // Слив избытка жетонов при входе («Пустота забираёт своё»)
        void OnPlayerLogin(Player* player) override
        {
            if (!enable || !player)
                return;

            DrainExcessTokens(player);

            // Доставка отложенных наград (в т.ч. накопленных офлайн)
            if (outboxEnabled)
                ProcessOutboxFor(player);
        }

        // Периодическая доставка (раз в 60 сек онлайна) — награда
        // доезжает, даже если игрок давно в игре
        void OnPlayerUpdate(Player* /*player*/, uint32 /*diff*/) override
        {
            // PlayerScript не имеет OnUpdate; доставка при login и zone.
            // Дополнительный тик не требуется для пилота.
        }

        void DrainExcessTokens(Player* player)
        {
            if (tokenCap == 0 || drainPercent == 0)
                return;

            uint32 count = player->GetItemCount(tokenItem);
            if (count <= tokenCap)
                return;

            uint32 excess = count - tokenCap;
            uint32 drained = uint32(uint64(excess) * drainPercent / 100);
            if (drained == 0)
                return;

            player->DestroyItemCount(tokenItem, drained, true, false);

            if (announceDrain)
            {
                if (strcmp(GetLocale(player), "ru") == 0)
                    player->SendSystemMessage("|cff8e44ad[Эхо Пустоты]|r Пустота забираёт своё: " +
                        std::to_string(drained) + " жетонов истаило (лимит " + std::to_string(tokenCap) + ").");
                else
                    player->SendSystemMessage("|cff8e44ad[Echo of the Void]|r The Void claims its own: " +
                        std::to_string(drained) + " tokens withered away (limit " + std::to_string(tokenCap) + ").");
            }

            LOG_INFO("module.echo-economy", "Token drain: player %s (guid %u) had %u, cap %u, drained %u",
                player->GetName().c_str(), player->GetGUID().GetCounter(), count, tokenCap, drained);
        }

        // Публичный API для других модулей реалма (echo-pve, echo-pvp):
        // поставить durable-намерение награды. Идемпотентно по reward_key.
        static void EnqueueOutboxReward(Player* player, std::string const& rewardKey,
                                        uint32 tokens, std::string const& reason)
        {
            if (!outboxEnabled || !player || tokens == 0)
                return;

            CharacterDatabase.Execute(
                "INSERT IGNORE INTO realm_token_outbox "
                "(reward_key, guid, account, tokens, reason, created_at, delivered) "
                "VALUES ('{}', {}, {}, {}, '{}', {}, 0)",
                rewardKey, player->GetGUID().GetCounter(),
                player->GetSession()->GetAccountId(), tokens, reason,
                uint32(GameTime::GetGameTime().count()));
        }

        // Доставка недоставленных наград игрока (до BatchSize за вызов).
        static void ProcessOutboxFor(Player* player)
        {
            if (!outboxEnabled || !player)
                return;

            uint32 guid = player->GetGUID().GetCounter();
            auto result = CharacterDatabase.Query(
                "SELECT id, reward_key, tokens FROM realm_token_outbox "
                "WHERE guid = {} AND delivered = 0 ORDER BY id LIMIT {}",
                guid, outboxBatchSize);
            if (!result)
                return;

            uint32 deliveredCount = 0;
            do
            {
                auto fields = result->Fetch();
                uint64 id = fields[0].Get<uint64>();
                std::string rewardKey = fields[1].Get<std::string>();
                uint32 tokens = fields[2].Get<uint32>();

                // Идемпотентность: если квитанция уже есть — только маркер
                auto receipt = CharacterDatabase.Query(
                    "SELECT 1 FROM realm_token_receipt WHERE reward_key = '{}'", rewardKey);
                if (!receipt)
                {
                    player->AddItem(tokenItem, tokens);
                    CharacterDatabase.Execute(
                        "INSERT INTO realm_token_receipt (reward_key, guid, tokens, delivered_at) "
                        "VALUES ('{}', {}, {}, {})",
                        rewardKey, guid, tokens, uint32(GameTime::GetGameTime().count()));
                    ++deliveredCount;
                }

                CharacterDatabase.Execute(
                    "UPDATE realm_token_outbox SET delivered = 1 WHERE id = {}", id);
            }
            while (result->NextRow());

            if (deliveredCount > 0)
            {
                if (strcmp(GetLocale(player), "ru") == 0)
                    player->SendSystemMessage("|cff9b59b6[Эхо Пустоты]|r Пустота вернула долг: " +
                        std::to_string(deliveredCount) + " наград доставлено.");
                else
                    player->SendSystemMessage("|cff9b59b6[Echo of the Void]|r The Void repaid its debt: " +
                        std::to_string(deliveredCount) + " rewards delivered.");
            }
        }
    };
}

// Публичный API outbox для других модулей реалма
void EchoEconomy_EnqueueTokenReward(Player* player, std::string const& rewardKey,
                                    uint32 tokens, std::string const& reason)
{
    EchoEconomyPlayerscript::EnqueueOutboxReward(player, rewardKey, tokens, reason);
}

void EchoEconomy_ProcessTokenOutbox(Player* player)
{
    EchoEconomyPlayerscript::ProcessOutboxFor(player);
}

// Регистрация в ядре
EchoEconomyWorldscript* EchoEconomyWorldscriptInstance = new EchoEconomyWorldscript();
EchoEconomyPlayerscript* EchoEconomyPlayerscriptInstance = new EchoEconomyPlayerscript();

// Точка входа для генерируемого загрузчика модулей ядра
void Addecho_economyScripts()
{
    // Скрипты зарегистрированы глобальными инстансами выше.
}
