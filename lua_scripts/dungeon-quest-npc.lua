-- ============================================================================
--  DungeonQuestNPC
--
--  A quest giver at the entrance of every instance, a turn-in NPC and a
--  return portal at the exit:
--    * the start NPC lists every quest of that instance in one menu
--    * the end NPC takes the turn-in of every quest of that instance
--    * the portal beside him sends you back to the entrance
--
--  Three files, kept together in your lua_scripts folder:
--    dungeon-quest-npc.lua   this one - the menu and the portal
--    dungeon-quest-data.lua  the dungeons, their NPCs and their quests
--    dungeon-quest.sql       the NPCs, the spawns and the turn-ins
--
--  AzerothCore / WotLK 3.3.5a.  Needs Eluna with WorldDBQuery
--  (Eluna.UseUnsafeMethods = 1, which is the default).
--
--  Everything a quest is - title, level, requirements, chain links - is read
--  from the world database when the first player speaks to an NPC, so it is
--  always your server's data, in the player's own language.
-- ============================================================================
-- --------------------------------------------------------------------------
--  SETTINGS
-- --------------------------------------------------------------------------

local Config = {

    -- How many rows a page holds.  16 fits the 3.3.5 gossip window;
    -- capped at 24 so the menu can never overflow.
    PAGE_SIZE = 16,

    -- Which requirements keep a quest out of reach.  false = the giver
    -- ignores that requirement and offers the quest anyway.
    ENFORCE = {
        minLevel       = true,
        maxLevel       = false,
        race           = true,
        class          = true,
        reputation     = true,
        skill          = true,

        previousQuest  = false,
        nextChain      = false,
        prevChain      = false,
        breadcrumb     = false,

        exclusiveGroup = true,

        requiredGroup  = false,

    },

    -- Which quests you cannot take earn a row in the menu, with the reason
    -- in brackets.  true = all of them, false = none, and a table names the
    -- ones to leave out - by gate, the same names as ENFORCE above:
    --
    --     SHOW_UNAVAILABLE = { race = false, class = false }
    --
    -- leaves out everything your race or class rules out and still lists
    -- what you are too low level for.  A gate you do not name stays shown,
    -- so the table is a list of exceptions, not a list of what to keep.
    -- The quest states (inLog, ready, done, failed) and the kinds switched
    -- off in OFFER (escort, attunement, ...) work the same way.
    -- SHOW_UNAVAILABLE = true,
    SHOW_UNAVAILABLE = { race = false, class = false , skill = false , reputation = false},

    -- "Take every available quest (n)" as the first row of the menu.
    SHOW_TAKE_ALL = true,

    -- The icon the client draws on the left of a row (GossipOptionIcon).
    -- The split is what the rows MEAN:
    --    0  a gossip bubble - every row that does something when clicked
    --   10  a grey dot     - rows that are only there to be read: the
    --                        section headings and the quests you cannot take
    -- 7 is a speech bubble, if you would rather "take every available
    -- quest" stood out from the rest.
    ICONS = {
        quest   = 0,
        command = 0,
        page    = 0,
        locked  = 10,
        heading = 10,
        empty   = 10,
    },

    -- Dungeons to skip, by the slug in dungeon-quest-data.lua.  The real
    -- switch is the configuration block at the top of dungeon-quest.sql;
    -- this one is for when you cannot re-import.
    DISABLE = {

    },

    -- npc_text row used as the body text of the menu (created by
    -- dungeon-quest.sql).
    NPC_TEXT_START = 92000,

    -- Entry base of the return portals.  Must match dungeon-quest.sql;
    -- the portal of dungeon n is PORTAL_BASE + n.
    PORTAL_BASE = 9400000,

    -- Entry column of the `creature` spawn table: "id1" on a current
    -- AzerothCore, "id" on databases built before 2021.  It is only read
    -- to see which map a quest's turn-in NPC stands on.
    -- Adapted for our AzerothCore (creature uses id1).
    CREATURE_ID_COLUMN = "id1",

    -- Kinds of quest the giver offers.  false = listed greyed out, with
    -- the kind as the reason.
    OFFER = {
        breadcrumb       = true,
        breadcrumbTarget = true,
        chain            = true,
        repeatable       = true,
        event            = true,
        raid             = true,
        group            = true,
        heroic           = true,
        escort           = false,
        errand           = false,
        outside          = true,
        attunement       = false,
    },

    -- Kinds of quest left out of the menu altogether.  Wins over OFFER.
    HIDE = {
        breadcrumb       = false,
        breadcrumbTarget = false,
        chain            = false,
        repeatable       = false,
        event            = false,
        raid             = false,
        group            = false,
        heroic           = false,
        escort           = false,
        errand           = true,
        outside          = false,
        attunement       = false,
    },

    -- Menu text colours, six hex digits each.  Chat messages are
    -- unaffected and keep the client's own bright hues.
    COLOURS = {
        red     = "841313",
        orange  = "814100",
        yellow  = "816a00",
        green   = "118100",
        trivial = "4a7a35",
        locked  = "7a2e2e",
        grey    = "505050",
        white   = "858585",
        teal    = "006780",
    },

    -- Print the module's log lines to the server console.
    DEBUG = false,
}

-- --------------------------------------------------------------------------
--  EVENT IDS, ICONS AND INTERNAL NUMBERS
-- --------------------------------------------------------------------------

local GOSSIP_EVENT_ON_HELLO  = 1
local GOSSIP_EVENT_ON_SELECT = 2
local GAMEOBJECT_EVENT_ON_USE = 14

local GOSSIP_ICON_CHAT = 0

-- The icon of a kind of row, from Config.ICONS.
local function RowIcon(kind)
    local icons = type(Config.ICONS) == "table" and Config.ICONS or {}
    local value = tonumber(icons[kind])
    if value and value >= 0 and value <= 10 then
        return value
    end
    return GOSSIP_ICON_CHAT
end

local QUEST_STATUS_NONE       = 0
local QUEST_STATUS_COMPLETE   = 1
local QUEST_STATUS_INCOMPLETE = 3
local QUEST_STATUS_FAILED     = 5
local QUEST_STATUS_REWARDED   = 6

local SENDER_START = 1

local ACTION_PAGE       = 0
local ACTION_ENTRY      = 1000
local ACTION_ALL        = 100000
local ACTION_TAKE_ALL   = ACTION_ALL + 1
local ACTION_NOOP       = ACTION_ALL + 2

local MAX_ENTRIES = 1000
local PAGE_STRIDE = MAX_ENTRIES

-- Entries carry the page number inside their intid, so clicking one -
-- or clicking one you cannot take - leaves you on the page you were
-- reading instead of sending you back to the first one.
local function EntryIntid(page, index)
    return ACTION_ENTRY + (page - 1) * PAGE_STRIDE + (index - 1)
end

local function GlobalIntid(action, page)
    return action + (page - 1) * PAGE_STRIDE
end

local function DecodeIntid(intid)
    if intid > 0 and intid < ACTION_ENTRY then
        return "page", intid, 0
    end
    if intid >= ACTION_ALL then
        local n     = intid - ACTION_ALL
        local slot  = (n - 1) % PAGE_STRIDE
        local page  = math.floor((n - 1) / PAGE_STRIDE) + 1
        return (slot == 0) and "takeall" or "noop", page, 0
    end
    local n = intid - ACTION_ENTRY
    return "entry", math.floor(n / PAGE_STRIDE) + 1, n % PAGE_STRIDE + 1
