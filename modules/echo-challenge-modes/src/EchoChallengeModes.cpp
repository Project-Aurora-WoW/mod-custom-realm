// ============================================================
// echo-challenge-modes — src/EchoChallengeModes.cpp
// Режимы испытаний реалма «Эхо Пустоты» (AzerothCore).
//
// Референс: mod-challenge-modes (AzerothCore community, AGPL v3),
// импортирован в SourceCraft: m-orlovrus59/mod-challenge-modes.
// Локализованный форк (конвенции реалма: ru/en по DBC-локали).
//
// 8 режимов, активируются игроком у Алтаря Испытаний (GO 705605):
//   Hardcore            — смерть = перманентный дух (воскрешение невозможно)
//   SemiHardcore        — смерть = потеря экипировки и золота
//   SelfCrafted         — носить только скрафченное собой
//   ItemQualityLevel    — только Poor/Normal качество
//   SlowXpGain          — x0.5 опыта
//   VerySlowXpGain      — x0.25 опыта
//   QuestXpOnly         — опыт только с квестов
//   IronMan             — правила wowchallenges (без зелий/фласок/энчантов/
//                         талантов/профессий/групп, только белые вещи)
//
// Отличия от оригинала:
//   1. Полная локализация ru/en (оригинал — хардкод китайских строк).
//   2. Алтарь — GO 705605 (оригинал: 254605, стоковый диапазон Blizzard).
//   3. Semi-Hardcore: убрана мёртвая проверка !IsEquipped() в цикле
//      по экипировке (слоты INVENTORY_SLOT_BAG_0 — это экипировка).
//   4. Локаль по GetSessionDbcLocale() (8 = ruRU → русский текст).
//
// Требования: EnablePlayerSettings = 1 в worldserver.conf.
// Конфиг: echo-challenge-modes.conf.dist.
// ============================================================

#include "ScriptMgr.h"
#include "Player.h"
#include "Config.h"
#include "Chat.h"
#include "ScriptedCreature.h"
#include "ScriptedGossip.h"
#include "SpellMgr.h"
#include "Item.h"
#include "ItemTemplate.h"
#include "GameObjectAI.h"
#include "Pet.h"
#include <unordered_map>
#include <sstream>

namespace
{
    constexpr uint32 ALTAR_ENTRY = 705605;

    enum ChallengeModeSettings
    {
        SETTING_HARDCORE           = 0,
        SETTING_SEMI_HARDCORE      = 1,
        SETTING_SELF_CRAFTED       = 2,
        SETTING_ITEM_QUALITY_LEVEL = 3,
        SETTING_SLOW_XP_GAIN       = 4,
        SETTING_VERY_SLOW_XP_GAIN  = 5,
        SETTING_QUEST_XP_ONLY      = 6,
        SETTING_IRON_MAN           = 7,
        HARDCORE_DEAD              = 8
    };

    enum AllowedProfessions
    {
        RUNEFORGING    = 53428,
        POISONS        = 2842,
        BEAST_TRAINING = 5149
    };

    // ---- Локализация ru/en (DBC-локаль клиента; 8 = ruRU) ----
    constexpr char const* HC_KICK_MSG_RU = "Режим испытаний «Хардкор»: ваш персонаж мёртв навсегда.";
    constexpr char const* HC_KICK_MSG_EN = "Hardcore challenge: your character is dead permanently.";

    constexpr char const* SH_LOST_ITEM_RU = "Вы потеряли |cffffffff|Hitem:%u:0:0:0:0:0:0:0:0|h[%s]|h|r!";
    constexpr char const* SH_LOST_ITEM_EN = "You have lost |cffffffff|Hitem:%u:0:0:0:0:0:0:0:0|h[%s]|h|r!";

    constexpr char const* GOSSIP_HARDCORE_RU = "Включить режим «Хардкор»";
    constexpr char const* GOSSIP_HARDCORE_EN = "Enable Hardcore mode";
    constexpr char const* GOSSIP_SEMI_RU     = "Включить режим «Полухардкор»";
    constexpr char const* GOSSIP_SEMI_EN     = "Enable Semi-Hardcore mode";
    constexpr char const* GOSSIP_CRAFTED_RU  = "Включить режим «Крафтовая экипировка»";
    constexpr char const* GOSSIP_CRAFTED_EN  = "Enable Self-Crafted mode";
    constexpr char const* GOSSIP_QUALITY_RU  = "Включить режим «Низкое качество»";
    constexpr char const* GOSSIP_QUALITY_EN  = "Enable Item Quality Level mode";
    constexpr char const* GOSSIP_SLOWXP_RU   = "Включить режим «Медленный опыт»";
    constexpr char const* GOSSIP_SLOWXP_EN   = "Enable Slow XP Gain mode";
    constexpr char const* GOSSIP_VSLOWXP_RU  = "Включить режим «Очень медленный опыт»";
    constexpr char const* GOSSIP_VSLOWXP_EN  = "Enable Very Slow XP Gain mode";
    constexpr char const* GOSSIP_QUESTXP_RU  = "Включить режим «Опыт только за квесты»";
    constexpr char const* GOSSIP_QUESTXP_EN  = "Enable Quest XP Only mode";
    constexpr char const* GOSSIP_IRONMAN_RU  = "Включить режим «Железный человек»";
    constexpr char const* GOSSIP_IRONMAN_EN  = "Enable Iron Man mode";
    constexpr char const* GOSSIP_ENABLED_RU  = "Режим испытания включён. Эхо будет следить за вами.";
    constexpr char const* GOSSIP_ENABLED_EN  = "Challenge mode enabled. The Echo will be watching you.";

    constexpr bool IsRuLocale(uint8 sessionDbcLocale)
    {
        return sessionDbcLocale == 8; // ruRU
    }

    // ---- Центральный класс конфигурации/доступа ----
    class ChallengeModes
    {
    public:
        static ChallengeModes* instance()
        {
            static ChallengeModes instance;
            return &instance;
        }

        bool challengeEnabledForPlayer(uint8 setting, Player* player) const
        {
            if (!enabled() || !challengeEnabled(setting))
                return false;
            return player->GetPlayerSetting("mod-challenge-modes", setting).value;
        }

