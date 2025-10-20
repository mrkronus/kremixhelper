--[[============================================================================
  StatsTracker.lua
  Purpose:
    - Parse Infinite Power aura stat effects
    - Return normalized stat lines for display
============================================================================]]--

local _, Addon = ...

---@class StatsTracker
local StatsTracker = {}
Addon.StatsTracker = StatsTracker


--------------------------------------------------------------------------------
-- Stat Mapping
--------------------------------------------------------------------------------

-- Canonical mapping of aura.points indices
-- NOTE: this is unused and is just here as documentation of:
-- https://www.wowhead.com/spell=1232454/infinite-power
StatsTracker.STAT_MAP = {
    [1]  = "Primary Stats",   -- Str/Agi/Int
    [2]  = "Stamina",
    [3]  = "Attack Speed",
    [4]  = "Critical Strike",
    [5]  = "Versatility",
    [6]  = "Mastery",
    [7]  = "Speed",
    [8]  = "Leech",
    [9]  = "Avoidance",
    [10] = "Experience Gain", -- from kills
    [11] = "Experience Gain", -- from quests (though should be the same as the other)
    [12] = "Stamina",
    [13] = "Unknown Stat",    -- usually the flat primary stat increase
    [14] = "Armor %",
    [15] = "Mastery Rating",
    [16] = "Stamina",         -- for some reason it's split into two stats
}


--------------------------------------------------------------------------------
-- Display Spec (order + grouping)
--------------------------------------------------------------------------------

StatsTracker.STAT_DISPLAY = {
    { label = "Primary",         type = "percent", indices = { 1 } },
    { label = "Primary",         type = "flat",    indices = { 13 } },
    { label = "Stamina",         type = "percent", indices = { 2 } },
    { label = "Stamina",         type = "flat",    indices = { 12, 16 } },
    { label = "Attack Speed",    type = "percent", indices = { 3 } },
    { label = "Critical Strike", type = "percent", indices = { 4 } },
    { label = "Versatility",     type = "percent", indices = { 5 } },
    { label = "Mastery",         type = "percent", indices = { 6 } },
    { label = "Mastery Rating",  type = "flat",    indices = { 15 } },
    { label = "Speed",           type = "flat",    indices = { 7 } },
    { label = "Leech",           type = "percent", indices = { 8 } },
    { label = "Avoidance",       type = "flat",    indices = { 9 } },
    { label = "Armor",           type = "percent", indices = { 14 } },
    { label = "Experience Gain", type = "percent", indices = { 10 } },
    -- 11 is ignored since it's a duplicate of 10
}


--------------------------------------------------------------------------------
-- Public: Stat Line Builder
--------------------------------------------------------------------------------

local function GetPrimaryStatName()
    if UnitStat("player", 1) > UnitStat("player", 2) and UnitStat("player", 1) > UnitStat("player", 4) then
        return "Strength"
    elseif UnitStat("player", 2) > UnitStat("player", 1) and UnitStat("player", 2) > UnitStat("player", 4) then
        return "Agility"
    else
        return "Intellect"
    end
end

---Build normalized stat lines from an aura.
---@param aura table Aura data
---@return string[] lines List of formatted stat lines
function StatsTracker:GetStatLines(aura)
    local lines = {}
    if not aura then
        return lines
    end

    local function addLine(value, suffix, isPercent)
        local prefix = "+" .. FormatWithCommas(value)
        if isPercent then
            table.insert(lines, prefix .. "% " .. suffix)
        else
            table.insert(lines, prefix .. " " .. suffix)
        end
    end

    for _, entry in ipairs(self.STAT_DISPLAY) do
        local total = 0
        for _, idx in ipairs(entry.indices) do
            if aura.points[idx] then
                total = total + aura.points[idx]
            end
        end

        if total > 0 then
            if entry.label == "Primary" then
                addLine(total, GetPrimaryStatName(), entry.type == "percent")
            else
                addLine(total, entry.label, entry.type == "percent")
            end
        end
    end

    return lines
end