end

Config.PAGE_SIZE = math.min(math.max(Config.PAGE_SIZE, 5), 24)

-- --------------------------------------------------------------------------
--  SMALL HELPERS
-- --------------------------------------------------------------------------

local MODULE = "|cff00ccff[DungeonQuestNPC]|r "

local function Debug(fmt, ...)
    if Config.DEBUG then
        print(string.format("[DungeonQuestNPC] " .. fmt, ...))
    end
end

-- Bit test that needs no bit32 / LuaBitOp / 5.3 operators; index 0 is
-- the lowest bit.
local POW2 = {}
for i = 0, 31 do
    POW2[i] = 2 ^ i
end

local function HasBit(value, index)
    local bit = index and POW2[index]
    if not value or not bit then
        return false
    end
    return value % (bit * 2) >= bit
end

-- |cffRRGGBB
local function Colour(r, g, b)
    return string.format("|cff%02x%02x%02x", r, g, b)
end

-- Chat colours: messages land on a dark background, so they are bright.
local C_GREY  = Colour(0x9d, 0x9d, 0x9d)
local C_GREEN = Colour(0x1e, 0xff, 0x00)
local C_RED   = Colour(0xff, 0x20, 0x20)
local C_TEAL  = Colour(0x00, 0xcc, 0xff)
local RESET   = "|r"

-- the client's own quest-difficulty colours, for the links below
local C_DIFF = {
    Colour(0xff, 0x20, 0x20),
    Colour(0xff, 0x80, 0x00),
    Colour(0xff, 0xff, 0x00),
    Colour(0x1e, 0xff, 0x00),
    C_GREY,
    C_GREY,
}

-- Config colours are plain hex strings; an unusable one falls back.
local function Hex(value, fallback)
    local hex = tostring(value or ""):lower():gsub("^#", ""):gsub("[^0-9a-f]", "")
    if #hex ~= 6 then
        hex = fallback
    end
    return "|cff" .. hex
end

-- Menu colours.  The gossip frame is a mid-tone parchment that washes
-- text out, so the same hues are darkened.  "trivial" is a quest you
-- have out-levelled but can still take, "locked" one you cannot take -
-- deliberately not shades of each other, so the two are never confused.
local C = Config.COLOURS or {}

local M_RED     = Hex(C.red,     "841313")
local M_ORANGE  = Hex(C.orange,  "814100")
local M_YELLOW  = Hex(C.yellow,  "816a00")
local M_GREEN   = Hex(C.green,   "118100")
local M_TRIVIAL = Hex(C.trivial, "4a7a35")
local M_LOCKED  = Hex(C.locked,  "7a2e2e")
local M_GREY    = Hex(C.grey,    "505050")
local M_WHITE   = Hex(C.white,   "858585")
local M_TEAL    = Hex(C.teal,    "006780")

-- how hard a quest is for this player: 1 hardest, 6 trivial
local function DifficultyRank(questLevel, playerLevel)
    if not questLevel or questLevel <= 0 then
        return 5
    end
    local diff = questLevel - playerLevel
    if diff >= 5 then
        return 1
    elseif diff >= 3 then
        return 2
    elseif diff >= -2 then
        return 3
    elseif diff >= -5 then
        return 4
    end
    return 6
end

local function QuestColour(questLevel, playerLevel)
    local rank = DifficultyRank(questLevel, playerLevel)
    if rank == 1 then
        return M_RED
    elseif rank == 2 then
        return M_ORANGE
    elseif rank == 3 then
        return M_YELLOW
    elseif rank == 4 then
        return M_GREEN
    elseif rank == 5 then
        return M_WHITE
    end
    return M_TRIVIAL
end

-- a line in the player's chat
local function Msg(player, text)
    player:SendBroadcastMessage(MODULE .. text)
end

-- AllowableRaces / AllowableClasses bit -> name
local RACE_NAMES = {
    [0] = "Human", "Orc", "Dwarf", "Night Elf", "Undead", "Tauren",
    "Gnome", "Troll", "Goblin", "Blood Elf", "Draenei",
}
local CLASS_NAMES = {
    [0] = "Warrior", "Paladin", "Hunter", "Rogue", "Priest", "Death Knight",
    "Shaman", "Mage", "Warlock", nil, "Druid",
}