        bool challengeEnabled(uint8 setting) const
        {
            switch (setting)
            {
                case SETTING_HARDCORE:           return hardcoreEnable;
                case SETTING_SEMI_HARDCORE:      return semiHardcoreEnable;
                case SETTING_SELF_CRAFTED:       return selfCraftedEnable;
                case SETTING_ITEM_QUALITY_LEVEL: return itemQualityLevelEnable;
                case SETTING_SLOW_XP_GAIN:       return slowXpGainEnable;
                case SETTING_VERY_SLOW_XP_GAIN:  return verySlowXpGainEnable;
                case SETTING_QUEST_XP_ONLY:      return questXpOnlyEnable;
                case SETTING_IRON_MAN:           return ironManEnable;
                case HARDCORE_DEAD:
                    break;
            }
            return false;
        }

        uint32 getDisableLevel(uint8 setting) const
        {
            switch (setting)
            {
                case SETTING_HARDCORE:           return hardcoreDisableLevel;
                case SETTING_SEMI_HARDCORE:      return semiHardcoreDisableLevel;
                case SETTING_SELF_CRAFTED:       return selfCraftedDisableLevel;
                case SETTING_ITEM_QUALITY_LEVEL: return itemQualityLevelDisableLevel;
                case SETTING_SLOW_XP_GAIN:       return slowXpGainDisableLevel;
                case SETTING_VERY_SLOW_XP_GAIN:  return verySlowXpGainDisableLevel;
                case SETTING_QUEST_XP_ONLY:      return questXpOnlyDisableLevel;
                case SETTING_IRON_MAN:           return ironManDisableLevel;
                case HARDCORE_DEAD:
                    break;
            }
            return 0;
        }

        float getXpBonusForChallenge(uint8 setting) const
        {
            switch (setting)
            {
                case SETTING_HARDCORE:           return hardcoreXpBonus;
                case SETTING_SEMI_HARDCORE:      return semiHardcoreXpBonus;
                case SETTING_SELF_CRAFTED:       return selfCraftedXpBonus;
                case SETTING_ITEM_QUALITY_LEVEL: return itemQualityLevelXpBonus;
                case SETTING_SLOW_XP_GAIN:       return slowXpGainBonus;
                case SETTING_VERY_SLOW_XP_GAIN:  return verySlowXpGainBonus;
                case SETTING_QUEST_XP_ONLY:      return questXpOnlyXpBonus;
                case SETTING_IRON_MAN:           return ironManXpBonus;
                case HARDCORE_DEAD:
                    break;
            }
            return 1.0f;
        }

        std::unordered_map<uint8, uint32> const* getTitleMapForChallenge(uint8 setting) const
        {
            switch (setting)
            {
                case SETTING_HARDCORE:           return &hardcoreTitleRewards;
                case SETTING_SEMI_HARDCORE:      return &semiHardcoreTitleRewards;
                case SETTING_SELF_CRAFTED:       return &selfCraftedTitleRewards;
                case SETTING_ITEM_QUALITY_LEVEL: return &itemQualityLevelTitleRewards;
                case SETTING_SLOW_XP_GAIN:       return &slowXpGainTitleRewards;
                case SETTING_VERY_SLOW_XP_GAIN:  return &verySlowXpGainTitleRewards;
                case SETTING_QUEST_XP_ONLY:      return &questXpOnlyTitleRewards;
                case SETTING_IRON_MAN:           return &ironManTitleRewards;
                case HARDCORE_DEAD:
                    break;
            }
            return nullptr;
        }

        std::unordered_map<uint8, uint32> const* getTalentMapForChallenge(uint8 setting) const
        {
            switch (setting)
            {
                case SETTING_HARDCORE:           return &hardcoreTalentRewards;
                case SETTING_SEMI_HARDCORE:      return &semiHardcoreTalentRewards;
                case SETTING_SELF_CRAFTED:       return &selfCraftedTalentRewards;
                case SETTING_ITEM_QUALITY_LEVEL: return &itemQualityLevelTalentRewards;
                case SETTING_SLOW_XP_GAIN:       return &slowXpGainTalentRewards;
                case SETTING_VERY_SLOW_XP_GAIN:  return &verySlowXpGainTalentRewards;
                case SETTING_QUEST_XP_ONLY:      return &questXpOnlyTalentRewards;
                case SETTING_IRON_MAN:           return &ironManTalentRewards;
                case HARDCORE_DEAD:
                    break;
            }
            return nullptr;
        }

        std::unordered_map<uint8, uint32> const* getItemMapForChallenge(uint8 setting) const
        {
            switch (setting)
            {
                case SETTING_HARDCORE:           return &hardcoreItemRewards;
                case SETTING_SEMI_HARDCORE:      return &semiHardcoreItemRewards;
                case SETTING_SELF_CRAFTED:       return &selfCraftedItemRewards;
                case SETTING_ITEM_QUALITY_LEVEL: return &itemQualityLevelItemRewards;
                case SETTING_SLOW_XP_GAIN:       return &slowXpGainItemRewards;
                case SETTING_VERY_SLOW_XP_GAIN:  return &verySlowXpGainItemRewards;
                case SETTING_QUEST_XP_ONLY:      return &questXpOnlyItemRewards;
                case SETTING_IRON_MAN:           return &ironManItemRewards;
                case HARDCORE_DEAD:
                    break;
            }
            return nullptr;
        }

        std::unordered_map<uint8, uint32> const* getAchievementMapForChallenge(uint8 setting) const
        {
            switch (setting)
            {
                case SETTING_HARDCORE:           return &hardcoreAchievementReward;
                case SETTING_SEMI_HARDCORE:      return &semiHardcoreAchievementReward;
                case SETTING_SELF_CRAFTED:       return &selfCraftedAchievementReward;
                case SETTING_ITEM_QUALITY_LEVEL: return &itemQualityLevelAchievementReward;
                case SETTING_SLOW_XP_GAIN:       return &slowXpGainAchievementReward;
                case SETTING_VERY_SLOW_XP_GAIN:  return &verySlowXpGainAchievementReward;
                case SETTING_QUEST_XP_ONLY:      return &questXpOnlyAchievementReward;
                case SETTING_IRON_MAN:           return &ironManAchievementReward;
                case HARDCORE_DEAD:
                    break;
            }
            return nullptr;
        }

        uint32 getItemRewardAmount(uint8 setting) const
        {
            switch (setting)
            {
                case SETTING_HARDCORE:           return hardcoreItemRewardAmount;
                case SETTING_SEMI_HARDCORE:      return semiHardcoreItemRewardAmount;
                case SETTING_SELF_CRAFTED:       return selfCraftedItemRewardAmount;
                case SETTING_ITEM_QUALITY_LEVEL: return itemQualityLevelItemRewardAmount;
                case SETTING_SLOW_XP_GAIN:       return slowXpGainItemRewardAmount;
                case SETTING_VERY_SLOW_XP_GAIN:  return verySlowXpGainItemRewardAmount;
                case SETTING_QUEST_XP_ONLY:      return questXpOnlyItemRewardAmount;
                case SETTING_IRON_MAN:           return ironManItemRewardAmount;
                case HARDCORE_DEAD:
                    break;
            }
            return 0;
        }

        // ---- Поля конфигурации (заполняются LoadConfig) ----
        bool challengesEnabled = false;
        bool hardcoreEnable = true, semiHardcoreEnable = true, selfCraftedEnable = true, itemQualityLevelEnable = true;
        bool slowXpGainEnable = true, verySlowXpGainEnable = true, questXpOnlyEnable = true, ironManEnable = true;
        uint32 hardcoreDisableLevel = 0, semiHardcoreDisableLevel = 0, selfCraftedDisableLevel = 0, itemQualityLevelDisableLevel = 0;
        uint32 slowXpGainDisableLevel = 0, verySlowXpGainDisableLevel = 0, questXpOnlyDisableLevel = 0, ironManDisableLevel = 0;
        uint32 hardcoreItemRewardAmount = 1, semiHardcoreItemRewardAmount = 1, selfCraftedItemRewardAmount = 1, itemQualityLevelItemRewardAmount = 1;
        uint32 slowXpGainItemRewardAmount = 1, verySlowXpGainItemRewardAmount = 1, questXpOnlyItemRewardAmount = 1, ironManItemRewardAmount = 1;
        float hardcoreXpBonus = 1.0f, semiHardcoreXpBonus = 1.0f, selfCraftedXpBonus = 1.0f, itemQualityLevelXpBonus = 1.0f;
        float questXpOnlyXpBonus = 1.0f, slowXpGainBonus = 0.50f, verySlowXpGainBonus = 0.25f, ironManXpBonus = 1.0f;

        std::unordered_map<uint8, uint32> hardcoreTitleRewards, semiHardcoreTitleRewards, selfCraftedTitleRewards, itemQualityLevelTitleRewards;
        std::unordered_map<uint8, uint32> slowXpGainTitleRewards, verySlowXpGainTitleRewards, questXpOnlyTitleRewards, ironManTitleRewards;
        std::unordered_map<uint8, uint32> hardcoreItemRewards, semiHardcoreItemRewards, selfCraftedItemRewards, itemQualityLevelItemRewards;
        std::unordered_map<uint8, uint32> slowXpGainItemRewards, verySlowXpGainItemRewards, questXpOnlyItemRewards, ironManItemRewards;
        std::unordered_map<uint8, uint32> hardcoreTalentRewards, semiHardcoreTalentRewards, selfCraftedTalentRewards, itemQualityLevelTalentRewards;
        std::unordered_map<uint8, uint32> slowXpGainTalentRewards, verySlowXpGainTalentRewards, questXpOnlyTalentRewards, ironManTalentRewards;
        std::unordered_map<uint8, uint32> hardcoreAchievementReward, semiHardcoreAchievementReward, selfCraftedAchievementReward, itemQualityLevelAchievementReward;
        std::unordered_map<uint8, uint32> slowXpGainAchievementReward, verySlowXpGainAchievementReward, questXpOnlyAchievementReward, ironManAchievementReward;

        std::unordered_map<std::string, std::unordered_map<uint8, uint32>*> rewardConfigMap =
        {
            { "Hardcore.TitleRewards",                &hardcoreTitleRewards                 },
            { "SemiHardcore.TitleRewards",            &semiHardcoreTitleRewards             },
            { "SelfCrafted.TitleRewards",             &selfCraftedTitleRewards              },
            { "ItemQualityLevel.TitleRewards",        &itemQualityLevelTitleRewards         },
            { "SlowXpGain.TitleRewards",              &slowXpGainTitleRewards               },
            { "VerySlowXpGain.TitleRewards",          &verySlowXpGainTitleRewards           },
            { "QuestXpOnly.TitleRewards",             &questXpOnlyTitleRewards              },
            { "IronMan.TitleRewards",                 &ironManTitleRewards                  },
            { "Hardcore.TalentRewards",               &hardcoreTalentRewards                },
            { "SemiHardcore.TalentRewards",           &semiHardcoreTalentRewards            },
            { "SelfCrafted.TalentRewards",            &selfCraftedTalentRewards             },
            { "ItemQualityLevel.TalentRewards",       &itemQualityLevelTalentRewards        },
            { "SlowXpGain.TalentRewards",             &slowXpGainTalentRewards              },
            { "VerySlowXpGain.TalentRewards",         &verySlowXpGainTalentRewards          },
            { "QuestXpOnly.TalentRewards",            &questXpOnlyTalentRewards             },
            { "IronMan.TalentRewards",                &ironManTalentRewards                 },
            { "Hardcore.ItemRewards",                 &hardcoreItemRewards                  },
            { "SemiHardcore.ItemRewards",             &semiHardcoreItemRewards              },
            { "SelfCrafted.ItemRewards",              &selfCraftedItemRewards               },
            { "ItemQualityLevel.ItemRewards",         &itemQualityLevelItemRewards          },
            { "SlowXpGain.ItemRewards",               &slowXpGainItemRewards                },
            { "VerySlowXpGain.ItemRewards",           &verySlowXpGainItemRewards            },
            { "QuestXpOnly.ItemRewards",              &questXpOnlyItemRewards               },
            { "IronMan.ItemRewards",                  &ironManItemRewards                   },
            { "Hardcore.AchievementReward",           &hardcoreAchievementReward            },
            { "SemiHardcore.AchievementReward",       &semiHardcoreAchievementReward        },
            { "SelfCrafted.AchievementReward",        &selfCraftedAchievementReward         },
            { "ItemQualityLevel.AchievementReward",   &itemQualityLevelAchievementReward    },
            { "SlowXpGain.AchievementReward",         &slowXpGainAchievementReward          },
            { "VerySlowXpGain.AchievementReward",     &verySlowXpGainAchievementReward      },
            { "QuestXpOnly.AchievementReward",        &questXpOnlyAchievementReward         },
            { "IronMan.AchievementReward",            &ironManAchievementReward             }
        };