local function MaskNames(mask, names)
    if not mask or mask == 0 then
        return nil
    end
    local out = {}
    for i = 0, 31 do
        if names[i] and HasBit(mask, i) then
            out[#out + 1] = names[i]
        end
    end
    if #out == 0 then
        return nil
    end
    return table.concat(out, ", ")
end

local RACE_ALLIANCE = 1 + 4 + 8 + 64 + 1024
local RACE_HORDE    = 2 + 16 + 32 + 128 + 512

-- A faction mask is named after the faction: spelling out its five
-- races wraps on half the menu lines.
local function OnlyFor(mask, names, fallback)
    if mask == RACE_ALLIANCE then return "Alliance only" end
    if mask == RACE_HORDE then return "Horde only" end
    local text = MaskNames(mask, names)
    if not text then return fallback end
    return text .. " only"
end

if not DQN or not DQN.DUNGEONS then
    print("[DungeonQuestNPC] ERROR: dungeon-quest-data.lua did not load - "
          .. "the module is disabled.")
    return
end

local DUNGEONS = DQN.DUNGEONS

-- The two kinds of quest the database cannot describe ("outside" and
-- "attunement"), listed by quest id in the data file.  They are seeds
-- rather than a complete classification; "errand" is detected on its own.
local TAGS = DQN.TAGS or {}

-- creature entry -> dungeon id, built once from the data file
local BY_ENTRY = DQN.BY_ENTRY or {}
if not DQN.BY_ENTRY then
    BY_ENTRY = {}
    for id, d in pairs(DUNGEONS) do
        if d.giver and d.giver > 0 then BY_ENTRY[d.giver] = id end
        if d.ender and d.ender > 0 then BY_ENTRY[d.ender] = id end
    end
    DQN.BY_ENTRY = BY_ENTRY
end

-- NPC entry -> its dungeon
local function DungeonOf(entry)
    local id = BY_ENTRY[entry]
    return id and DUNGEONS[id] or nil, id
end

-- --------------------------------------------------------------------------
--  QUEST DATA - READ FROM THE WORLD DATABASE, ONCE, ON FIRST USE
-- --------------------------------------------------------------------------

-- Quest attributes, keyed by quest id.  Field names:
--   n title   l quest level   m min level   M max level
--   r AllowableRaces          c AllowableClasses
--   g ExclusiveGroup          p PrevQuestID   x NextQuestID
--   b BreadcrumbForQuestId    s { skill, points }
--   rm { faction, min rep }   rx { faction, max rep }
--   r2 { faction, value } - the reputation the core refuses you AT or above
--   i QuestInfoID   f Flags   S SpecialFlags   T a breadcrumb leads here
--   o the quest asks for something (kills, items, reputation)
local ATTR      = nil
local LOCALES   = {}
local loadError = nil

local LOCALE_NAME = {
    [0] = "enUS", [1] = "koKR", [2] = "frFR", [3] = "deDE", [4] = "zhCN",
    [5] = "zhTW", [6] = "esES", [7] = "esMX", [8] = "ruRU",
}

-- every quest the givers offer
local function QuestIds()
    local seen, ids = {}, {}
    for _, d in pairs(DUNGEONS) do
        for _, qid in ipairs(d.start or {}) do
            if not seen[qid] then
                seen[qid] = true
                ids[#ids + 1] = qid
            end
        end
    end
    table.sort(ids)
    return ids
end

-- keeps the IN() lists a sane size
local function Chunks(ids, size)
    local out, chunk = {}, {}
    for _, id in ipairs(ids) do
        chunk[#chunk + 1] = id
        if #chunk >= size then
            out[#out + 1] = chunk
            chunk = {}
        end
    end
    if #chunk > 0 then
        out[#out + 1] = chunk
    end
    return out
end

-- iterates over the rows of a query; yields nothing when there are none
local function Rows(sql)
    local ok, result = pcall(WorldDBQuery, sql)
    if not ok or not result or result:GetRowCount() == 0 then
        return function() return nil end
    end
    local first = true
    return function()
        if not first and not result:NextRow() then
            return nil
        end
        first = false
        return result:GetRow()
    end
end

-- true when the quest asks for anything at all - kills, items, a
-- reputation to build.  With none of those it is "go and speak to
-- somebody", which is what makes a quest an errand.
local function HasObjectives(row)
    for _, name in ipairs({ "RequiredNpcOrGo1", "RequiredNpcOrGo2",
                            "RequiredNpcOrGo3", "RequiredNpcOrGo4",
                            "RequiredItemId1", "RequiredItemId2",
                            "RequiredItemId3", "RequiredItemId4",
                            "RequiredItemId5", "RequiredItemId6" }) do
        local value = tonumber(row[name])
        if value and value ~= 0 then
            return true
        end
    end
    return false
end

-- RequiredFactionId1/Value1 is a reputation OBJECTIVE, not a gate, so
-- it is deliberately not read here.
local function ReadQuests(attr, ids)
    for _, chunk in ipairs(Chunks(ids, 500)) do
        local inList = table.concat(chunk, ",")

        for row in Rows("SELECT `ID`, `LogTitle`, `QuestLevel`, `MinLevel`, "
            .. "`AllowableRaces`, `RequiredFactionId2`, "
            .. "`RequiredFactionValue2`, `QuestInfoID`, `Flags`, "
            .. "`RequiredNpcOrGo1`, `RequiredNpcOrGo2`, "
            .. "`RequiredNpcOrGo3`, `RequiredNpcOrGo4`, "
            .. "`RequiredItemId1`, `RequiredItemId2`, `RequiredItemId3`, "
            .. "`RequiredItemId4`, `RequiredItemId5`, `RequiredItemId6` "
            .. "FROM `quest_template` "
            .. "WHERE `ID` IN (" .. inList .. ")") do
            local qid = row.ID
            if qid then
                attr[qid] = {
                    n  = row.LogTitle or ("Quest " .. tostring(qid)),
                    l  = row.QuestLevel or 0,
                    m  = row.MinLevel or 0,
                    M  = 0,
                    r  = row.AllowableRaces or 0,
                    c  = 0, g = 0, p = 0, x = 0, b = 0,
                    rm = { 0, 0 },
                    rx = { 0, 0 },
                    r2 = { 0, 0 },
                    s  = { 0, 0 },
                    i  = row.QuestInfoID or 0,
                    f  = row.Flags or 0,
                    S  = 0,
                    T  = false,
                    o  = HasObjectives(row),
                }

                if row.RequiredFactionId2 and row.RequiredFactionId2 ~= 0 then
                    attr[qid].r2 = { row.RequiredFactionId2,
                                     row.RequiredFactionValue2 or 0 }
                end
            end
        end

        for row in Rows("SELECT `ID`, `MaxLevel`, `AllowableClasses`, "
            .. "`ExclusiveGroup`, `PrevQuestID`, `NextQuestID`, "
            .. "`BreadcrumbForQuestId`, `RequiredSkillID`, "
            .. "`RequiredSkillPoints`, `RequiredMinRepFaction`, "
            .. "`RequiredMinRepValue`, `RequiredMaxRepFaction`, "
            .. "`RequiredMaxRepValue`, `SpecialFlags` "
            .. "FROM `quest_template_addon` "
            .. "WHERE `ID` IN (" .. inList .. ")") do
            local a = row.ID and attr[row.ID]
            if a then
                a.M = row.MaxLevel or 0
                a.c = row.AllowableClasses or 0
                a.g = row.ExclusiveGroup or 0
                a.p = row.PrevQuestID or 0
                a.x = row.NextQuestID or 0
                a.b = row.BreadcrumbForQuestId or 0
                a.S = row.SpecialFlags or 0
                if row.RequiredSkillID and row.RequiredSkillID ~= 0 then
                    a.s = { row.RequiredSkillID,
                            row.RequiredSkillPoints or 0 }
                end
                if row.RequiredMinRepFaction
                        and row.RequiredMinRepFaction ~= 0 then
                    a.rm = { row.RequiredMinRepFaction,
                             row.RequiredMinRepValue or 0 }
                end
                if row.RequiredMaxRepFaction
                        and row.RequiredMaxRepFaction ~= 0 then
                    a.rx = { row.RequiredMaxRepFaction,
                             row.RequiredMaxRepValue or 0 }
                end
            end
        end
    end
end

-- read everything the gates need, once, on first use
local function LoadAttributes()
    if ATTR then
        return true
    end
    if loadError then
        return false
    end

    if type(WorldDBQuery) ~= "function" then
        loadError = "WorldDBQuery() is not available. Enable it with "
                    .. "Eluna.UseUnsafeMethods = 1 in your Eluna config."
        print("[DungeonQuestNPC] ERROR: " .. loadError)
        return false
    end

    local ok, err = pcall(function()
        local attr = {}
        ReadQuests(attr, QuestIds())

        for _, a in pairs(attr) do
            if a.b ~= 0 and attr[a.b] then
                attr[a.b].T = true
            end
        end
        ATTR = attr

        local extra = {}
        for _, a in pairs(attr) do
            for _, ref in ipairs({ a.p, a.x, a.b }) do
                ref = math.abs(ref or 0)
                if ref ~= 0 and not attr[ref] then
                    extra[#extra + 1] = ref
                end
            end
        end
        if #extra > 0 then
            ReadQuests(attr, extra)
        end
    end)

    if not ok then
        loadError = tostring(err)
        print("[DungeonQuestNPC] ERROR: could not read quest data from the "
              .. "world database: " .. loadError)
        return false
    end

    local n = 0
    for _ in pairs(ATTR) do n = n + 1 end
    Debug("read %d quests from the world database", n)
    if n == 0 then
        loadError = "quest_template returned no rows"
        print("[DungeonQuestNPC] ERROR: " .. loadError)
        return false
    end
    return true
end

-- every quest the module knows: what the givers offer, plus the ones
-- that are only named inside a reason
local function KnownIds()
    local ids = {}
    for qid in pairs(ATTR or {}) do ids[#ids + 1] = qid end
    table.sort(ids)
    return ids
end

-- quest_template_locale titles for one language, read once
local function LoadLocale(index)
    if index == 0 or not LOCALE_NAME[index] or LOCALES[index] then
        return LOCALES[index]
    end
    local titles = {}
    for _, chunk in ipairs(Chunks(KnownIds(), 500)) do
        for row in Rows("SELECT `ID`, `Title` FROM `quest_template_locale` "
            .. "WHERE `locale` = '" .. LOCALE_NAME[index] .. "' AND `ID` IN ("
            .. table.concat(chunk, ",") .. ")") do
            if row.ID and row.Title and row.Title ~= "" then
                titles[row.ID] = row.Title
            end
        end
    end
    LOCALES[index] = titles
    return titles
end

local function PlayerLocale(player)
    if type(player.GetDbLocaleIndex) ~= "function" then
        return 0
    end
    local ok, index = pcall(function() return player:GetDbLocaleIndex() end)
    if ok and type(index) == "number" then
        return index
    end
    return 0
end

-- the quest title in the player's own language
local function Title(player, qid)
    local a = ATTR and ATTR[qid]
    if not a then
        return "Quest " .. tostring(qid)
    end
    local index = PlayerLocale(player)
    if index ~= 0 then
        local titles = LoadLocale(index)
        if titles and titles[qid] then
            return titles[qid]
        end
    end
    return a.n
end

local function QuestLevelOf(qid)
    local a = ATTR and ATTR[qid]
    return a and a.l or 0
end

-- A clickable quest link for chat: the client asks the server about the
-- quest when the player hovers it, so the tooltip - title, objectives,
-- rewards - comes from the core in the player's own language.
local function QuestLink(player, qid)
    local level = QuestLevelOf(qid)
    return string.format("%s|Hquest:%d:%d|h[%s]|h|r",
                         C_DIFF[DifficultyRank(level, player:GetLevel())],
                         qid, level, Title(player, qid))
end

-- --------------------------------------------------------------------------
--  WHY A QUEST IS NOT OFFERED
-- --------------------------------------------------------------------------

-- reverse indexes, built once from the attributes above:
--   GROUPS[group]     { questId, ... }  ExclusiveGroup, either sign
--   PREV_CHAIN[qid]   { questId, ... }  quests whose NextQuestID is this
--   BREADCRUMBS[qid]  { questId, ... }  quests that breadcrumb to this
local GROUPS, PREV_CHAIN, BREADCRUMBS

local function BuildIndexes()
    if GROUPS then
        return
    end
    GROUPS, PREV_CHAIN, BREADCRUMBS = {}, {}, {}
    for qid, q in pairs(ATTR or {}) do
        if q.g and q.g ~= 0 then
            GROUPS[q.g] = GROUPS[q.g] or {}
            table.insert(GROUPS[q.g], qid)
        end
        if q.x and q.x > 0 then
            PREV_CHAIN[q.x] = PREV_CHAIN[q.x] or {}
            table.insert(PREV_CHAIN[q.x], qid)
        end
        if q.b and q.b > 0 then
            BREADCRUMBS[q.b] = BREADCRUMBS[q.b] or {}
            table.insert(BREADCRUMBS[q.b], qid)
        end
    end
end

local function GroupTitles(player, group)
    if not GROUPS or not GROUPS[group] then
        return nil
    end
    local names = {}
    for _, qid in ipairs(GROUPS[group]) do
        names[#names + 1] = Title(player, qid)
    end
    if #names == 0 then
        return nil
    end
    table.sort(names)
    if #names > 2 then
        return names[1] .. ", " .. names[2] .. " and " .. (#names - 2) .. " more"
    end
    return table.concat(names, ", ")
end

-- nil when the player may take the quest, otherwise the reason, shown in
-- brackets after the title, and the name of the gate behind it - which is
-- what Config.SHOW_UNAVAILABLE is keyed by.
local function Gate(player, qid)
    local q = ATTR and ATTR[qid]
    if not q then
        return nil
    end

    local E = Config.ENFORCE

    if E.minLevel and q.m and q.m > 0 and player:GetLevel() < q.m then
        return "lvl " .. q.m, "minLevel"
    end
    if E.maxLevel and q.M and q.M > 0 and player:GetLevel() > q.M then
        return "max lvl " .. q.M, "maxLevel"
    end

    if E.race and q.r and q.r > 0
            and not HasBit(q.r, player:GetRace() - 1) then
        return OnlyFor(q.r, RACE_NAMES, "another race"), "race"
    end
    if E.class and q.c and q.c > 0
            and not HasBit(q.c, player:GetClass() - 1) then
        return OnlyFor(q.c, CLASS_NAMES, "another class"), "class"
    end

    if E.reputation then
        if q.rm and q.rm[1] and q.rm[1] > 0
                and player:GetReputation(q.rm[1]) < q.rm[2] then
            return "rep too low", "reputation"
        end
        if q.rx and q.rx[1] and q.rx[1] > 0
                and player:GetReputation(q.rx[1]) >= q.rx[2] then
            return "rep too high", "reputation"
        end
        if q.r2 and q.r2[1] and q.r2[1] > 0
                and player:GetReputation(q.r2[1]) >= q.r2[2] then
            return "rep too high", "reputation"
        end
    end

    if E.skill and q.s and q.s[1] and q.s[1] > 0
            and player:GetSkillValue(q.s[1]) < (q.s[2] or 0) then
        return "needs skill", "skill"
    end

    if E.previousQuest and q.p and q.p ~= 0 then
        local prev = math.abs(q.p)
        local status = player:GetQuestStatus(prev)
        if q.p > 0 then

            if status ~= QUEST_STATUS_REWARDED then
                return "needs " .. Title(player, prev), "previousQuest"
            end
        elseif status == QUEST_STATUS_NONE then

            return "needs " .. Title(player, prev), "previousQuest"
        end
    end

    if E.requiredGroup and q.g and q.g < 0 then
        local done = false
        for _, other in ipairs(GROUPS[q.g] or {}) do
            if player:GetQuestStatus(other) == QUEST_STATUS_REWARDED then
                done = true
                break
            end
        end
        if not done then
            return "needs one: " .. (GroupTitles(player, q.g)
                                        or "this quest group"),
                   "requiredGroup"
        end
    end

    if E.exclusiveGroup and q.g and q.g > 0 then
        for _, other in ipairs(GROUPS[q.g] or {}) do
            if other ~= qid and player:GetQuestStatus(other) ~= QUEST_STATUS_NONE then
                return "conflicts: " .. Title(player, other),
                       "exclusiveGroup"
            end
        end
    end

    if E.nextChain and q.x and q.x > 0
            and player:GetQuestStatus(q.x) ~= QUEST_STATUS_NONE then
        return "follow-up: " .. Title(player, q.x), "nextChain"
    end

    if E.prevChain then
        for _, prev in ipairs(PREV_CHAIN[qid] or {}) do
            if player:GetQuestStatus(prev) ~= QUEST_STATUS_NONE then
                return "finish " .. Title(player, prev) .. " first",
                       "prevChain"
            end
        end
    end

    if E.breadcrumb then

        if q.b and q.b > 0
                and player:GetQuestStatus(q.b) ~= QUEST_STATUS_NONE then
            return "superseded: " .. Title(player, q.b), "breadcrumb"
        end

        for _, crumb in ipairs(BREADCRUMBS[qid] or {}) do
            local status = player:GetQuestStatus(crumb)
            if status == QUEST_STATUS_INCOMPLETE
                    or status == QUEST_STATUS_COMPLETE
                    or status == QUEST_STATUS_FAILED then
                return "breadcrumb: " .. Title(player, crumb),
                       "breadcrumb"
            end
        end
    end

    return nil
end

-- --------------------------------------------------------------------------
--  DRAWING THE MENU
-- --------------------------------------------------------------------------

-- Where each page starts.  A page holds Config.PAGE_SIZE rows, except
-- that a section heading is never the last thing on it: it moves down
-- to the page the rows under it are on, rather than hanging there.
local function PageStarts(entries)
    local starts, used, count = { 1 }, 0, #entries
    for index, e in ipairs(entries) do
        if used >= Config.PAGE_SIZE
                or (e.heading and used == Config.PAGE_SIZE - 1
                    and index < count) then
            starts[#starts + 1] = index
            used = 0
        end
        used = used + 1
    end
    return starts
end

local function DrawPage(player, creature, entries, page, sender, npcText)
    local count  = #entries
    local starts = PageStarts(entries)
    local pages  = #starts
    page = math.min(math.max(page or 1, 1), pages)

    local first = starts[page]
    local last  = (starts[page + 1] or (count + 1)) - 1

    for i = first, last do
        local e = entries[i]
        player:GossipMenuAddItem(e.icon or RowIcon("quest"), e.text,
                                 sender, e.intid)
    end

    if pages > 1 then
        if page > 1 then
            player:GossipMenuAddItem(RowIcon("page"),
                                     M_TEAL .. "<-- Previous page|r",
                                     sender, ACTION_PAGE + page - 1)
        end
        if page < pages then
            player:GossipMenuAddItem(RowIcon("page"),
                                     M_TEAL .. "Next page -->|r",
                                     sender, ACTION_PAGE + page + 1)
        end
    end

    player:GossipSendMenu(npcText, creature)
end

-- --------------------------------------------------------------------------
--  QUEST KINDS - Config.OFFER AND Config.HIDE
-- --------------------------------------------------------------------------

local TYPE_ORDER = { "breadcrumb", "breadcrumbTarget", "chain", "repeatable",
                     "event", "raid", "group", "heroic", "escort", "errand",
                     "outside", "attunement" }

-- the reason shown in brackets when a kind is switched off: a word or
-- two, because it shares a gossip line with the quest title
local TYPE_LABEL = {
    breadcrumb       = "breadcrumb",
    breadcrumbTarget = "breadcrumb target",
    chain            = "chain",
    repeatable       = "repeatable",
    event            = "event",
    raid             = "raid",
    group            = "group",
    heroic           = "heroic",
    escort           = "escort",
    errand           = "errand",
    outside          = "outside",
    attunement       = "attunement",
}

local TAG_CACHE = {}

-- Everything the database can say about a quest's kind.  The tags in
-- the data file add what the database cannot express, and win over
-- anything detected here.
local function QuestTags(qid)
    local cached = TAG_CACHE[qid]
    if cached then
        return cached
    end

    local tags = {}
    local a = ATTR and ATTR[qid]
    if a then
        if a.b ~= 0 then
            tags.breadcrumb = true
        end
        if a.T then
            tags.breadcrumbTarget = true
        end
        if a.p ~= 0 or a.x ~= 0 then
            tags.chain = true
        end
        if HasBit(a.S, 0) then
            tags.repeatable = true
        end
        if HasBit(a.S, 1) then
            tags.event = true
        end

        if a.i == 62 or HasBit(a.f, 6) then
            tags.raid = true
        end
        if a.i == 1 then
            tags.group = true
        end
        if a.i == 84 then
            tags.escort = true
        end
        if a.i == 85 then
            tags.heroic = true
        end
    end

    local tagged = TAGS[qid]
    if tagged then
        tags[tagged] = true
    end

    TAG_CACHE[qid] = tags
    return tags
end

-- nil        offer it
-- "hidden"   leave it out of the menu (Config.HIDE)
-- "reason"   list it greyed out (Config.OFFER = false)
-- nil = offer it, "hidden" = leave it out, otherwise the reason to show;
-- the second value is the kind's name either way
local function TypeVerdict(qid)
    local tags = QuestTags(qid)
    for _, name in ipairs(TYPE_ORDER) do
        if tags[name] then
            if Config.HIDE and Config.HIDE[name] then
                return "hidden", name
            end
            if Config.OFFER and Config.OFFER[name] == false then
                return TYPE_LABEL[name] or name, name
            end
        end
    end
    return nil
end

-- --------------------------------------------------------------------------
--  QUESTS THAT ARE HANDED IN SOMEWHERE ELSE
-- --------------------------------------------------------------------------

-- A few of an instance's quests are not finished inside it: "take this
-- to Hamuul Runetotem in Thunder Bluff" and the like.  They are the
-- ones with nothing to kill, collect or reach, whose turn-in NPCs all
-- stand outside.  Detected rather than listed by hand, because a wrong
-- guess must only ever misplace a quest, never hide it.
local ERRANDS = {}

-- the maps this instance's NPCs stand on
local function DungeonMaps(dungeon)
    local maps = {}
    for _, spawn in ipairs(dungeon.giverSpawns or {}) do
        maps[tonumber(spawn[1]) or 0] = true
    end
    return maps
end

-- { [questId] = { creatureEntry, ... } } - everyone who takes these
-- quests off the player's hands.  Our own NPCs are left out: they stand
-- in the instance by definition, so they would hide the answer.
local function QuestEnders(ids)
    local enders = {}
    if not ids or #ids == 0 then
        return enders
    end
    for _, chunk in ipairs(Chunks(ids, 500)) do
        for row in Rows("SELECT `id`, `quest` FROM `creature_questender` "
                        .. "WHERE `quest` IN ("
                        .. table.concat(chunk, ",") .. ")") do
            local qid, entry = tonumber(row.quest), tonumber(row.id)
            if qid and entry and not BY_ENTRY[entry] then
                enders[qid] = enders[qid] or {}
                enders[qid][#enders[qid] + 1] = entry
            end
        end
    end
    return enders
end

-- which of these creatures are standing on one of these maps
local function SpawnsOn(entries, maps)
    local inside, seen, wanted, mapList = {}, {}, {}, {}
    for _, entry in ipairs(entries) do
        if entry and not seen[entry] then
            seen[entry] = true
            wanted[#wanted + 1] = entry
        end
    end
    for map in pairs(maps) do
        mapList[#mapList + 1] = tostring(map)
    end
    if #wanted == 0 or #mapList == 0 then
        return inside
    end
    local column = Config.CREATURE_ID_COLUMN or "id"
    for _, chunk in ipairs(Chunks(wanted, 500)) do
        for row in Rows(string.format(
            "SELECT `%s` FROM `creature` WHERE `%s` IN (%s) AND `map` IN (%s)",
            column, column, table.concat(chunk, ","),
            table.concat(mapList, ","))) do
            local entry = tonumber(row[column])
            if entry then
                inside[entry] = true
            end
        end
    end
    return inside
end

local function DetectErrands(dungeon)
    local candidates, ids = {}, {}
    for _, qid in ipairs(dungeon.start or {}) do
        local a = ATTR and ATTR[qid]
        if a and not a.o then
            candidates[qid] = true
            ids[#ids + 1] = qid
        end
    end

    local enders = QuestEnders(ids)
    local wanted = {}
    for _, list in pairs(enders) do
        for _, entry in ipairs(list) do
            wanted[#wanted + 1] = entry
        end
    end
    local inside = SpawnsOn(wanted, DungeonMaps(dungeon))

    local found = {}
    for qid in pairs(candidates) do
        local list = enders[qid]
        if list then
            local outside = true
            for _, entry in ipairs(list) do
                if inside[entry] then
                    outside = false
                    break
                end
            end
            if outside then
                found[qid] = true
            end
        end
    end
    return found
end

-- cached per dungeon: none of it changes while the server is up
local function ErrandsOf(dungeon, dungeonId)
    if ERRANDS[dungeonId] == nil then
        ERRANDS[dungeonId] = DetectErrands(dungeon)
    end
    return ERRANDS[dungeonId]
end

-- The instance's name in the player's own language.  He is standing
-- inside it when he talks to us, so his zone is the instance's zone.
-- The name in the data file is the fallback, for a server whose area
-- data carries no translation and until somebody has been inside.
local function DungeonName(player, dungeon)
    if type(GetAreaName) == "function" then
        local zone = nil
        if type(player.GetMapId) == "function"
                and type(player.GetZoneId) == "function" then
            local okMap, map = pcall(function() return player:GetMapId() end)
            if okMap and DungeonMaps(dungeon)[tonumber(map) or 0] then
                local okZone, id = pcall(function()
                    return player:GetZoneId()
                end)
                if okZone and type(id) == "number" and id > 0 then
                    dungeon.zones = dungeon.zones or {}
                    dungeon.zones[tonumber(map)] = id
                    zone = id
                end
            end
        end
        if not zone and dungeon.zones then
            for _, known in pairs(dungeon.zones) do
                zone = known
                break
            end
        end
        if zone then
            local index = PlayerLocale(player)
            for _, locale in ipairs({ index, 0 }) do
                local ok, name = pcall(GetAreaName, zone, locale)
                if ok and type(name) == "string" and name ~= "" then
                    return name
                end
            end
        end
    end
    return dungeon.name
end

-- --------------------------------------------------------------------------
--  THE LIST OF QUESTS
-- --------------------------------------------------------------------------

-- How the quests that are out of reach are grouped: everything blocked
-- for the same reason sits together, then by level, and a kind turned
-- off in Config.OFFER comes last.  Longest prefix first inside a group,
-- because reasons are told apart by their prefix - "needs skill" has
-- to be tested before the bare "needs ".
local REASON_ORDER = {
    "ready",
    "in log",
    "failed",
    "done",
    "lvl ",
    "max lvl ",
    "rep too low",
    "rep too high",
    "needs skill",
    "needs one: ",
    "needs ",
    "conflicts: ",
    "follow-up: ",
    "finish ",
    "superseded: ",
    "breadcrumb: ",
    "only",
    "chain",
    "breadcrumb target",
    "breadcrumb",
    "group",
    "escort",
    "heroic",
    "raid",
    "event",
    "repeatable",
    "errand",
    "attunement",
    "outside",
}

local function ReasonRank(reason)
    for index, prefix in ipairs(REASON_ORDER) do
        if reason:sub(1, #prefix) == prefix then
            return index
        end
    end
    return #REASON_ORDER + 1
end

-- what you can take first, then the rest grouped by reason and level
local function SortStartList(list)
    table.sort(list, function(a, b)
        if (a.section == nil) ~= (b.section == nil) then
            return a.section == nil
        end
        if (a.locked == nil) ~= (b.locked == nil) then
            return a.locked == nil
        end
        if a.locked and b.locked then
            local ra, rb = ReasonRank(a.locked), ReasonRank(b.locked)
            if ra ~= rb then
                return ra < rb
            end
        end
        local la, lb = QuestLevelOf(a.qid), QuestLevelOf(b.qid)
        if la ~= lb then
            return la < lb
        end
        return a.qid < b.qid
    end)
end

-- the dungeon's quests with the reason each one is out of reach, and
-- how many the kind filters left out
local function BuildStartList(player, dungeon, dungeonId)
    BuildIndexes()
    local list, hidden = {}, 0
    local errands = ErrandsOf(dungeon, dungeonId)
    for index, qid in ipairs(dungeon.start or {}) do
        if index > MAX_ENTRIES then
            break
        end

        local section = nil
        if errands and errands[qid] then
            section = "errand"
        elseif QuestTags(qid).outside then
            section = "outside"
        end
        if section and Config.HIDE and Config.HIDE[section] then
            hidden = hidden + 1
        else
            local verdict, kind = TypeVerdict(qid)
            if section and Config.OFFER and Config.OFFER[section] == false then
                verdict, kind = TYPE_LABEL[section], section
                section = nil
            end
            if verdict == "hidden" then
                hidden = hidden + 1
            else
                local status = player:GetQuestStatus(qid)
                local reason, gate
                if status == QUEST_STATUS_NONE then
                    reason, gate = Gate(player, qid)
                    if not reason then
                        reason, gate = verdict, kind
                    end
                elseif status == QUEST_STATUS_REWARDED then
                    reason, gate = "done", "done"
                elseif status == QUEST_STATUS_COMPLETE then
                    reason, gate = "ready", "ready"
                elseif status == QUEST_STATUS_FAILED then
                    reason, gate = "failed", "failed"
                else
                    reason, gate = "in log", "inLog"
                end
                list[#list + 1] = { qid = qid, locked = reason, gate = gate,
                                    section = section }
            end
        end
    end
    SortStartList(list)
    return list, hidden
end

local function CountTakeable(list)
    local n = 0
    for _, e in ipairs(list) do
        if not e.locked then n = n + 1 end
    end
    return n
end

-- whether a quest out of reach still gets a row, from Config.SHOW_UNAVAILABLE
local function Shown(gate)
    local show = Config.SHOW_UNAVAILABLE
    if type(show) == "table" then
        return show[gate] ~= false
    end
    return show ~= false
end

-- a section heading: a row that does nothing when it is clicked
local function SectionRow(text, page)
    return {
        text    = M_TEAL .. text .. RESET,
        icon    = RowIcon("heading"),
        intid   = GlobalIntid(ACTION_NOOP, page),
        heading = true,
    }
end

-- Three sections, in this order: what you can take here, what you can
-- take but finish somewhere else, and what you cannot take.  The first
-- is headed with the instance's own name, so the menu says where you
-- are without spending a row on a title.  A section with nothing in it
-- is left out, heading included.
local function ShowStartMenu(player, creature, dungeon, dungeonId, page)
    local list, hidden = BuildStartList(player, dungeon, dungeonId)
    local takeable = CountTakeable(list)
    if hidden > 0 then
        Debug("%d quest%s of %s are hidden by the type filters", hidden,
              hidden == 1 and "" or "s", dungeon.name or "this dungeon")
    end

    local available, elsewhere, unavailable = {}, {}, {}
    local plevel, skipped = player:GetLevel(), 0

    for index, e in ipairs(list) do
        if not e.locked or Shown(e.gate) then
            local lvl = QuestLevelOf(e.qid)
            local text
            if e.locked then
                text = string.format("%s[%d] %s  (%s)|r", M_LOCKED, lvl,
                                     Title(player, e.qid), e.locked)
            else
                text = string.format("%s[%d] %s|r",
                                     QuestColour(lvl, plevel), lvl,
                                     Title(player, e.qid))
            end
            local row = {
                text  = text,
                icon  = e.locked and RowIcon("locked") or RowIcon("quest"),
                intid = EntryIntid(page, index),
            }
            if e.locked then
                unavailable[#unavailable + 1] = row
            elseif e.section then
                elsewhere[#elsewhere + 1] = row
            else
                available[#available + 1] = row
            end
        else
            skipped = skipped + 1
        end
    end

    if skipped > 0 then
        Debug("%d quest%s of %s are hidden by SHOW_UNAVAILABLE", skipped,
              skipped == 1 and "" or "s", dungeon.name or "this dungeon")
    end

    local entries = {}

    if takeable > 0 and Config.SHOW_TAKE_ALL then
        table.insert(entries, {
            text  = string.format("%sTake every available quest (%d)|r",
                                  M_GREEN, takeable),
            icon  = RowIcon("command"),
            intid = GlobalIntid(ACTION_TAKE_ALL, page),
        })
    end

    local header = DungeonName(player, dungeon)

    for _, group in ipairs({ { header, available },
                             { "Outside the instance", elsewhere },
                             { "Unavailable", unavailable } }) do
        if #group[2] > 0 then
            table.insert(entries, SectionRow(group[1], page))
            for _, row in ipairs(group[2]) do
                entries[#entries + 1] = row
            end
        end
    end

    if #entries == 0 then
        table.insert(entries, {
            text  = M_GREY .. "There are no quests left for you here.|r",
            icon  = RowIcon("empty"),
            intid = GlobalIntid(ACTION_NOOP, page),
        })
    end

    local pages = #PageStarts(entries)
    page = math.min(math.max(page or 1, 1), pages)

    DrawPage(player, creature, entries, page, SENDER_START,
             Config.NPC_TEXT_START)
    return list
end

-- --------------------------------------------------------------------------
--  TAKING QUESTS
-- --------------------------------------------------------------------------

-- Eluna's AddQuest() only asks "does it fit?", so the gates above are
-- what decide whether a quest is offered at all.
local function TakeQuest(player, qid)
    player:AddQuest(qid)
    return player:GetQuestStatus(qid) ~= QUEST_STATUS_NONE
end

local function TakeList(player, list)
    local added, failed = 0, 0
    for _, e in ipairs(list) do
        if not e.locked then
            if TakeQuest(player, e.qid) then
                added = added + 1
            else
                failed = failed + 1
            end
        end
    end
    if added > 0 then
        Msg(player, string.format("%sAdded %d quest%s to your log.", C_GREEN,
                                  added, added == 1 and "" or "s"))
    end
    if failed > 0 then
        Msg(player, string.format(
            "%s%d quest%s could not be added - your quest log is full (or the "
            .. "quest is started by an item).", C_RED, failed,
            failed == 1 and "" or "s"))
    end
    if added == 0 and failed == 0 then
        Msg(player, C_GREY .. "Nothing left to take here.")
    end
end

-- --------------------------------------------------------------------------
--  WHAT HAPPENS WHEN THE NPC IS SPOKEN TO
-- --------------------------------------------------------------------------

local function OnStartHello(event, player, creature)
    local dungeon, dungeonId = DungeonOf(creature:GetEntry())
    if not dungeon then
        return false
    end
    if not LoadAttributes() then
        Msg(player, C_RED .. "This NPC is not set up correctly - see the "
                 .. "server console.")

        return false
    end
    ShowStartMenu(player, creature, dungeon, dungeonId, 1)
    return true
end

-- clicking an entry: take it, say why it cannot be taken, or turn the
-- page
local function OnStartSelect(event, player, creature, sender, intid)
    if sender ~= SENDER_START then
        return
    end
    local dungeon, dungeonId = DungeonOf(creature:GetEntry())
    if not dungeon or not LoadAttributes() then
        return
    end

    local kind, page, index = DecodeIntid(intid)

    if kind == "page" then
        ShowStartMenu(player, creature, dungeon, dungeonId, page)
        return
    end

    if kind == "takeall" then
        TakeList(player, BuildStartList(player, dungeon, dungeonId))
        ShowStartMenu(player, creature, dungeon, dungeonId, page)
        return
    end

    if kind == "noop" then
        ShowStartMenu(player, creature, dungeon, dungeonId, page)
        return
    end

    local entry = BuildStartList(player, dungeon, dungeonId)[index]
    if entry then
        if entry.locked then
            Msg(player, string.format("%s: %s%s", QuestLink(player, entry.qid),
                                      C_GREY, entry.locked))
        elseif TakeQuest(player, entry.qid) then
            Msg(player, string.format("%sQuest accepted: %s%s", C_GREEN,
                                      QuestLink(player, entry.qid), RESET))
        else
            Msg(player, string.format(
                "%sCould not add %s%s - your quest log is full or the quest is "
                .. "started by an item.", C_RED, QuestLink(player, entry.qid),
                C_RED))
        end
    end
    ShowStartMenu(player, creature, dungeon, dungeonId, page)
end

-- back to the entrance of the map the player is standing in; dungeons
-- with several wings each keep their own
local function TeleportToEntrance(player, dungeon)
    local map = player:GetMapId()
    local pos = nil
    for _, p in ipairs(dungeon.giverSpawns or {}) do
        if p[1] == map then
            pos = p
            break
        end
    end
    if not pos then
        pos = dungeon.giverSpawns and dungeon.giverSpawns[1]
    end
    if not pos then
        Msg(player, C_RED .. "No entrance is known for this instance.")
        return false
    end
    player:GossipComplete()
    player:Teleport(pos[1], pos[2], pos[3], pos[4], pos[5])
    Msg(player, C_TEAL .. "Back to the entrance.")
    return true
end

-- The return portal is an object rather than a gossip option on the end
-- NPC because the core rebuilds an NPC's gossip from two sources on
-- every right click and can drop a database option; an object's use
-- event always fires.
local function OnPortalUse(event, go, player)
    local entry = go and go.GetEntry and go:GetEntry()
    local dungeon = entry and DUNGEONS[entry - Config.PORTAL_BASE]
    if not dungeon then
        return
    end
    Debug("%s used the exit of %s", player:GetName(), dungeon.name)
    TeleportToEntrance(player, dungeon)
    return true
end

-- --------------------------------------------------------------------------
--  HOOKING THE NPCS AND THE PORTALS UP
-- --------------------------------------------------------------------------

local registered = {}

local nRegistered, nNoEntry, nMissing, nDuplicate = 0, 0, 0, 0
local noEntrySeen, missingSeen = {}, {}
local failures = {}

-- not in the database: the dungeon is switched off in
-- dungeon-quest.sql, or it was never imported.  Expected, so it is
-- counted, not listed.
local function CountMissing(entry)
    local tag = tostring(entry)
    if not missingSeen[tag] then
        missingSeen[tag] = true
        nMissing = nMissing + 1
    end
end

-- which of `entries` really exist; nil when the database cannot be
-- asked, in which case the caller registers everything and takes
-- Eluna's word
local function ExistingEntries(entries, tbl, column)
    if type(WorldDBQuery) ~= "function" or #entries == 0 then
        return nil
    end
    local found = {}
    for _, chunk in ipairs(Chunks(entries, 100)) do
        local sql = string.format("SELECT `%s` FROM `%s` WHERE `%s` IN (%s)",
                                  column, tbl, column,
                                  table.concat(chunk, ","))
        local ok, result = pcall(WorldDBQuery, sql)
        if not ok or not result then
            return nil
        end
        if result:GetRowCount() > 0 then
            repeat
                local row = result:GetRow()
                local value = row and row[column]
                if value then
                    found[tonumber(value) or value] = true
                end
            until not result:NextRow()
        end
    end
    return found
end

-- registrar is RegisterCreatureGossipEvent or RegisterGameObjectEvent;
-- existSet is the [entry] = true table for that kind of thing, when it
-- is known
local function Register(registrar, entry, event, func, existSet)
    if type(registrar) ~= "function" then
        failures[#failures + 1] = "the Eluna registration function is missing"
                                  .. " - is this server running Eluna?"
        return false
    end

    if type(entry) ~= "number" or entry <= 0 or entry % 1 ~= 0 then
        local tag = tostring(entry)
        if not noEntrySeen[tag] then
            noEntrySeen[tag] = true
            nNoEntry = nNoEntry + 1
        end
        Debug("no creature entry for %s - skipped", tostring(entry))
        return false
    end

    if existSet and not existSet[entry] then
        CountMissing(entry)
        Debug("entry %d is not in the database - skipped", entry)
        return false
    end

    local key = entry * 10 + event
    if registered[key] then
        nDuplicate = nDuplicate + 1
        Debug("entry %d (event %d) is claimed by more than one dungeon - "
              .. "registered once only", entry, event)
        return false
    end

    local ok, err = pcall(registrar, entry, event, func)
    if not ok then
        local msg = tostring(err)

        if msg:find("Couldn't find a creature", 1, true) then
            CountMissing(entry)
            Debug("entry %d is not in the database: %s", entry, msg)
        else
            failures[#failures + 1] = string.format("entry %d (event %d): %s",
                                                    entry, event, msg)
        end
        return false
    end

    registered[key] = true
    nRegistered = nRegistered + 1
    return true
end

local startEntries, portalEntries, skippedDungeons, noEntrance = {}, {}, {}, {}
local dungeonIds = {}
for id in pairs(DUNGEONS) do dungeonIds[#dungeonIds + 1] = id end
table.sort(dungeonIds)

for _, id in ipairs(dungeonIds) do
    local d = DUNGEONS[id]
    local key = d.key
    if Config.DISABLE[key] then
        skippedDungeons[#skippedDungeons + 1] = (d.name or tostring(id))
                                                .. " (" .. key .. ")"
    else

        if d.giver and d.start and #d.start > 0 then
            startEntries[#startEntries + 1] = d.giver
        end

        if d.ender and d.ender > 0 then
            if d.giverSpawns and #d.giverSpawns > 0 then
                portalEntries[#portalEntries + 1] = Config.PORTAL_BASE + id
            else
                noEntrance[#noEntrance + 1] = d.name or tostring(id)
            end
        end
    end
end

local nWanted, npcExists, portalExists = 0, nil, nil
do
    local wanted, seen = {}, {}
    for _, entry in ipairs(startEntries) do
        if not seen[entry] then
            seen[entry] = true
            wanted[#wanted + 1] = entry
        end
    end
    nWanted = #wanted + #portalEntries
    npcExists = ExistingEntries(wanted, "creature_template", "entry")
    portalExists = ExistingEntries(portalEntries, "gameobject_template", "entry")
end

local nStartOK, nPortalOK = 0, 0

for _, entry in ipairs(startEntries) do

    local hello = Register(RegisterCreatureGossipEvent, entry,
                           GOSSIP_EVENT_ON_HELLO, OnStartHello, npcExists)
    local select = Register(RegisterCreatureGossipEvent, entry,
                            GOSSIP_EVENT_ON_SELECT, OnStartSelect, npcExists)
    if hello and select then
        nStartOK = nStartOK + 1
    end
end

for _, entry in ipairs(portalEntries) do
    if Register(RegisterGameObjectEvent, entry, GAMEOBJECT_EVENT_ON_USE,
                OnPortalUse, portalExists) then
        nPortalOK = nPortalOK + 1
    end
end

-- --------------------------------------------------------------------------
--  ONE LINE AT STARTUP, SO A SILENT FAILURE IS VISIBLE
-- --------------------------------------------------------------------------

local nDungeons = 0
for _ in pairs(DUNGEONS) do nDungeons = nDungeons + 1 end

local nTags = 0
for _ in pairs(TAGS) do nTags = nTags + 1 end

print(string.format("[DungeonQuestNPC] loaded - %d start NPCs, %d return portals, "
                    .. "%d dungeons, %d quests, %d tagged quests (%d handlers "
                    .. "registered; quest details are read from the world "
                    .. "database on first use).", nStartOK, nPortalOK, nDungeons,
                    #QuestIds(), nTags, nRegistered))

if DQN.TAGS == nil then
    print("[DungeonQuestNPC] the data file carries no quest tags - the "
          .. "\"outside\" and \"attunement\" quests are then offered like "
          .. "any other.")
end

if #skippedDungeons > 0 then
    table.sort(skippedDungeons)
    print("[DungeonQuestNPC] disabled through Config.DISABLE: "
          .. table.concat(skippedDungeons, ", "))
end

if nNoEntry > 0 then
    print(string.format("[DungeonQuestNPC] %d dungeon NPC%s %s no creature "
                        .. "entry in the data file - skipped.",
                        nNoEntry, nNoEntry == 1 and "" or "s",
                        nNoEntry == 1 and "has" or "have"))
end

if nMissing > 0 then
    print(string.format("[DungeonQuestNPC] %d of %d NPC/portal entries are not in "
                        .. "the database - expected for a dungeon that is "
                        .. "switched off in the SQL script (Config.DEBUG lists "
                        .. "them).", nMissing, nWanted))
end

if nRegistered == 0 then
    print("[DungeonQuestNPC] nothing of ours is in the database - import "
          .. "dungeon-quest.sql and reload Eluna; until then the dungeon "
          .. "NPCs cannot be spoken to.")
end

if #noEntrance > 0 then
    table.sort(noEntrance)
    print("[DungeonQuestNPC] no entrance on file for "
          .. table.concat(noEntrance, ", ")
          .. " - their return portals have nowhere to send you, so they are left "
          .. "unhooked (they still spawn).")
end

if nDuplicate > 0 then
    print(string.format("[DungeonQuestNPC] %d duplicate handler%s ignored "
                        .. "(set Config.DEBUG = true for the entries).",
                        nDuplicate, nDuplicate == 1 and "" or "s"))
end

if #failures > 0 then
    print(string.format("[DungeonQuestNPC] %d handler%s could NOT be "
                        .. "registered:", #failures,
                        #failures == 1 and "" or "s"))
    for i = 1, math.min(#failures, 10) do
        print("  - " .. failures[i])
    end
    if #failures > 10 then
        print(string.format("  - and %d more", #failures - 10))
    end
end