        [[nodiscard]] bool enabled() const { return challengesEnabled; }
    };

#define sChallengeModes ChallengeModes::instance()

    // ---- Загрузка конфига ----
    void LoadStringToMap(std::unordered_map<uint8, uint32>& mapToLoad, std::string const& configString)
    {
        std::string delimitedValue;
        std::stringstream configIdStream(configString);

        while (std::getline(configIdStream, delimitedValue, ','))
        {
            std::string pairOne, pairTwo;
            std::stringstream configPairStream(delimitedValue);
            configPairStream >> pairOne >> pairTwo;
            uint32 configLevel = atoi(pairOne.c_str());
            uint32 rewardValue = atoi(pairTwo.c_str());
            mapToLoad[uint8(configLevel)] = rewardValue;
        }
    }

    class ChallengeModesWorldScript : public WorldScript
    {
    public:
        ChallengeModesWorldScript() : WorldScript("ChallengeModesWorldScript") { }

        void OnBeforeConfigLoad(bool /*reload*/) override
        {
            LoadConfig();
        }

    private:
        static void LoadConfig()
        {
            sChallengeModes->challengesEnabled = sConfigMgr->GetOption<bool>("ChallengeModes.Enable", false);
            if (!sChallengeModes->enabled())
                return;

            for (auto& [confName, rewardMap] : sChallengeModes->rewardConfigMap)
            {
                rewardMap->clear();
                LoadStringToMap(*rewardMap, sConfigMgr->GetOption<std::string>(confName, ""));
            }

            sChallengeModes->hardcoreEnable          = sConfigMgr->GetOption<bool>("Hardcore.Enable", true);
            sChallengeModes->semiHardcoreEnable      = sConfigMgr->GetOption<bool>("SemiHardcore.Enable", true);
            sChallengeModes->selfCraftedEnable       = sConfigMgr->GetOption<bool>("SelfCrafted.Enable", true);
            sChallengeModes->itemQualityLevelEnable  = sConfigMgr->GetOption<bool>("ItemQualityLevel.Enable", true);
            sChallengeModes->slowXpGainEnable        = sConfigMgr->GetOption<bool>("SlowXpGain.Enable", true);
            sChallengeModes->verySlowXpGainEnable    = sConfigMgr->GetOption<bool>("VerySlowXpGain.Enable", true);
            sChallengeModes->questXpOnlyEnable       = sConfigMgr->GetOption<bool>("QuestXpOnly.Enable", true);
            sChallengeModes->ironManEnable           = sConfigMgr->GetOption<bool>("IronMan.Enable", true);

            sChallengeModes->hardcoreDisableLevel          = sConfigMgr->GetOption<uint32>("Hardcore.DisableLevel", 0);
            sChallengeModes->semiHardcoreDisableLevel      = sConfigMgr->GetOption<uint32>("SemiHardcore.DisableLevel", 0);
            sChallengeModes->selfCraftedDisableLevel       = sConfigMgr->GetOption<uint32>("SelfCrafted.DisableLevel", 0);
            sChallengeModes->itemQualityLevelDisableLevel  = sConfigMgr->GetOption<uint32>("ItemQualityLevel.DisableLevel", 0);
            sChallengeModes->slowXpGainDisableLevel        = sConfigMgr->GetOption<uint32>("SlowXpGain.DisableLevel", 0);
            sChallengeModes->verySlowXpGainDisableLevel    = sConfigMgr->GetOption<uint32>("VerySlowXpGain.DisableLevel", 0);
            sChallengeModes->questXpOnlyDisableLevel       = sConfigMgr->GetOption<uint32>("QuestXpOnly.DisableLevel", 0);
            sChallengeModes->ironManDisableLevel           = sConfigMgr->GetOption<uint32>("IronMan.DisableLevel", 0);

            sChallengeModes->hardcoreXpBonus         = sConfigMgr->GetOption<float>("Hardcore.XPMultiplier", 1.0f);
            sChallengeModes->semiHardcoreXpBonus     = sConfigMgr->GetOption<float>("SemiHardcore.XPMultiplier", 1.0f);
            sChallengeModes->selfCraftedXpBonus      = sConfigMgr->GetOption<float>("SelfCrafted.XPMultiplier", 1.0f);
            sChallengeModes->itemQualityLevelXpBonus = sConfigMgr->GetOption<float>("ItemQualityLevel.XPMultiplier", 1.0f);
            sChallengeModes->questXpOnlyXpBonus      = sConfigMgr->GetOption<float>("QuestXpOnly.XPMultiplier", 1.0f);
            sChallengeModes->slowXpGainBonus         = sConfigMgr->GetOption<float>("SlowXpGain.XPMultiplier", 0.50f);
            sChallengeModes->verySlowXpGainBonus     = sConfigMgr->GetOption<float>("VerySlowXpGain.XPMultiplier", 0.25f);
            sChallengeModes->ironManXpBonus          = sConfigMgr->GetOption<float>("IronMan.XPMultiplier", 1.0f);

            sChallengeModes->hardcoreItemRewardAmount         = sConfigMgr->GetOption<uint32>("Hardcore.ItemRewardAmount", 1);
            sChallengeModes->semiHardcoreItemRewardAmount     = sConfigMgr->GetOption<uint32>("SemiHardcore.ItemRewardAmount", 1);
            sChallengeModes->selfCraftedItemRewardAmount      = sConfigMgr->GetOption<uint32>("SelfCrafted.ItemRewardAmount", 1);
            sChallengeModes->itemQualityLevelItemRewardAmount = sConfigMgr->GetOption<uint32>("ItemQualityLevel.ItemRewardAmount", 1);
            sChallengeModes->slowXpGainItemRewardAmount       = sConfigMgr->GetOption<uint32>("SlowXpGain.ItemRewardAmount", 1);
            sChallengeModes->verySlowXpGainItemRewardAmount   = sConfigMgr->GetOption<uint32>("VerySlowXpGain.ItemRewardAmount", 1);
            sChallengeModes->questXpOnlyItemRewardAmount      = sConfigMgr->GetOption<uint32>("QuestXpOnly.ItemRewardAmount", 1);
            sChallengeModes->ironManItemRewardAmount          = sConfigMgr->GetOption<uint32>("IronMan.ItemRewardAmount", 1);
        }
    };

    // ---- Базовый PlayerScript всех режимов (XP-множитель + награды за уровни) ----
    class ChallengeMode : public PlayerScript
    {
    public:
        ChallengeMode(char const* scriptName, uint8 settingName)
            : PlayerScript(scriptName), settingName(settingName)
        { }

        void OnPlayerGiveXP(Player* player, uint32& amount, Unit* /*victim*/, uint8 /*xpSource*/) override
        {
            if (!sChallengeModes->challengeEnabledForPlayer(settingName, player))
                return;
            amount = uint32(amount * sChallengeModes->getXpBonusForChallenge(settingName));
        }

        void OnPlayerLevelChanged(Player* player, uint8 /*oldlevel*/) override
        {
            if (!sChallengeModes->challengeEnabledForPlayer(settingName, player))
                return;

            std::unordered_map<uint8, uint32> const* titleRewardMap       = sChallengeModes->getTitleMapForChallenge(settingName);
            std::unordered_map<uint8, uint32> const* talentRewardMap      = sChallengeModes->getTalentMapForChallenge(settingName);
            std::unordered_map<uint8, uint32> const* itemRewardMap        = sChallengeModes->getItemMapForChallenge(settingName);
            std::unordered_map<uint8, uint32> const* achievementRewardMap = sChallengeModes->getAchievementMapForChallenge(settingName);
            uint8 level = player->GetLevel();

            if (titleRewardMap && titleRewardMap->find(level) != titleRewardMap->end())
            {
                CharTitlesEntry const* titleInfo = sCharTitlesStore.LookupEntry(titleRewardMap->at(level));
                if (!titleInfo)
                {
                    LOG_ERROR("module.echo-challenge-modes", "Некорректный ID титула {}!", titleRewardMap->at(level));
                    return;
                }
                player->SetTitle(titleInfo);
            }

            if (talentRewardMap && talentRewardMap->find(level) != talentRewardMap->end())
            {
                player->RewardExtraBonusTalentPoints(talentRewardMap->at(level));
            }

            if (achievementRewardMap && achievementRewardMap->find(level) != achievementRewardMap->end())
            {
                AchievementEntry const* achievementInfo = sAchievementStore.LookupEntry(achievementRewardMap->at(level));
                if (!achievementInfo)
                {
                    LOG_ERROR("module.echo-challenge-modes", "Некорректный ID ачивки {}!", achievementRewardMap->at(level));
                    return;
                }
                player->CompletedAchievement(achievementInfo);
            }

            if (itemRewardMap && itemRewardMap->find(level) != itemRewardMap->end())
            {
                uint32 itemEntry = itemRewardMap->at(level);
                uint32 itemAmount = sChallengeModes->getItemRewardAmount(settingName);
                player->SendItemRetrievalMail({ { itemEntry, itemAmount } });
            }

            if (sChallengeModes->getDisableLevel(settingName) && sChallengeModes->getDisableLevel(settingName) <= level)
            {
                player->UpdatePlayerSetting("mod-challenge-modes", settingName, 0);
            }
        }

    private:
        uint8 settingName;
    };

    // ---- Hardcore ----
    class ChallengeModeHardcore : public ChallengeMode
    {
    public:
        ChallengeModeHardcore() : ChallengeMode("ChallengeModeHardcore", SETTING_HARDCORE) { }

        void OnPlayerLogin(Player* player) override
        {
            if (!sChallengeModes->challengeEnabledForPlayer(SETTING_HARDCORE, player)
                || !sChallengeModes->challengeEnabledForPlayer(HARDCORE_DEAD, player))
            {
                return;
            }
            player->KillPlayer();
            KickWithLocale(player);
        }

        void OnPlayerReleasedGhost(Player* player) override
        {
            if (!sChallengeModes->challengeEnabledForPlayer(SETTING_HARDCORE, player))
                return;
            player->UpdatePlayerSetting("mod-challenge-modes", HARDCORE_DEAD, 1);
            KickWithLocale(player);
        }

        void OnPlayerPVPKill(Player* /*killer*/, Player* killed) override
        {
            if (!sChallengeModes->challengeEnabledForPlayer(SETTING_HARDCORE, killed))
                return;
            killed->UpdatePlayerSetting("mod-challenge-modes", HARDCORE_DEAD, 1);
        }

        void OnPlayerKilledByCreature(Creature* /*killer*/, Player* killed) override
        {
            if (!sChallengeModes->challengeEnabledForPlayer(SETTING_HARDCORE, killed))
                return;
            killed->UpdatePlayerSetting("mod-challenge-modes", HARDCORE_DEAD, 1);
        }

        void OnPlayerResurrect(Player* player, float /*restore_percent*/, bool& /*applySickness*/) override
        {
            if (!sChallengeModes->challengeEnabledForPlayer(SETTING_HARDCORE, player))
                return;
            // Оригинал: воскрешение невозможно, но хук запрета реса в ядре
            // отсутствует — после реса игрок тут же умирает снова.
            player->UpdatePlayerSetting("mod-challenge-modes", HARDCORE_DEAD, 1);
            player->KillPlayer();
            KickWithLocale(player);
        }

        void OnPlayerGiveXP(Player* player, uint32& amount, Unit* victim, uint8 xpSource) override
        {
            ChallengeMode::OnPlayerGiveXP(player, amount, victim, xpSource);
        }

        void OnPlayerLevelChanged(Player* player, uint8 oldlevel) override
        {
            ChallengeMode::OnPlayerLevelChanged(player, oldlevel);
        }

    private:
        static void KickWithLocale(Player* player)
        {
            bool ruLocale = IsRuLocale(player->GetSession()->GetSessionDbcLocale());
            player->GetSession()->KickPlayer(std::string(ruLocale ? HC_KICK_MSG_RU : HC_KICK_MSG_EN));
        }
    };

    // ---- Semi-Hardcore ----
    class ChallengeModeSemiHardcore : public ChallengeMode
    {
    public:
        ChallengeModeSemiHardcore() : ChallengeMode("ChallengeModeSemiHardcore", SETTING_SEMI_HARDCORE) { }

        void OnPlayerKilledByCreature(Creature* /*killer*/, Player* player) override
        {
            if (!sChallengeModes->challengeEnabledForPlayer(SETTING_SEMI_HARDCORE, player))
                return;

            bool ruLocale = IsRuLocale(player->GetSession()->GetSessionDbcLocale());
            for (uint8 i = 0; i < EQUIPMENT_SLOT_END; ++i)
            {
                if (Item* pItem = player->GetItemByPos(INVENTORY_SLOT_BAG_0, i))
                {
                    uint8 slot = pItem->GetSlot();
                    if (ruLocale)
                        ChatHandler(player->GetSession()).PSendSysMessage(SH_LOST_ITEM_RU, pItem->GetEntry(), pItem->GetTemplate()->Name1.c_str());
                    else
                        ChatHandler(player->GetSession()).PSendSysMessage(SH_LOST_ITEM_EN, pItem->GetEntry(), pItem->GetTemplate()->Name1.c_str());
                    player->DestroyItem(INVENTORY_SLOT_BAG_0, slot, true);
                }
            }
            player->SetMoney(0);
        }

        void OnPlayerGiveXP(Player* player, uint32& amount, Unit* victim, uint8 xpSource) override
        {
            ChallengeMode::OnPlayerGiveXP(player, amount, victim, xpSource);
        }

        void OnPlayerLevelChanged(Player* player, uint8 oldlevel) override
        {
            ChallengeMode::OnPlayerLevelChanged(player, oldlevel);
        }
    };

    // ---- Self-Crafted ----
    class ChallengeModeSelfCrafted : public ChallengeMode
    {
    public:
        ChallengeModeSelfCrafted() : ChallengeMode("ChallengeModeSelfCrafted", SETTING_SELF_CRAFTED) { }

        bool OnPlayerCanEquipItem(Player* player, uint8 /*slot*/, uint16& /*dest*/, Item* pItem, bool /*swap*/, bool /*not_loading*/) override
        {
            if (!sChallengeModes->challengeEnabledForPlayer(SETTING_SELF_CRAFTED, player))
                return true;
            if (!pItem->GetTemplate()->HasSignature())
                return false;
            return pItem->GetGuidValue(ITEM_FIELD_CREATOR) == player->GetGUID();
        }

        void OnPlayerGiveXP(Player* player, uint32& amount, Unit* victim, uint8 xpSource) override
        {
            ChallengeMode::OnPlayerGiveXP(player, amount, victim, xpSource);
        }

        void OnPlayerLevelChanged(Player* player, uint8 oldlevel) override
        {
            ChallengeMode::OnPlayerLevelChanged(player, oldlevel);
        }
    };

    // ---- Item Quality Level ----
    class ChallengeModeItemQualityLevel : public ChallengeMode
    {
    public:
        ChallengeModeItemQualityLevel() : ChallengeMode("ChallengeModeItemQualityLevel", SETTING_ITEM_QUALITY_LEVEL) { }

        bool OnPlayerCanEquipItem(Player* player, uint8 /*slot*/, uint16& /*dest*/, Item* pItem, bool /*swap*/, bool /*not_loading*/) override
        {
            if (!sChallengeModes->challengeEnabledForPlayer(SETTING_ITEM_QUALITY_LEVEL, player))
                return true;
            return pItem->GetTemplate()->Quality <= ITEM_QUALITY_NORMAL;
        }

        void OnPlayerGiveXP(Player* player, uint32& amount, Unit* victim, uint8 xpSource) override
        {
            ChallengeMode::OnPlayerGiveXP(player, amount, victim, xpSource);
        }

        void OnPlayerLevelChanged(Player* player, uint8 oldlevel) override
        {
            ChallengeMode::OnPlayerLevelChanged(player, oldlevel);
        }
    };

    // ---- Slow/Very Slow XP ----
    class ChallengeModeSlowXpGain : public ChallengeMode
    {
    public:
        ChallengeModeSlowXpGain() : ChallengeMode("ChallengeModeSlowXpGain", SETTING_SLOW_XP_GAIN) { }
    };

    class ChallengeModeVerySlowXpGain : public ChallengeMode
    {
    public:
        ChallengeModeVerySlowXpGain() : ChallengeMode("ChallengeModeVerySlowXpGain", SETTING_VERY_SLOW_XP_GAIN) { }
    };

    // ---- Quest XP Only ----
    class ChallengeModeQuestXpOnly : public ChallengeMode
    {
    public:
        ChallengeModeQuestXpOnly() : ChallengeMode("ChallengeModeQuestXpOnly", SETTING_QUEST_XP_ONLY) { }

        void OnPlayerGiveXP(Player* player, uint32& amount, Unit* victim, uint8 xpSource) override
        {
            if (!sChallengeModes->challengeEnabledForPlayer(SETTING_QUEST_XP_ONLY, player))
                return;
            if (victim)
            {
                // XP с убийств не начисляем; питомцу остаётся (не обгонит игрока)
                Pet* pet = player->GetPet();
                if (pet && xpSource == XPSOURCE_KILL)
                    pet->GivePetXP(player->GetGroup() ? amount / 2 : amount);
                amount = 0;
            }
            else
            {
                ChallengeMode::OnPlayerGiveXP(player, amount, victim, xpSource);
            }
        }
    };

    // ---- Iron Man ----
    class ChallengeModeIronMan : public ChallengeMode
    {
    public:
        ChallengeModeIronMan() : ChallengeMode("ChallengeModeIronMan", SETTING_IRON_MAN) { }

        void OnPlayerResurrect(Player* player, float /*restore_percent*/, bool& /*applySickness*/) override
        {
            if (!sChallengeModes->challengeEnabledForPlayer(SETTING_IRON_MAN, player))
                return;
            // Аналогично Hardcore: хук запрета реса отсутствует — убиваем повторно
            player->KillPlayer();
        }

        void OnPlayerGiveXP(Player* player, uint32& amount, Unit* victim, uint8 xpSource) override
        {
            ChallengeMode::OnPlayerGiveXP(player, amount, victim, xpSource);
        }

        void OnPlayerLevelChanged(Player* player, uint8 oldlevel) override
        {
            if (!sChallengeModes->challengeEnabledForPlayer(SETTING_IRON_MAN, player))
                return;
            player->SetFreeTalentPoints(0);
            ChallengeMode::OnPlayerLevelChanged(player, oldlevel);
        }

        void OnPlayerTalentsReset(Player* player, bool /*noCost*/) override
        {
            if (!sChallengeModes->challengeEnabledForPlayer(SETTING_IRON_MAN, player))
                return;
            player->SetFreeTalentPoints(0);
        }

        bool OnPlayerCanEquipItem(Player* player, uint8 /*slot*/, uint16& /*dest*/, Item* pItem, bool /*swap*/, bool /*not_loading*/) override
        {
            if (!sChallengeModes->challengeEnabledForPlayer(SETTING_IRON_MAN, player))
                return true;
            return pItem->GetTemplate()->Quality <= ITEM_QUALITY_NORMAL;
        }

        bool OnPlayerCanApplyEnchantment(Player* player, Item* /*item*/, EnchantmentSlot /*slot*/, bool /*apply*/, bool /*apply_dur*/, bool /*ignore_condition*/) override
        {
            if (!sChallengeModes->challengeEnabledForPlayer(SETTING_IRON_MAN, player))
                return true;
            return false;
        }

        void OnPlayerLearnSpell(Player* player, uint32 spellID) override
        {
            if (!sChallengeModes->challengeEnabledForPlayer(SETTING_IRON_MAN, player))
                return;
            // Классовые навыки — не профессии, разрешены
            switch (spellID)
            {
                case RUNEFORGING:    // рунный ковач ДК
                case POISONS:        // яды разбойника
                case BEAST_TRAINING: // дрессировка зверя охотника
                    return;
                default:
                    break;
            }
            SpellInfo const* spellInfo = sSpellMgr->GetSpellInfo(spellID);
            if (!spellInfo)
                return;
            for (uint8 i = 0; i < 3; i++)
            {
                if (spellInfo->Effects[i].Effect == SPELL_EFFECT_TRADE_SKILL)
                {
                    player->removeSpell(spellID, SPEC_MASK_ALL, false);
                    return;
                }
            }
        }

        bool OnPlayerCanUseItem(Player* player, ItemTemplate const* proto, InventoryResult& /*result*/) override
        {
            if (!sChallengeModes->challengeEnabledForPlayer(SETTING_IRON_MAN, player))
                return true;
            // Запрет зелий, эликсиров, фласок
            if (proto->Class == ITEM_CLASS_CONSUMABLE &&
                (proto->SubClass == ITEM_SUBCLASS_POTION ||
                 proto->SubClass == ITEM_SUBCLASS_ELIXIR ||
                 proto->SubClass == ITEM_SUBCLASS_FLASK))
                return false;
            // Запрет еды, дающей баффы
            if (proto->Class == ITEM_CLASS_CONSUMABLE && proto->SubClass == ITEM_SUBCLASS_FOOD)
            {
                for (auto const& spell : proto->Spells)
                {
                    SpellInfo const* spellInfo = sSpellMgr->GetSpellInfo(spell.SpellId);
                    if (!spellInfo)
                        continue;
                    for (uint8 i = 0; i < 3; i++)
                    {
                        if (spellInfo->Effects[i].ApplyAuraName == SPELL_AURA_PERIODIC_TRIGGER_SPELL)
                            return false;
                    }
                }
            }
            return true;
        }

        bool OnPlayerCanGroupInvite(Player* player, std::string& /*membername*/) override
        {
            if (!sChallengeModes->challengeEnabledForPlayer(SETTING_IRON_MAN, player))
                return true;
            return false;
        }

        bool OnPlayerCanGroupAccept(Player* player, Group* /*group*/) override
        {
            if (!sChallengeModes->challengeEnabledForPlayer(SETTING_IRON_MAN, player))
                return true;
            return false;
        }
    };

    // ---- Алтарь Испытаний (GameObjectScript) ----
    class altar_challenge_modes : public GameObjectScript
    {
    private:
        static bool playerSettingEnabled(Player* player, uint8 settingIndex)
        {
            return player->GetPlayerSetting("mod-challenge-modes", settingIndex).value;
        }

    public:
        altar_challenge_modes() : GameObjectScript("altar_challenge_modes") { }

        struct AltarAI : public GameObjectAI
        {
            explicit AltarAI(GameObject* object) : GameObjectAI(object) { }

            bool CanBeSeen(Player const* player) override
            {
                if ((player->GetLevel() > 1 && player->getClass() != CLASS_DEATH_KNIGHT) || (player->GetLevel() > 55))
                    return false;
                return sChallengeModes->enabled();
            }
        };

        bool OnGossipHello(Player* player, GameObject* go) override
        {
            bool ruLocale = IsRuLocale(player->GetSession()->GetSessionDbcLocale());

            if (sChallengeModes->challengeEnabled(SETTING_HARDCORE)
                && !playerSettingEnabled(player, SETTING_HARDCORE) && !playerSettingEnabled(player, SETTING_SEMI_HARDCORE))
            {
                AddGossipItemFor(player, GOSSIP_ICON_CHAT, ruLocale ? GOSSIP_HARDCORE_RU : GOSSIP_HARDCORE_EN, 0, SETTING_HARDCORE);
            }
            if (sChallengeModes->challengeEnabled(SETTING_SEMI_HARDCORE)
                && !playerSettingEnabled(player, SETTING_HARDCORE) && !playerSettingEnabled(player, SETTING_SEMI_HARDCORE))
            {
                AddGossipItemFor(player, GOSSIP_ICON_CHAT, ruLocale ? GOSSIP_SEMI_RU : GOSSIP_SEMI_EN, 0, SETTING_SEMI_HARDCORE);
            }
            if (sChallengeModes->challengeEnabled(SETTING_SELF_CRAFTED)
                && !playerSettingEnabled(player, SETTING_SELF_CRAFTED) && !playerSettingEnabled(player, SETTING_IRON_MAN))
            {
                AddGossipItemFor(player, GOSSIP_ICON_CHAT, ruLocale ? GOSSIP_CRAFTED_RU : GOSSIP_CRAFTED_EN, 0, SETTING_SELF_CRAFTED);
            }
            if (sChallengeModes->challengeEnabled(SETTING_ITEM_QUALITY_LEVEL)
                && !playerSettingEnabled(player, SETTING_ITEM_QUALITY_LEVEL))
            {
                AddGossipItemFor(player, GOSSIP_ICON_CHAT, ruLocale ? GOSSIP_QUALITY_RU : GOSSIP_QUALITY_EN, 0, SETTING_ITEM_QUALITY_LEVEL);
            }
            if (sChallengeModes->challengeEnabled(SETTING_SLOW_XP_GAIN)
                && !playerSettingEnabled(player, SETTING_SLOW_XP_GAIN) && !playerSettingEnabled(player, SETTING_VERY_SLOW_XP_GAIN))
            {
                AddGossipItemFor(player, GOSSIP_ICON_CHAT, ruLocale ? GOSSIP_SLOWXP_RU : GOSSIP_SLOWXP_EN, 0, SETTING_SLOW_XP_GAIN);
            }
            if (sChallengeModes->challengeEnabled(SETTING_VERY_SLOW_XP_GAIN)
                && !playerSettingEnabled(player, SETTING_SLOW_XP_GAIN) && !playerSettingEnabled(player, SETTING_VERY_SLOW_XP_GAIN))
            {
                AddGossipItemFor(player, GOSSIP_ICON_CHAT, ruLocale ? GOSSIP_VSLOWXP_RU : GOSSIP_VSLOWXP_EN, 0, SETTING_VERY_SLOW_XP_GAIN);
            }
            if (sChallengeModes->challengeEnabled(SETTING_QUEST_XP_ONLY)
                && !playerSettingEnabled(player, SETTING_QUEST_XP_ONLY))
            {
                AddGossipItemFor(player, GOSSIP_ICON_CHAT, ruLocale ? GOSSIP_QUESTXP_RU : GOSSIP_QUESTXP_EN, 0, SETTING_QUEST_XP_ONLY);
            }
            if (sChallengeModes->challengeEnabled(SETTING_IRON_MAN)
                && !playerSettingEnabled(player, SETTING_IRON_MAN) && !playerSettingEnabled(player, SETTING_SELF_CRAFTED))
            {
                AddGossipItemFor(player, GOSSIP_ICON_CHAT, ruLocale ? GOSSIP_IRONMAN_RU : GOSSIP_IRONMAN_EN, 0, SETTING_IRON_MAN);
            }
            SendGossipMenuFor(player, 12669, go->GetGUID());
            return true;
        }

        bool OnGossipSelect(Player* player, GameObject* /*go*/, uint32 /*sender*/, uint32 action) override
        {
            player->UpdatePlayerSetting("mod-challenge-modes", action, 1);
            bool ruLocale = IsRuLocale(player->GetSession()->GetSessionDbcLocale());
            ChatHandler(player->GetSession()).PSendSysMessage(ruLocale ? GOSSIP_ENABLED_RU : GOSSIP_ENABLED_EN);
            CloseGossipMenuFor(player);
            return true;
        }

        GameObjectAI* GetAI(GameObject* object) const override
        {
            return new AltarAI(object);
        }
    };
}

// Регистрация скриптов ядра (глобальные инстансы)
ChallengeModesWorldScript* ChallengeModesWorldScriptInstance = new ChallengeModesWorldScript();
altar_challenge_modes* altar_challenge_modesInstance = new altar_challenge_modes();
ChallengeModeHardcore* ChallengeModeHardcoreInstance = new ChallengeModeHardcore();
ChallengeModeSemiHardcore* ChallengeModeSemiHardcoreInstance = new ChallengeModeSemiHardcore();
ChallengeModeSelfCrafted* ChallengeModeSelfCraftedInstance = new ChallengeModeSelfCrafted();
ChallengeModeItemQualityLevel* ChallengeModeItemQualityLevelInstance = new ChallengeModeItemQualityLevel();
ChallengeModeSlowXpGain* ChallengeModeSlowXpGainInstance = new ChallengeModeSlowXpGain();
ChallengeModeVerySlowXpGain* ChallengeModeVerySlowXpGainInstance = new ChallengeModeVerySlowXpGain();
ChallengeModeQuestXpOnly* ChallengeModeQuestXpOnlyInstance = new ChallengeModeQuestXpOnly();
ChallengeModeIronMan* ChallengeModeIronManInstance = new ChallengeModeIronMan();

// Точка входа для генерируемого загрузчика модулей ядра
// (modules/CMakeLists.txt -> ConfigureScriptLoader -> AddEchoChallengeModesScripts()).
void AddEchoChallengeModesScripts()
{
    // Скрипты зарегистрированы глобальными инстансами выше.
}
